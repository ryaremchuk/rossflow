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
DON'T: 30-line function mixing validation, summation, formatting in one body.

---

### Parameter Count — Max 3, Then Options Object
Beyond 3 params, callers forget argument order. Use a named object.

DO: `function createUser({ name, email, role, orgId }) { ... }`
DON'T: `function createUser(name, email, role, orgId) { ... }`

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
DON'T: pyramid of nested `if (user) { if (active) { if (premium) ... } }`.

---

### Naming — Verbs, Prefixes, No Abbreviations
Functions: verb phrases. Booleans: `is`/`has`/`can`/`should` prefix. No abbreviations except `id`, `url`, `db`.

DO: `fetchUserById(id)`, `const isActive = ...`, `const hasPermission = ...`
DON'T: `userData(u)`, `const active = ...`, `const perm = checkRole(usr, 'adm')`

---

### Pure Functions — Isolate Side Effects at Boundaries
Business logic is pure: input in, output out, no hidden state. Side effects (DB, email, queue) live at the edge.

DO:
```
def apply_discount(price: float, rate: float) -> float:
    return price * (1 - rate)

async def update_order_price(order_id, rate):
    order = await db.orders.get(order_id)
    order.total = apply_discount(order.total, rate)
    await db.orders.save(order)
```
DON'T: bury `db.orders.get` and `email.send` inside `apply_discount`.

---

### DRY Threshold — Extract at 3 Duplications, Not Before
Two identical blocks might be coincidence. Three is a pattern. Extract then, not sooner.

DO: extract `formatCurrency(amount, currency)` after the third call site appears.
DON'T: extract on the first or second occurrence — abstraction not yet proven necessary.

---

### YAGNI — Build What the Spec Requires, Nothing Else
No "we'll probably need" code. No plugin systems for one use case. No abstract bases with one subclass.

DO: `function sendEmail(to, subject, body) { return mailer.send({ to, subject, body }); }`
DON'T: `class NotificationService` with `adapter` constructor for "future channels" that don't exist.

---

### Comments — Explain WHY, Never WHAT
If you need a comment to explain what the code does, rewrite the code. Reserve comments for non-obvious constraints, workarounds, or invariants.

DO:
```
# Stripe requires idempotency key to be unique per 24h retry window
key = f"{order_id}-{int(time.time() // 86400)}"
```
DON'T: `# loop through items and sum prices` above an obvious for-loop.

---

### Single Responsibility — One Module, One Reason to Change
If a module changes for two different reasons, it has two responsibilities. Split it.

DO: `user_validator.py` (validation), `user_repository.py` (DB), `user_service.py` (business rules).
DON'T: one `user.py` that validates, queries, emails, and formats responses.

---

### Cyclomatic Complexity — Max 4 Branches Per Function
More than 4 conditions → extract predicates or use a dispatch table.

DO:
```
handlers = {
  'created': handle_created, 'updated': handle_updated,
  'deleted': handle_deleted, 'cancelled': handle_cancelled,
}
handlers[event.type](event)
```
DON'T: long `if/elif` chain on `event.type`.

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

---

## Hard caps (enforced by /simplify and CI)

- **Max file LOC: 250** for any single source file. Excess → must extract sub-modules / sub-components.
- **Max cyclomatic complexity per function: 20**. Excess → split or refactor.

Caps are auto-checked by `/simplify` (which reads this file) and may be enforced as DEC `verifies` rules.
