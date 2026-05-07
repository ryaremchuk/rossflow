# Patterns Library

Pattern files loaded by skills at runtime. Use grep/search to find relevant patterns — do not read entire files.

---

## Always Load

These apply to every implementation task regardless of stack.

- [principles.md](principles.md) — Language-agnostic coding rules: function size, naming, early return, pure functions, DRY, YAGNI, comments, single responsibility, cyclomatic complexity (10 patterns)
- [arch.md](arch.md) — System architecture: three-layer model, HTTP/DB layer boundaries, module interfaces, ports and adapters, god object detection, unidirectional data flow, error handling at boundaries (8 patterns)

---

## Load When Relevant

Load the file that matches the framework or language in use for the current spec.

- [fastapi.md](fastapi.md) — FastAPI: route definition, Pydantic request validation, Depends() injection, HTTPException error handling, BackgroundTasks, structured logging, router organisation (7 patterns)
- [sqlalchemy.md](sqlalchemy.md) — SQLAlchemy async: async session factory, Mapped[T] columns, select() queries, transaction scope, migration-only schema changes, explicit relationship loading, session lifecycle (7 patterns)
- [pytest.md](pytest.md) — Pytest async: fixture scope, asyncio_mode=auto, parametrize, monkeypatch/AsyncMock, AsyncClient+ASGITransport, conftest structure, assertion messages, test naming (8 patterns)
- [nextjs.md](nextjs.md) — Next.js App Router: Server vs Client components, server-side data fetching, typed API client, dynamic imports, error.tsx, loading.tsx, route handler conventions (7 patterns)
- [reactnative.md](reactnative.md) — React Native: StyleSheet.create, typed navigation params, Platform.select, centralised API client, useEffect cleanup, native module error handling, FlatList (7 patterns)
- [django.md](django.md) — Django REST Framework: model conventions, serializer fields, ViewSet vs APIView, permissions, settings structure, signal usage, QuerySet manager methods (7 patterns)
