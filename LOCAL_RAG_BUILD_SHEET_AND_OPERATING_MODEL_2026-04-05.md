# Local RAG Build Sheet And Operating Model

Date: 2026-04-05

## Purpose

This document converts the earlier `Context7`-style implementation plan into a practical local RAG build sheet for this lab.

RAG here means:

- Retrieval-Augmented Generation
- a local or private document retrieval layer
- used to ground AI answers in your own chosen sources
- able to combine public technical material with internal lab artifacts

This is the missing piece for areas where no strong official MCP exists, especially:

- Linux administration
- Aruba documentation coverage
- multi-vendor CCIE-style study
- internal runbooks and operational memory

## What Local RAG Actually Solves

Without RAG, the assistant often relies on:

- generic model memory
- incomplete public search
- weak vendor-neutral synthesis
- zero awareness of your own lab state

With local RAG, the assistant can answer from:

- your repo Markdown
- your build notes
- your configs
- your packet analysis summaries
- your preferred vendor documentation set
- RFCs and standards material

That changes the answer quality from generic to environment-aware.

## Why Local RAG Matters In This Lab

This lab already has high-value internal documentation:

- Windows build runbooks
- AD CS design docs
- NAC and CML notes
- topology and IP planning
- DNS and routing notes
- incident and build status notes

Those documents are too important to leave outside the retrieval layer.

Local RAG is also the best answer for domains where the market still does not offer one strong official MCP:

- broad Linux
- broad Aruba
- broad CCIE study
- mixed-vendor design reasoning

## The Target Model

The recommended model for this lab is:

### Tier 1

Use official MCP where official MCP is already strong.

Examples:

- Microsoft Learn MCP
- Cisco DevNet Content Search MCP
- Vault MCP if used

### Tier 2

Use local RAG for everything that is fragmented, multi-vendor, internal, or standards-heavy.

Examples:

- Linux
- Aruba
- Juniper broad docs
- RFCs
- your own runbooks and configs

### Tier 3

Use answer routing so queries go to the right corpus first.

Examples:

- internal lab question -> internal corpus first
- RFC question -> standards corpus first
- Windows question -> Microsoft corpus first
- Cisco automation question -> Cisco official MCP first

## What To Put Into The Local RAG

### 1. Internal Lab Corpus

This should be the highest-priority corpus because it contains the lab's actual operating memory.

Include:

- all important `.md` files from this repo
- architecture notes
- IP plans
- topology documents
- build checklists
- incident notes
- troubleshooting notes
- decision records

Examples from this repo:

- `README.md`
- `README_START_HERE.md`
- `PHASE1_TOPOLOGY.md`
- `LAB_BUILD_PLAN_PHASED.md`
- `NAC_STATIC_IP_PLAN_2026.md`
- `CML_BUILD_STATUS_AND_CODEX_NOTES_2026-04-04.md`
- `L2_INCIDENT_TEST_RESULTS.md`
- `LAB_PORTABILITY_PLAYBOOK.md`

### 2. Systems Corpus

Include:

- Linux distro docs
- Windows build references you export or summarize
- PKI docs
- security hardening references
- PowerShell and Bash operational notes
- your own system build procedures

Good source examples:

- Ubuntu docs
- Red Hat docs
- Vault docs
- Smallstep docs
- STIG or hardening reference material you rely on

### 3. Networking Corpus

Include:

- Cisco docs and design guides
- Juniper docs
- Aruba docs
- wireless references
- storage networking references if relevant
- your own network build and troubleshooting notes

### 4. Standards Corpus

Include:

- RFCs
- IETF drafts
- your own standards summaries
- protocol interpretation notes

This corpus is especially important for:

- BGP
- MPLS
- EVPN
- IS-IS
- OSPF
- multicast
- SIP and RTP
- ISP topics

## What Not To Put Into The Same Corpus

Do not mix all sources into one giant undifferentiated index.

Avoid this:

