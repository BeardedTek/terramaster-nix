#!/usr/bin/env bash
set -euo pipefail

WIZ_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$WIZ_SELF_DIR/lib/common.sh"
# shellcheck source=lib/wiz-claim.sh
source "$WIZ_SELF_DIR/lib/wiz-claim.sh"

# Selects which implementation of wiz_msgbox/wiz_yesno/wiz_input/
# wiz_password/wiz_menu/wiz_checklist/wiz_textbox gets defined — every
# stage file below calls only these names, identically either way (see
# lib/ui-web.sh's own header comment). hosts/installer/configuration.nix's
# environment.loginShellInit invokes this script with no override
# (defaults to tui, today's behavior, unchanged); the WebUI's own
# systemd service (installer-wizard-web) sets WIZ_UI_BACKEND=web.
: "${WIZ_UI_BACKEND:=tui}"
case "$WIZ_UI_BACKEND" in
  web)
    # shellcheck source=lib/ui-web.sh
    source "$WIZ_SELF_DIR/lib/ui-web.sh"
    ;;
  tui)
    # shellcheck source=lib/ui-tui.sh
    source "$WIZ_SELF_DIR/lib/ui-tui.sh"
    ;;
  *)
    echo "Unknown WIZ_UI_BACKEND=$WIZ_UI_BACKEND (expected tui or web)" >&2
    exit 1
    ;;
esac

# shellcheck source=lib/pool-existing.sh
source "$WIZ_SELF_DIR/lib/pool-existing.sh"
# shellcheck source=lib/pool-new.sh
source "$WIZ_SELF_DIR/lib/pool-new.sh"
# shellcheck source=lib/generate-config.sh
source "$WIZ_SELF_DIR/lib/generate-config.sh"

for stage in "$WIZ_SELF_DIR"/stages/*.sh; do
  # shellcheck disable=SC1090
  source "$stage"
done

trap 'echo; echo "Wizard exited unexpectedly. Nothing after the last completed stage ran." >&2' ERR

# Records which stage is currently running in $WIZ_CURRENT_STAGE — purely
# informational (lib/ui-web.sh includes it in question.json for the
# frontend's own breadcrumb/progress display); no stage's own logic reads
# it. stage_50_users's internal recursive self-re-invocation on "no admin
# user added" bypasses this wrapper on its second call, which is fine —
# the label is already correct from the first call.
_wiz_run_stage() {
  # shellcheck disable=SC2034  # read by lib/ui-web.sh's _wiz_web_ask
  WIZ_CURRENT_STAGE="$1"
  "$1"
}

_wiz_run_stage stage_00_welcome
_wiz_run_stage stage_10_repo_update
_wiz_run_stage stage_20_network
_wiz_run_stage stage_30_instance
_wiz_run_stage stage_40_storage
_wiz_run_stage stage_50_users
_wiz_run_stage stage_60_features
_wiz_run_stage stage_65_smtp
_wiz_run_stage stage_66_tailscale
_wiz_run_stage stage_70_secrets
_wiz_run_stage stage_71_dns01
_wiz_run_stage stage_80_review
_wiz_run_stage stage_90_install
