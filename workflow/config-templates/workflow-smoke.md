# Workflow Smoke Config
# Smoke test execution config — read by spec-smoke-test.
# Populated by project-init-new during project initialization.

## UI Testing
ui_driver:              # playwright | cypress | maestro | none
ui_script_lang:         # javascript | typescript | python | none
ui_script_lang_ext:     # js | ts | py — file extension derived from ui_script_lang

## Temp scripts
tmp_script_prefix:      # e.g. smoke-tests/.tmp-

## Log tailing
log_tail_backend:       # e.g. 50
log_tail_frontend:      # e.g. 30
