---
title: WebUI
linkTitle: WebUI
weight: 20
description: The web dashboard — logging in, the home page, services, and System Preferences.
---

The web dashboard is the box's own landing page — reachable on your LAN,
and over a Nebula mesh if you've set one up, at whichever domain or IP
your installation uses.

## Logging In / Out

The dashboard's home page is public — anyone who can reach it sees live
status at a glance, no login needed. Everything else (Services, Samba/NFS
info, System Preferences) requires signing in with your LLDAP username
and password (see [LLDAP](/docs/usage/lldap/) for where that account
comes from).

- **Log in** from the Login link in the top-right, or by visiting any
  page that requires it — you'll be redirected there automatically.
- **Log out** from the profile menu (your username, top-right) once
  you're signed in.

## Dashboard

The home page shows live, current-reading status: storage usage per
pool/dataset, system load, memory, network interface status, and which
services are currently reachable. It refreshes on its own every 30
seconds — no need to reload the page.

## Services

The Services page lists every enabled service as a clickable tile, with a
live up/down badge for each. Only shows what's actually turned on for
this box — see [Available Services](/docs/usage/services/) for what each
one is and how to use it.

## System Preferences

Visible only to admin accounts (see [LLDAP](/docs/usage/lldap/)), reached
from the profile menu once you're logged in.

### Updating

The Update panel shows the currently installed version and the latest
available release. **Check for updates** refreshes that comparison;
**Update now** (enabled once a newer release is available) fetches it and
rebuilds the system in place — this can take several minutes, and
services may briefly restart as part of it. Only admin accounts can
trigger an update; everyone else can still see the version info.
