---
name: report
description: Use when the user wants a polished, hand-to-client report from a deliverable, status, or schedule — a clean HTML page or a PDF (e.g. "export the risk register as a PDF", "make a nice report for Acme", "generate an HTML report", "PDF this for the sponsor"). Tidies the markdown, then renders a self-contained HTML (live mermaid diagrams) and optionally a PDF via .fde/bin/fde-report.sh.
allowed-tools: Bash, Read, Write, Glob
---

# fde-report — clean HTML / PDF a client can read

Turns an internal markdown artifact (a drafted deliverable, a status update, a
delivery schedule) into a presentable report. Two stages, matching the spine's
"LLM tidies, shell renders deterministically" split:

1. **You tidy the markdown** (the non-deterministic part).
2. **`.fde/bin/fde-report.sh` renders it** to self-contained HTML (with live
   mermaid diagrams) and, on request, a PDF — no API key, no network at render
   time, the HTML carries its own print CSS.

## Steps
1. Resolve what to render. Usually `engagements/<client>/deliverables/<type>.md`;
   also valid: a `status/<date>.md`, or an assembled pack (see step 4).
2. **Tidy a copy of the markdown** before rendering — never hand raw notes to a
   client. Produce a clean version under
   `engagements/<client>/reports/<type>.md`:
   - One clear `# Title` (e.g. "Acme — Risk Register"), tight section headings.
   - Fix list/heading spacing; turn dumped fragments into readable prose.
   - **Add a mermaid diagram where it earns its place** — a Delivery Schedule as
     a `flowchart`/`gantt`, an Ontology Map as an entity diagram, a phase flow.
     Fence it ```mermaid so the renderer makes it a live diagram:
     ````
     ```mermaid
     flowchart LR
       A[Discovery] --> B[Integration] --> C[Pilot] --> D[Go-live]
     ```
     ````
   - Strip anything not meant for this audience (internal asides, TODOs).
3. **Render** with the spine script:
   ```bash
   .fde/bin/fde-report.sh --title "Acme — Risk Register" --pdf \
     engagements/<client>/reports/risk-register.md
   # -> reports/risk-register.html  (+ .pdf when a PDF engine is available)
   ```
   - HTML always works (self-contained, print-ready).
   - `--pdf` uses headless Chrome when present (renders the mermaid diagrams);
     else weasyprint/wkhtmltopdf/pandoc (static); else it prints the
     "open + Cmd/Ctrl-P → Save as PDF" fallback. Relay whatever the script says.
4. To bundle a whole engagement, concatenate the chosen markdowns into one
   `reports/<client>-pack.md` (cover `# ` title, then each deliverable as `## `),
   then render that once.

## Hard rules
- A report contains *this client's* specifics — it lives under the engagement
  dir, is never promoted to the corpus, and should not be pushed to a remote.
- Don't reimplement rendering in prose or inline HTML — call `fde-report.sh`, the
  deterministic renderer, so every report comes out identical and reviewable.
- For a fully offline file, drop a copy of mermaid at
  `.fde/bin/vendor/mermaid.min.js` (or set `FDE_MERMAID_JS`); the script inlines
  it instead of the CDN. Mention this only if the user needs air-gapped output.
