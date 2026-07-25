#!/usr/bin/env bash
set -euo pipefail

WIZ_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "$WIZ_SELF_DIR/lib/common.sh"
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

stage_00_welcome
stage_10_repo_update
stage_20_network
stage_30_instance
stage_40_storage
stage_50_users
stage_60_features
stage_70_secrets
stage_80_review
stage_90_install
