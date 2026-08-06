---
title: Troubleshooting
linkTitle: Troubleshooting
weight: 40
description: Common problems and what to do about them.
---

Common problems you might run into using this NAS, and what to do about
them. If you're maintaining or extending the flake itself and are looking
for deeper build/deploy failure modes instead, see
[Architecture](/docs/architecture/#failure-modes-hit-during-development).

## I can't log into the dashboard

- Double check your username and password — this is your
  [LLDAP](/docs/usage/lldap/) account, the same one used everywhere else
  on this box, not a separate dashboard-only login.
- If you've forgotten your password, you can't reset it yourself — ask an
  admin to set a new one for you.
- Make sure you're on the right network (LAN or the Nebula mesh, if one
  is set up) — the dashboard won't be reachable at all from outside
  either of those.

## A service tile on the dashboard shows "down"

- Confirm the service is actually supposed to be enabled — the
  [Services page](/docs/usage/webui/#services) only shows what's turned
  on for this box; a service that was never enabled won't appear at all,
  and one that's enabled but genuinely stopped will show as down.
- Give it a minute and refresh — the dashboard's status refreshes every
  30 seconds, so a service that just restarted may briefly show as down.
- If it stays down, ask whoever manages this box to check on it — this
  usually means the underlying service crashed or failed to start.

## The update button won't work / is grayed out

- **Update now** only becomes clickable once a newer release is actually
  available — if it's grayed out, click **Check for updates** first.
- Triggering an actual update requires an admin account — if you can see
  the version numbers but the button stays disabled even after a newer
  release shows up, you likely don't have admin access on this box.
- If an update visibly fails partway through, the log details (Show
  details, in the progress panel) usually explain why — share that with
  whoever manages this box if you need help.

## Can't connect to a Samba or NFS share

- Samba uses its **own separate password**, not your LLDAP password —
  ask whoever manages this box if you don't know it (see
  [Samba](/docs/usage/services/samba/)).
- NFS doesn't use a password at all — access is granted by network, so if
  it's not working, you're most likely not on the same LAN or mesh the
  share is exported to.
- Double-check the share path/hostname — see
  [Samba](/docs/usage/services/samba/) or [NFS](/docs/usage/services/nfs/)
  for the exact connection syntax for your operating system.

## Jellyfin playback is slow or stuttering

- Check whether it's actually transcoding (Jellyfin's own Dashboard →
  Active Devices/Sessions shows this) — direct-playing a file your device
  already supports natively is always smoother than transcoding it on the
  fly.
- If it is transcoding, confirm hardware acceleration is actually turned
  on in Jellyfin's own Dashboard → Playback settings — see
  [Jellyfin](/docs/usage/services/jellyfin/).
- A show/movie that's still downloading or importing may play back
  incompletely — check [Sonarr](/docs/usage/services/sonarr/)/
  [Radarr](/docs/usage/services/radarr/) to confirm it finished.

## Home Assistant onboarding

- Home Assistant has its **own separate account system** — the admin
  account you create the first time you visit it is not your LLDAP
  account, and there's no unification between the two.
- If you're not the first person to visit it, someone's already completed
  onboarding — ask them for an invite/account instead of trying to
  re-run the setup wizard.
- See [Home Assistant](/docs/usage/services/home-assistant/) for HACS
  activation and other first-time setup steps.

## None of this covers my problem

Ask whoever manages this box — if it turns out to be a deeper NixOS
configuration issue rather than a day-to-day usage problem, the
[Architecture](/docs/architecture/) doc's
[failure modes section](/docs/architecture/#failure-modes-hit-during-development)
is where that gets tracked.
