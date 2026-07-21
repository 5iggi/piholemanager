#!/usr/bin/env bash
set -u
PLUGIN=piholemanager
BASE="${LBHOMEDIR:-/opt""/loxberry}"
CONFROOT="${LBPCONFIG:-$BASE/config/plugins}"
DATAROOT="${LBPDATA:-$BASE/data/plugins}"
LOGROOT="${LBPLOG:-$BASE/log/plugins}"
BINROOT="${LBPBIN:-$BASE/bin/plugins}"
TEMPLROOT="${LBPTEMPLATE:-$BASE/templates/plugins}"
HTMLAUTHROOT="${LBPHTMLAUTH:-$BASE/webfrontend/htmlauth/plugins}"
BACKUP=""
[ -f "/tmp/${PLUGIN}_upgrade_latest" ] && BACKUP="$(cat "/tmp/${PLUGIN}_upgrade_latest" 2>/dev/null || true)"
mkdir -p "$CONFROOT/$PLUGIN" "$DATAROOT/$PLUGIN" "$DATAROOT/$PLUGIN/templates" "$LOGROOT/$PLUGIN"
if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
  [ -d "$BACKUP/config" ] && cp -an "$BACKUP/config/." "$CONFROOT/$PLUGIN/" 2>/dev/null || true
  [ -d "$BACKUP/data" ] && cp -an "$BACKUP/data/." "$DATAROOT/$PLUGIN/" 2>/dev/null || true
  [ -d "$BACKUP/log" ] && cp -an "$BACKUP/log/." "$LOGROOT/$PLUGIN/" 2>/dev/null || true
fi
cp -a "$TEMPLROOT/$PLUGIN/dnsmasq_templates/"*.conf "$DATAROOT/$PLUGIN/templates/" 2>/dev/null || true
chmod 755 "$BINROOT/$PLUGIN/piholemanager.sh" 2>/dev/null || true
chmod 755 "$HTMLAUTHROOT/$PLUGIN/index.cgi" 2>/dev/null || true
chmod 755 "$HTMLAUTHROOT/$PLUGIN/index.php" 2>/dev/null || true
touch "$LOGROOT/$PLUGIN/install.log" "$LOGROOT/$PLUGIN/actions.log" "$LOGROOT/$PLUGIN/healthcheck.log" 2>/dev/null || true
exit 0
