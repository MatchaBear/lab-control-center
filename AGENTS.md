# Repository Guidelines

## Project Structure & Module Organization

This repository is primarily an operations and lab runbook repo. Most content lives at the repo root as dated Markdown guides such as `WS2025_ISSUING_CA_BUILD_2026-04-05.md`, `ADCS_CEREMONY_RUNBOOK.md`, and `CML_WINDOWS_ENDPOINT_IDIOTPROOF_RUNBOOK_2026-04-05.md`. Shell automation lives alongside the docs in scripts like `labctl.sh`, `bootstrap-lab.sh`, `install-lab-networks.sh`, and `shutdown-all-graceful.sh`. Environment and topology artifacts include `lab.env`, `image-manifest.csv`, and `libvirt-network-*.xml`.

## Build, Test, and Development Commands

- `bash -n labctl.sh` or `bash -n install-lab-networks.sh`: syntax-check shell scripts before committing.
- `./labctl.sh vms`: inspect current VM inventory and lab state.
- `./lab-net-egress.sh status`: check current lab egress configuration.
- `git status --short`: verify only intended docs/scripts changed.

There is no compiled application build. Validate changes by running the smallest relevant command for the touched script or by following the documented runbook steps in a lab VM.

## Coding Style & Naming Conventions

Use ASCII unless an existing file already requires otherwise. Keep shell scripts POSIX/Bash-friendly, with 2-4 space indentation and descriptive function/variable names. Name new runbooks in uppercase snake case with a date suffix when they capture a dated incident or ceremony, for example `WINDOWS_TIME_BASELINE_2026-04-05.md`. Prefer explicit filenames over nested folders so related docs stay searchable from the repo root.

## Testing Guidelines

There is no formal test suite. For scripts, run `bash -n <script>` and one safe read-only command path where possible. For docs, verify commands, hostnames, IPs, and file paths against the current lab before committing. When documenting troubleshooting, include the exact command used and the observed result.

## Documentation Requirements

This repo is documentation-first. Every meaningful change should leave a future operator with enough context to follow the steps blindly.

- Always record both what was suggested and what was actually performed.
- Record exact commands, prompts, outputs, file paths, hostnames, and IPs.
- Explain what went wrong, why it was wrong, and how the final fix was chosen.
- Call out temporary workarounds vs clean end-state fixes.
- Prefer step-by-step, idiot-proof wording over terse expert shorthand.
- When a UI prompt or hidden behavior matters, document the prompt text and the safe response.

Good runbooks in this repo should let someone with minimal subject knowledge reproduce the ceremony or troubleshoot the same failure later without relying on chat history.

## Commit & Pull Request Guidelines

Recent history uses imperative, documentation-focused commit subjects such as `Document final issuing CA activation and revocation troubleshooting` and `Add source links to ClearPass AD site runbook`. Follow that style: short imperative subject, optionally with a detailed body for operationally important changes. PRs should summarize the lab scenario, affected hosts or IPs, exact files changed, and any manual follow-up steps. Include screenshots only when UI behavior or console prompts are part of the fix.

## Security & Configuration Tips

Do not commit secrets, private keys, or unredacted credentials. Treat CA artifacts, exported certs, and host access details as sensitive even in a lab. Prefer documenting credential locations or procedures rather than hardcoding them into scripts.