- vendor docs mixed with internal runbooks without metadata
- standards docs mixed with product docs without labels
- obsolete notes mixed with current build docs without date tags

Why:

- retrieval quality drops
- conflicting versions become harder to spot
- the assistant will cite the wrong source class

## Recommended Directory Structure

Use a dedicated directory under the repo, for example:

```text
knowledge-base/
  internal/
    docs/
    runbooks/
    incidents/
    topology/
    decisions/
  systems/
    linux/
    windows/
    pki/
    security/
  networking/
    cisco/
    juniper/
    aruba/
    wireless/
    storage/
    devnet/
  standards/
    rfc/
    ietf-drafts/
    summaries/
  metadata/
    source-catalog.csv
    ingestion-log.md
    tagging-guide.md
```

If you want a flatter repo, keep the original docs where they are and build a separate ingest manifest instead of moving files.

## Recommended Metadata And Tagging

Every ingested document should have enough metadata for routing and filtering.

Minimum fields:

- title
- source_type
- vendor
- domain
- product
- date
- trust_level
- audience
- environment_scope
- tags

### Suggested values

`source_type`

- internal_note
- runbook
- official_doc
- standard
- kb_article
- design_guide
- config_reference
- incident_note

`domain`

- systems
- networking
- standards
- pki
- security
- wireless
- automation

`trust_level`

- official
- internal-validated
- internal-draft
- community

`environment_scope`

- lab
- vendor-general
- standards-general

## Recommended File Naming

Prefer names that make age and scope obvious.

Good pattern:

- `TOPIC_SCOPE_YYYY-MM-DD.md`
- `VENDOR_PRODUCT_TOPIC_YYYY-MM-DD.md`
- `INCIDENT_SHORTNAME_YYYY-MM-DD.md`

This repo already does this fairly well. Keep doing it.

## Chunking Strategy

Chunking is how you split documents for retrieval.

Recommended approach:

- split by section headings first
- keep chunks semantically complete
- include title and section heading with each chunk
- avoid tiny fragments

Practical chunk target:

- about 400 to 1200 words per chunk for prose docs
- smaller chunks for config references or command outputs

Do not:

- split every paragraph into tiny fragments
- combine many unrelated sections into one huge chunk

Why:

- tiny chunks lose context
- oversized chunks dilute precision

## Retrieval Strategy

Use a two-step retrieval strategy.

### Step 1: corpus routing

Decide which corpus should be searched first:

- internal
- systems
- networking
- standards

### Step 2: scoped retrieval

Search the chosen corpus first, then optionally expand to a secondary corpus if confidence is low.

Example:

- question about your AD CS build -> internal corpus first, systems corpus second
- question about BGP communities and RFC behavior -> standards corpus first, networking corpus second
- question about Aruba Central operations -> networking corpus first, internal corpus second

## Answer Priority Rules

For this lab, the answer stack should prefer:

1. internal validated notes
2. official vendor documentation
3. standards documents
4. internal draft notes
5. community references

This keeps answers grounded in your real environment while still allowing standards and vendor correction when needed.

## Ingestion Workflow

### Initial ingestion

Start with:

1. this repo's important Markdown
2. RFCs and standards references you use often
3. Microsoft and Cisco official references
4. Linux, PKI, Juniper, and Aruba documentation sets

### Ongoing ingestion

After every major build, change, or incident:

1. write or update the runbook
2. summarize what changed
3. capture key command outputs in cleaned form
4. tag the note
5. ingest or re-index the changed files

### Monthly hygiene

Once a month:

1. mark obsolete docs clearly
2. remove duplicated notes
3. promote useful draft notes to validated notes
4. re-check high-value external source lists

## What To Ingest From This Repo First

### Internal foundation set

Start with these first:

- `README.md`
- `README_START_HERE.md`
- `LAB_BUILD_PLAN_PHASED.md`
- `PHASE1_TOPOLOGY.md`
- `LAB_PORTABILITY_PLAYBOOK.md`
- `LAB_SECURITY_AND_VIRT_SUMMARY.md`

