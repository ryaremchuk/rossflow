Zustand patterns. Apply to every React / React Native project that selected Zustand during init.

Read `state-management.md` first for library-agnostic principles. This file covers Zustand-specific recipes only.

## Patterns

### Typed store per domain concern

One store per shared concern. Define the state shape + actions + selectors together.

```ts
// src/store/inventory.ts
import { create } from 'zustand';

type InventoryItem = { id: string; qty: number };

type InventoryStore = {
  items: InventoryItem[];
  isHydrated: boolean;
  setItems: (items: InventoryItem[]) => void;
  addItem: (item: InventoryItem) => void;
  setHydrated: () => void;
};

export const useInventoryStore = create<InventoryStore>((set) => ({
  items: [],
  isHydrated: false,
  setItems: (items) => set({ items }),
  addItem: (item) => set((s) => ({ items: [...s.items, item] })),
  setHydrated: () => set({ isHydrated: true }),
}));
```

Always produce new references inside `set` — never mutate `s.items.push(...)`.

### Selector subscriptions — never read whole store

Components subscribe to the slice they use, not the whole store. Reading `useInventoryStore()` (no selector) re-renders on every change.

```ts
// good — re-render only when items change
const items = useInventoryStore((s) => s.items);

// bad — re-renders on any field change
const { items } = useInventoryStore();
```

For multiple fields use shallow equality:
```ts
import { shallow } from 'zustand/shallow';
const { items, isHydrated } = useInventoryStore(
  (s) => ({ items: s.items, isHydrated: s.isHydrated }),
  shallow,
);
```

### Atomic multi-store mutations

When two stores must update together (inventory − 1 AND gems − cost), do it in one function that calls both setters in sequence with rollback on failure. Never let UI dispatch the two halves separately.

```ts
// src/store/actions/buyAndEquip.ts
export async function buyAndEquip(itemId: string, cost: number) {
  const before = useGemsStore.getState().gems;
  const ok = useGemsStore.getState().spend(cost);
  if (!ok) return false;
  try {
    useInventoryStore.getState().addItem({ id: itemId, qty: 1 });
    return true;
  } catch (err) {
    useGemsStore.setState({ gems: before });    // rollback
    throw err;
  }
}
```

### Slicing big stores

Stores past ~6 actions or ~3 concerns should split. Compose slices via separate stores, or use the slice pattern within one store.

```ts
// slice pattern within one store
type AuthSlice = { user: User | null; signIn: (u: User) => void };
type CartSlice = { items: Item[]; addItem: (i: Item) => void };

const createAuthSlice: StateCreator<AuthSlice & CartSlice, [], [], AuthSlice> = (set) => ({
  user: null,
  signIn: (user) => set({ user }),
});

const createCartSlice: StateCreator<AuthSlice & CartSlice, [], [], CartSlice> = (set) => ({
  items: [],
  addItem: (item) => set((s) => ({ items: [...s.items, item] })),
});

export const useAppStore = create<AuthSlice & CartSlice>()((...a) => ({
  ...createAuthSlice(...a),
  ...createCartSlice(...a),
}));
```

### Persist middleware for cross-launch state

Use `persist` middleware composed with the storage adapter from `client-persistence.md`. Always set a `version` and a `migrate` function — schema changes without migration corrupt loaded state.

```ts
import { persist, createJSONStorage } from 'zustand/middleware';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const useAuthStore = create<AuthSlice>()(
  persist(
    (set) => ({
      user: null,
      signIn: (user) => set({ user }),
    }),
    {
      name: 'auth-store',
      version: 1,
      storage: createJSONStorage(() => AsyncStorage),
      migrate: (persisted: any, fromVersion) => {
        if (fromVersion === 0) return { ...persisted, user: persisted.user ?? null };
        return persisted;
      },
    },
  ),
);
```

### Async actions inline, no thunks needed

Zustand has no thunk concept — async actions are plain async functions on the store.

```ts
type UserStore = {
  user: User | null;
  isLoading: boolean;
  loadUser: (id: string) => Promise<void>;
};

export const useUserStore = create<UserStore>((set) => ({
  user: null,
  isLoading: false,
  loadUser: async (id) => {
    set({ isLoading: true });
    try {
      const user = await api.users.get(id);
      set({ user, isLoading: false });
    } catch (err) {
      set({ isLoading: false });
      throw err;
    }
  },
}));
```

## Anti-patterns

- **No selector — destructuring the whole store.** Forces re-render on any state change.
- **Mutating state inside `set`.** `set((s) => { s.items.push(x); return s; })` returns the same ref — no re-render.
- **Skipping `version` + `migrate` in persist.** First schema change crashes hydration on every existing install.
- **Accessing store outside React via `useStore()`.** Outside components, use `useStore.getState()` / `useStore.setState()`.
