LAUNCHERS := codex codex2
# The container is the sandbox (dr mounts only the current dir, .git read-only),
# so skip per-command approvals and codex's own bubblewrap sandbox.
ARGS := \
  --dangerously-bypass-approvals-and-sandbox \
  -c check_for_update_on_startup=false \
  -c tui.disable_mouse_capture=true \
  --no-alt-screen

include ../agents-base/build.mk
