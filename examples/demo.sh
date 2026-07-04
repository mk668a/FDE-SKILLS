#!/usr/bin/env bash
# demo.sh — reproducible proof of the compounding loop, using ONLY the
# deterministic spine (no LLM). Builds a throwaway workspace, runs three
# engagements, and shows:
#   - risk-register coverage climbing as priors accumulate (4/6 -> 5/6 -> 6/6),
#   - the sighting counter ticking candidate ×1 -> ×2 -> ×3,
#   - the PAVE moment at the third sighting: the schema itself gains a slot
#     and bumps its version — shown as a real diff.
# Every number below is printed by .fde/bin/*.sh, not narrated.
#
#   usage: examples/demo.sh            # fast, CI-friendly; renders the wall once
#          examples/demo.sh --live     # paced beats + auto-refreshing dashboard,
#                                      # workspace kept for the browser
#
# Recording the README GIF (~30s, split screen):
#   1. run `examples/demo.sh --live`; it prints the dashboard path first
#   2. open that .fde/dashboard.html in a browser next to the terminal
#      (it auto-refreshes every second)
#   3. screen-record terminal (left) + browser (right); convert with
#      ffmpeg/gifski to docs/demo.gif, target < 5 MB (2x speed is fine)
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)        # repo root
tpl="$here/skills/init/templates"

live=0
[ "${1:-}" = "--live" ] && live=1

if [ "$live" -eq 1 ]; then
  work="${TMPDIR:-/tmp}/fde-demo-live"
  rm -rf "$work"; mkdir -p "$work"
else
  work=$(mktemp -d)
  trap 'rm -rf "$work"' EXIT
fi
cd "$work"

