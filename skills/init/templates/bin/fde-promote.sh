#!/usr/bin/env bash
# fde-promote.sh — merge one deliverable's staged, anonymized patterns into the
# shared corpus with a sighting counter, and PAVE patterns that hit the Rule-of-
# Three threshold into the schema. No LLM. The /fde:promote skill does the
# *semantic* anonymization and writes the staging file; this script is the
# deterministic backstop (redaction + leak gate) and the only writer of
# .fde/corpus/ and the schema's evolved_slots.
#
#   usage: fde-promote.sh <client-slug> <deliverable-type>
#
# Reads   engagements/<client>/deliverables/<type>.promote.yml   (staging):
#   schema: <type>
#   patterns:
#     - key: sso-auth-integration          # stable kebab-case pattern id;
#       slot: technical_risks              #   reuse the key when the same
#       label: ""                          #   pattern recurs (see /fde:promote)
#       prompt: ""                         # label+prompt only for NEW-slot proposals
#       pattern: "one-line generalized learning, already anonymized"
#
# Maintains .fde/corpus/<type>.yml (one entry per key+slot, sightings counted):
#   entries:
#     - key: ...
#       slot: ...
#       sightings: N
#       first_seen: YYYY-MM-DD
#       last_seen: YYYY-MM-DD
#       paved: true|false
#       label: ""
#       prompt: ""
#       pattern: "..."
#
# Tiering (Rule of Three): sighting 1 = candidate, 2 = recurring, at
# config.yml paving.threshold (default 3) the entry is PAVED — marked
# paved: true, and if its slot id is not in the schema yet, appended to
# .fde/schemas/<type>.schema.yml under evolved_slots with a version bump.
# That schema diff is the visible "paving" moment.
#
# Safety order: the merged corpus is built in a temp file and checked against
# the full identifier set (all engagements + config extra_identifiers) BEFORE
# it replaces the real corpus. A leak aborts with the corpus untouched.
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"
today=$(date +%F)

client="${1:-}"; type="${2:-}"
{ [ -z "$client" ] || [ -z "$type" ]; } && {
  echo "usage: fde-promote.sh <client-slug> <deliverable-type>" >&2; exit 1; }

staging="$ENG_ROOT/$client/deliverables/$type.promote.yml"
[ -f "$staging" ] || {
  echo "no staging file: $staging" >&2
  echo "(/fde:promote writes it: anonymized patterns with stable keys)" >&2
  exit 1
}

corpus_dir="$FDE_ROOT/corpus"
corpus="$corpus_dir/$type.yml"
schema="$FDE_ROOT/schemas/$type.schema.yml"
mkdir -p "$corpus_dir"

