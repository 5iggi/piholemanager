#!/usr/bin/env bash
set -u
PLUGIN=piholemanager
BASE="${LBHOMEDIR:-/opt""/loxberry}"
CONFROOT="${LBPCONFIG:-$BASE/config/plugins}"
DATAROOT="${LBPDATA:-$BASE/data/plugins}"
LOGROOT="${LBPLOG:-$BASE/log/plugins}"
DEST="/tmp/${PLUGIN}_upgrade_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DEST"
[ -d "$CONFROOT/$PLUGIN" ] && cp -a "$CONFROOT/$PLUGIN" "$DEST/config" 2>/dev/null || true
[ -d "$DATAROOT/$PLUGIN" ] && cp -a "$DATAROOT/$PLUGIN" "$DEST/data" 2>/dev/null || true
[ -d "$LOGROOT/$PLUGIN" ] && cp -a "$LOGROOT/$PLUGIN" "$DEST/log" 2>/dev/null || true
echo "$DEST" > "/tmp/${PLUGIN}_upgrade_latest"
exit 0
