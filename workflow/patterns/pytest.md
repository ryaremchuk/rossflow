Pytest patterns for async Python applications. Apply to every test file and fixture.

## Patterns

### Fixture Scope — Function Scope by Default
Use `function` scope by default. Use `session` scope only for expensive resources (DB connection pool). Document why when using wider scope.

DO:
```python
@pytest.fixture
def order():   # function scope — clean state every test
    return Order(id=uuid4(), total=Decimal('99.00'))

@pytest.fixture(scope='session')
def db_engine():
    # session scope — DB engine setup is expensive, safe to share (read-only)
    engine = create_async_engine(TEST_DB_URL)
    yield engine
    engine.sync_engine.dispose()
```

DON'T:
```python
@pytest.fixture(scope='session')
def order():   # mutable object shared across all tests — state leaks between tests
    return Order(id=uuid4(), total=Decimal('99.00'))
```

---

### Async Tests — asyncio_mode=auto in pytest.ini
No manual event loop management. Set `asyncio_mode = auto` and write coroutines directly.

DO:
```ini
# pytest.ini
[pytest]
asyncio_mode = auto
```
```python
async def test_create_order(client: AsyncClient):
    response = await client.post('/orders', json={'total': 99})
    assert response.status_code == 201
```

DON'T:
```python
def test_create_order():
    loop = asyncio.get_event_loop()     # manual event loop management
    result = loop.run_until_complete(order_svc.create(...))
    assert result.id is not None
```

---

### Parametrize — Use @pytest.mark.parametrize for Variants
Never duplicate test functions with different hardcoded inputs. Use `parametrize`.

DO:
```python
@pytest.mark.parametrize('total,expected_status', [
    (99.00, 201),
    (-1.00, 422),
    (0,     422),
])
async def test_create_order_validation(client, total, expected_status):
    response = await client.post('/orders', json={'total': total})
    assert response.status_code == expected_status
```

DON'T:
```python
async def test_create_order_valid():
    response = await client.post('/orders', json={'total': 99})
    assert response.status_code == 201

async def test_create_order_negative():
    response = await client.post('/orders', json={'total': -1})
    assert response.status_code == 422
```

---

### Mocking — monkeypatch for Simple, AsyncMock for Async
Patch where the object is used, not where it is defined.

DO:
```python
async def test_send_confirmation_called(monkeypatch, client):
    mock = AsyncMock()
    monkeypatch.setattr('orders.service.email_svc.send', mock)   # patched where used
    await client.post('/orders', json={'total': 99})
    mock.assert_called_once()
```

DON'T:
```python
async def test_send_confirmation_called(monkeypatch):
    mock = AsyncMock()
    monkeypatch.setattr('email.service.EmailService.send', mock)  # patched where defined
    # won't intercept calls from orders.service that already imported it
```

---

### HTTP Testing — AsyncClient with ASGITransport
Never spin up a real server. Use `AsyncClient` with `ASGITransport` to call the app in-process.

DO:
```python
@pytest.fixture
async def client(app):
    async with AsyncClient(transport=ASGITransport(app=app), base_url='http://test') as c:
        yield c
```

DON'T:
```python
@pytest.fixture
def client():
    subprocess.Popen(['uvicorn', 'main:app', '--port', '8001'])  # real server in test
    time.sleep(1)
    return httpx.Client(base_url='http://localhost:8001')
```

---

### Conftest — Shared Fixtures at the Right Directory Level
Shared fixtures in `conftest.py` at the appropriate level. Never import fixtures manually — pytest discovers them.

DO:
```
tests/
  conftest.py          # app-wide fixtures: db engine, settings override
  orders/
    conftest.py        # order-specific fixtures: seed data, order client
    test_create.py
```

DON'T:
```python
# test_create.py
from tests.fixtures import client, db_session   # manual fixture import — pytest won't inject them
```

---

### Assertion Messages — Add Message to Non-Obvious Asserts
Add a message string to every assert where the failure output alone won't tell you what went wrong.

DO:
```python
assert response.status_code == 201, f"expected 201, got {response.status_code}: {response.text}"
assert len(orders) == 3, f"expected 3 orders, got {len(orders)}: {orders}"
```

DON'T:
```python
assert response.status_code == 201   # failure shows '201 != 422' with no context
```

---

### Test Naming — [unit]_[scenario]_[expected]
`test_[unit]_[scenario]_[expected_outcome]`. No `test_1`, `test_thing`, `test_works`.

DO:
```python
async def test_create_order_with_negative_total_returns_422(): ...
async def test_apply_discount_at_zero_rate_returns_original_price(): ...
async def test_get_order_when_not_found_raises_404(): ...
```

DON'T:
```python
async def test_order(): ...
async def test_works(): ...
async def test_1(): ...
```

---

## Anti-Patterns

### Test Interdependence
Tests that rely on execution order or shared mutable state. One test seeds data, the next test reads it.
→ Each test sets up and tears down its own state. Use function-scoped fixtures.

### Asserting Implementation, Not Behaviour
`assert mock.called_with(db, order, True)` — testing internal wiring, not observable outcomes.
→ Assert on HTTP responses, DB rows, return values. Verify the observable result.

### Overusing unittest.mock.patch
`@patch('module.ClassName')` decorators stacking 3-deep. Hard to read, fragile.
→ Use `monkeypatch` for simple attribute replacement. Inject dependencies through the app's DI system.

### Empty Except in Tests
```python
try:
    await svc.create(bad_data)
except Exception:
    pass   # silently passes even if the wrong exception is raised
```
→ `with pytest.raises(SpecificError):` — assert the exact exception type.
