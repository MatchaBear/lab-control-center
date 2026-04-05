# CRL and OCSP over HTTP vs HTTPS (2026-04-06)

Contributors: bermekbukair, Codex

## Purpose

Explain, in plain English, why CRL and OCSP are often published over plain HTTP, why this is usually acceptable, and what security properties actually protect revocation checking.

This file exists because it is very easy to assume:

- `HTTP = insecure`
- therefore `CRL over HTTP = broken`

That conclusion is too simplistic.

## Short answer

For Microsoft PKI and many enterprise PKI deployments:

- CRLs are commonly published over `HTTP`
- OCSP is also commonly exposed over `HTTP`
- this is usually acceptable

Why:

- revocation information is public data
- integrity comes from digital signatures, not from TLS transport alone

## What CRL actually is

A CRL is a **Certificate Revocation List**.

It is:

- a signed list published by a CA
- containing certificates that the CA says are revoked
- along with timing information such as:
  - `ThisUpdate`
  - `NextUpdate`

Clients download the CRL and verify:

1. the CRL signature
2. the issuer
3. the validity/freshness window
4. whether the certificate serial number is listed

So a client is not supposed to trust the transport blindly.
It is supposed to trust the **CA signature on the CRL**.

## What OCSP actually is

OCSP is an online revocation-status protocol.

Instead of downloading a whole CRL file, the client asks for the status of a specific certificate.

The response is:

- signed by the OCSP responder
- which itself is trusted through PKI rules

So again:

- integrity comes from the signature on the OCSP response
- not merely from whether the transport is HTTP or HTTPS

## Why HTTP is commonly used

HTTP is popular for CRL and OCSP because it is simple and reliable.

Benefits:

- easy for many clients and appliances to consume
- easy to publish from IIS or any web server
- avoids TLS bootstrap/circular-trust problems
- revocation data is not secret data anyway

The important point:

- CRLs and OCSP responses are designed to be **publicly retrievable**
- they are not supposed to rely on secrecy

## Why HTTPS is not automatically better

HTTPS can be used, but it introduces extra complexity.

Problem:

- to trust `https://...`, the client must already trust the web server certificate
- but revocation checking is often part of certificate trust evaluation

This can create awkward bootstrap or circular dependency problems.

So while HTTPS is possible, it is often not the first or most useful choice for CRL/OCSP publication.

## Can a man-in-the-middle fake revocation data?

A sniffer or MITM can:

- read plain HTTP traffic
- block access
- replay or delay data in some cases
- cause denial-of-service conditions

But a MITM should **not** be able to successfully forge CRL or OCSP contents unless they can also forge valid signatures.

Why:

- a CRL is signed by the CA
- an OCSP response is signed by the responder certificate

If an attacker changes the content, the signature verification should fail.

## So what security property does HTTP still lack?

HTTP does not provide:

- confidentiality
- transport-layer server authentication
- transport-layer tamper resistance

But for revocation data, confidentiality is usually not the goal.

The main security goals are:

- integrity
- authenticity
- freshness
- availability

In PKI revocation, those are handled primarily by:

- CRL/OCSP signatures
- `ThisUpdate` / `NextUpdate`
- reachable publication points
- client freshness checks

## What still matters operationally

Even if HTTP is acceptable, you still care about:

- stale CRLs
- unreachable OCSP responder
- broken AIA/CDP URLs
- bad publication copies
- clients falling back in unexpected ways

So the real risk is usually not:

- “someone can read the CRL”

The real risks are more often:

- revocation server unavailable
- stale revocation data
- misconfigured URLs
- clients not checking the path you thought they would

## Recommended lab stance

For this lab, the sensible design is:

- AIA/CRL over `HTTP`
- OCSP over `HTTP`
- trust integrity from signatures
- focus operational effort on:
  - correct publication
  - correct freshness
  - correct URL embedding
  - correct client verification

This is a normal and defensible PKI design.

## Practical conclusion

It is usually **not necessary** to force TLS/HTTPS for CRL publication.

Using plain HTTP for CRL and OCSP does **not** mean revocation can be trivially forged.

What protects revocation data is:

- the CA signature on the CRL
- the responder signature on the OCSP response

So the right question is not only:

- “is this encrypted in transit?”

The more important questions are:

- “is it signed correctly?”
- “is it fresh?”
- “is it reachable?”
- “is the client actually validating it?”
