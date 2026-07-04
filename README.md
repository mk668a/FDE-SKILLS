<div align="center">

# FDE-SKILLS

**The forward-deployed engineer's toolbox: the repos you actually run an engagement with, plus four Claude Code skills that make your deliverables compound across clients.**

<a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT"></a>
<img src="https://img.shields.io/badge/Claude_Code-skill_pack-d97757.svg" alt="Claude Code skill pack">
<img src="https://img.shields.io/badge/skills-4-blue.svg" alt="4 skills">
<img src="https://img.shields.io/badge/hosted_backend-none-brightgreen.svg" alt="No hosted backend">

English · [日本語](./docs/README.ja.md)

</div>

You're on your third client this year. The deliverables are the same *kinds* of
document every time: a risk register, an integration spec, a stakeholder map.
Each one starts from a blank page, even though the last two engagements already
taught you most of what belongs in them. And the tools that would help live in
twenty scattered repos you keep re-discovering.

This repo is both halves of the fix:

1. **A curated toolbox** (below): the repositories worth installing for each
   stage of an engagement, from discovery to handoff. Ordered by *when you
   reach for them*, not by tool category.
2. **Four skills of our own** for the one thing none of those repos ship:
   **deliverables that remember.** Your deliverable schemas accumulate
   evidence across engagements, and at the third recurrence a pattern is
   *paved* into the schema itself. Install with one script, no marketplace, no
   API key, no hosted backend:

```bash
git clone https://github.com/mk668a/fde-skills
cd fde-skills && ./install.sh     # plain cp under the hood; read it first
```

![The compounding wall](docs/dashboard.png)

*The compounding wall (`.fde/dashboard.html`, rendered by plain shell): each
column is a client, each bar a deliverable. Green slots were inherited from
past engagements, blue were filled fresh. Left to right, the green grows.
That's the product.*

---

## 🧭 The toolbox

