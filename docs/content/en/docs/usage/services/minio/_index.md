---
title: MinIO
linkTitle: MinIO
weight: 90
description: S3-compatible object storage.
---

## Information and purpose

[MinIO](https://min.io/) provides S3-compatible object storage — useful
for backups, self-hosted apps that expect an S3 bucket, or anything else
that speaks the S3 API, without needing an actual cloud account.

## Configuration

- **Access**: the S3 API itself is at
  `https://minio.<your-nas>.<domain>/` (or directly at
  `http://<nas-ip>:9000/`); the web console is at
  `https://minio-console.<your-nas>.<domain>/` (or directly at
  `http://<nas-ip>:9001/`), with Nebula equivalents if configured.
- **Login**: root credentials are set up by whoever manages this box
  during install — ask them if you need console access, or a bucket/key
  created for something you're setting up.
- **Storage**: backed by its own dedicated storage area on this box,
  separate from the media library.

## Usage

MinIO's own object-storage documentation moved between hosts recently as
the upstream project restructured its open-source offering — check
[min.io](https://min.io/) or the
[MinIO GitHub repository](https://github.com/minio/minio) for current
docs on the web console, `mc` CLI, and S3 client compatibility.
