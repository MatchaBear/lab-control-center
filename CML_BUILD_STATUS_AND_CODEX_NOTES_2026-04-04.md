# CML Build Status And Codex Notes

Last updated: 2026-04-04

## Current status

The CML environment on this host is successfully built and operational.

What is already confirmed working:

- `cml-core01` is installed and reachable at `192.168.122.210`
- CML UI is reachable over HTTPS
- CML Cockpit web console is reachable on `9090`
- CML console server works over SSH on port `22`
- Linux shell access to the CML controller works over SSH on port `1122`
- CML internal NAT is working on `192.168.255.0/24`
- CML `System Bridge` to host `virbr0` is working on `192.168.122.0/24`
- reference platform media is present and usable
- lightweight endpoint nodes were tested:
  - `server-0`
  - `desktop-0`
- router uplinks were tested:
  - one uplink via CML NAT
  - one uplink via `virbr0`

## What was tested successfully

Confirmed from live testing:

- `desktop-0` received a `192.168.255.x` address through CML NAT
- `desktop-0` could ping `192.168.255.1`
- `desktop-0` could reach `8.8.8.8`
- `R1` received a `192.168.255.x` address on the NAT-facing interface
- `R1` received a `192.168.122.x` address on the `virbr0`-facing interface
- the Ubuntu host could reach `R1` on the `192.168.122.0/24` side
- the Ubuntu host could SSH to the CML controller shell on port `1122`

## Current limitation

The main remaining work is not basic CML bring-up.

The main remaining work is to build the correct topology and addressing model for the lab use case.

That includes:

- deciding which interfaces are for management
- deciding which subnets live behind `R1`
- deciding which endpoints should use CML NAT
- deciding which endpoints should use `System Bridge`
- wiring the NAC test topology cleanly behind the switches

So the summary is:

- CML itself is already built successfully
- the external connectivity models are already proven
- the next task is lab topology design, not CML installation rescue

## Practical interpretation

At this point, the CML portion is no longer the blocker.

The blocker is choosing and implementing the right lab topology for:

- endpoint access
- switch uplinks
- ClearPass reachability
- management reachability
- future `802.1X` and `MAB` testing

## Note on how this lab was built

This lab was built with 100% help from Codex.

That does **not** mean the lab owner does not understand what is going on.

The intent was to test Codex as a practical assistant for building a networking and security lab from a real Ubuntu host with libvirt, CML, ClearPass, Windows media, routing questions, and topology design decisions.

Observed outcome so far:

- Codex has been genuinely useful end to end
- local repo inspection helped keep the build state consistent
- web search capability reduced the need for manual Googling
- Cisco-specific behavior was easier to verify quickly
- documentation was produced while the lab was being built, instead of after the fact

## Bottom line

The lab owner used Codex deliberately as the main build assistant and test subject for this work.

So far, that experiment has been successful.
