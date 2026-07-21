#!/usr/bin/env bash
set -u
PLUGIN=piholemanager
PDIR="${3:-$PLUGIN}"
BASE="${LBHOMEDIR:-/opt""/loxberry}"
BINSCRIPT="${LBPBIN:-$BASE/bin/plugins}/$PDIR/piholemanager.sh"
LOG="${LBPLOG:-$BASE/log/plugins}/$PDIR/install.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
touch "$LOG" 2>/dev/null || true
chmod 755 "$BINSCRIPT" 2>/dev/null || true
TMPFILE="$(mktemp /tmp/piholemanager-sudoers.XXXXXX)"
echo "# Pi-hole Manager sudoers file" > "$TMPFILE"
echo "ALL ALL=(root) NOPASSWD: $BINSCRIPT *" >> "$TMPFILE"
chmod 0440 "$TMPFILE"
if visudo -cf "$TMPFILE" >> "$LOG" 2>&1; then install -o root -g root -m 0440 "$TMPFILE" /etc/sudoers.d/piholemanager; else rm -f "$TMPFILE"; exit 1; fi
rm -f "$TMPFILE"
exit 0
