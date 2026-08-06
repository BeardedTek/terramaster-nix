---
title: Frigate
linkTitle: Frigate
weight: 70
description: NVR with real-time object detection for IP cameras.
---

## Information and purpose

[Frigate](https://frigate.video/) is a network video recorder with
real-time object detection — watches IP camera feeds, detects people,
vehicles, and other objects, and records/alerts around what it finds
rather than recording everything continuously.

## Configuration

- **Access**: `https://frigate.<your-nas>.<domain>/`, the Nebula
  equivalent if configured, or directly at `http://<nas-ip>:8098/`.
- **Login**: Frigate's own built-in login — the admin account is
  auto-generated on first start. If this is a fresh install and you don't
  have the password, an admin can find it in the service log.
- **Cameras**: none are configured out of the box — add your own camera
  feeds through Frigate's own configuration.

## Usage

See [Frigate's own documentation](https://docs.frigate.video/) for adding
cameras, configuring detection zones, and setting up notifications.
