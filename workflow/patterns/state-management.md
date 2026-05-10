State management principles. Library-agnostic. Apply to every project with shared state.

For library-specific recipes, see `state-redux-toolkit.md` or `state-zustand.md` (only one per project — selected during init).

## Decision tree

1. Used by 1 component, <1s, no persistence → local hook (`useState`).
2. Used by 1 screen, persists across re-renders, no other screen reads → `useState` / `useReducer` at screen root.
3. Shared across ≥2 screens or modules → MUST use the project's chosen state library (single provider/store). Per-screen domain-hook instantiation is FORBIDDEN — every consumer reads from the same store.
4. Persists across app launches → composed inside the store via the persistence pattern (`client-persistence.md`).

## Principles

### Single source per concern
Each shared concern (auth user, cart, inventory, …) lives in exactly one slice/store/atom. Never duplicate the state in two places "for convenience" — they will diverge.

### Immutability
Always produce a new reference for changed state. Mutating in place breaks change detection and re-renders. (Redux Toolkit uses Immer — drafts look mutable but produce new references; same rule applies.)

### Atomic multi-key mutations
When two values must update together (e.g. inventory − 1 AND gems − cost), commit them in one action / one setter call. Never split into two sequential commits — a failure between them leaves state torn.

```ts
// good — one action handles both
dispatch(buyAndEquipItem({ itemId, cost }));

// bad — two dispatches, partial failure tears state
dispatch(spendGems(cost));
dispatch(equipItem(itemId));
```

### Reducers for ≥3 mutators on one slice
Three or more setters on one piece of state → use a reducer (or RTK slice / Zustand action map). Easier to test, no closure traps, single audit point.

### Derived state — compute, don't store
Filtered lists, totals, derived flags → compute via selectors / `useMemo`. Do not write derived values back into state — they go stale.

### Closure-stale guard for sequential async
`useCallback` with state in `deps` for sequential async ops captures stale state. Prefer reading the latest via a selector or ref inside the async fn.

```ts
// bad — items captured at first render
const submit = useCallback(async () => {
  await api.save(items);
}, [items]);

// good — read fresh on call
const itemsRef = useRef(items);
itemsRef.current = items;
const submit = useCallback(async () => {
  await api.save(itemsRef.current);
}, []);
```

## Anti-patterns

- **Per-screen instantiation of a domain hook.** Two screens each calling `useInventory()` create two state trees that drift after navigation.
- **Global mutable singletons outside the framework.** A plain module-level object will mutate without triggering re-renders.
- **Storing derived data.** "We'll just keep `total` in state" → forgets to update on item edit, displays wrong number.
- **Mutating state in handlers.** `state.items.push(x)` then `setState(state)` — same reference, no re-render.
