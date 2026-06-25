# mtproto.sh

A script to quickly deploy a Telegram MTProto proxy in Docker using [nineseconds/mtg](https://hub.docker.com/r/nineseconds/mtg).

## Requirements

- [Docker](https://github.com/docker/docker-install)
- Python 3 (used to build the `tg://proxy` link)
- `curl` (for the QR code at the end; install separately if you launch via `wget`)

## Quick start

### curl

```bash
curl -fsSL https://raw.githubusercontent.com/duck-psycho/mtproto-sh/refs/heads/main/mtproto.sh | bash
```

### wget

```bash
wget -qO- https://raw.githubusercontent.com/duck-psycho/mtproto-sh/refs/heads/main/mtproto.sh | bash
```

The script will prompt for three options (press `Enter` to accept the defaults):

| Option | Default | Description |
|---|---|---|
| Domain (SNI) | `google.com` | Domain used for TLS disguise |
| Port | `443` | Host TCP port |
| DoH IP | `1.1.1.1` | DNS-over-HTTPS server IP |

When finished, the script prints a `tg://proxy?...` link and a QR code in the terminal.

## Local setup

```bash
git clone https://github.com/duck-psycho/mtproto-sh.git
cd mtproto-sh
bash mtproto.sh
```
