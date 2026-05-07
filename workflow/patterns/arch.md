System architecture patterns. Apply when designing modules, layers, and cross-cutting concerns.

## Patterns

### Three-Layer Model — Domain → Application → Infrastructure
Dependencies always point inward. Domain never imports from infrastructure.

DO:
```
domain/order.py          # pure business rules — no imports from infra
application/order_svc.py # orchestrates domain + calls infra via interfaces
infrastructure/order_repo.py  # implements repository interface, talks to DB
```

DON'T:
```
domain/order.py
  from infrastructure.db import session  # domain importing from infra — forbidden
```

---

### HTTP Layer — Validate, Delegate, Respond
No business logic in route handlers. Validates input, calls application layer, formats response. Nothing else.

DO:
```
@router.post('/orders')
async def create_order(body: CreateOrderRequest, svc: OrderService = Depends()):
    result = await svc.create(body.to_domain())
    return CreateOrderResponse.from_domain(result)
```

DON'T:
```
@router.post('/orders')
async def create_order(body: CreateOrderRequest, db: Session = Depends()):
    if body.total < 0:
        raise HTTPException(400, 'negative total')
    order = Order(id=uuid4(), total=body.total, ...)
    db.add(order)
    db.commit()
    await email.send(body.user_id, 'order created')
    return {'id': str(order.id)}
```

---

### DB Layer — Queries Only
No business logic in repositories. Transformations happen in application or domain layer.

DO:
```
class OrderRepository:
    async def get_by_id(self, order_id: UUID) -> OrderRow | None:
        result = await self.session.execute(select(OrderRow).where(OrderRow.id == order_id))
        return result.scalar_one_or_none()
```

DON'T:
```
class OrderRepository:
    async def get_and_apply_discount(self, order_id: UUID, rate: float) -> OrderRow:
        order = await self.get_by_id(order_id)
        order.total = order.total * (1 - rate)   # transformation in DB layer
        await self.session.commit()
        return order
```

---

### Module Boundaries — Communicate via Interfaces
Modules communicate through defined interfaces, not by reaching into each other's internals.

DO:
```
# billing module exposes an interface
class PaymentGateway(Protocol):
    async def charge(self, amount: int, token: str) -> ChargeResult: ...

# order module depends on the interface, not the implementation
class OrderService:
    def __init__(self, payments: PaymentGateway): ...
```

DON'T:
```
# order module reaches into billing internals
from billing.stripe_client import StripeClient, build_charge_payload
```

---

### Ports and Adapters — Interface Every External Dependency
Define an interface for every external dependency (DB, email, payment, queue). Never call external services directly from business logic.

DO:
```
class EmailPort(Protocol):
    async def send(self, to: str, subject: str, body: str) -> None: ...

class UserService:
    def __init__(self, email: EmailPort): ...  # depends on port, not implementation
```

DON'T:
```
class UserService:
    async def register(self, user: User) -> None:
        ...
        await sendgrid.send(...)  # external service called directly from business logic
```

---

### God Object Detection — Split at 5+ Responsibilities
If a class or module has more than 5 responsibilities, split it. Signs: long import list, methods that don't use `self`/`this`.

DO:
```
UserAuthService      # authentication only
UserProfileService   # profile management only
UserNotificationService  # notification preferences only
```

DON'T:
```
UserService  # authenticates, manages profile, sends emails,
             # handles billing, generates reports, manages permissions
```

---

### Unidirectional Data Flow — No Circular Dependencies
Data flows in one direction through the system. No circular imports between modules.

DO:
```
auth → user → billing → notification
# each layer only depends on layers below it
```

DON'T:
```
auth imports billing
billing imports user
user imports auth   # circular — any change can cascade unpredictably
```

---

### Error Handling at Boundaries
Catch errors at the boundary where they enter your system (HTTP handler, queue consumer). Let them propagate naturally inside.

DO:
```
@router.post('/webhooks/payment')
async def payment_webhook(body: PaymentEvent):
    try:
        await payment_svc.process(body)
    except InsufficientFundsError as e:
        raise HTTPException(422, detail=e.message)
    except Exception:
        logger.exception('unhandled payment webhook error')
        raise HTTPException(500)
```

DON'T:
```
async def calculate_fee(amount: float) -> float:
    try:
        return amount * FEE_RATE
    except Exception:
        return 0.0   # swallowing errors inside business logic
```

---

## Anti-Patterns

### Anemic Domain Model
Domain objects are just data bags with no behaviour. All logic lives in service classes that manipulate the domain objects.
→ Move behaviour into domain objects. `order.apply_discount(rate)` not `order_service.apply_discount(order, rate)`.

### Shared Mutable State
Two modules write to the same global dict or singleton. Race conditions, hard to test.
→ Pass state explicitly. Use dependency injection.

### Leaky Abstraction
Repository returns SQLAlchemy model objects to the service layer. Service layer starts using `.session`, `.lazy`, ORM internals.
→ Repository converts ORM rows to domain types before returning. Service layer never sees ORM objects.

### Cross-Module Direct Imports
`from billing.internal.stripe_adapter import StripeClient` used in the order module.
→ Billing module exposes a public interface. Everything else imports from that.
