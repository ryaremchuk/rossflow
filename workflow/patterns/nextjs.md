Next.js App Router patterns. Apply to every component, route, and data-fetching decision.

## Patterns

### Server vs Client Components — Default to Server
Use Server Components unless you need hooks, event handlers, or browser APIs. Add `"use client"` only when required.

DO:
```tsx
// app/orders/page.tsx — Server Component, no directive needed
export default async function OrdersPage() {
  const orders = await fetchOrders();   // direct async call, no useEffect
  return <OrderList orders={orders} />;
}
```

DON'T:
```tsx
'use client';   // unnecessary — no hooks or browser APIs used
export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  useEffect(() => { fetchOrders().then(setOrders); }, []);
  return <OrderList orders={orders} />;
}
```

---

### Data Fetching — Server Components with Explicit Cache Control
Fetch in Server Components. Set `cache` explicitly. Never fetch in Client Components unless user-triggered.

DO:
```tsx
// Server Component
async function getOrders() {
  const res = await fetch('/api/orders', { cache: 'no-store' });  // explicit
  if (!res.ok) throw new Error('Failed to load orders');
  return res.json();
}
```

DON'T:
```tsx
'use client';
export function OrderList() {
  const [orders, setOrders] = useState([]);
  useEffect(() => {
    fetch('/api/orders').then(r => r.json()).then(setOrders);  // client fetch, no loading state, no error handling
  }, []);
}
```

---

### API Client — Centralised Typed Module
One typed API client module. Never call `fetch()` directly in components.

DO:
```tsx
// lib/api.ts
export async function getOrder(id: string): Promise<Order> {
  const res = await fetch(`${API_BASE}/orders/${id}`, { cache: 'no-store' });
  if (!res.ok) throw new ApiError(res.status, await res.text());
  return OrderSchema.parse(await res.json());
}

// component
const order = await getOrder(params.id);
```

DON'T:
```tsx
// inline in component
const res = await fetch(`https://api.example.com/orders/${id}`);
const order = await res.json();   // no validation, URL scattered, error ignored
```

---

### Dynamic Imports — ssr:false for Browser-Only Components
Components that use `window`, `document`, or browser-only libs must be dynamically imported with `ssr: false`.

DO:
```tsx
const MapWidget = dynamic(() => import('@/components/MapWidget'), { ssr: false });
```

DON'T:
```tsx
import MapWidget from '@/components/MapWidget';
// MapWidget uses window.google — causes hydration error on SSR
```

---

### Error Boundaries — error.tsx per Route Segment
Add `error.tsx` at each route segment that can fail independently. Never let one component failure crash the whole page.

DO:
```
app/
  orders/
    error.tsx      # catches errors in /orders segment only
    [id]/
      error.tsx    # catches errors in /orders/[id] — isolated
      page.tsx
```

DON'T:
```
app/
  error.tsx        # one global error boundary — one failure kills the whole app
  orders/
    page.tsx
```

---

### Loading States — loading.tsx per Route Segment
Add `loading.tsx` per route segment that fetches slow data. Never block the whole layout.

DO:
```
app/
  orders/
    loading.tsx    # Suspense fallback for /orders — shown while page.tsx fetches
    page.tsx
  dashboard/
    loading.tsx    # independent loading state — dashboard loads separately
    page.tsx
```

DON'T:
```tsx
// app/layout.tsx wraps everything in one Suspense
<Suspense fallback={<FullPageSpinner />}>
  {children}   // all routes blocked until slowest segment resolves
</Suspense>
```

---

### Route Handlers — One File per Resource, No Business Logic
`app/api/[resource]/route.ts` — one file per resource. Calls service layer only. No inline logic.

DO:
```tsx
// app/api/orders/route.ts
export async function POST(request: Request) {
  const body = CreateOrderSchema.parse(await request.json());
  const order = await orderService.create(body);
  return Response.json(order, { status: 201 });
}
```

DON'T:
```tsx
// app/api/orders/route.ts
export async function POST(request: Request) {
  const body = await request.json();
  const order = new Order();
  order.id = crypto.randomUUID();
  order.total = body.items.reduce((s, i) => s + i.price, 0);
  await db.insert(ordersTable).values(order);
  await emailClient.send(body.userId, 'order created');
  return Response.json(order);
}
```

---

## Anti-Patterns

### Client Component Creep
Marking a parent component `"use client"` because one child needs it. Everything in the subtree becomes a Client Component.
→ Extract the interactive part into a small leaf `"use client"` component. Keep the parent as a Server Component.

### Waterfall Fetches in Server Components
```tsx
const user = await getUser(id);
const orders = await getOrders(user.id);  // waits for user before starting
```
→ `Promise.all([getUser(id), getOrders(id)])` when requests are independent.

### Hardcoded API URLs in Components
`fetch('https://api.example.com/...')` in 12 different components.
→ All API calls go through the centralised `lib/api.ts` client.

### Missing Revalidation Strategy
`fetch('/api/data')` with no `cache` or `revalidate` option — behaviour is implicit and changes across Next.js versions.
→ Always set `{ cache: 'no-store' }` or `{ next: { revalidate: 60 } }` explicitly.
