#!/usr/bin/env bash
# fde-dashboard.sh — render the compounding wall: one self-contained HTML page
# showing every engagement × deliverable type as a provenance-colored coverage
# bar (green = inherited from corpus, blue = filled this engagement, gray =
# still empty), plus corpus growth and paved-slot counts. No LLM, no network,
# no JS — bash + awk emitting HTML, in the same spirit as the rest of the spine.
#
#   usage: fde-dashboard.sh [-o out.html] [--watch]
#
#   -o out.html   where to write (default: .fde/dashboard.html)
#   --watch       inject <meta refresh> (1s) so a browser tab follows the
#                 workspace live — used by examples/demo.sh --live
#
# CONFIDENTIALITY: the output contains client slugs. It lives inside .fde/ but
# must never be committed — keep .fde/dashboard.html in .gitignore.
set -euo pipefail
FDE_ROOT="${FDE_ROOT:-.fde}"
ENG_ROOT="${ENG_ROOT:-engagements}"

out="$FDE_ROOT/dashboard.html"; watch=0
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out="${2:-}"; shift 2 ;;
    --watch) watch=1; shift ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# --- engagement order (index.yml if present, else directory order) -----------
slugs=""
if [ -f "$FDE_ROOT/index.yml" ]; then
  slugs=$(awk '/^  - slug:/{print $3}' "$FDE_ROOT/index.yml")
fi
if [ -z "$slugs" ] && [ -d "$ENG_ROOT" ]; then
  slugs=$(for d in "$ENG_ROOT"/*/; do [ -d "$d" ] && basename "$d"; done; true)
fi

# --- deliverable types + labels from config -----------------------------------
# records joined with "|" (BSD awk -v cannot carry newlines)
types_tsv=$(awk '
  /^deliverable_types:/ { inblk=1; next }
  inblk && /^[^[:space:]]/ { inblk=0 }
  inblk && /^[[:space:]]+- id:/    { id=$3 }
  inblk && /^[[:space:]]+label:/   { lab=$0; sub(/^[[:space:]]+label:[[:space:]]*/,"",lab)
                                     printf "%s\t%s|", id, lab }
' "$FDE_ROOT/config.yml" 2>/dev/null || true)