### Systems and PKI set

- `ADCS_2TIER_BLUEPRINT_2026.md`
- `ADCS_CEREMONY_RUNBOOK.md`
- `WS2025_OFFLINE_ROOT_CA_BUILD_2026-04-05.md`
- `WS2025_ISSUING_CA_BUILD_2026-04-05.md`
- `WINDOWS_TIME_BASELINE_2026-04-05.md`
- `WINDOWS_DC_FIREWALL_RULESET_2026.md`
- `CML_WINDOWS_ENDPOINT_AND_WS2025_CA_BUILD_2026-04-05.md`
- `CML_WINDOWS_ENDPOINT_IDIOTPROOF_RUNBOOK_2026-04-05.md`

### Networking set

- `NAC_STATIC_IP_PLAN_2026.md`
- `CPPM_HOST_PORT_MAP_2026-04-03.md`
- `CML_CONTROLLER_ACCESS_AND_INTERFACES.md`
- `HOW_TO_CONFIGURE_ENDPOINTS_ON_CML.md`
- `SPECIAL_CASE_CML_NAT_ROUTING_192.168.255.0.md`
- `DNS_NOTES_INDEX.md`
- `DNS_ENCRYPTION_VERIFICATION_LINUX_AND_BROWSERS.md`

### Incident and operational memory set

- `CML_BUILD_STATUS_AND_CODEX_NOTES_2026-04-04.md`
- `L2_INCIDENT_TEST_RESULTS.md`
- `PUBLISHING_SECURITY_AUDIT_2026-04-03.md`

## Tooling Model

This document stays tool-agnostic on purpose.

You can implement local RAG with:

- a vector database
- BM25 or full-text search
- hybrid retrieval using both
- local embeddings
- private hosted embeddings

The important part is not the trendy stack. The important part is:

- corpus separation
- metadata quality
- clean chunking
- update discipline

## Minimum Viable Local RAG

If you want the simplest useful version:

1. keep docs where they already are
2. create an ingest manifest listing approved source files
3. split by headings
4. index into separate corpora
5. route queries by domain
6. show source references in every answer

That is already enough to beat generic model memory for lab work.

## Better-Than-Minimum Version

Add these next:

1. trust scoring
2. stale-document detection
3. duplicate-note detection
4. source pinning for standards questions
5. incident-note promotion into stable runbooks
6. command-output summarization before ingest

## Failure Modes To Avoid

### 1. Over-ingesting junk

Do not ingest random low-quality web pages just to increase corpus size.

### 2. No metadata

Documents without source labels and dates are hard to trust.

### 3. No obsolete marker

Old design notes can silently corrupt retrieval if they look current.

### 4. Mixing lab reality with generic vendor defaults

Your environment-specific notes must remain identifiable.

### 5. Treating packet captures as raw ingest

Do not ingest raw pcaps directly into the same pipeline. Ingest summaries, extracted findings, and annotated notes instead.

## Recommended Operating Rules

1. Any major lab change gets a short Markdown note.
2. Any resolved incident gets a short postmortem.
3. Any stable repeated fix gets promoted to a runbook.
4. Any superseded document gets marked obsolete in the first few lines.
5. Any answer generated from RAG should include which corpus the grounding came from.

## Suggested Next Build Artifacts

To support this model, consider adding these repo files later:

- `knowledge-base/source-catalog.csv`
- `knowledge-base/ingestion-log.md`
- `knowledge-base/tagging-guide.md`
- `knowledge-base/corpus-policy.md`
- `knowledge-base/stale-docs.md`

## Final Recommendation

For this lab, local RAG should not be treated as an optional enhancement. It is the main mechanism that fills the real gaps left by public MCP coverage.

Use official MCP where the vendors already provide strong grounding. Use local RAG for:

- your own lab memory
- Linux operations
- Aruba coverage
- multi-vendor networking
- standards-heavy study

That hybrid model is the most practical and defensible design for this environment.