What to install for each stage of an engagement. Criteria for inclusion: the
repo exists and is maintained, and it earns its place in real client work.
(Star counts drift, so we don't print them; every entry was verified live.)

### Start here

| Repo | What it is | Form |
|---|---|---|
| [anthropics/skills](https://github.com/anthropics/skills) | Anthropic's official Agent Skills collection. The document skills (`docx`, `pptx`, `xlsx`, `pdf`) write the actual files clients expect back. | plugin / copy skill dirs |

### Discovery & scoping

| Repo | What it is | Form |
|---|---|---|
| [github/spec-kit](https://github.com/github/spec-kit) | Spec-driven development: turn a fuzzy ask into an executable spec before you build. | CLI + slash commands |
| [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | Agile AI-driven development framework with PM- and architect-style planning agents. | npm framework |
| [snarktank/ai-dev-tasks](https://github.com/snarktank/ai-dev-tasks) | A lightweight PRD → task-list markdown workflow for AI dev agents. | copy .md files |
| [obra/superpowers](https://github.com/obra/superpowers) | Brainstorming, plan writing/execution, systematic debugging, TDD and code review as skills. Serves discovery and the build alike. | plugin |

### Build with the client

| Repo | What it is | Form |
|---|---|---|
| [wshobson/agents](https://github.com/wshobson/agents) | Multi-domain plugin marketplace: hundreds of expert agents, skills and commands (architecture, security, data, docs). | plugin marketplace |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) | Agent harness optimization: skills, instincts, memory, hooks, rules. (Formerly `everything-claude-code`.) | config collection |
| [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | 100+ specialized subagents to copy into `.claude/agents/`. | copy .md files |
| [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) | Official AI security review Action: run it before anything ships to the client. | GitHub Action |
| [dlt-hub/dlt](https://github.com/dlt-hub/dlt) | Python data-loading pipelines; the fastest honest way to a data quick win. | pip |

### Client deliverables

| Repo | What it is | Form |
|---|---|---|
| [jgm/pandoc](https://github.com/jgm/pandoc) | The universal markup converter: markdown in, `docx`/`pdf`/anything out. | CLI |
| [quarto-dev/quarto-cli](https://github.com/quarto-dev/quarto-cli) | Technical publishing on top of Pandoc: reports, dashboards, books. | CLI |
| [marp-team/marp-cli](https://github.com/marp-team/marp-cli) | Markdown to slide decks (PPTX/PDF/HTML) from the command line. | CLI |
| [mermaid-js/mermaid-cli](https://github.com/mermaid-js/mermaid-cli) | Render Mermaid diagrams to images for docs and decks. | CLI |
| [terrastruct/d2](https://github.com/terrastruct/d2) | Text-to-diagram language that makes architecture diagrams reviewable in git. | CLI |

### Client data safety

| Repo | What it is | Form |
|---|---|---|
| [microsoft/presidio](https://github.com/microsoft/presidio) | PII detection, redaction and anonymization. Run it before client data touches anything shared. | pip |

### Engagement management & handoff

| Repo | What it is | Form |
|---|---|---|
| [makeplane/plane](https://github.com/makeplane/plane) | Self-hosted Jira/Linear alternative when the client can't give you a seat in theirs. | self-hosted |

### Going deeper

| Repo | What it is |
|---|---|
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | The canonical Claude Code resource list. |
| [ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | Curated Claude skills across domains. |
| [pierpaolo28/Awesome-FDE-Roadmap](https://github.com/pierpaolo28/Awesome-FDE-Roadmap) | The FDE *career* roadmap: learning resources, consulting frameworks, interview prep. Complements this list, which is about tooling. |

Missing something you reach for every engagement? PRs welcome (see
[Contributing](#-contributing)).

---

## 🔁 Our four skills: deliverables that remember

None of the repos above make engagement N easier than engagement N-1. That's
the gap these four skills fill. A deliverable here is not a document: it is a
**typed schema of slots**, and the schema is a versioned prior that hardens
with evidence.

| Skill | You say | It does |
|---|---|---|
| `/fde-init` | "set up fde here", "new engagement with Acme" | Scaffolds the `.fde/` spine (once) and one directory per client |
| `/fde-draft` | "draft the risk register for Acme" | Fills the typed schema from this client's notes AND pre-fills from past engagements, then reports coverage |
| `/fde-promote` | "make these learnings reusable" | Anonymizes, counts sightings, and paves at the third |
| `/fde-recall` | "what did we learn about pilots like this?" | Surfaces anonymized priors, weighted by how often they recurred |

You don't memorize the commands; each skill has a precise trigger description,
so describing the outcome fires the right one.

### The Rule of Three, made mechanical

"Don't generalize from one example, extract on the third" (Fowler,
*Refactoring*) is usually advice. Here it's a counter in a shell script:

| Sightings | Tier | What `/fde-draft` does with it |
|---|---|---|
| ×1 | candidate | offers it as `[candidate ×1: confirm]` (one engagement's opinion) |
| ×2 | recurring | offers it as `[candidate ×2: confirm]` |
| ×3 | **paved** | pre-fills it by default; if it's a new dimension, the schema itself gains the slot and bumps its version |

The pave moment is a real, git-diff-able change to your schema. Run the
15-second proof yourself (no LLM involved, every number printed by the spine
scripts):

```console
$ examples/demo.sh
=== Engagement 1: Acme Corp: from scratch ===
acme-corp: risk-register  ·  4/6 slots filled (66%) · 0 inherited · 4 new
  candidate ×1: sso-auth-integration (technical_risks)
  candidate ×1: rollback-plan (rollback_plan)

=== Engagement 2: Globex: inherits Acme priors ===
globex: risk-register  ·  5/6 slots filled (83%) · 2 inherited · 3 new
  sighting ×2: sso-auth-integration (technical_risks)

=== Engagement 3: Initech: third sighting PAVES the schema ===
initech: risk-register  ·  6/6 slots filled (100%) · 5 inherited · 1 new
  -> near-complete on day one: 5 of 6 slots inherited, not retyped.
  sighting ×3: sso-auth-integration (technical_risks)
PAVED: risk-register v1 -> v2: + rollback_plan (3 sightings)

--- the schema itself just changed (git-diff-able expertise) ---
  -version: 1
  +version: 2
  -evolved_slots: []
  +evolved_slots:
  +  - id: rollback_plan
  +    label: Rollback plan
  +    prompt: "How do we return to the pre-pilot state if go-live fails?"
  +    paved_from: "3 sightings, 2026-07-04"

=== Confidentiality check (shared layers must be client-anonymous) ===
validate: OK: no client identifiers in corpus/ or research/
```

Three engagements in, `git diff .fde/schemas/` shows exactly what your clients
taught you, with no client in it. Run `examples/demo.sh --live` to watch the
same run on the auto-refreshing dashboard (that's how the screenshot above was
made).

### Two layers, honestly divided

| Layer | What it is | Examples |
|---|---|---|
| **LLM skills** (`skills/*`) | Read messy notes, fill slots, paraphrase client specifics away, decide what's durable | `/fde-draft`, `/fde-promote` |
| **Deterministic spine** (`.fde/bin/*.sh`) | Count, redact, gate, pave, render. No LLM, reproducible, auditable | `fde-coverage.sh`, `fde-promote.sh`, `fde-validate.sh`, `fde-dashboard.sh` |

The coverage numbers, the sighting counters, the redaction gate and the
dashboard are all plain shell. The judgment calls are all yours (via your own
Claude Code). Nothing here calls an LLM at runtime and nothing is hosted.

### Workspace layout

```
.fde/                          the spine (commit-safe: schemas + anonymized corpus)
  config.yml                   deliverable types + paving threshold + extra identifiers
  schemas/<type>.schema.yml    slot definitions that evolve across engagements
  corpus/<type>.yml            anonymized priors with sighting counters
  bin/*.sh                     the deterministic scripts
  dashboard.html               the compounding wall (never commit)
engagements/                   CONFIDENTIAL: one dir per client, never cross-read
  acme-corp/
    engagement.yml, notes/, deliverables/
```

Eight deliverable schemas ship out of the box (discovery doc, integration
spec, ontology map, delivery schedule, risk register, findings report,
stakeholder map, enablement plan), each slot prompt anchored in a named method
(pre-mortem, MEDDPICC, Pyramid Principle, Working-Backwards, ...).

---

## 🔒 Confidentiality: a gate, not a promise

Being precise about what is enforced and what is judgment:

- **Enforced (deterministic):** `fde-validate.sh` fails if any engagement
  slug, client-name token, or configured extra identifier appears in the
  shared layers. `fde-promote.sh` builds the merged corpus in a temp file and
  refuses to write it at all if the result would leak an identifier. Dollar
  amounts and percentages are always stripped.
- **Judgment (LLM + you):** person names, internal system names and "you'd
  know it's them" phrasing are paraphrased away by the `/fde-promote` skill.
  The scripts can't guess those, so anything you want *mechanically* guarded
  forever goes into `anonymization.extra_identifiers` in `.fde/config.yml`.
- The **only** path knowledge crosses engagements is `/fde-promote`. Skills
  never read another client's `engagements/<other>/` directory.

### Do not push client material to GitHub

`/fde-init` adds `engagements/` and `.fde/dashboard.html` to `.gitignore`.
Keep it that way: a push to a remote is effectively irreversible (clones,
forks, caches, code-search indexes), and a private repo is not a safe haven
either. Commit only the anonymized `.fde/corpus/` and `.fde/schemas/`, and
only after `fde-validate.sh` passes. For most engagements, a client name in a
remote is a contract and NDA breach. The anonymized corpus exists precisely so
the *reusable structure* can survive without the client behind it.

---

## ❓ Why "FDE"?

Forward Deployed Engineer is the role this is shaped for: embedded,
multi-client, deliverable-heavy. But the toolbox and the compounding loop fit
anyone who ships the same kinds of deliverable to different clients: delivery
consultants, embedded PMs, solutions architects, fractional CTOs. The name is
the wedge; the mechanism is general.

---

## 🤝 Contributing

**Toolbox entries:** open a PR adding a row to the right stage. The bar:
the repo exists, is maintained, and you actually reach for it in engagements.
One line on what it does, no marketing copy.

**Skills:** each skill is one `skills/<name>/SKILL.md`; the spine `/fde-init`
scaffolds lives in `skills/init/templates/`. Test locally with `./install.sh`
and `examples/demo.sh`. If a PR changes a skill or schema, update both READMEs
(English and Japanese).

---

## 📄 License

MIT. See [LICENSE](LICENSE).
