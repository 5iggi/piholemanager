#!/usr/bin/env bash
set -u
PLUGIN=piholemanager
PDIR="${3:-$PLUGIN}"
BASE="${LBHOMEDIR:-/opt""/loxberry}"
mkdir -p "${LBPCONFIG:-$BASE/config/plugins}/$PDIR" "${LBPDATA:-$BASE/data/plugins}/$PDIR/install" "${LBPLOG:-$BASE/log/plugins}/$PDIR" "${LBPDATA:-$BASE/data/plugins}/$PDIR/templates" 2>/dev/null || true
chmod 755 "${LBPBIN:-$BASE/bin/plugins}/$PDIR/piholemanager.sh" 2>/dev/null || true
chmod 755 "${LBPHTMLAUTH:-$BASE/webfrontend/htmlauth/plugins}/$PDIR/index.cgi" 2>/dev/null || true
chmod 755 "${LBPHTMLAUTH:-$BASE/webfrontend/htmlauth/plugins}/$PDIR/index.php" 2>/dev/null || true
cp -a "${LBPTEMPLATE:-$BASE/templates/plugins}/$PDIR/dnsmasq_templates/"*.conf "${LBPDATA:-$BASE/data/plugins}/$PDIR/templates/" 2>/dev/null || true
touch "${LBPLOG:-$BASE/log/plugins}/$PDIR/install.log" "${LBPLOG:-$BASE/log/plugins}/$PDIR/actions.log" "${LBPLOG:-$BASE/log/plugins}/$PDIR/healthcheck.log" 2>/dev/null || true
exit 0
