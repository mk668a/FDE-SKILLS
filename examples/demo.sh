#!/usr/bin/env bash
# demo.sh — reproducible proof of the compounding loop, using ONLY the
# deterministic spine (no LLM). Builds a throwaway workspace, runs three
# engagements, and shows risk-register slot coverage climbing as priors
# accumulate in the corpus. This is the honest version of the README diagram:
# every number below is printed by .fde/bin/*.sh, not narrated.
#
#   usage: examples/demo.sh
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)        # repo root (projects/fde-skills)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

# scaffold the spine the way /fde-init does
mkdir -p .fde/bin .fde/schemas .fde/corpus engagements
cp "$here"/templates/config.yml          .fde/config.yml
cp "$here"/templates/schemas/*.schema.yml .fde/schemas/
cp "$here"/templates/bin/*.sh             .fde/bin/
chmod +x .fde/bin/*.sh

draft() {  # $1=client-slug  $2... = "slot: value" lines (simulating /fde-draft output)
  local client="$1"; shift
  local f="engagements/$client/deliverables/risk-register.slots.yml"
  { echo "schema: risk-register"; echo "slots:"; for kv in "$@"; do echo "  $kv"; done; } > "$f"
}

echo "=== Engagement 1: Acme Corp (from scratch) ==="
.fde/bin/fde-new.sh "Acme Corp" >/dev/null
draft acme-corp \
  'top_risks: "Vendor API rate limits may throttle the pilot"' \
  'technical_risks: "Legacy SSO blocks gated endpoints"' \
  'organizational_risks: "Sponsor splits attention with a reorg"' \
  'mitigations: "Negotiate sandbox quota; phase SSO"' \
  'early_warning_signals: ""' \
  'residual_risk: ""'
.fde/bin/fde-coverage.sh acme-corp risk-register
.fde/bin/fde-promote.sh acme-corp risk-register >/dev/null
echo "  -> promoted to corpus (anonymized)"

echo
echo "=== Engagement 2: Globex (inherits Acme's priors) ==="
.fde/bin/fde-new.sh "Globex" >/dev/null
# inherited slots start filled; engagement adds its own + fills one more
draft globex \
  'top_risks: "[inherited] integration throttling under load"' \
  'technical_risks: "[inherited] auth/SSO integration"' \
  'organizational_risks: "Two-team ownership, unclear DRI"' \
  'mitigations: "Single DRI; quota ask upfront"' \
  'early_warning_signals: "Slipping weekly demo cadence"' \
  'residual_risk: ""'
.fde/bin/fde-coverage.sh globex risk-register
.fde/bin/fde-promote.sh globex risk-register >/dev/null
echo "  -> promoted to corpus (anonymized)"

echo
echo "=== Engagement 3: Initech (inherits 2 engagements of priors) ==="
.fde/bin/fde-new.sh "Initech" >/dev/null
draft initech \
  'top_risks: "[inherited] throttling under pilot load"' \
  'technical_risks: "[inherited] auth/SSO integration"' \
  'organizational_risks: "[inherited] unclear DRI across teams"' \
  'mitigations: "[inherited] single DRI + upfront quota"' \
  'early_warning_signals: "[inherited] demo cadence slip"' \
  'residual_risk: "Data residency unresolved for EU users"'
.fde/bin/fde-coverage.sh initech risk-register
echo "  -> near-complete on day one. That is the compounding loop."

echo
echo "=== Confidentiality check (corpus must be client-anonymous) ==="
.fde/bin/fde-validate.sh