# --- per (engagement, type) coverage: slug type total filled inherited --------
cells=""
for slug in $slugs; do
  for f in "$ENG_ROOT/$slug/deliverables/"*.slots.yml; do
    [ -f "$f" ] || continue
    type=$(basename "$f" .slots.yml)
    line=$(awk -v slug="$slug" -v type="$type" '
      function trim(s){ gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s }
      /^slots:/   { blk="slots"; next }
      /^sources:/ { blk="sources"; next }
      /^[^[:space:]]/ { blk="" }
      blk=="" { next }
      $0 ~ /^  [^ ][^:]*:/ {
        val=$0; sub(/^[^:]*:/,"",val); val=trim(val)
        if (blk=="slots") {
          total++
          if (val != "" && val != "\"\"") filled++
        } else if (blk=="sources") {
          gsub(/"/,"",val)
          if (val=="inherited") inh++
        }
      }
      END { printf "%s\t%s\t%d\t%d\t%d\n", slug, type, total, filled, inh }
    ' "$f")
    cells="$cells$line
"
  done
done

# --- corpus stats per type: type entries sightings paved ----------------------
corpus_stats=""
if [ -d "$FDE_ROOT/corpus" ]; then
  for c in "$FDE_ROOT/corpus/"*.yml; do
    [ -f "$c" ] || continue
    type=$(basename "$c" .yml)
    line=$(awk -v type="$type" '
      /^  - key:/            { entries++ }
      /^    sightings:/      { sightings += $2 }
      /^    paved: true/     { paved++ }
      END { printf "%s\t%d\t%d\t%d\n", type, entries, sightings, paved }
    ' "$c")
    corpus_stats="$corpus_stats$line
"
  done
fi

# --- headline numbers ----------------------------------------------------------
n_eng=$(printf '%s\n' $slugs | awk 'NF' | wc -l | tr -d ' ')
n_priors=$(printf '%s' "$corpus_stats" | awk -F'\t' '{s+=$2} END{print s+0}')
n_paved=$(printf '%s' "$corpus_stats" | awk -F'\t' '{s+=$4} END{print s+0}')
validate="—"
if [ -x "$FDE_ROOT/bin/fde-validate.sh" ]; then
  if FDE_ROOT="$FDE_ROOT" ENG_ROOT="$ENG_ROOT" "$FDE_ROOT/bin/fde-validate.sh" >/dev/null 2>&1; then
    validate="PASS"
  else
    validate="FAIL"
  fi
fi

# --- render --------------------------------------------------------------------
mkdir -p "$(dirname "$out")"
{
cat <<HTML
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
$( [ "$watch" -eq 1 ] && printf '<meta http-equiv="refresh" content="1">\n' )
<title>FDE dashboard — the compounding wall</title>
<style>
  :root{ --ink:#1f2937; --muted:#6b7280; --line:#e5e7eb;
         --inh:#34d399; --new:#60a5fa; --empty:#e5e7eb; }
  *{ box-sizing:border-box }
  body{ font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
        color:var(--ink); max-width:60rem; margin:2.5rem auto; padding:0 1.5rem; }
  h1{ font-size:1.5rem; margin:0 }
  .sub{ color:var(--muted); font-size:.85rem; margin:.2rem 0 1.2rem }
  .stats{ display:flex; gap:1.5rem; flex-wrap:wrap; margin:0 0 1.6rem }
  .stat{ border:1px solid var(--line); border-radius:10px; padding:.6rem 1rem; min-width:8rem }
  .stat b{ display:block; font-size:1.4rem }
  .stat span{ color:var(--muted); font-size:.78rem; text-transform:uppercase; letter-spacing:.04em }
  .pass b{ color:#059669 } .fail b{ color:#dc2626 }
  table{ border-collapse:collapse; width:100%; margin:0 0 1.6rem }
  th,td{ border:1px solid var(--line); padding:.55rem .7rem; text-align:left; vertical-align:middle }
  th{ background:#f9fafb; font-size:.82rem }
  .bar{ display:flex; height:14px; width:100%; min-width:7rem; border-radius:7px; overflow:hidden; background:var(--empty) }
  .bar .inh{ background:var(--inh) } .bar .new{ background:var(--new) }
  .n{ color:var(--muted); font-size:.78rem; margin-top:.25rem }
  .legend{ color:var(--muted); font-size:.8rem; margin:0 0 .8rem }
  .dot{ display:inline-block; width:.7em; height:.7em; border-radius:50%; margin:0 .25em 0 .9em; vertical-align:baseline }
  .empty-note{ color:var(--muted); border:1px dashed var(--line); border-radius:10px; padding:1rem 1.2rem }
  h2{ font-size:1.05rem; margin:1.8rem 0 .5rem }
  .paved{ color:#059669; font-weight:600 }
</style>
</head><body>
<h1>The compounding wall</h1>
<div class="sub">Deliverable coverage per engagement, colored by where each slot came from. Rendered by <code>fde-dashboard.sh</code> — plain shell, no LLM. Do not commit this file.</div>
<div class="stats">
  <div class="stat"><b>${n_eng}</b><span>engagements</span></div>
  <div class="stat"><b>${n_priors}</b><span>corpus priors</span></div>
  <div class="stat"><b>${n_paved}</b><span>paved slots</span></div>
  <div class="stat $( [ "$validate" = PASS ] && printf 'pass' || printf 'fail' )"><b>${validate}</b><span>validate</span></div>
</div>
<div class="legend">
  <span class="dot" style="background:var(--inh);margin-left:0"></span>inherited from corpus
  <span class="dot" style="background:var(--new)"></span>filled this engagement
  <span class="dot" style="background:var(--empty)"></span>empty
</div>
HTML

if [ -z "$(printf '%s' "$cells" | awk 'NF')" ]; then
  printf '<div class="empty-note">No deliverables yet. Draft one with <code>/fde:draft</code> and the wall starts here.</div>\n'
else
  printf '%s' "$cells" | awk -F'\t' -v slugs="$(printf '%s\n' $slugs | tr '\n' ',')" -v types="$types_tsv" '
    BEGIN {
      ns=split(slugs, S, ","); while (ns>0 && S[ns]=="") ns--
      nt=split(types, TL, "|"); while (nt>0 && TL[nt]=="") nt--
      for (i=1;i<=nt;i++) { split(TL[i], p, "\t"); TID[i]=p[1]; LAB[p[1]]=p[2] }
    }
    NF>=5 { key=$1 SUBSEP $2; total[key]=$3; filled[key]=$4; inh[key]=$5; hastype[$2]=1 }
    END {
      print "<table><thead><tr><th>deliverable</th>"
      for (i=1;i<=ns;i++) printf "<th>%s</th>", S[i]
      print "</tr></thead><tbody>"
      for (t=1;t<=nt;t++) {
        id=TID[t]
        if (!(id in hastype)) continue
        printf "<tr><td><b>%s</b></td>", (LAB[id] != "" ? LAB[id] : id)
        for (i=1;i<=ns;i++) {
          key=S[i] SUBSEP id
          if (!(key in total) || total[key]==0) { print "<td>—</td>"; continue }
          tt=total[key]; ff=filled[key]; hh=inh[key]
          nn=ff-hh; if (nn<0) nn=0
          wi=int(hh*100/tt); wn=int(nn*100/tt)
          printf "<td><div class=\"bar\"><span class=\"inh\" style=\"width:%d%%\"></span><span class=\"new\" style=\"width:%d%%\"></span></div><div class=\"n\">%d/%d filled · %d inherited · %d new</div></td>", wi, wn, ff, tt, hh, nn
        }
        print "</tr>"
      }
      print "</tbody></table>"
    }'
fi

if [ -n "$(printf '%s' "$corpus_stats" | awk 'NF')" ]; then
  printf '<h2>Corpus — what past engagements paid forward</h2>\n'
  printf '%s' "$corpus_stats" | awk -F'\t' -v types="$types_tsv" '
    BEGIN { nt=split(types, TL, "|")
      for (i=1;i<=nt;i++) { split(TL[i], p, "\t"); LAB[p[1]]=p[2] } }
    NF>=4 {
      lab = (LAB[$1] != "" ? LAB[$1] : $1)
      paved = ($4>0 ? sprintf(" · <span class=\"paved\">%d paved</span>", $4) : "")
      printf "<p><b>%s</b> — %d priors · %d sightings%s</p>\n", lab, $2, $3, paved
    }'
fi

printf '</body></html>\n'
} > "$out"

echo "wrote $out"
