# Home Assistant

Native `services.home-assistant` (no Docker, no HA Supervisor/HAOS) —
consistent with how everything else in this repo runs. This means the
usual HAOS/Supervised "Add-on Store" doesn't exist here; each add-on the
user actually asked for (HACS, Z-Wave JS, a Samba share, an MQTT broker)
is instead wired up as its own native NixOS service or a small piece of
plumbing around `services.home-assistant`, in `modules/home-assistant.nix`
(plus one line in `modules/samba.nix` for the share).

- **Nebula**: `https://hass-young.nebula.beardedtek.com`
- **LAN**: `https://hass.young.beardedtek.com`
- Direct, without Traefik: `http://192.168.3.181:8123` (LAN) or
  `http://10.100.0.17:8123` (Nebula) — opened on both interfaces
  alongside the proxied domains above, same posture as Jellyfin/Sonarr
  elsewhere in this repo.

Both proxied domains come for free from the same generic
`backends`-map/`routersFor` pattern every other service in this repo
uses (see `docs/ARCHITECTURE.md`'s Traefik section) — Home Assistant
needed no special-casing there, unlike Frigate or qBittorrent.

## First boot

Home Assistant runs its own onboarding wizard on first visit — create
your own admin account there. This is entirely separate from the NixOS
`beardedtek`/`dyoung` system accounts; there's no unification between the
two here (see `docs/TROUBLESHOOTING.md` if you're looking for the same
discussion in Frigate's context — the short version is that neither
project has real Linux/PAM account integration, so there's no clean way
to share credentials without a much bigger identity-provider setup).

## Reverse-proxy config (already handled, informational)

Home Assistant validates that requests came from a `trusted_proxies`
entry and outright rejects anything else — "Requests from reverse
proxies will be blocked if these options are not set" per HA's own `http`
integration docs. This repo already sets:

```nix
services.home-assistant.config.http = {
  trusted_proxies = [ "127.0.0.1" "::1" ];
  use_x_forwarded_for = true;
};
```

If HA is ever moved behind a *different* reverse proxy (or Traefik starts
running somewhere other than `127.0.0.1` relative to HA), this list needs
updating or every proxied request will 400.

## HACS

[HACS](https://hacs.xyz) isn't packaged in nixpkgs'
`pkgs.home-assistant-custom-components` set — it's designed to self-update
at runtime by downloading from GitHub, which doesn't fit Nix's
reproducible-build model, so nixpkgs doesn't ship it. Instead:

- `modules/home-assistant.nix` fetches a pinned HACS release directly
  (`pkgs.fetchzip`, version + hash pinned in the module) and a one-shot
  systemd service, `hass-install-hacs`, installs it into
  `/var/lib/hass/custom_components/hacs` every time the system activates
  (`before`/`requires` ordering ensures this always runs before
  `home-assistant.service` starts).
- **To bump the HACS version**: edit `hacsVersion` and the `sha256` in
  `modules/home-assistant.nix`. Get the new hash with:
  ```sh
  nix-prefetch-url --unpack https://github.com/hacs/integration/releases/download/<version>/hacs.zip
  ```
- **Activating it** is a one-time, interactive step done through the HA
  UI itself (not automatable via Nix): Settings → Devices & Services →
  Add Integration → search "HACS" → follow its GitHub device-authorization
  flow to link your account. After that, HACS manages itself through its
  own panel like it would on any other HA install.

## Z-Wave JS — disabled until a dongle is attached

`services.zwave-js.enable = false` right now. Its `serialPort` option has
no sane default, and the service would just fail to start without a real
USB device path — there was no Z-Wave dongle physically attached to
`young` when this was set up.

**Once the dongle is attached:**

1. On the box: `ls /dev/serial/by-id/` — find its stable device path
   (don't use a bare `/dev/ttyUSB0`-style path; USB enumeration order
   isn't guaranteed across reboots, same reasoning as the boot drive's
   `by-id` path in `hosts/young/disko.nix`).
2. In `modules/home-assistant.nix`, set:
   ```nix
   services.zwave-js = {
     enable = true;
     serialPort = "/dev/serial/by-id/<the-real-path>";
   };
   ```
3. Redeploy. Home Assistant's `zwave_js` component is already included
   (`extraComponents`), so once the zwave-js-server is actually running,
   add the "Z-Wave JS" integration through Settings → Devices & Services —
   it should find the local server automatically (`localhost:3000`, the
   module's default `port`).

## Mosquitto (MQTT broker)

Runs on port 1883, **anonymous access, no password** —
`omitPasswordAuth = true` / `listener_allow_anonymous = true` in
`modules/home-assistant.nix`. This matches the same trust posture as
Jellyfin/Sonarr/etc. elsewhere in this repo: protected by the LAN +
`nebula1` firewall rules (nothing outside those networks can reach it at
all), not by an application-level password. It is **not** fronted by
Traefik — MQTT isn't HTTP, so there's nothing for a reverse proxy to do
here.

To connect Home Assistant to it: Settings → Devices & Services → Add
Integration → MQTT → broker `localhost` (or `127.0.0.1`), port `1883`,
leave username/password blank.

**If this ever needs real authentication** (e.g. exposing MQTT beyond the
current LAN/Nebula scope, or just wanting per-device credentials): add a
`users` block to the listener in `modules/home-assistant.nix` and drop
`omitPasswordAuth`/`listener_allow_anonymous` — see the
`services.mosquitto.listeners.*.users` option for the shape (supports
plaintext, a password file, or a pre-hashed password, all documented
inline in the module).

## Samba share for the config directory

`modules/samba.nix` has a `hass` share pointing at `/var/lib/hass` (Home
Assistant's `configDir`), so `configuration.yaml` and friends can be
edited directly from a PC — same "Samba Share" add-on functionality HAOS
users are used to, just backed by the Samba service this repo already
runs rather than a separate add-on container.

It uses `"force user" = "hass"; "force group" = "hass";` rather than
adding `beardedtek`/`dyoung` to the `hass` system user's group — any file
written through this share ends up owned correctly by `hass` regardless
of which Samba user connected, so Home Assistant can still read/write it
normally afterward.

Connect the same way as the other shares — see `docs/DEPLOYMENT.md`'s
Samba section — just pick `hass` instead of `media`/`data`.

## Persistence

`/var/lib/hass` (HA's whole config dir — `configuration.yaml`, the
`.storage/` directory holding UI-configured integrations/entities/HACS
state, `custom_components/`, its own SQLite recorder database, etc.) and
`/var/lib/mosquitto` (retained messages, its persistence database) are
both in `environment.persistence."/persist".directories`
(`hosts/young/configuration.nix`) — full state survives every reboot
despite the tmpfs root, same as every other stateful service here.

## No build-time config validator

Unlike Frigate (`services.frigate.checkConfig`, which genuinely runs
Frigate's own `--validate-config` against the generated YAML as part of
the Nix build), `services.home-assistant` has no equivalent safety net. A
mistake in `services.home-assistant.config` will evaluate and build fine,
and only surface once the service actually tries to start:

```sh
sudo systemctl status home-assistant
sudo journalctl -u home-assistant -n 100 --no-pager
```

is the first place to look if it doesn't come up after a deploy.

## Adding more integrations later

Anything needing extra Python dependencies bundled into the HA package
(most built-in integrations beyond `default_config`'s bundle) needs
adding to `services.home-assistant.extraComponents` in
`modules/home-assistant.nix` — the component name is whatever appears in
the URL of its page under
[home-assistant.io/integrations](https://www.home-assistant.io/integrations/)
(e.g. `https://www.home-assistant.io/integrations/ffmpeg/` → `"ffmpeg"`).
Currently just `["mqtt" "zwave_js"]`.
