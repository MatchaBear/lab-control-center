# DNS Notes Index

Contributors: bermekbukair, Codex

## Purpose

This index is a quick guide to the DNS notes in this directory so you do not have to guess which file to read later.

## Read This First

- [DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md](./DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md)

Use this when you want the conceptual explanation:

- how `1.1.1.1` secures DNS,
- why encrypted DNS is different from plain DNS,
- why Cloudflare is often described as more private than Google,
- what `DoH` and `DoT` actually do,
- what your ISP can still see.

If you only want one note to understand the big picture, start here.

## Read This Second

- [DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md](./DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md)

Use this when you want practical verification steps:

- how to check Linux DNS behavior,
- how to inspect `systemd-resolved`,
- how to verify browser secure DNS,
- how to use packet capture to distinguish plain DNS from `DoT`,
- how to avoid false assumptions.

Read this when you want proof that encrypted DNS is actually working on a system.

## Read This Third

- [DNS_RESOLVER_COMPARISON_CLOUDFLARE_GOOGLE_QUAD9_NEXTDNS.md](./DNS_RESOLVER_COMPARISON_CLOUDFLARE_GOOGLE_QUAD9_NEXTDNS.md)

Use this when you want to choose a resolver:

- Cloudflare vs Google
- Quad9 vs NextDNS
- privacy vs filtering
- simplicity vs customization
- which resolver fits a home lab or security-focused setup

Read this when you already understand encrypted DNS and now want to decide which provider makes sense.

## Recommended Reading Order

1. [DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md](./DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md)
2. [DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md](./DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md)
3. [DNS_RESOLVER_COMPARISON_CLOUDFLARE_GOOGLE_QUAD9_NEXTDNS.md](./DNS_RESOLVER_COMPARISON_CLOUDFLARE_GOOGLE_QUAD9_NEXTDNS.md)

## Quick Decision Guide

If you are asking:

- "How does `1.1.1.1` protect DNS?"  
  Read [DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md](./DNS_PRIVACY_1.1.1.1_VS_8.8.8.8.md)

- "How do I prove my machine is really using encrypted DNS?"  
  Read [DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md](./DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md)

- "Which resolver should I use?"  
  Read [DNS_RESOLVER_COMPARISON_CLOUDFLARE_GOOGLE_QUAD9_NEXTDNS.md](./DNS_RESOLVER_COMPARISON_CLOUDFLARE_GOOGLE_QUAD9_NEXTDNS.md)

## Bottom Line

Use this file as the entry point.
If you forget which note does what, come back here first.
