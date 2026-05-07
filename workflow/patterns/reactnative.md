React Native patterns. Apply to every component, screen, and navigation definition.

## Patterns

### Styles — StyleSheet.create() Always
No inline style objects in JSX. No magic numbers — use spacing and color constants.

DO:
```tsx
const SPACING = { sm: 8, md: 16, lg: 24 };
const COLORS = { primary: '#1A73E8', danger: '#D93025' };

const styles = StyleSheet.create({
  container: { padding: SPACING.md, backgroundColor: COLORS.primary },
  title:     { fontSize: 18, color: COLORS.primary },
});

return <View style={styles.container}><Text style={styles.title}>{label}</Text></View>;
```

DON'T:
```tsx
return (
  <View style={{ padding: 16, backgroundColor: '#1A73E8' }}>
    <Text style={{ fontSize: 18, color: '#1A73E8' }}>{label}</Text>
  </View>
);
```

---

### Navigation Types — Typed RootStackParamList
Define `RootStackParamList` for every navigator. Never call `navigation.navigate()` untyped.

DO:
```tsx
type RootStackParamList = {
  Home:     undefined;
  OrderDetail: { orderId: string };
  Checkout: { cartId: string; promoCode?: string };
};

type Props = NativeStackScreenProps<RootStackParamList, 'Home'>;

export function HomeScreen({ navigation }: Props) {
  navigation.navigate('OrderDetail', { orderId: '123' });
}
```

DON'T:
```tsx
export function HomeScreen({ navigation }) {
  navigation.navigate('OrderDetail', { id: '123' });   // typo in param name, no type check
}
```

---

### Platform Differences — Platform.select() for Divergent Behaviour
Use `Platform.select()` for platform-specific values. Never scatter `Platform.OS === 'ios'` inline.

DO:
```tsx
const shadowStyle = Platform.select({
  ios:     { shadowColor: '#000', shadowOffset: { width: 0, height: 2 }, shadowOpacity: 0.2 },
  android: { elevation: 4 },
});

const styles = StyleSheet.create({ card: { ...shadowStyle } });
```

DON'T:
```tsx
<View style={{
  shadowColor: Platform.OS === 'ios' ? '#000' : undefined,
  elevation: Platform.OS === 'android' ? 4 : undefined,
}}>
```

---

### API Client — Centralised with Auth Header Injection
One API client module with base URL and auth header injection. Never call `fetch()` directly in components.

DO:
```tsx
// lib/api.ts
const client = {
  get: async <T>(path: string): Promise<T> => {
    const token = await getAuthToken();
    const res = await fetch(`${API_BASE}${path}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (!res.ok) throw new ApiError(res.status);
    return res.json();
  },
};

export const getOrder = (id: string) => client.get<Order>(`/orders/${id}`);
```

DON'T:
```tsx
// inside a component
const res = await fetch(`https://api.example.com/orders/${id}`, {
  headers: { Authorization: `Bearer ${token}` },  // auth logic duplicated everywhere
});
```

---

### useEffect Cleanup — Always Return Cleanup Function
Every `useEffect` that sets up a subscription, timer, or listener must return a cleanup function.

DO:
```tsx
useEffect(() => {
  const sub = AppState.addEventListener('change', handleAppStateChange);
  return () => sub.remove();   // cleanup prevents memory leak
}, []);
```

DON'T:
```tsx
useEffect(() => {
  AppState.addEventListener('change', handleAppStateChange);
  // no cleanup — listener accumulates on every mount
}, []);
```

---

### Native Modules — Wrap Every Call in try/catch
Native module errors are uncatchable without an explicit try/catch. Unhandled native exceptions crash the app.

DO:
```tsx
async function requestCameraPermission() {
  try {
    const granted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA);
    return granted === PermissionsAndroid.RESULTS.GRANTED;
  } catch (err) {
    logger.error('camera permission request failed', { err });
    return false;
  }
}
```

DON'T:
```tsx
async function requestCameraPermission() {
  const granted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.CAMERA);
  return granted === PermissionsAndroid.RESULTS.GRANTED;
  // native exception crashes the app with no error boundary catching it
}
```

---

### List Rendering — FlatList for Dynamic Data
`FlatList` for any list that can grow. Never `map()` inside `ScrollView` for dynamic data — all items render at once.

DO:
```tsx
<FlatList
  data={orders}
  keyExtractor={item => item.id}
  renderItem={({ item }) => <OrderCard order={item} />}
  initialNumToRender={10}
/>
```

DON'T:
```tsx
<ScrollView>
  {orders.map(order => <OrderCard key={order.id} order={order} />)}
</ScrollView>
```

---

## Anti-Patterns

### Anonymous Inline Components
`renderItem={() => <View><Text>{item.name}</Text></View>}` — new function reference every render, kills FlatList optimisation.
→ Extract as a named component defined outside the parent.

### Missing keyExtractor
`<FlatList data={items} renderItem={...} />` with no `keyExtractor`. React warns, list updates are incorrect.
→ Always provide `keyExtractor={item => item.id}` using a stable unique identifier.

### Touching State in Background
`setOrders(data)` inside a `fetch` callback after the component has unmounted.
→ Track mount status with a ref, or use a library like React Query that handles cancellation.

### Direct AsyncStorage in Components
Reading/writing AsyncStorage directly in components. Logic scattered, no error handling.
→ Wrap in a typed storage service module. Components call service methods.
