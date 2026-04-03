# DNS Privacy: `1.1.1.1` vs `8.8.8.8`

Contributors: bermekbukair, Codex

## Short Answer

`1.1.1.1` does not automatically encrypt DNS just because the resolver IP is `1.1.1.1`.

The real difference is:

- Plain DNS uses UDP/TCP port `53` and is readable on the network path.
- Encrypted DNS uses `DoH` or `DoT`, which wrap the DNS query in TLS.

Cloudflare's privacy story is mainly:

- strong support for encrypted DNS,
- a public claim of stricter logging/privacy posture than Google Public DNS.

## How `1.1.1.1` Secures DNS Queries

When encrypted DNS is used:

- Your device opens a TLS connection to Cloudflare's DNS endpoint.
- The DNS query is sent inside that encrypted session.
- Your ISP or local network can still see that you connected to Cloudflare.
- They usually cannot see the exact domain names inside the DNS requests.
- Cloudflare still sees the DNS queries because it is the resolver.

This means encrypted DNS protects the query from the network path, not from the resolver operator.

## What Actually Encrypts DNS

### `DoT` - DNS over TLS

- Uses TLS directly for DNS.
- Usually runs on port `853`.
- Clean and purpose-built for DNS.
- Easier for networks to identify and block as encrypted DNS.

### `DoH` - DNS over HTTPS

- Sends DNS inside HTTPS.
- Usually runs on port `443`.
- Blends in with normal web traffic.
- Harder for middleboxes to distinguish from ordinary HTTPS.
- Common in browsers and modern operating systems.

## `DoH` vs `DoT`

Both encrypt DNS between client and resolver. The main difference is transport style.

- `DoH` is often easier on desktops, browsers, and phones.
- `DoT` is often preferred in routers, firewalls, and infrastructure setups.
- In privacy terms, both are similar if configured correctly.

## What Encrypted DNS Protects Against

- ISP inspection of plain DNS lookups
- local Wi-Fi snooping
- simple DNS tampering on the path

## What Encrypted DNS Does Not Protect Against

- The resolver still sees your queries
- Destination IPs are still visible
- Traffic timing and volume are still visible
- Browser/app telemetry can still reveal where you go
- It does not provide anonymity like Tor
- It does not replace a VPN

## What Your ISP Can Still See

Even with encrypted DNS, your ISP can usually still see:

- that you connected to a resolver such as Cloudflare or Google,
- the resolver IP address,
- the destination IPs you later connect to,
- traffic timing and size patterns.

Your ISP usually cannot see:

- the domain name inside the encrypted DNS request,
- the plaintext DNS answer.

Important nuance:

- Even if the DNS name is hidden, the destination IP may strongly suggest the site.
- CDNs can make that less exact, but not always.

## Who Sees What

### Plain DNS

- Local network: sees the domain
- ISP: sees the domain
- Resolver: sees the domain

### Encrypted DNS (`DoH` or `DoT`)

- Local network: sees connection to resolver, not the DNS contents
- ISP: sees connection to resolver, not the DNS contents
- Resolver: still sees the DNS contents

So encrypted DNS reduces visibility on the path and centralizes trust at the resolver.

## `1.1.1.1` vs `8.8.8.8`

Technically:

- Both support plain DNS.
- Both can support encrypted DNS.
- Neither is private if used only over plain port `53`.

The practical difference is trust and policy:

- Cloudflare markets minimal logging and privacy-focused retention claims.
- Google Public DNS is operated by Google, which many people trust less for privacy reasons.
- The transport security is not fundamentally different if both are used with `DoH` or `DoT`.

So the honest version is:

- `1.1.1.1` is not private by magic.
- `1.1.1.1` becomes private from the network path when used with `DoH` or `DoT`.
- `8.8.8.8` can also be encrypted.
- The real choice is often which resolver operator you trust more.

## Why Cloudflare Claims More Privacy

Cloudflare's argument is mostly not "we encrypt better."
It is:

- they support encrypted DNS well,
- they claim shorter retention and less identifying log storage,
- they position themselves as more privacy-oriented than Google.

So the difference is largely business posture and logging policy, not a unique cryptographic mechanism.

## What Encrypted DNS Is Not

Think of it this way:

- Plain DNS: postcard
- Encrypted DNS: sealed envelope to the resolver
- VPN: encrypted tunnel to another network
- Tor: multi-hop anonymity network

Encrypted DNS hides DNS contents from the path, but not the fact that you are communicating or where you ultimately connect.

## How To Verify If You Are Actually Using Encrypted DNS

You want proof from local config and traffic behavior, not just marketing labels.

### Linux Checks

Check resolver status:

```bash
resolvectl status
```

Look for:

- DNS servers in use
- `DNSOverTLS=yes` if systemd-resolved is handling DoT

Check resolver stub:

```bash
cat /etc/resolv.conf
```

If this points to `127.0.0.53`, that may indicate `systemd-resolved`, but it does not prove encryption by itself.

Inspect relevant config:

```bash
grep -R "DNSOverTLS" /etc/systemd /etc/NetworkManager 2>/dev/null
```

### Browser Checks

Browsers may use their own secure DNS path independent of the OS.

Look for settings such as:

- `Use secure DNS`
- provider choices like Cloudflare, Google, Quad9, or NextDNS

### Packet-Level Checks

If you see DNS to port `53`, that is usually plain DNS.
If you see DNS to port `853`, that is usually DoT.
If DNS is going over `443`, it may be DoH.

Example:

```bash
sudo tcpdump -ni any port 53 or port 853
```

If you only see port `53` DNS queries, those queries are not encrypted.

`DoH` is harder to verify from packets alone because it blends into normal HTTPS traffic on port `443`.

### Functional Test Pages

You can also use test pages such as:

- Cloudflare `1.1.1.1/help`

These can indicate whether `DoH` or `DoT` is active, though local configuration plus packet capture is stronger evidence.

## Practical Recommendations

If you want better privacy with low complexity:

- use `1.1.1.1` or `Quad9` with `DoH` or `DoT`

If you want filtering/security features too:

- use `Quad9`, `NextDNS`, or a local resolver with encrypted upstreams

If you want to reduce trust in third-party resolvers:

- run a local recursive resolver, or
- use a trusted local resolver that forwards upstream over TLS carefully

## Bottom Line

- Encryption method: `DoH` or `DoT`
- Main privacy gain: hides DNS contents from ISP/local network
- Remaining trust point: the resolver operator
- Main Cloudflare vs Google difference: trust and policy, not a magical transport difference
