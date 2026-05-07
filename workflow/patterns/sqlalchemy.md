SQLAlchemy async patterns. Apply to every model definition, query, and session usage.

## Patterns

### Async Session — Use Async Session Factory
Never use sync sessions in an async context. Use `async_sessionmaker` with `AsyncSession`.

DO:
```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

engine = create_async_engine(settings.db_url)
async_session = async_sessionmaker(engine, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session
```

DON'T:
```python
from sqlalchemy.orm import Session
engine = create_engine(settings.db_url)   # sync engine in async app

def get_db():
    return Session(engine)   # sync session, will block the event loop
```

---

### Model Definition — Use Mapped[T] Typed Columns
No untyped `Column()`. Use `Mapped[T]` with `mapped_column()` for full type inference.

DO:
```python
class Order(Base):
    __tablename__ = 'orders'

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey('users.id'), nullable=False)
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    created_at: Mapped[datetime] = mapped_column(server_default=func.now())
```

DON'T:
```python
class Order(Base):
    __tablename__ = 'orders'
    id = Column(UUID, primary_key=True)       # untyped, no inference
    user_id = Column(UUID, nullable=False)
    total = Column(Numeric(12, 2))
```

---

### Query Patterns — Use select() Statements
Never use the legacy `Query` API (`session.query(...)`). Use `select()` with `session.execute()`.

DO:
```python
async def get_by_user(self, user_id: UUID) -> list[Order]:
    result = await self.session.execute(
        select(Order).where(Order.user_id == user_id).order_by(Order.created_at.desc())
    )
    return list(result.scalars().all())
```

DON'T:
```python
async def get_by_user(self, user_id: UUID):
    return self.session.query(Order).filter_by(user_id=user_id).all()  # legacy API
```

---

### Transaction Scope — One Transaction per Request
Commit at the HTTP boundary, not inside business logic or repositories. Pass the session; don't manage transactions in service layer.

DO:
```python
# repository — no commit
async def save(self, order: Order) -> None:
    self.session.add(order)
    # no commit here

# FastAPI dependency — commits after handler returns
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        async with session.begin():
            yield session
        # auto-commits on clean exit, rolls back on exception
```

DON'T:
```python
async def create_order(self, data: CreateOrderData) -> Order:
    order = Order(**data.dict())
    self.session.add(order)
    await self.session.commit()   # committing inside business logic
    return order
```

---

### Schema Changes — Migrations Only
Never `ALTER TABLE` manually or in application startup code. All schema changes go through the migration tool.

DO:
```bash
# generate migration after editing the model
alembic revision --autogenerate -m "add_orders_status_column"
# review the generated file, then apply
alembic upgrade head
```

DON'T:
```python
# in app startup
async def on_startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)  # bypasses migrations
```

---

### Relationship Loading — Declare Strategy Explicitly
Never rely on default implicit loading in async context — it raises `MissingGreenlet` errors. Declare `lazy`, `selectin`, or `joined` explicitly.

DO:
```python
class Order(Base):
    items: Mapped[list[OrderItem]] = relationship(
        'OrderItem', back_populates='order', lazy='selectin'
    )
```

DON'T:
```python
class Order(Base):
    items = relationship('OrderItem')   # default lazy loading — breaks in async
```

---

### Session Lifecycle — Never Share Sessions Across Requests
One session per request. Never store a session on a long-lived object or share it across background tasks.

DO:
```python
@router.get('/orders', response_model=list[OrderResponse])
async def list_orders(db: AsyncSession = Depends(get_db)):
    repo = OrderRepository(db)   # session scoped to this request
    return await repo.list_all()
```

DON'T:
```python
class OrderService:
    def __init__(self):
        self.db = AsyncSession(engine)   # session lives for the lifetime of the service

    async def list_orders(self):
        return await self.db.execute(select(Order))   # shared across all requests
```

---

## Anti-Patterns

### Lazy Loading in Async
Accessing a relationship attribute without a strategy declared causes `MissingGreenlet` errors in async SQLAlchemy.
→ Always declare `lazy='selectin'` or `lazy='joined'` on relationships used in async code.

### `create_all` in Production
`Base.metadata.create_all()` in app startup silently skips columns and constraints that already exist.
→ Use Alembic migrations exclusively. `create_all` is for test fixtures only.

### Raw SQL Strings
`session.execute(text('SELECT * FROM orders WHERE id = :id'), {'id': order_id})` scattered through the codebase.
→ Use the ORM `select()` API. Raw SQL belongs only in migrations or highly optimised queries, isolated in the repository layer.

### Session in Background Task
Passing an HTTP-scoped `AsyncSession` into a `BackgroundTask` — the session closes when the request ends.
→ Background tasks must open their own session via the session factory.
