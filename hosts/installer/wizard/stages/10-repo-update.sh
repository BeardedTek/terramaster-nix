#!/usr/bin/env bash

# Populates WIZ_REPO_WORKDIR with a writable checkout: either a fresh
# `git clone` of WIZ_REPO_URL (if the operator opts in and it succeeds),
# or a copy of the ISO's baked-in snapshot otherwise. Nothing here writes
# into the baked-in copy itself — it stays a clean fallback.
stage_10_repo_update() {
  local use_fresh=false

  if wiz_yesno "Check for updates?" "This ISO has a snapshot of terramaster-nix baked in from when it was built.

Check for a newer version now? Requires network access. If this fails or you say no, the baked-in copy is used instead — nothing is lost either way."; then
    use_fresh=true
  fi

  rm -rf "$WIZ_REPO_WORKDIR"

  if [ "$use_fresh" = true ]; then
    if git clone --depth 1 "$WIZ_REPO_URL" "$WIZ_REPO_WORKDIR" 2>/tmp/wiz-git-clone.log; then
      wiz_set repo_source "fresh clone of $WIZ_REPO_URL"
      return 0
    fi
    wiz_msgbox "No update available" "Couldn't clone $WIZ_REPO_URL (no network, or the clone failed — see /tmp/wiz-git-clone.log). Falling back to the baked-in copy."
  fi

  cp -r "$WIZ_REPO_BAKED_IN" "$WIZ_REPO_WORKDIR"
  chmod -R u+w "$WIZ_REPO_WORKDIR"
  wiz_set repo_source "baked-in ISO snapshot"
}
