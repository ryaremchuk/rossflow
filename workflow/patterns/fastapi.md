FastAPI-specific patterns. Apply to every route, model, and dependency in a FastAPI application.

## Patterns

### Route Definition — response_model and Docstring Mandatory
Every route must declare `response_model` and a one-line docstring.

DO:
```python
@router.post('/orders', response_model=CreateOrderResponse)
async def create_order(body: CreateOrderRequest, svc: OrderService = Depends(get_order_service)):
    """Create a new order and return its ID."""
    return await svc.create(body)
```

DON'T:
```python
@router.post('/orders')
async def create_order(body, svc=Depends(get_order_service)):
    return await svc.create(body)
```

---

### Request Validation — All Input via Pydantic Models
Never read raw request body or access `request.json()` directly. All input is validated by Pydantic before the handler runs.

DO:
```python
class CreateOrderRequest(BaseModel):
    user_id: UUID
    items: list[OrderItem]
    currency: str = 'USD'

@router.post('/orders', response_model=CreateOrderResponse)
async def create_order(body: CreateOrderRequest): ...
```

DON'T:
```python
@router.post('/orders')
async def create_order(request: Request):
    data = await request.json()
    user_id = data.get('user_id')   # no validation, no types
```

---

### Dependency Injection — Use Depends() for Shared Resources
Never instantiate services, DB sessions, or clients inside route functions. Use `Depends()`.

DO:
```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

@router.get('/orders/{order_id}', response_model=OrderResponse)
async def get_order(order_id: UUID, db: AsyncSession = Depends(get_db)):
    ...
```

DON'T:
```python
@router.get('/orders/{order_id}')
async def get_order(order_id: UUID):
    db = AsyncSession(engine)    # session created and never properly closed
    svc = OrderService(db)
    ...
```

---

### Error Handling — HTTPException with Explicit Status Codes
Raise `HTTPException` with a specific status code. Never return error details in a 200 response.

DO:
```python
@router.get('/orders/{order_id}', response_model=OrderResponse)
async def get_order(order_id: UUID, svc: OrderService = Depends(get_order_service)):
    order = await svc.get(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail='Order not found')
    return order
```

DON'T:
```python
@router.get('/orders/{order_id}')
async def get_order(order_id: UUID):
    order = await svc.get(order_id)
    if order is None:
        return {'status': 'error', 'message': 'not found'}   # 200 with error body
```

---

### Background Tasks — Use BackgroundTasks for Fire-and-Forget
Never block the response for async side effects (email, analytics, webhook). Use `BackgroundTasks`.

DO:
```python
@router.post('/orders', response_model=CreateOrderResponse)
async def create_order(body: CreateOrderRequest, background_tasks: BackgroundTasks):
    order = await order_svc.create(body)
    background_tasks.add_task(email_svc.send_confirmation, order.user_id, order.id)
    return order
```

DON'T:
```python
@router.post('/orders')
async def create_order(body: CreateOrderRequest):
    order = await order_svc.create(body)
    await email_svc.send_confirmation(order.user_id, order.id)  # blocks response
    return order
```

---

### Structured Logging — Log Entry and Exit of Every Route
Log at entry and exit with request id, method, path, status, and duration.

DO:
```python
@router.post('/orders', response_model=CreateOrderResponse)
async def create_order(body: CreateOrderRequest, request: Request):
    """Create a new order."""
    logger.info('request', method='POST', path='/orders', request_id=request.state.request_id)
    result = await order_svc.create(body)
    logger.info('response', status=200, duration_ms=elapsed(), request_id=request.state.request_id)
    return result
```

DON'T:
```python
@router.post('/orders')
async def create_order(body: CreateOrderRequest):
    return await order_svc.create(body)   # no observability
```

---

### Router Organisation — One Router per Domain Module
One `APIRouter` per domain. Mount all routers in `main.py`. Never put all routes in one file.

DO:
```python
# orders/router.py
router = APIRouter(prefix='/orders', tags=['orders'])

# main.py
app.include_router(orders.router)
app.include_router(users.router)
app.include_router(payments.router)
```

DON'T:
```python
# main.py — all 40 routes defined here
@app.post('/orders') ...
@app.get('/orders/{id}') ...
@app.post('/users') ...
```

---

## Anti-Patterns

### Flat Response on Error
Returning `{'success': False, 'error': '...'}` with HTTP 200. Clients can't use HTTP status to branch logic.
→ Raise `HTTPException` with the correct 4xx/5xx status.

### Logic in Depends()
A `Depends()` function that contains business rules, not just resource provisioning.
→ `Depends()` provisions resources (session, auth token, config). Business logic belongs in the service layer.

### Global Service Instances
`order_svc = OrderService()` at module level. Hard to test, shares state across requests.
→ Instantiate services inside `Depends()` functions so each request gets a fresh instance.

### Mixing Router and Schema in One File
Route handlers, Pydantic models, and DB logic all in `routes.py`.
→ `schemas.py` for request/response models, `router.py` for route handlers, `service.py` for logic.
