General coding principles. Language-agnostic. Apply in every file you write or modify.

## Patterns

### Function Size — Stay Under 20 Lines
Split any function that exceeds 20 lines. Extract named helpers.

DO:
```
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order.items);
  return buildReceipt(order, total);
}
```

DON'T:
```
function processOrder(order) {
  if (!order.id) throw new Error('missing id');
  if (!order.items.length) throw new Error('no items');
  let total = 0;
  for (const item of order.items) {
    if (item.discount) {
      total += item.price * (1 - item.discount);
    } else {
      total += item.price;
    }
  }
  // ... 15 more lines of mixed logic
}
```

---

### Parameter Count — Max 3, Then Options Object
Beyond 3 params, callers forget argument order. Use a named object.

DO:
```
function createUser({ name, email, role, orgId }) { ... }
```

DON'T:
```
function createUser(name, email, role, orgId) { ... }
```

---

### Early Return — Flatten Conditionals
Handle invalid cases first and return. No nested if/else pyramids.

DO:
```
function getDiscount(user) {
  if (!user) return 0;
  if (!user.isActive) return 0;
  if (!user.isPremium) return 0.05;
  return 0.15;
}
```

DON'T:
```
function getDiscount(user) {
  if (user) {
    if (user.isActive) {
      if (user.isPremium) {
        return 0.15;
      } else {
        return 0.05;
      }
    }
  }
  return 0;
}
```

---

### Naming — Verbs, Prefixes, No Abbreviations
Functions: verb phrases. Booleans: `is`/`has`/`can`/`should` prefix. No abbreviations except `id`, `url`, `db`.

DO:
```
function fetchUserById(id) { ... }
const isActive = user.status === 'active';
const hasPermission = checkRole(user, 'admin');
```

DON'T:
```
function userData(u) { ... }
const active = user.status === 'active';
const perm = checkRole(usr, 'adm');
```

---

### Pure Functions — Isolate Side Effects at Boundaries
Business logic is pure: input in, output out, no hidden state. Side effects (DB, email, queue) live at the edge.

DO:
```
# pure — testable in isolation
def apply_discount(price: float, rate: float) -> float:
    return price * (1 - rate)

# boundary — side effects contained here only
async def update_order_price(order_id: str, rate: float) -> None:
    order = await db.orders.get(order_id)
    order.total = apply_discount(order.total, rate)
    await db.orders.save(order)
```

DON'T:
```
async def apply_discount(order_id: str, rate: float) -> None:
    order = await db.orders.get(order_id)       # side effect buried in logic
    order.total = order.total * (1 - rate)
    await db.orders.save(order)
    await email.send(order.user_id, 'discount applied')
```

---

### DRY Threshold — Extract at 3 Duplications, Not Before
Two identical blocks might be coincidence. Three is a pattern. Extract then, not sooner.

DO:
```
# third occurrence appears → extract now
function formatCurrency(amount, currency) {
  return `${currency}${amount.toFixed(2)}`;
}
```

DON'T:
```
# premature extraction after seeing it once or twice
function formatCurrency(amount) { ... }  # abstraction not yet proven necessary
```

---

### YAGNI — Build What the Spec Requires, Nothing Else
No "we'll probably need" code. No plugin systems for one use case. No abstract bases with one subclass.

DO:
```
function sendEmail(to, subject, body) {
  return mailer.send({ to, subject, body });
}
```

DON'T:
```
class NotificationService {
  constructor(adapter) { this.adapter = adapter; }  // no second adapter exists
  send(channel, payload) { ... }                    // "for future channels"
}
```

---

### Comments — Explain WHY, Never WHAT
If you need a comment to explain what the code does, rewrite the code. Reserve comments for non-obvious constraints, workarounds, or invariants.

DO:
```
# Stripe requires idempotency key to be unique per 24h retry window
key = f"{order_id}-{int(time.time() // 86400)}"
```

DON'T:
```
# loop through items and sum prices
total = 0
for item in items:
    total += item.price  # add price to total
```

---

### Single Responsibility — One Module, One Reason to Change
If a module changes for two different reasons, it has two responsibilities. Split it.

DO:
```
user_validator.py   # changes when validation rules change
user_repository.py  # changes when DB schema changes
user_service.py     # changes when business rules change
```

DON'T:
```
user.py  # validates input, queries DB, sends emails, formats responses
```

---

### Cyclomatic Complexity — Max 4 Branches Per Function
More than 4 conditions → extract predicates or use a dispatch table.

DO:
```
handlers = {
  'created':   handle_created,
  'updated':   handle_updated,
  'deleted':   handle_deleted,
  'cancelled': handle_cancelled,
}
handlers[event.type](event)
```

DON'T:
```
def handle_event(event):
    if event.type == 'created': ...
    elif event.type == 'updated': ...
    elif event.type == 'deleted': ...
    elif event.type == 'cancelled': ...
    elif event.type == 'expired': ...
```

---

## Anti-Patterns

### The Omnibus Function
One function handles validation, transformation, persistence, and notification. Needs a paragraph comment to describe what it does.
→ Break into one function per responsibility, compose at the boundary.

### Boolean Trap
`createUser(name, true, false, true)` — caller has no idea what the booleans mean.
→ Use a named options object or named constants.

### Premature Abstraction
Interface with one implementation. Factory for one product. Template method with one subclass.
→ Wait for the second case before abstracting.

### Magic Numbers
`if (retries > 3)` or `setTimeout(fn, 2000)` with no explanation.
→ Named constant with a comment explaining where the value comes from.
