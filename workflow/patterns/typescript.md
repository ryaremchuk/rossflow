TypeScript patterns. Apply to every .ts/.tsx file.

## Patterns

### Strict mode always
tsconfig MUST have `"strict": true`. No `// @ts-ignore` without comment + dated TODO.

### No `any`
Use `unknown` and narrow. Missing third-party type → declare local interface in `src/types/`.

### Discriminated unions for multi-state
Multi-state values use unions, not optional fields.

DO:
```ts
type AsyncState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };
```

DON'T: `{ isLoading?: boolean; data?: T; error?: Error }`.

### `as const` for token objects
```ts
export const Colors = { purple: { deep: '#534AB7' } } as const;
```

### No inline `#hex` outside `src/constants/`
All color values must come from a typed token const (e.g. `Colors.purple.deep`). `#[0-9a-fA-F]{3,8}` literals in any file outside `src/constants/` are forbidden. Same rule for spacing literals (use `Spacing.X`), font sizes (`Typography.X`), border radii (`Radius.X`).

### Closure-stale guards in async hooks
useState + useCallback with state in deps + sequential async calls = stale closure.

DO (atomic, setter-callback):
```ts
const addGems = useCallback(async (n: number) => {
  setUser(prev => {
    const next = { ...prev, gems: prev.gems + n };
    persist(next);
    return next;
  });
}, []);
```

DON'T: `useCallback(async () => { setUser({...user, ...}); }, [user])` then call sequentially.

### Branded types for primitive IDs
```ts
type UserId = string & { readonly __brand: 'UserId' };
```

## Anti-patterns

- `as any` / `as unknown as Foo` — almost always a type modeling failure.
- Optional chaining as control flow (`obj?.method?.()` to silently no-op).
- Barrel files (`src/index.ts`) re-exporting everything → circular deps + breaks tree-shaking.
