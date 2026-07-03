#!/usr/bin/env bash
# fde-report.sh — render a markdown file to a clean, self-contained HTML report
# (and optionally a PDF), with live mermaid diagrams. No LLM, no API key.
# The HTML carries its own print CSS, so anyone can open it and Cmd/Ctrl-P ->
# Save as PDF even with zero tooling installed.
#
# usage:
#   fde-report.sh [--title "Report title"] [--pdf] <input.md> [output.html]
#   fde-report.sh --title "Acme - Risk Register" --pdf \
#       engagements/acme/deliverables/risk-register.md
#
#   <input.md>      source markdown ('-' reads stdin)
#   [output.html]   where to write (default: <input>.html; stdout if input is '-')
#   --title T       document title + cover heading (default: input filename)
#   --pdf           also emit <output>.pdf. Prefers headless Chrome (renders
#                   mermaid); falls back to weasyprint/wkhtmltopdf/pandoc (static,
#                   no diagrams); else prints the Cmd/Ctrl-P tip (still zero-dep).
#
# mermaid: ```mermaid fences become live diagrams. By default mermaid.js loads
# from a CDN (needs network when the report is *viewed*). Drop a copy at
# vendor/mermaid.min.js next to this script (or set FDE_MERMAID_JS=/path) and it
# is inlined instead, for a fully offline, self-contained file.
set -euo pipefail

title=""; want_pdf=0
args=()
while [ $# -gt 0 ]; do
  case "$1" in
    --title) title="${2:-}"; shift 2 ;;
    --pdf)   want_pdf=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) args+=("$1"); shift ;;
  esac
done

in="${args[0]:-}"
[ -z "$in" ] && { echo "usage: fde-report.sh [--title T] [--pdf] <input.md> [output.html]" >&2; exit 1; }
if [ "$in" = "-" ]; then
  out="${args[1]:-/dev/stdout}"; src=$(cat)
else
  [ -f "$in" ] || { echo "no such file: $in" >&2; exit 1; }
  out="${args[1]:-${in%.md}.html}"; src=$(cat "$in")
fi
[ -z "$title" ] && title=$(basename "${in%.md}")
has_mermaid=0; printf '%s\n' "$src" | grep -q '^```mermaid' && has_mermaid=1

