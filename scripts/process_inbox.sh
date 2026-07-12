#!/usr/bin/env bash
# Drain the inbox: every *.pdf gets converted, logged, and archived.
# Triggered by systemd pdf2kindle.path, or run by hand / from the orchestrator.
set -euo pipefail

ROOT="${PDF2KINDLE_ROOT:-/srv/pdf2kindle}"
INBOX="$ROOT/inbox"
OUTBOX="$ROOT/outbox"
ARCHIVE="$ROOT/archive"
LOGS="$ROOT/logs"
BIN="${PDF2KINDLE_BIN:-/opt/pdf2kindle/bin/pdf2kindle}"
LANG_OPT="${PDF2KINDLE_LANG:-eng}"
VARIANT="${PDF2KINDLE_VARIANT:-both}"     # full | paperwhite | both
FORMAT="${PDF2KINDLE_FORMAT:-both}"       # epub | azw3 | both

mkdir -p "$INBOX" "$OUTBOX" "$ARCHIVE" "$LOGS"

shopt -s nullglob
for pdf in "$INBOX"/*.pdf "$INBOX"/*.PDF; do
  base="$(basename "${pdf%.*}")"
  stamp="$(date +%Y%m%d-%H%M%S)"
  job="$OUTBOX/${base}"
  logf="$LOGS/${base}-${stamp}.log"

  # Wait until the file stops growing (guards against half-copied uploads).
  prev=-1
  for _ in {1..30}; do
    cur=$(stat -c%s "$pdf")
    [[ "$cur" == "$prev" && "$cur" -gt 0 ]] && break
    prev=$cur; sleep 1
  done

  mkdir -p "$job"
  echo "=== $(date -Is) converting $pdf" | tee "$logf"
  if "$BIN" "$pdf" -o "$job" --variant "$VARIANT" --format "$FORMAT" --lang "$LANG_OPT" >>"$logf" 2>&1; then
    status=ok
  else
    status=FAILED
  fi
  echo "=== $(date -Is) $status" | tee -a "$logf"

  mv -f "$pdf" "$ARCHIVE/${base}-${stamp}.pdf"
  echo "$status  $base  -> $job  (log: $logf)"
done
