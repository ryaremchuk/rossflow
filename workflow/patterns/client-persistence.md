Client-side persistence patterns. Apply to every project that stores data on-device (KV, secure tokens, structured records).

Picks the right primitive per use case, then applies the same principles regardless of which library backs it.

## Picking the storage primitive

| Use case | Primitive | Examples |
|---------|-----------|----------|
| Plain key-value, non-sensitive | KV store | AsyncStorage, MMKV, `localStorage` (web) |
| Auth tokens, secrets, PII | Secure store | Expo SecureStore, react-native-keychain |
| Structured / queryable records | Embedded SQL | expo-sqlite, op-sqlite, WatermelonDB |
| Big binary blobs | Filesystem | expo-file-system, react-native-fs |

Mixing primitives is fine — pick the right one per concern, never use one as a workaround for another (e.g. don't store auth tokens in AsyncStorage; don't shoehorn a 50-row table into stringified JSON).

## Principles (apply to all primitives)

### Components never import the storage SDK directly
All access goes through a typed wrapper module (`src/store/` or `src/persistence/`). Components call the wrapper. The wrapper hides which library is in use, so swapping (e.g. AsyncStorage → MMKV) is one file.

### Versioned keys with namespaced prefix
```ts
const KEYS = {
  user: '@app/user_v1',
  inventory: '@app/inventory_v1',
} as const;
```
Schema change → bump version in the key, write a migration that reads the old key, transforms, writes the new one.

### Atomic multi-key writes
Two values that must update together → write them in one operation if the API supports it (`multiSet`, transaction, batch). Two sequential `setItem` calls can leave torn state if the process is killed between them.

### Await every write, surface failures
Hooks MUST `await` the storage call and surface errors to the UI (toast, error state, retry). Fire-and-forget loses data silently.

### Hydration loading state
The wrapper exposes `isHydrated: boolean` (or equivalent). Screens render a skeleton while `isHydrated` is false — never render seed data that flashes and then jumps when storage loads.

### Defensive parse
Wrap `JSON.parse` in try/catch. Corrupt storage entries (interrupted writes, format change without migration) MUST NOT crash hydration — fall back to defaults and log.

### Migrations are idempotent and explicit
On read, check the stored value's shape/version. If old, transform and rewrite. Migrations live next to the store, are unit-tested, and never silently discard fields.

### Never block render on storage
All reads happen in `useEffect` or async actions, never inline in render. Storage is async even when it looks synchronous (some libraries lie).

## Adapter examples

### AsyncStorage (KV, async)
```ts
import AsyncStorage from '@react-native-async-storage/async-storage';

export const userStore = {
  async read(): Promise<User | null> {
    const raw = await AsyncStorage.getItem(KEYS.user);
    if (!raw) return null;
    try { return JSON.parse(raw) as User; }
    catch { logger.warn('user store: corrupt entry'); return null; }
  },
  async write(user: User) {
    await AsyncStorage.setItem(KEYS.user, JSON.stringify(user));
  },
  async writeBoth(user: User, inventory: Inventory) {
    await AsyncStorage.multiSet([
      [KEYS.user, JSON.stringify(user)],
      [KEYS.inventory, JSON.stringify(inventory)],
    ]);
  },
};
```

### MMKV (KV, synchronous, faster)
```ts
import { MMKV } from 'react-native-mmkv';
const mmkv = new MMKV();

export const userStore = {
  read(): User | null {
    const raw = mmkv.getString(KEYS.user);
    if (!raw) return null;
    try { return JSON.parse(raw) as User; } catch { return null; }
  },
  write(user: User) { mmkv.set(KEYS.user, JSON.stringify(user)); },
};
```
MMKV is synchronous — wrappers can stay sync. `isHydrated` still useful if you batch initial reads in a startup effect.

### SecureStore (auth tokens)
```ts
import * as SecureStore from 'expo-secure-store';

export const authStore = {
  async readToken(): Promise<string | null> {
    return SecureStore.getItemAsync('auth_token');
  },
  async writeToken(token: string) {
    await SecureStore.setItemAsync('auth_token', token, {
      keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
    });
  },
  async clearToken() { await SecureStore.deleteItemAsync('auth_token'); },
};
```
Never log tokens. Never duplicate tokens into a KV store.

### SQLite (structured records)
```ts
import * as SQLite from 'expo-sqlite';
const db = SQLite.openDatabaseSync('app.db');

db.execSync(`CREATE TABLE IF NOT EXISTS items (
  id TEXT PRIMARY KEY,
  qty INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);`);

export const itemRepo = {
  list(): Item[] {
    return db.getAllSync<Item>('SELECT id, qty, updated_at FROM items ORDER BY updated_at DESC');
  },
  upsert(item: Item) {
    db.runSync(
      'INSERT OR REPLACE INTO items (id, qty, updated_at) VALUES (?, ?, ?)',
      [item.id, item.qty, Date.now()],
    );
  },
};
```
Schema changes go in numbered migration files, not ad-hoc `ALTER TABLE` calls inside the repo.

## Anti-patterns

- **Direct storage SDK calls in components.** Components import storage libraries → logic scattered, no error handling, can't swap library.
- **`JSON.parse` without try/catch.** A single corrupt entry crashes hydration on every launch until manual reset.
- **Stringly-typed keys.** Inline `'user'` / `'@app/user'` strings → typos and scattered key collisions. Centralise in a `KEYS` const.
- **Fire-and-forget writes.** No `await`, no error surface → data loss is invisible.
- **Auth tokens in plain KV.** AsyncStorage / MMKV are not encrypted by default. Tokens, biometric secrets, payment refs go in SecureStore / Keychain.
