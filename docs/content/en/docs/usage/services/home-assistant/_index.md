---
title: Home Assistant
linkTitle: Home Assistant
weight: 80
description: Home automation, with HACS, optional Z-Wave, and an MQTT broker.
---

## Information and purpose

[Home Assistant](https://www.home-assistant.io/) is a home automation
platform — connects and automates smart-home devices from one place,
regardless of brand.

## Configuration

- **Access**: `https://homeassistant.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:8123/`.
- **Login**: Home Assistant's own account system — you'll create an
  admin account through its onboarding wizard the first time you visit.
  This is separate from your [LLDAP](/docs/usage/lldap/) account.
- **HACS** (the Home Assistant Community Store) comes pre-installed, but
  still needs a one-time activation: Settings → Devices & Services → Add
  Integration → search "HACS" → follow its GitHub sign-in flow to link
  your account.
- **Z-Wave**: off unless you have a Z-Wave USB dongle attached and it's
  been enabled for your box — ask whoever manages this NAS if you need it
  turned on.
- **MQTT broker (Mosquitto)** runs alongside Home Assistant for smart-home
  devices that speak MQTT, already wired up as an integration — no setup
  needed on the Home Assistant side.
- **File access**: Home Assistant's own config directory is available as
  a network share (see [Samba](/docs/usage/services/samba/)) if you want
  to edit `configuration.yaml` and friends directly from a PC.

## Usage

See [Home Assistant's own documentation](https://www.home-assistant.io/docs/)
for adding integrations, automations, and dashboards, and the
[HACS documentation](https://hacs.xyz/) for installing community
integrations once it's activated.