# scaffold the spine the way /fde-init does
mkdir -p .fde/bin .fde/schemas .fde/corpus engagements
cp "$tpl"/config.yml           .fde/config.yml
cp "$tpl"/schemas/*.schema.yml .fde/schemas/
cp "$tpl"/bin/*.sh             .fde/bin/
chmod +x .fde/bin/*.sh

wall() {  # regenerate the dashboard; pause so the browser catches the beat
  if [ "$live" -eq 1 ]; then .fde/bin/fde-dashboard.sh --watch >/dev/null; sleep 2; fi
}

slots() {  # slots <client> <file-body...>: write slots.yml + refresh the wall
  local client="$1"; shift
  printf '%s\n' "$@" > "engagements/$client/deliverables/risk-register.slots.yml"
  wall
}

stage() {  # stage <client>: the anonymized patterns /fde:promote would write.
  # Stable keys are what make the sighting counter tick across engagements.
  cat > "engagements/$1/deliverables/risk-register.promote.yml" <<'EOF'
schema: risk-register
patterns:
  - key: integration-throttling
    slot: top_risks
    label: ""
    prompt: ""
    pattern: "Vendor-side API throttling surfaces once pilot load is realistic; ask for sandbox quota upfront"
  - key: sso-auth-integration
    slot: technical_risks
    label: ""
    prompt: ""
    pattern: "SSO/auth integration recurs as the first technical blocker; get sandbox access in week 1"
  - key: rollback-plan
    slot: rollback_plan
    label: Rollback plan
    prompt: "How do we return to the pre-pilot state if go-live fails?"
    pattern: "Every pilot needs an explicit rollback path agreed before go-live"
EOF
}

if [ "$live" -eq 1 ]; then
  .fde/bin/fde-dashboard.sh --watch >/dev/null
  echo "DASHBOARD: open $work/.fde/dashboard.html in a browser (auto-refreshes)"
  echo; sleep 3
fi

echo "=== Engagement 1: Acme Corp: from scratch ==="
.fde/bin/fde-new.sh "Acme Corp" >/dev/null; wall
slots acme-corp \
  'schema: risk-register' 'schema_version: 1' 'slots:' \
  '  top_risks: "Vendor API rate limits may throttle the pilot"' \
  '  technical_risks: "Legacy SSO blocks gated endpoints"' \
  '  organizational_risks: "Sponsor splits attention with a reorg"' \
  '  mitigations: "Negotiate sandbox quota; phase the SSO work"' \
  '  early_warning_signals: ""' \
  '  residual_risk: ""' \
  'sources:' \
  '  top_risks: engagement' \
  '  technical_risks: engagement' \
  '  organizational_risks: engagement' \
  '  mitigations: engagement'
.fde/bin/fde-coverage.sh acme-corp risk-register
stage acme-corp
.fde/bin/fde-promote.sh acme-corp risk-register | grep -E 'candidate|sighting|PAVED' || true
wall

echo
echo "=== Engagement 2: Globex: inherits Acme priors ==="
.fde/bin/fde-new.sh "Globex" >/dev/null; wall
# inherited slots land first...
slots globex \
  'schema: risk-register' 'schema_version: 1' 'slots:' \
  '  top_risks: "Integration throttling under realistic load (from corpus)"' \
  '  technical_risks: "Auth/SSO integration path (from corpus)"' \
  '  organizational_risks: ""' \
  '  mitigations: ""' \
  '  early_warning_signals: ""' \
  '  residual_risk: ""' \
  'sources:' \
  '  top_risks: inherited' \
  '  technical_risks: inherited'
# ...then this engagement fills its own
slots globex \
  'schema: risk-register' 'schema_version: 1' 'slots:' \
  '  top_risks: "Integration throttling under realistic load (from corpus)"' \
  '  technical_risks: "Auth/SSO integration path (from corpus)"' \
  '  organizational_risks: "Two-team ownership, unclear DRI"' \
  '  mitigations: "Single DRI; quota ask upfront"' \
  '  early_warning_signals: "Slipping weekly demo cadence"' \
  '  residual_risk: ""' \
  'sources:' \
  '  top_risks: inherited' \
  '  technical_risks: inherited' \
  '  organizational_risks: engagement' \
  '  mitigations: engagement' \
  '  early_warning_signals: engagement'
.fde/bin/fde-coverage.sh globex risk-register
stage globex
.fde/bin/fde-promote.sh globex risk-register | grep -E 'candidate|sighting|PAVED' || true
wall

echo
echo "=== Engagement 3: Initech: third sighting PAVES the schema ==="
.fde/bin/fde-new.sh "Initech" >/dev/null; wall
slots initech \
  'schema: risk-register' 'schema_version: 1' 'slots:' \
  '  top_risks: "Throttling under pilot load (from corpus)"' \
  '  technical_risks: "Auth/SSO integration path (from corpus)"' \
  '  organizational_risks: "Cross-team DRI ambiguity (from corpus)"' \
  '  mitigations: "Single DRI + upfront quota (from corpus)"' \
  '  early_warning_signals: "Demo cadence slip (from corpus)"' \
  '  residual_risk: "Data residency unresolved for EU users"' \
  'sources:' \
  '  top_risks: inherited' \
  '  technical_risks: inherited' \
  '  organizational_risks: inherited' \
  '  mitigations: inherited' \
  '  early_warning_signals: inherited' \
  '  residual_risk: engagement'
.fde/bin/fde-coverage.sh initech risk-register
echo "  -> near-complete on day one: 5 of 6 slots inherited, not retyped."
stage initech
cp .fde/schemas/risk-register.schema.yml "$work/.schema-before"
.fde/bin/fde-promote.sh initech risk-register | grep -E 'candidate|sighting|PAVED' || true
echo
echo "--- the schema itself just changed (git-diff-able expertise) ---"
diff -u "$work/.schema-before" .fde/schemas/risk-register.schema.yml \
  | grep -E '^[-+][^-+]' | sed 's/^/  /' || true
rm -f "$work/.schema-before"
wall

echo
echo "=== Confidentiality check (shared layers must be client-anonymous) ==="
.fde/bin/fde-validate.sh

.fde/bin/fde-dashboard.sh $( [ "$live" -eq 1 ] && printf -- '--watch' ) | sed 's/^/  /'
if [ "$live" -eq 1 ]; then
  echo "  (workspace kept at $work; Ctrl-C when you finish recording)"
fi
