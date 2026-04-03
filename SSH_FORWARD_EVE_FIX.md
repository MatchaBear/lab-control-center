# SSH Forward to EVE-NG from LAN (Permanent Fix)

Contributors: bermekbukair, Codex

Last updated: 2026-03-27

## Goal

From another LAN host (example `192.168.68.112`), SSH into `eve-ng` (`192.168.122.100`) through this Ubuntu host.

Working path:

`192.168.68.112 -> 192.168.68.144:2222 -> 192.168.122.100:22`

## Why direct SSH failed initially

- `eve-ng` lives on libvirt NAT network `192.168.122.0/24`.
- Not directly routable from LAN `192.168.68.0/24`.
- Initial UFW DNAT rules conflicted with libvirt forward chains and caused `connection refused`.

## Final working approach (recommended)

Use a persistent `socat` systemd service instead of UFW DNAT hacks.

## Service file in use

- `/etc/systemd/system/eve-ssh-forward.service`

Contents:
```ini
[Unit]
Description=Forward host TCP 2222 to eve-ng SSH (192.168.122.100:22)
After=network-online.target libvirtd.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/socat TCP-LISTEN:2222,fork,reuseaddr,bind=0.0.0.0 TCP:192.168.122.100:22
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
```

## Required UFW rules

Keep:
- `ALLOW IN 2222/tcp`

Do not rely on custom DNAT entries in `/etc/ufw/before.rules` for this use case.

## Critical cleanup that fixed it

Problem:
- Stale runtime iptables DNAT rules still existed for port `2222`.

Detected with:
```bash
sudo iptables -t nat -S | grep 2222
```

Removed with:
```bash
sudo iptables -t nat -D PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.122.100:22
sudo iptables -t nat -D POSTROUTING -p tcp -d 192.168.122.100 --dport 22 -j MASQUERADE
```

Repeat deletions until:
```bash
sudo iptables -t nat -S | grep 2222
```
returns no output.

## Validation commands

On Ubuntu host:
```bash
ss -ltnp | grep 2222
systemctl status --no-pager eve-ssh-forward.service
sudo ufw status numbered
```

From remote LAN host:
```bash
nc -vz 192.168.68.144 2222
ssh -p 2222 <eve_user>@192.168.68.144
```

## Troubleshooting quick map

1. `connection refused`:
- Check stale DNAT rules in nat table.

2. `timeout`:
- Check LAN path/router/client isolation.

3. `ssh auth failed`:
- Port path is fine; check EVE user/key/password.

