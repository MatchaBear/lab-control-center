# Publishing Security Audit 2026-04-03

Contributors: bermekbukair, Codex
Last updated: 2026-04-03

## Goal

Make this repo safe and practical to publish while preserving the lab build story, scripts, and technical decisions.

## Five review passes completed

### Pass 1: Repository inventory

Checked the full top-level tree, current git state, largest files, and which files were still untracked.

Main result:
- the repo had just been initialized
- only one file had been committed
- multiple local-only artifacts were sitting next to publishable docs

### Pass 2: Secret and credential pattern scan

Searched for:
- private keys
- access tokens
- API secrets
- embedded auth headers
- obvious password material

Main result:
- no actual private keys or API tokens were found in the repo content reviewed
- several operational transcripts contained auth-related prompts and SSH negotiation detail, which are not appropriate for public publication even if they do not expose raw secrets

### Pass 3: Personal data and path leakage scan

Searched for:
- `/home/hadescloak/...`
- personal usernames
- Codex resume IDs
- email-style strings
- internal host path references

Main result:
- many docs used hardcoded absolute local paths
- those absolute paths leaked the local Ubuntu username and were not GitHub-friendly
- local session residue files contained Codex resume identifiers and should stay private

### Pass 4: Publishability and repo hygiene review

Checked whether the repo had:
- a `.gitignore`
- a safe separation between durable docs and local troubleshooting artifacts
- a repo-friendly navigation structure
- portable scripts that avoid user-specific path assumptions

Main result:
- `.gitignore` was missing
- local-only artifacts were mixed into the publishable root
- a few key scripts hardcoded `/home/hadescloak/...`
- several markdown links were local-filesystem oriented instead of repo oriented

### Pass 5: Final pre-publish hardening review

Validated the post-fix intent:
- local-only artifacts should be ignored
- docs should prefer relative links or `$REPO_DIR` path language
- core scripts should resolve the repo path dynamically instead of relying on a fixed home path

Main result:
- publish blockers were reduced to manageable repo-policy choices rather than accidental leaks

## What is now intentionally kept private

These items are local troubleshooting or session residue and should not be published:
- `codex_session.txt`
- `hardening_ubuntu.txt`
- `ssh vv o Ciphers aes256_remote_ubuntu_to_MacbookAir.txt`
- `tcpdump-exceed-codex-limit/`
- future packet captures and raw test-evidence folders

## What changed in this hardening pass

- added a real `.gitignore`
- added this audit document
- sanitized key docs away from hardcoded local-path links where possible
- made core helper scripts more portable by deriving the repo directory dynamically
- kept the lab architecture, IP plan, and port map documented because those are core repo value, not sensitive secrets

## What is still missing before public release

These are not emergency blockers, but they are still missing:
- a chosen open-source or source-available `LICENSE`
- a short repo description for GitHub
- a clear screenshot folder with intentionally-selected publishable images
- optional architecture diagrams rendered for public readers instead of only text docs

## Publish stance

Current recommendation:
- safe to publish after staging only the non-ignored files
- keep RFC1918 lab IPs documented because they are lab design detail, not internet-exposed secrets
- keep local session residue, raw packet captures, and ad hoc SSH debug logs out of git

## Quick checks for future agents

Check ignored private residue:

```bash
git status --ignored --short
```

Check tracked files:

```bash
git ls-files
```

Check for remaining local home-path leakage:

```bash
grep -RIn '/home/hadescloak' . --exclude-dir=.git
```
