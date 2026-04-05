# Windows Time Baseline (2026-04-05)

Contributors: bermekbukair, Codex

## Purpose

This note records the known-good Windows time state for the current lab after time-zone correction and `w32time` recovery work.

Use this file later if:

- Kerberos breaks
- domain join starts failing
- AD CS shows time-related weirdness
- certificate validity appears wrong
- you suspect clock skew between domain members, DC, and root CA

---

## Baseline timestamp

Recorded on:

- `2026-04-05`
- local timezone target: `Singapore Standard Time`
- expected local wall time at validation: around `18:56` to `18:58` SGT

---

## Hosts checked

### 1. `ws2025-rootca01`

- host/IP: `192.168.122.98`
- role: offline standalone root CA

Observed `w32tm /query /status`:

```text
Leap Indicator: 0(no warning)
Stratum: 4 (secondary reference - syncd by (S)NTP)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0416694s
Root Dispersion: 0.7777574s
ReferenceId: 0x349472BC (source IP:  52.148.114.188)
Last Successful Sync Time: 4/5/2026 6:56:38 PM
Source: time.windows.com,0x8
Poll Interval: 6 (64s)
```

Interpretation:

- healthy
- timezone corrected
- time service working
- external time source working at the moment of capture

---

### 2. `ws25-ica01`

- host/IP: `192.168.122.196`
- role: future enterprise subordinate issuing CA

Initial fault observed:

```text
The following error occurred: The specified service does not exist as an installed service. (0x80070424)
```

Recovery commands used:

```powershell
w32tm /unregister
w32tm /register
Restart-Service w32time
w32tm /query /status
```

Post-recovery observed status:

```text
Leap Indicator: 3(not synchronized)
Stratum: 0 (unspecified)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0000000s
Root Dispersion: 0.0000000s
ReferenceId: 0x00000000 (unspecified)
Last Successful Sync Time: unspecified
Source: Local CMOS Clock
Poll Interval: 6 (64s)
```

Interpretation:

- `w32time` service was repaired successfully
- the server is no longer missing the time service
- but this is **not yet a good domain-sync state**
- it is currently alive but using `Local CMOS Clock`
- after DC time hierarchy is finalized, this server should be moved to normal domain hierarchy sync

Future target for this host:

```powershell
w32tm /config /syncfromflags:domhier /update
w32tm /resync /rediscover
w32tm /query /status
```

---

### 3. `dns-adcs01`

- host/IP: `192.168.122.10`
- role: domain controller / DNS / existing AD-related services

Initial fault observed:

```text
The following error occurred: The specified service does not exist as an installed service. (0x80070424)
```

Recovery commands used:

```powershell
w32tm /unregister
w32tm /register
Restart-Service w32time
w32tm /query /status
```

Post-recovery observed status:

```text
Leap Indicator: 0(no warning)
Stratum: 1 (primary reference - syncd by radio clock)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0000000s
Root Dispersion: 10.0000000s
ReferenceId: 0x4C4F434C (source name:  "LOCL")
Last Successful Sync Time: 4/5/2026 6:58:24 PM
Source: Local CMOS Clock
Poll Interval: 6 (64s)
```

Interpretation:

- `w32time` service was repaired successfully
- the DC is now acting from local clock
- this is acceptable as a short-term lab baseline if you deliberately keep the lab self-contained
- if you want internet-backed authoritative time later, configure an upstream NTP source on this DC

---

## Current baseline judgment

### Healthy enough right now

- `ws2025-rootca01`: yes
- `dns-adcs01`: yes for lab baseline, because `w32time` exists and the clock is sane

### Still needs follow-up

- `ws25-ica01`: partially fixed

Reason:

- time service exists again
- but source is still `Local CMOS Clock`
- for a proper domain-member baseline, it should later sync from the domain hierarchy after the DC time source strategy is finalized

---

## Minimum verification commands for future troubleshooting

Run on any Windows server:

```powershell
Get-Date
w32tm /query /status
```

Signs of a good result:

- correct local wall time
- correct timezone
- no `0x80070424`
- sensible `Source`
- recent `Last Successful Sync Time`

Red flags:

- `The specified service does not exist as an installed service`
- large wall-clock drift
- wrong timezone
- `Source: Local CMOS Clock` on systems that should follow domain hierarchy or external NTP
- Kerberos or certificate validity errors

---

## Recovery commands used in this incident

### Recreate missing Windows Time service

```powershell
w32tm /unregister
w32tm /register
Restart-Service w32time
```

### Set timezone to Singapore

```powershell
Set-TimeZone -Id "Singapore Standard Time"
Get-Date
```

### Root CA resync example

```powershell
w32tm /resync /force
w32tm /query /status
```

### Member server target after DC is stable

```powershell
w32tm /config /syncfromflags:domhier /update
w32tm /resync /rediscover
w32tm /query /status
```

---

## Operational note

If anything time-related breaks later:

1. Check this baseline file first.
2. Compare `Get-Date` and `w32tm /query /status`.
3. Fix the DC time service before trying to fix domain members.
4. Recheck issuing CA and clients after the DC is healthy.