threshold=$(awk '
  /^paving:/ { inblk=1; next }
  inblk && /^[^[:space:]]/ { inblk=0 }
  inblk && /^[[:space:]]+threshold:/ { print $2; exit }
' "$FDE_ROOT/config.yml" 2>/dev/null)
[ -n "$threshold" ] || threshold=3

# --- yaml -> TSV helpers (fields are single-line; tabs stripped) -------------
# TSV columns: key slot sightings first_seen last_seen paved label prompt pattern
entries2tsv() {  # corpus file -> TSV
  awk '
    function flush() {
      if (k != "") printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", k,s,n,f,l,p,lb,pr,pt
      k=s=n=f=l=p=lb=pr=pt=""
    }
    function val(line,   v) { v=line; sub(/^[[:space:]]*(-[[:space:]]+)?[a-z_]+:[[:space:]]*/,"",v)
      gsub(/^"|"$/,"",v); gsub(/\t/," ",v); return v }
    /^[[:space:]]+- key:/    { flush(); k=val($0); next }
    /^[[:space:]]+slot:/     { s=val($0); next }
    /^[[:space:]]+sightings:/{ n=val($0); next }
    /^[[:space:]]+first_seen:/{ f=val($0); next }
    /^[[:space:]]+last_seen:/{ l=val($0); next }
    /^[[:space:]]+paved:/    { p=val($0); next }
    /^[[:space:]]+label:/    { lb=val($0); next }
    /^[[:space:]]+prompt:/   { pr=val($0); next }
    /^[[:space:]]+pattern:/  { pt=val($0); next }
    END { flush() }
  ' "$1"
}

staging2tsv() {  # staging file -> TSV: key slot label prompt pattern
  awk '
    function flush() {
      if (k != "") printf "%s\t%s\t%s\t%s\t%s\n", k,s,lb,pr,pt
      k=s=lb=pr=pt=""
    }
    function val(line,   v) { v=line; sub(/^[[:space:]]*(-[[:space:]]+)?[a-z_]+:[[:space:]]*/,"",v)
      gsub(/^"|"$/,"",v); gsub(/\t/," ",v); return v }
    /^[[:space:]]+- key:/  { flush(); k=val($0); next }
    /^[[:space:]]+slot:/   { s=val($0); next }
    /^[[:space:]]+label:/  { lb=val($0); next }
    /^[[:space:]]+prompt:/ { pr=val($0); next }
    /^[[:space:]]+pattern:/{ pt=val($0); next }
    END { flush() }
  ' "$1"
}

tsv2yaml() {  # TSV on stdin -> corpus yaml on stdout
  {
    printf '# Corpus: %s — anonymized cross-engagement priors.\n' "$type"
    printf '# Maintained by fde-promote.sh. Never contains client identifiers.\n'
    printf 'entries:\n'
    awk -F'\t' '{
      printf "  - key: %s\n", $1
      printf "    slot: %s\n", $2
      printf "    sightings: %s\n", $3
      printf "    first_seen: %s\n", $4
      printf "    last_seen: %s\n", $5
      printf "    paved: %s\n", $6
      printf "    label: \"%s\"\n", $7
      printf "    prompt: \"%s\"\n", $8
      printf "    pattern: \"%s\"\n", $9
    }'
  }
}

# --- 1. redact the staged patterns (figures + every identifying token) -------
# fde-identifiers.sh is the single source of identifying tokens; validate
# checks the very same set, so promote and validate can never disagree.
ids=$(FDE_ROOT="$FDE_ROOT" ENG_ROOT="$ENG_ROOT" "$FDE_ROOT/bin/fde-identifiers.sh" "$client")

tmp_staged=$(mktemp); tmp_merged_tsv=$(mktemp); tmp_corpus=$(mktemp)
trap 'rm -f "$tmp_staged" "$tmp_merged_tsv" "$tmp_corpus"' EXIT

