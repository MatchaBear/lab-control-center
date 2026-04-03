# DNS Encryption Verification on Linux and Browsers

Contributors: bermekbukair, Codex

## Goal

This note focuses on how to verify whether a machine is actually using encrypted DNS such as:

- `DoT` - DNS over TLS
- `DoH` - DNS over HTTPS

It is written as a practical companion to:

- [DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md](./DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md)

## What You Are Trying To Prove

You want evidence for one of these states:

- DNS is plain and going out on port `53`
- DNS is encrypted with `DoT` on port `853`
- DNS is encrypted with `DoH` over `443`

Do not rely only on a resolver IP like `1.1.1.1` or `8.8.8.8`.
The IP alone does not prove encryption.

## Linux Verification

### 1. Check Resolver Status

If your system uses `systemd-resolved`, run:

```bash
resolvectl status
```

Things to look for:

- which DNS servers are in use,
- whether `DNSOverTLS=yes` is shown,
- whether fallback DNS servers are being used unexpectedly.

If `DNSOverTLS=yes` appears for the active link or global resolver, that is a strong sign that `DoT` is configured.

### 2. Check `/etc/resolv.conf`

```bash
cat /etc/resolv.conf
```

Interpretation:

- If you see a normal remote resolver IP, that often means classic stub behavior.
- If you see `127.0.0.53`, that usually means `systemd-resolved` is acting as a local stub.

Important:

- `127.0.0.53` does not prove encryption by itself.
- It only shows that the local machine is forwarding DNS through the local resolver stub.

### 3. Inspect `systemd-resolved` Configuration

```bash
grep -R "DNSOverTLS" /etc/systemd /etc/NetworkManager 2>/dev/null
```

Common values:

- `DNSOverTLS=yes`
- `DNSOverTLS=opportunistic`
- not set at all

Meaning:

- `yes` means require TLS when supported
- `opportunistic` means try TLS, but may fall back
- unset means you should verify behavior by traffic capture

You can also inspect:

```bash
grep -R "DNS=" /etc/systemd /etc/NetworkManager 2>/dev/null
```

That helps confirm which resolver is configured.

### 4. Look at Active NetworkManager Settings

If NetworkManager is in use:

```bash
nmcli connection show
nmcli connection show "<your-connection-name>"
```

Check whether DNS is:

- provided by DHCP,
- manually configured,
- or routed through systemd-resolved.

### 5. Packet Capture Test

This is the most practical network-level check.

To look for plain DNS or `DoT`:

```bash
sudo tcpdump -ni any port 53 or port 853
```

Interpretation:

- traffic on port `53` usually means plain DNS
- traffic on port `853` usually means `DoT`

If you consistently see port `53` DNS requests leaving the machine, those requests are not encrypted.

### 6. Why `DoH` Is Harder To Confirm with Packets

`DoH` usually rides inside HTTPS on port `443`.
That means packet captures may only show HTTPS sessions to the resolver, not obvious DNS traffic.

So for `DoH`, you usually need a combination of:

- browser settings,
- OS resolver settings,
- firewall/proxy visibility,
- and sometimes resolver test pages.

### 7. Check Open Connections

Useful commands:

```bash
ss -tulpn
ss -tpn | grep -E '(:853|:443)'
```

These help you spot:

- active sessions to resolver IPs,
- long-lived TLS connections to DNS providers,
- possible `DoT` sessions on `853`.

This is supportive evidence, not perfect proof.

## Browser Verification

Modern browsers may use their own secure DNS path, bypassing part of the OS resolver path.

That means:

- the OS may use plain DNS,
- while the browser still uses `DoH`,
- or the opposite.

You must verify both layers if you care about the full system.

### Firefox

Open Firefox settings and look for:

- `Enable DNS over HTTPS`
- resolver/provider choice

Common behavior:

- Firefox can use Cloudflare or another `DoH` provider directly
- this may work independently of Linux resolver settings

### Chrome / Chromium / Edge

Look for:

- `Use secure DNS`
- provider selection or auto-upgrade behavior

Common behavior:

- browser may try to upgrade to secure DNS when the current provider supports it
- browser may use OS DNS settings in some cases

### Why Browser Settings Matter

If the browser uses `DoH`, then browser name lookups may be encrypted even if the rest of the OS is not.

Examples of non-browser apps that may still use OS DNS:

- terminal tools
- package managers
- local services
- VPN clients
- custom applications

## Test Pages

These can help validate encrypted DNS behavior:

- Cloudflare: `https://1.1.1.1/help`

These pages are useful for quick checks, but they are not as authoritative as:

- local config review,
- packet capture,
- or firewall/proxy logs.

## Recommended Verification Workflow

Use this order:

### For Linux system-wide DNS

1. Check:

```bash
resolvectl status
```

2. Check:

```bash
cat /etc/resolv.conf
```

3. Inspect config:

```bash
grep -R "DNSOverTLS" /etc/systemd /etc/NetworkManager 2>/dev/null
```

4. Capture traffic:

```bash
sudo tcpdump -ni any port 53 or port 853
```

### For browser DNS

1. Check browser secure DNS settings
2. Use the browser to visit a DNS test page
3. Compare browser behavior against OS traffic capture

## How To Interpret Results

### Case 1: You See Port `53`

That usually means plain DNS is being used for those queries.

### Case 2: You See Port `853`

That strongly suggests `DoT`.

### Case 3: You See No Port `53`, But Browser Claims Secure DNS

That may mean the browser is using `DoH`.

### Case 4: OS Looks Encrypted, But Apps Still Leak Port `53`

That means some applications are bypassing the intended encrypted path.

## Common Pitfalls

- Seeing `1.1.1.1` in config and assuming it is encrypted
- assuming browser secure DNS means the entire OS is protected
- assuming `127.0.0.53` means encryption is active
- forgetting that VPN clients may replace DNS behavior
- forgetting that captive portals and enterprise controls may interfere

## Stronger Validation Options

If you want higher-confidence validation:

- inspect firewall logs,
- inspect router logs,
- inspect proxy logs,
- compare resolver traffic before and after enabling secure DNS,
- test with browser secure DNS both enabled and disabled.

## Practical Bottom Line

To verify encrypted DNS reliably:

- check local resolver config,
- check browser secure DNS settings,
- and confirm with traffic capture.

No single indicator is enough by itself.
