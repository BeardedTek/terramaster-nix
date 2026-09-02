---
title: WebUI
linkTitle: WebUI
weight: 20
description: The web dashboard — logging in, the home page, services, and the admin pages (System Preferences, Service Configuration, Users, System Update).
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

![Login page](/terramaster-nix/images/webui/02-login.png)

## Dashboard

The home page shows live, current-reading status: storage usage per
pool/dataset, system load, memory, network interface status, and which
services are currently reachable. It refreshes on its own every 30
seconds — no need to reload the page.

![Dashboard, logged in](/terramaster-nix/images/webui/03-dashboard-loggedin.png)

## Services

The Services page lists every enabled service as a clickable tile, with a
live up/down badge for each. Only shows what's actually turned on for
this box — see [Available Services](/docs/usage/services/) for what each
one is and how to use it.

![Services page](/terramaster-nix/images/webui/04-services.png)

## Admin pages

Everything below is visible only to admin accounts (see
[LLDAP](/docs/usage/lldap/) for what makes an account admin), reached from
the profile menu (your username, top-right) once you're logged in.

### System Preferences

Network and outbound email (SMTP) settings.

![System Preferences](/terramaster-nix/images/webui/05-preferences.png)

### Service Configuration

Enable, disable, and configure individual services — grouped by category,
each expandable down to a specific service's own settings. Changes here
rebuild the system in place once you hit **Save**, the same way enabling a
service in the installer wizard does.

![Service Configuration](/terramaster-nix/images/webui/08-service-configuration.png)

### Users

Add, remove, and modify accounts, and reset passwords — all without
touching a config file. Toggling admin (wheel) access or adding a new user
rebuilds the system in place; removing a user is non-destructive (drops
them from the managed list only, the account itself is never deleted) and
resetting a password takes effect immediately across Unix, LLDAP, and
Samba together, no rebuild needed.

![Users](/terramaster-nix/images/webui/06-users.png)

### System Update

Shows the currently installed version and the latest available release.
**Check for updates** refreshes that comparison; **Update now** (enabled
once a newer release is available) fetches it and rebuilds the system in
place — this can take several minutes, and services may briefly restart
as part of it. Only admin accounts can trigger an update; everyone else
can still see the version info.

![System Update](/terramaster-nix/images/webui/07-update.png)

### Let's Encrypt

Configure DNS-01 certificate issuance after the fact, if you skipped it
during installation — same provider list and fields as the installer
wizard's own DNS-01 step.

![Let's Encrypt](/terramaster-nix/images/webui/10-letsencrypt.png)
