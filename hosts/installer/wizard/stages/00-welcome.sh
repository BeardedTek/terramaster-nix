#!/usr/bin/env bash

stage_00_welcome() {
  wiz_msgbox "Welcome" "This wizard sets up a new NAS using the terramaster-nix flake.

It will ask about networking, storage, users, and which services to enable, then generate the real Nix config for this box and install NixOS.

Two storage paths are supported:
  - Adopt an EXISTING ZFS pool (non-destructive — only changes dataset properties, never deletes data)
  - Create a NEW pool on blank disks (DESTRUCTIVE — wipes whatever is on the disks you pick)

You will be asked to explicitly confirm before anything destructive happens. Nothing is written to disk before the final confirmation screen."
}
