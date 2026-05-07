Django REST Framework patterns. Apply to every model, serializer, view, and settings file.

## Patterns

### Model Conventions — verbose_name, Meta, __str__
Every model: `verbose_name` on model and each field, `class Meta` with `ordering`, `__str__` implemented.

DO:
```python
class Order(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name='user')
    total = models.DecimalField(max_digits=12, decimal_places=2, verbose_name='total amount')
    created_at = models.DateTimeField(auto_now_add=True, verbose_name='created at')

    class Meta:
        verbose_name = 'order'
        verbose_name_plural = 'orders'
        ordering = ['-created_at']

    def __str__(self) -> str:
        return f'Order {self.id} — {self.user}'
```

DON'T:
```python
class Order(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    total = models.DecimalField(max_digits=12, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    # no Meta, no __str__ — admin is unusable, queries unordered
```

---

### Serializers — Explicit Fields, validate_<field> for Validation
Always list fields explicitly. Never `fields = '__all__'`. Per-field validation in `validate_<field>` methods.

DO:
```python
class CreateOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ['user_id', 'items', 'currency']

    def validate_currency(self, value: str) -> str:
        if value not in SUPPORTED_CURRENCIES:
            raise serializers.ValidationError(f'{value} is not a supported currency')
        return value
```

DON'T:
```python
class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = '__all__'   # exposes all columns including internal fields
```

---

### ViewSet vs APIView — CRUD vs Custom
`ViewSet` for standard CRUD operations. `APIView` for custom endpoints. Never mix logic into both.

DO:
```python
# standard CRUD — ViewSet
class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]

# custom endpoint — APIView
class OrderSummaryView(APIView):
    def get(self, request, order_id: int) -> Response:
        summary = order_svc.build_summary(order_id)
        return Response(OrderSummarySerializer(summary).data)
```

DON'T:
```python
class OrderViewSet(viewsets.ModelViewSet):
    def create(self, request):
        # 40 lines of custom business logic mixed with serializer calls
        ...
    def summary(self, request, pk):
        # custom action mixed with CRUD actions in same class
        ...
```

---

### Permissions — IsAuthenticated by Default, Override Explicitly
Set `IsAuthenticated` as the default. Override `permission_classes` on views that need different rules. Never rely on silent global defaults.

DO:
```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
}

# public endpoint — explicitly overrides the default
class HealthCheckView(APIView):
    permission_classes = [AllowAny]

    def get(self, request) -> Response:
        return Response({'status': 'ok'})
```

DON'T:
```python
# settings.py
REST_FRAMEWORK = {}   # no default — every view is publicly accessible unless devs remember to add permissions
```

---

### Settings Structure — base / local / production Split
`base.py` for shared config. `local.py` and `production.py` for environment-specific overrides. Secrets via environment variables only.

DO:
```python
# settings/base.py
INSTALLED_APPS = [...]
AUTH_PASSWORD_VALIDATORS = [...]

# settings/production.py
from .base import *
DEBUG = False
SECRET_KEY = env('DJANGO_SECRET_KEY')
DATABASES = {'default': env.db('DATABASE_URL')}
```

DON'T:
```python
# settings.py
DEBUG = True
SECRET_KEY = 'dev-secret-key-do-not-use-in-prod'  # hardcoded secrets
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': 'db.sqlite3'}}
```

---

### Signals — Cross-Cutting Concerns Only
Use signals for audit logs and notifications that span modules. Never replace direct service layer calls with signals. Every signal file must include a comment explaining why it isn't a direct call.

DO:
```python
# signals.py
# Using a signal here because AuditLog must record all model saves
# without requiring every save site to import audit_svc.
@receiver(post_save, sender=Order)
def log_order_save(sender, instance, created, **kwargs):
    audit_svc.record(instance, 'created' if created else 'updated')
```

DON'T:
```python
@receiver(post_save, sender=Order)
def on_order_save(sender, instance, **kwargs):
    # hidden business logic — not obvious this runs on every Order.save()
    if instance.total > 1000:
        apply_high_value_discount(instance)
```

---

### QuerySet — Manager Methods for Reusable Filters
Define reusable filters as `Manager` methods. Never duplicate `.filter()` logic across views.

DO:
```python
class OrderQuerySet(models.QuerySet):
    def active(self):
        return self.filter(status='active')

    def for_user(self, user_id: int):
        return self.filter(user_id=user_id)

class Order(models.Model):
    objects = OrderQuerySet.as_manager()

# usage
Order.objects.active().for_user(request.user.id)
```

DON'T:
```python
# in view A
Order.objects.filter(status='active', user_id=request.user.id)

# in view B — same filter duplicated
Order.objects.filter(status='active', user_id=user.id)
```

---

## Anti-Patterns

### Fat ViewSet
ViewSet with `create`, `update`, 3 custom `@action` methods, helper methods, and DB queries all in one class.
→ Extract business logic into a service layer. ViewSet calls service, returns serialized response.

### `validate()` Doing DB Queries
`validate()` in a serializer queries the DB to check existence. Mixes persistence concerns into validation.
→ Perform existence checks in the view or service layer. Serializer validates structure and types only.

### Implicit Permission via `request.user` in Views
```python
orders = Order.objects.filter(user=request.user)  # access control hidden in queryset
```
This pattern looks safe but breaks when the view is reused in a context where `request.user` is not the intended filter.
→ Declare permissions explicitly on the view class. Access control is a view concern, not a queryset concern.

### Migration in Reverse Dependency Order
Applying migrations that reference models from apps listed later in `INSTALLED_APPS`.
→ Run `python manage.py migrate --check` in CI. Order `INSTALLED_APPS` so dependencies come first.
