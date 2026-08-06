---
title: LLDAP
linkTitle: LLDAP
weight: 10
description: The one directory backing every login on this box.
---

[LLDAP](https://github.com/lldap/lldap) is a lightweight LDAP directory —
the single account system every login on this box checks against: the
web dashboard, the media/home-automation services that support it, and
(if enabled) the box's own console/`sudo` login. One username and
password works everywhere, instead of a separate login per service.

## Reaching the admin UI

LLDAP has its own web interface, reachable on your LAN at
`http://<your-nas>:17170`. It's LAN-only by design — not proxied through
the same reverse proxy as everything else — so the directory that
everything else depends on stays reachable even if something else on the
box is broken.

## User Management

Who exists is controlled from the flake's `variables.nix`
(`mySystem.users`), not through LLDAP's UI directly — adding or removing
a user, or changing who's an admin, is a config change made by whoever
maintains this box, then applied with a rebuild. If you need an account
added, ask them.

- **Admins** — anyone with `wheel = true` in `mySystem.users` is placed
  in LLDAP's `admins` group automatically. Admin accounts get access to
  the dashboard's [System Preferences](/docs/usage/webui/#system-preferences)
  page, including the ability to trigger a system update.
- **Self-service password changes** — once your account exists, you can
  change your own password at any time through LLDAP's own web UI above
  (log in with your current username/password, then use the profile
  option to set a new one). This is the same password used for the
  dashboard and every other LLDAP-backed login — change it in one place,
  it takes effect everywhere.
- **Forgot your password?** Only an admin can reset it for you — there's
  no self-service "forgot password" email flow.
