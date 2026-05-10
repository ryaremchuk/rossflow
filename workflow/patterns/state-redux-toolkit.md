Redux Toolkit patterns. Apply to every React / React Native project that selected Redux Toolkit during init.

Read `state-management.md` first for library-agnostic principles. This file covers RTK-specific recipes only.

## Patterns

### Slice per domain concern

One slice per shared concern (auth, cart, inventory). Slice file colocates state shape + reducers + actions + selectors.

```ts
// src/store/slices/inventorySlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

type InventoryItem = { id: string; qty: number };
type InventoryState = { items: InventoryItem[]; isHydrated: boolean };

const initialState: InventoryState = { items: [], isHydrated: false };

export const inventorySlice = createSlice({
  name: 'inventory',
  initialState,
  reducers: {
    setItems(state, action: PayloadAction<InventoryItem[]>) {
      state.items = action.payload;       // Immer — looks mutable, produces new ref
    },
    addItem(state, action: PayloadAction<InventoryItem>) {
      state.items.push(action.payload);
    },
    setHydrated(state) { state.isHydrated = true; },
  },
});

export const { setItems, addItem, setHydrated } = inventorySlice.actions;
export const selectItems = (s: RootState) => s.inventory.items;
```

### Store setup with typed hooks

```ts
// src/store/index.ts
import { configureStore } from '@reduxjs/toolkit';
import { TypedUseSelectorHook, useDispatch, useSelector } from 'react-redux';
import { inventorySlice } from './slices/inventorySlice';

export const store = configureStore({
  reducer: { inventory: inventorySlice.reducer /* , ... */ },
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;

export const useAppDispatch: () => AppDispatch = useDispatch;
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
```

Components MUST use `useAppDispatch` / `useAppSelector` — never untyped `useDispatch` / `useSelector`.

### Atomic multi-slice mutation via thunk

When a single user intent updates two slices, use a thunk. Never dispatch two actions in sequence from a component — partial failure tears state.

```ts
// src/store/thunks/buyAndEquip.ts
import { createAsyncThunk } from '@reduxjs/toolkit';

export const buyAndEquip = createAsyncThunk(
  'shop/buyAndEquip',
  async ({ itemId, cost }: { itemId: string; cost: number }, { dispatch, getState }) => {
    const ok = await dispatch(spendGems(cost)).unwrap();   // throws on rejection
    if (!ok) throw new Error('insufficient gems');
    await dispatch(equipItem(itemId)).unwrap();
  },
);
```

Caller: `dispatch(buyAndEquip({ itemId, cost }))`. Failure rolls back via the thunk's rejection.

### RTK Query for server state

Server state belongs in RTK Query, not in slices. Avoids hand-rolled fetch + cache + invalidation logic.

```ts
// src/store/api/userApi.ts
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const userApi = createApi({
  reducerPath: 'userApi',
  baseQuery: fetchBaseQuery({ baseUrl: '/api/' }),
  tagTypes: ['User'],
  endpoints: (build) => ({
    getUser: build.query<User, string>({
      query: (id) => `users/${id}`,
      providesTags: (_r, _e, id) => [{ type: 'User', id }],
    }),
    updateUser: build.mutation<User, { id: string; patch: Partial<User> }>({
      query: ({ id, patch }) => ({ url: `users/${id}`, method: 'PATCH', body: patch }),
      invalidatesTags: (_r, _e, { id }) => [{ type: 'User', id }],
    }),
  }),
});

export const { useGetUserQuery, useUpdateUserMutation } = userApi;
```

Add the reducer + middleware to the store:
```ts
configureStore({
  reducer: { ..., [userApi.reducerPath]: userApi.reducer },
  middleware: (gdm) => gdm().concat(userApi.middleware),
});
```

### Persistence (KV / secure storage)

Slice-level persistence composes with `client-persistence.md`. Hydrate from storage on startup; mark `isHydrated` to gate UI rendering until first load completes.

```ts
// src/store/persist.ts
export async function hydrateInventory(dispatch: AppDispatch) {
  const saved = await store.inventory.read();    // typed wrapper from client-persistence
  if (saved) dispatch(setItems(saved));
  dispatch(setHydrated());
}
```

### Selectors live next to slices

Stable, memoized selectors via `createSelector`. Components use selectors, not raw `state.foo` access — refactors don't ripple.

```ts
import { createSelector } from '@reduxjs/toolkit';

export const selectActiveItems = createSelector(
  [selectItems],
  (items) => items.filter((i) => i.qty > 0),
);
```

## Anti-patterns

- **Hand-rolled fetch + cache.** If you wrote a `loading: bool` and `data: T | null` slice for server state, you reinvented RTK Query — replace it.
- **Inline anonymous selectors in components.** `useAppSelector(s => s.inventory.items.filter(...))` recomputes every render. Extract to a memoized selector.
- **Untyped `useDispatch` / `useSelector`.** Use the typed hooks defined alongside the store.
- **Mutating state outside reducers.** Even with Immer, mutate only inside `createSlice` reducers — never on a returned slice value.
