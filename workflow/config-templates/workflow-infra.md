# Workflow Infra Config
# Infrastructure and environment config — read by spec-smoke-test and bug-fix.
# Populated by project-init-new during project initialization.

## Orchestrator
type:                   # docker-compose | kubernetes | none

## Services
backend_service:        # e.g. backend — matches service name in docker-compose.yml
frontend_service:       # e.g. frontend | none
db_service:             # e.g. postgres | none

## Ports
backend_port:           # e.g. 8000
frontend_port:          # e.g. 3000 | none

## Database
db_type:                # postgresql | mysql | sqlite | mongodb | none
db_url:                 # e.g. postgresql://localhost/myproject | none
db_query_tool:          # psql | mysql | sqlite3 | none
db_migration_tool:      # alembic | flyway | prisma | liquibase | none