esc_html(){ printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# --- markdown -> HTML body (awk; covers the constructs our deliverables use) ---
md2html() {
  awk '
    function esc(s){ gsub(/&/,"\\&amp;",s); gsub(/</,"\\&lt;",s); gsub(/>/,"\\&gt;",s); return s }
    # awk gsub has no backreferences (no gensub on BSD awk), so rebuild by hand.
    function spans(s,   out){ out=""
      while(match(s,/`[^`]+`/)){ out=out substr(s,1,RSTART-1) "<code>" substr(s,RSTART+1,RLENGTH-2) "</code>"; s=substr(s,RSTART+RLENGTH) } return out s }
    function bolds(s,   out){ out=""
      while(match(s,/\*\*[^*]+\*\*/)){ out=out substr(s,1,RSTART-1) "<strong>" substr(s,RSTART+2,RLENGTH-4) "</strong>"; s=substr(s,RSTART+RLENGTH) } return out s }
    function links(s,   out,seg,p,L){ out=""
      while(match(s,/\[[^]]+\]\([^)]+\)/)){ out=out substr(s,1,RSTART-1); seg=substr(s,RSTART,RLENGTH); p=index(seg,"]"); L=length(seg)
        out=out "<a href=\"" substr(seg,p+2,L-p-2) "\">" substr(seg,2,p-2) "</a>"; s=substr(s,RSTART+RLENGTH) } return out s }
    function inline(s){ return links(bolds(spans(esc(s)))) }
    function close_list(){ if(inul){print "</ul>";inul=0} if(inol){print "</ol>";inol=0} }
    function close_tbl(){ if(intbl){print "</tbody></table>";intbl=0} }
    BEGIN{ inul=0;inol=0;inpre=0;intbl=0 }   # inpre: 0 none, 1 code, 2 mermaid
    {
      line=$0
      # fenced block (``` optionally followed by a language)
      if(line ~ /^```/){
        if(inpre){ print (inpre==2 ? "</pre>" : "</code></pre>"); inpre=0 }
        else { close_list(); close_tbl()
          if(line ~ /^```mermaid[[:space:]]*$/){ print "<pre class=\"mermaid\">"; inpre=2 }
          else { print "<pre><code>"; inpre=1 } }
        next }
      if(inpre){ print esc(line); next }
      # table row
      if(line ~ /^[[:space:]]*\|.*\|[[:space:]]*$/){
        if(line ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/){ next }  # separator row
        close_list()
        row=line; sub(/^[[:space:]]*\|/,"",row); sub(/\|[[:space:]]*$/,"",row)
        n=split(row,cells,"|")
        if(!intbl){ print "<table><thead><tr>"; for(i=1;i<=n;i++){g=cells[i];gsub(/^[[:space:]]+|[[:space:]]+$/,"",g);print "<th>" inline(g) "</th>"} print "</tr></thead><tbody>"; intbl=1; next }
        print "<tr>"; for(i=1;i<=n;i++){g=cells[i];gsub(/^[[:space:]]+|[[:space:]]+$/,"",g);print "<td>" inline(g) "</td>"} print "</tr>"; next
      } else close_tbl()
      # blank
      if(line ~ /^[[:space:]]*$/){ close_list(); next }
      # hr
      if(line ~ /^([-*_])[[:space:]]*\1[[:space:]]*\1[-*_[:space:]]*$/){ close_list(); print "<hr>"; next }
      # headings
      if(match(line,/^#+[[:space:]]/)){ close_list(); h=index(line," "); lvl=h-1; if(lvl>6)lvl=6; txt=substr(line,h+1); printf "<h%d>%s</h%d>\n",lvl,inline(txt),lvl; next }
      # blockquote
      if(line ~ /^>[[:space:]]?/){ close_list(); t=line; sub(/^>[[:space:]]?/,"",t); print "<blockquote>" inline(t) "</blockquote>"; next }
      # unordered list
      if(line ~ /^[[:space:]]*[-*][[:space:]]+/){ if(inol){print "</ol>";inol=0} if(!inul){print "<ul>";inul=1} t=line; sub(/^[[:space:]]*[-*][[:space:]]+/,"",t); print "<li>" inline(t) "</li>"; next }
      # ordered list
      if(line ~ /^[[:space:]]*[0-9]+\.[[:space:]]+/){ if(inul){print "</ul>";inul=0} if(!inol){print "<ol>";inol=1} t=line; sub(/^[[:space:]]*[0-9]+\.[[:space:]]+/,"",t); print "<li>" inline(t) "</li>"; next }
      # paragraph
      close_list(); print "<p>" inline(line) "</p>"
    }
    END{ if(inpre)print (inpre==2 ? "</pre>" : "</code></pre>"); close_list(); close_tbl() }
  '
}

# mermaid <script>: inline a local copy if present (offline), else CDN.
mermaid_script() {
  [ "$has_mermaid" -eq 1 ] || return 0
  local vendor="${FDE_MERMAID_JS:-$(cd "$(dirname "$0")" && pwd)/vendor/mermaid.min.js}"
  if [ -f "$vendor" ]; then
    printf '<script>'; cat "$vendor"; printf '</script>\n'
  else
    printf '%s\n' '<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>'
  fi
  printf '%s\n' '<script>mermaid.initialize({startOnLoad:true,theme:"neutral"});</script>'
}

# --- assemble self-contained HTML with embedded print CSS ---
render() {
  local t; t=$(esc_html "$1")
  cat <<HTML
<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${t}</title>
<style>
  :root{ --ink:#1f2937; --muted:#6b7280; --line:#e5e7eb; --accent:#1f2937; }
  *{ box-sizing:border-box }
  body{ font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
        color:var(--ink); max-width:48rem; margin:3rem auto; padding:0 1.5rem; }
  h1{ font-size:1.9rem; line-height:1.2; margin:0 0 .25rem; }
  h2{ font-size:1.35rem; margin:2.2rem 0 .6rem; padding-bottom:.3rem; border-bottom:2px solid var(--line); }
  h3{ font-size:1.1rem; margin:1.6rem 0 .4rem; }
  h4{ font-size:1rem; margin:1.2rem 0 .3rem; color:var(--muted); text-transform:uppercase; letter-spacing:.04em; }
  p,li{ margin:.4rem 0 } ul,ol{ padding-left:1.4rem }
  code{ font:.88em ui-monospace,SFMono-Regular,Menlo,Consolas,monospace; background:#f3f4f6; padding:.1em .35em; border-radius:4px; }
  pre{ background:#f9fafb; border:1px solid var(--line); border-radius:8px; padding:1rem; overflow:auto; }
  pre code{ background:none; padding:0 }
  pre.mermaid{ background:none; border:0; text-align:center; padding:1rem 0 }
  blockquote{ margin:1rem 0; padding:.4rem 1rem; border-left:4px solid var(--line); color:var(--muted); }
  table{ border-collapse:collapse; width:100%; margin:1rem 0; font-size:.95rem; }
  th,td{ border:1px solid var(--line); padding:.5rem .7rem; text-align:left; vertical-align:top; }
  th{ background:#f9fafb; font-weight:600 }
  hr{ border:0; border-top:1px solid var(--line); margin:2rem 0 }
  .fde-cover{ margin:0 0 2rem; padding-bottom:1rem; border-bottom:3px solid var(--accent); }
  .fde-cover .meta{ color:var(--muted); font-size:.85rem; margin-top:.4rem }
  @page{ margin:18mm }
  @media print{ body{ margin:0; max-width:none } a{ color:inherit; text-decoration:none } h2{ page-break-after:avoid } table,pre,blockquote{ page-break-inside:avoid } }
</style>
</head><body>
<header class="fde-cover">
  <h1>${t}</h1>
  <div class="meta">Prepared with FDE-SKILLS</div>
</header>
HTML
  printf '%s\n' "$src" | md2html
  mermaid_script
  printf '</body></html>\n'
}

render "$title" > "$out"
[ "$out" = "/dev/stdout" ] || echo "wrote $out"

# --- optional PDF -----------------------------------------------------------
# Prefer headless Chrome: it runs mermaid's JS, so diagrams render in the PDF.
# weasyprint/wkhtmltopdf/pandoc produce a static PDF (mermaid stays as raw text).
if [ "$want_pdf" -eq 1 ] && [ "$out" != "/dev/stdout" ]; then
  pdf="${out%.html}.pdf"
  chrome=""
  for c in google-chrome chrome chromium chromium-browser msedge \
           "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
    if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then chrome="$c"; break; fi
  done
  if [ -n "$chrome" ]; then
    "$chrome" --headless=new --disable-gpu --no-pdf-header-footer \
      --print-to-pdf="$pdf" "file://$(cd "$(dirname "$out")" && pwd)/$(basename "$out")" \
      >/dev/null 2>&1 && echo "wrote $pdf (mermaid rendered)" \
      || echo "PDF: headless Chrome failed; open $out and Print -> Save as PDF." >&2
  elif command -v weasyprint >/dev/null 2>&1; then
    weasyprint "$out" "$pdf" && echo "wrote $pdf (static; mermaid not rendered)"
  elif command -v wkhtmltopdf >/dev/null 2>&1; then
    wkhtmltopdf -q "$out" "$pdf" && echo "wrote $pdf (static; mermaid not rendered)"
  elif command -v pandoc >/dev/null 2>&1; then
    pandoc "$out" -o "$pdf" && echo "wrote $pdf (static; mermaid not rendered)"
  else
    echo "PDF: no Chrome/weasyprint/wkhtmltopdf/pandoc found." >&2
    echo "     Open $out in a browser and Print -> Save as PDF (the CSS is print-ready)." >&2
  fi
fi