staging2tsv "$staging" | IDS="$ids" perl -pe '
  BEGIN { @toks = grep { length } split /\n/, ($ENV{IDS} // ""); }
  s/\$[0-9][0-9,.]*/\$<REDACTED>/g;
  s/[0-9]+%/<N>%/g;
  for my $t (@toks) { s/\Q$t\E/<CLIENT>/gi; }
' > "$tmp_staged"

[ -s "$tmp_staged" ] || { echo "no patterns found in $staging" >&2; exit 1; }

# --- 2. merge into the corpus (in a temp file, not in place) ------------------
# Each line is tagged with its source (C=corpus, S=staged) so the merge works
# even when the corpus does not exist yet.
{
  [ -f "$corpus" ] && entries2tsv "$corpus" | sed 's/^/C\t/'
  sed 's/^/S\t/' "$tmp_staged"
} | awk -F'\t' -v OFS='\t' -v today="$today" '
  $1=="C" { id=$2 SUBSEP $3
    row[id]=$2 OFS $3 OFS $4 OFS $5 OFS $6 OFS $7 OFS $8 OFS $9 OFS $10
    order[++n]=id; next }
  $1=="S" { id=$2 SUBSEP $3
    if (id in row) {
      split(row[id], f, "\t")
      f[3]+=1; f[5]=today
      if ($4 != "" && f[7]=="") f[7]=$4   # backfill label/prompt if newly supplied
      if ($5 != "" && f[8]=="") f[8]=$5
      row[id]=f[1] OFS f[2] OFS f[3] OFS f[4] OFS f[5] OFS f[6] OFS f[7] OFS f[8] OFS f[9]
    } else {
      order[++n]=id
      row[id]=$2 OFS $3 OFS 1 OFS today OFS today OFS "false" OFS $4 OFS $5 OFS $6
    }
  }
  END { for (i=1;i<=n;i++) print row[order[i]] }
' > "$tmp_merged_tsv"

tsv2yaml < "$tmp_merged_tsv" > "$tmp_corpus"

# --- 3. leak gate BEFORE the corpus is touched --------------------------------
# Check the merged result against the FULL identifier set (every engagement +
# config extra_identifiers). On a hit, abort — the real corpus is unchanged.
leak=0
while IFS= read -r tok; do
  [ -n "$tok" ] || continue
  if grep -qiF -- "$tok" "$tmp_corpus"; then
    echo "LEAK BLOCKED: identifier '$tok' would enter the corpus — aborting, corpus untouched." >&2
    echo "  fix the pattern text in $staging and re-run." >&2
    leak=1
  fi
done < <(FDE_ROOT="$FDE_ROOT" ENG_ROOT="$ENG_ROOT" "$FDE_ROOT/bin/fde-identifiers.sh" --all)
[ "$leak" -eq 0 ] || exit 1

mv "$tmp_corpus" "$corpus"

added=$(awk -F'\t' -v d="$today" '$3==1 && $4==d {print "  candidate ×1: " $1 " (" $2 ")"}' "$tmp_merged_tsv")
bumped=$(awk -F'\t' -v d="$today" '$3>1 && $5==d {print "  sighting ×" $3 ": " $1 " (" $2 ")"}' "$tmp_merged_tsv")
echo "promoted $client/$type -> $corpus"
[ -n "$added" ]  && printf '%s\n' "$added"
[ -n "$bumped" ] && printf '%s\n' "$bumped"

# --- 4. pave: entries at the threshold graduate into the schema ---------------
pave_list=$(awk -F'\t' -v th="$threshold" '$3>=th && $6=="false" {print $1 "\t" $2 "\t" $3 "\t" $7 "\t" $8}' "$tmp_merged_tsv")
if [ -n "$pave_list" ]; then
  while IFS=$'\t' read -r key slot n label prompt; do
    [ -n "$key" ] || continue
    # flip paved: false -> true for this entry in the corpus
    awk -v key="$key" '
      /^[[:space:]]+- key:/ { cur=$0; sub(/^[[:space:]]+- key:[[:space:]]*/,"",cur); inent=(cur==key) }
      inent && /^[[:space:]]+paved:[[:space:]]*false/ { sub(/false/,"true") }
      { print }
    ' "$corpus" > "$corpus.tmp" && mv "$corpus.tmp" "$corpus"

    if [ -f "$schema" ] && ! grep -Eq "^[[:space:]]*- id: $slot\$" "$schema"; then
      # new slot: append under evolved_slots + version bump (the visible diff)
      old_v=$(awk '/^version: [0-9]+$/{print $2; exit}' "$schema")
      new_v=$((old_v + 1))
      [ -n "$label" ] || label="$slot"
      [ -n "$prompt" ] || prompt="(paved from $n sightings — refine this prompt)"
      awk -v v="$new_v" -v slot="$slot" -v label="$label" -v prompt="$prompt" -v n="$n" -v d="$today" '
        /^version: [0-9]+$/ && !vdone { print "version: " v; vdone=1; next }
        /^evolved_slots:[[:space:]]*\[\][[:space:]]*$/ {
          print "evolved_slots:"; emit(); done=1; next }
        { print }
        END { if (!done) emit() }
        function emit() {
          print "  - id: " slot
          print "    label: " label
          print "    required: false"
          print "    kind: text"
          print "    prompt: \"" prompt "\""
          print "    paved_from: \"" n " sightings, " d "\""
        }
      ' "$schema" > "$schema.tmp" && mv "$schema.tmp" "$schema"
      echo "PAVED: $type v$old_v -> v$new_v: + $slot ($n sightings)"
    else
      echo "PAVED: $type/$slot \"$key\" ($n sightings): now pre-fills by default"
    fi
  done <<EOF
$pave_list
EOF
fi

# --- 5. full workspace guard (belt over the braces above) ---------------------
if [ -x "$FDE_ROOT/bin/fde-validate.sh" ]; then
  FDE_ROOT="$FDE_ROOT" ENG_ROOT="$ENG_ROOT" "$FDE_ROOT/bin/fde-validate.sh"
fi
