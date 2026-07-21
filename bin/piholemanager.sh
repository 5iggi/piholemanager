#!/usr/bin/env bash
set -u
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN="$(basename "$SCRIPT_DIR")"
BASE="${LBHOMEDIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
CFGDIR="$BASE/config/plugins/$PLUGIN"
DATADIR="$BASE/data/plugins/$PLUGIN"
LOGDIR="$BASE/log/plugins/$PLUGIN"
TEMPLATEDIR="$DATADIR/templates"
LOG="$LOGDIR/install.log"
ACTIONLOG="$LOGDIR/actions.log"
HEALTHLOG="$LOGDIR/healthcheck.log"
DNSMASQ_DIR=/etc/dnsmasq.d
LEASE_CONF="$DNSMASQ_DIR/00-piholemanager-leasefile.conf"
LEASE_FILE=/etc/pihole/dhcp.leases

mkdir -p "$CFGDIR" "$DATADIR/backups" "$DATADIR/install" "$TEMPLATEDIR" "$LOGDIR" 2>/dev/null || true

cmd_exists(){ command -v "$1" >/dev/null 2>&1; }
need_root(){ [ "$(id -u)" -eq 0 ] || { echo "ERROR: root required"; exit 1; }; }
json_escape(){ sed 's/\\/\\\\/g; s/"/\\"/g'; }
valid_conf(){ local f="${1:-}"; [[ "$f" =~ ^[A-Za-z0-9_.-]+\.conf$ ]] && [[ "$f" != *..* ]]; }

pihole_bin(){
  local p=""
  for p in /usr/local/bin/pihole /usr/bin/pihole /opt/pihole/pihole; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  command -v pihole 2>/dev/null || true
}
ftl_bin(){
  local p=""
  for p in /usr/bin/pihole-FTL /usr/local/bin/pihole-FTL /usr/sbin/pihole-FTL /opt/pihole/pihole-FTL; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  command -v pihole-FTL 2>/dev/null || true
}
ftl_service_exists(){
  systemctl list-unit-files pihole-FTL.service >/dev/null 2>&1 && return 0
  [ -f /etc/systemd/system/pihole-FTL.service ] || [ -f /lib/systemd/system/pihole-FTL.service ] || [ -f /usr/lib/systemd/system/pihole-FTL.service ]
}
ftl_pid(){ pidof pihole-FTL 2>/dev/null | awk '{print $1}' || true; }
ftl_active(){ systemctl is-active --quiet pihole-FTL 2>/dev/null || [ -n "$(ftl_pid)" ]; }
ftl_enabled(){ systemctl is-enabled --quiet pihole-FTL 2>/dev/null; }
installer_pid_alive(){ local f="$DATADIR/install/install.pid"; [ -f "$f" ] && kill -0 "$(cat "$f" 2>/dev/null)" 2>/dev/null; }
pihole_installed(){
  [ -n "$(pihole_bin)" ] && return 0
  [ -n "$(ftl_bin)" ] && return 0
  ftl_service_exists && return 0
  [ -n "$(ftl_pid)" ] && return 0
  return 1
}

dnsmasq_active(){ systemctl is-active --quiet dnsmasq 2>/dev/null; }
dnsmasq_enabled(){ systemctl is-enabled --quiet dnsmasq 2>/dev/null; }
port53_processes(){ ss -ltnup 2>/dev/null | awk '$0 ~ /:53[[:space:]]/ {print}' || true; }
port53_has_ftl(){ port53_processes | grep -q 'pihole-FTL'; }
port53_has_dnsmasq(){ port53_processes | grep -q 'dnsmasq'; }
local_dns_works(){ cmd_exists dig && timeout 4 dig +time=2 +tries=1 @127.0.0.1 github.com A >/dev/null 2>&1; }

plugin_owned_conf(){
  local f="${1:-}" plugin="${f%.conf}"
  [ -n "$plugin" ] && { [ -d "$BASE/config/plugins/$plugin" ] || [ -d "$BASE/data/plugins/$plugin" ] || [ -d "$BASE/bin/plugins/$plugin" ] || [ -d "$BASE/webfrontend/html/plugins/$plugin" ] || [ -d "$BASE/webfrontend/htmlauth/plugins/$plugin" ]; }
}
protected_conf(){
  local f="${1:-}"
  case "$f" in
    00-piholemanager-leasefile.conf|*piholemanager*.conf) return 0;;
  esac
  plugin_owned_conf "$f"
}

settings_port(){
  local p=""
  [ -f "$CFGDIR/settings.json" ] && p="$(grep -oE '"pihole_web_port"[[:space:]]*:[[:space:]]*[0-9]+' "$CFGDIR/settings.json" 2>/dev/null | tail -n1 | grep -oE '[0-9]+$' || true)"
  [[ "$p" =~ ^[0-9]+$ ]] && echo "$p" || echo 8000
}
save_settings_port(){
  local port="$1"
  mkdir -p "$CFGDIR"
  echo "{\"plugin_version\":\"1.1.10\",\"pihole_web_port\":$port,\"open_mode\":\"named_tab\"}" > "$CFGDIR/settings.json"
}
raw_web_port(){ local ftl="$(ftl_bin)"; [ -n "$ftl" ] && "$ftl" --config webserver.port 2>/dev/null | tail -n1 || echo ""; }
normalize_config_port(){
  local raw="$1" part p
  [ -n "$raw" ] || return 0
  IFS=',' read -ra parts <<< "$raw"
  for part in "${parts[@]}"; do
    if [[ "$part" =~ ([0-9]{2,5}) ]]; then
      p="${BASH_REMATCH[1]}"
      [ "$p" = 80 ] || [ "$p" = 443 ] && continue
      echo "$p"; return
    fi
  done
}
live_web_port(){ ss -ltn 2>/dev/null | awk '/LISTEN/ {print $4}' | sed -E 's/^.*:([0-9]+)$/\1/' | awk '$1>=8000&&$1<=8099{print;exit}' || true; }
display_port(){
  local p=""
  p="$(normalize_config_port "$(raw_web_port)")"
  [[ "$p" =~ ^[0-9]+$ ]] && { echo "$p"; return; }
  p="$(live_web_port | head -n1 || true)"
  [[ "$p" =~ ^[0-9]+$ ]] && { echo "$p"; return; }
  pihole_installed && settings_port || echo ""
}
versions_safe(){
  local out="" cache="$CFGDIR/versions.cache" piholecmd="$(pihole_bin)" ftl="$(ftl_bin)" c=""
  [ -f /etc/pihole/versions ] && out="$(awk -F= '/^(CORE|WEB|FTL)_VERSION=/{print}' /etc/pihole/versions 2>/dev/null | tr '\n' ';' | json_escape)"
  if [ -z "$out" ] && [ -n "$piholecmd" ]; then
    out="$($piholecmd -v 2>/dev/null | awk 'BEGIN{IGNORECASE=1}/Core version is/{for(i=1;i<=NF;i++)if($i~/^v[0-9]/){print "CORE_VERSION="$i;break}}/Web version is/{for(i=1;i<=NF;i++)if($i~/^v[0-9]/){print "WEB_VERSION="$i;break}}/FTL version is/{for(i=1;i<=NF;i++)if($i~/^v[0-9]/){print "FTL_VERSION="$i;break}}' | tr '\n' ';' | json_escape)"
  fi
  if [ -n "$out" ] && [ -f "$cache" ]; then
    c="$(cat "$cache")"
    echo "$out" | grep -q CORE_VERSION= || out="$(echo "$c" | tr ';' '\n' | grep '^CORE_VERSION=' | tail -n1 | tr '\n' ';')$out"
    echo "$out" | grep -q WEB_VERSION= || out="$(echo "$c" | tr ';' '\n' | grep '^WEB_VERSION=' | tail -n1 | tr '\n' ';')$out"
  fi
  [ -z "$out" ] && [ -n "$ftl" ] && out="FTL_VERSION=$($ftl -v 2>/dev/null | grep -oE 'v[0-9]+(\.[0-9]+)+' | head -n1 | json_escape)"
  [ -n "$out" ] && { echo "$out" > "$cache"; echo "$out"; return; }
  [ -f "$cache" ] && cat "$cache" || echo ""
}
initial_password_value(){ local f="$DATADIR/install/initial_web_password.txt"; [ -f "$f" ] && head -n1 "$f" | json_escape || echo ""; }
gravity_status(){ [ -s /etc/pihole/gravity.db ] && echo true && return; [ -s /etc/pihole/gravity_old.db ] && echo true && return; [ -f /etc/pihole/adlists.list ] && grep -Ev '^\s*(#|$)' /etc/pihole/adlists.list >/dev/null 2>&1 && echo true || echo false; }

dhcp_pxe_conf_present(){ grep -R -E '^\s*(dhcp-range|dhcp-boot|pxe-service)=' "$DNSMASQ_DIR"/*.conf 2>/dev/null | grep -vq "^$LEASE_CONF:"; }
lease_conf_ok(){ grep -R -E '^\s*dhcp-leasefile=/etc/pihole/dhcp\.leases\s*$' "$DNSMASQ_DIR" /etc/pihole/dnsmasq.conf 2>/dev/null | grep -q . && [ -f "$LEASE_FILE" ] && [ -w "$LEASE_FILE" ]; }
leasefile_writable_by_pihole(){
  local f="${1:-}"
  [ -n "$f" ] && [ -f "$f" ] || return 1
  if cmd_exists runuser; then
    runuser -u pihole -- test -w "$f" 2>/dev/null
  elif cmd_exists sudo; then
    sudo -u pihole test -w "$f" 2>/dev/null
  else
    [ -w "$f" ]
  fi
}
default_leasefile_ok(){ leasefile_writable_by_pihole /var/lib/misc/dnsmasq.leases; }
any_leasefile_ok(){ lease_conf_ok || default_leasefile_ok; }
ensure_leasefile_conf(){
  need_root
  mkdir -p "$DNSMASQ_DIR" /etc/pihole
  cat > "$LEASE_CONF" <<EOF
# Pi-hole Manager: lease file for embedded dnsmasq running as user pihole.
# Required when /etc/dnsmasq.d contains DHCP/PXE directives like dhcp-range, dhcp-boot or pxe-service.
dhcp-leasefile=$LEASE_FILE
EOF
  touch "$LEASE_FILE"
  chown pihole:pihole "$LEASE_FILE" 2>/dev/null || chown pihole "$LEASE_FILE" 2>/dev/null || true
  chmod 0644 "$LEASE_FILE"
}
ensure_leasefile_if_needed(){ if [ -d "$DNSMASQ_DIR" ] && dhcp_pxe_conf_present; then ensure_leasefile_conf; fi; }

status(){
  local installed=false active=false enabled=false pid="" port="" live="" raw="" target="" dhcp="" dnsmasqd="" versions="" blocking="" initpw="" gravity=false
  local dnsmasq_s=false dnsmasq_e=false port53="" localdns=false conflict=false preinstall_blocker=false lease_ok=false dhcp_pxe=false ftl="$(ftl_bin)" piholecmd="$(pihole_bin)"
  pihole_installed && installed=true
  installer_pid_alive && installed=false
  ftl_active && active=true
  ftl_enabled && enabled=true
  dnsmasq_active && dnsmasq_s=true
  dnsmasq_enabled && dnsmasq_e=true
  local_dns_works && localdns=true
  port53="$(port53_processes | json_escape | tr '\n' ';')"
  if [ "$installed" = true ] && port53_has_dnsmasq && ! port53_has_ftl; then conflict=true; fi
  if [ "$installed" = true ] && port53_has_dnsmasq && port53_has_ftl; then conflict=true; fi
  if [ "$installed" != true ] && [ "$dnsmasq_s" = true ]; then preinstall_blocker=true; fi
  dhcp_pxe_conf_present && dhcp_pxe=true
  any_leasefile_ok && lease_ok=true
  target="$(settings_port)"
  if [ "$installed" = true ]; then
    pid="$(ftl_pid)"; port="$(display_port)"; [[ "$port" =~ ^[0-9]+$ ]] && target="$port"
    live="$(live_web_port | head -n1 || true)"; raw="$(raw_web_port)"
    [ -n "$ftl" ] && dhcp="$($ftl --config dhcp.active 2>/dev/null | tail -n1)" || true
    [ -n "$ftl" ] && dnsmasqd="$($ftl --config misc.etc_dnsmasq_d 2>/dev/null | tail -n1)" || true
    versions="$(versions_safe)"
    [ -n "$piholecmd" ] && blocking="$($piholecmd status 2>/dev/null | grep -qi 'blocking is enabled' && echo true || echo false)" || blocking=""
    initpw="$(initial_password_value)"; gravity="$(gravity_status)"
  fi
  cat <<JSON
{"pihole_installed":"$installed","pihole_ftl_active":"$active","pihole_ftl_enabled":"$enabled","pihole_ftl_pid":"$pid","web_port":"$port","target_web_port":"$target","live_web_port":"$live","raw_web_port":"$raw","dhcp_active":"$dhcp","etc_dnsmasq_d":"$dnsmasqd","versions":"$versions","blocking_enabled":"$blocking","initial_password":"$initpw","gravity_list_present":"$gravity","dnsmasq_active":"$dnsmasq_s","dnsmasq_enabled":"$dnsmasq_e","port53_conflict":"$conflict","dnsmasq_preinstall_blocker":"$preinstall_blocker","local_dns_works":"$localdns","port53_processes":"$port53","dhcp_pxe_conf_present":"$dhcp_pxe","lease_conf_ok":"$lease_ok","ftl_bin":"$(echo "$ftl" | json_escape)","pihole_bin":"$(echo "$piholecmd" | json_escape)"}
JSON
}
install_state(){
  local state=not_started msg="Not started yet" installed=false active=false web_active=false exitcode="" port="" initpw=""
  port="$(display_port)"; initpw="$(initial_password_value)"
  pihole_installed && installed=true
  installer_pid_alive && installed=false
  ftl_active && active=true
  [[ "$port" =~ ^[0-9]+$ ]] && web_active=true
  exitcode="$(grep -hE 'Installer exit code:' "$LOG" 2>/dev/null | tail -n1 | sed -E 's/.*Installer exit code: *([0-9]+).*/\1/' || true)"
  if installer_pid_alive; then state=running; msg="Installation is still running"; elif [ "$installed" = true ] && [ "$web_active" = true ] && [ "$exitcode" = 0 ]; then state=success; msg="Installation completed successfully"; elif [ "$installed" = true ]; then state=partial; msg="Pi-hole is present; please check healthcheck"; elif [ -f "$LOG" ]; then state=failed; msg="Installation did not complete successfully"; fi
  cat <<JSON
{"state":"$state","message":"$(echo "$msg" | json_escape)","installed":"$installed","active":"$active","web_active":"$web_active","port":"$port","exitcode":"$exitcode","initial_password":"$initpw"}
JSON
}
backup(){
  need_root
  local name="${1:-manual}" dest=""
  dest="$DATADIR/backups/$(date '+%Y%m%d_%H%M%S')_${name}"
  mkdir -p "$dest"
  [ -f /etc/pihole/pihole.toml ] && cp -a /etc/pihole/pihole.toml "$dest/" || true
  [ -d "$DNSMASQ_DIR" ] && cp -a "$DNSMASQ_DIR" "$dest/dnsmasq.d" || true
  ss -tulpn > "$dest/ports.txt" 2>&1 || true
  echo "$dest"
}
restart_check_dns(){ sleep 2; if port53_has_ftl && local_dns_works; then echo "DNS check OK: pihole-FTL listens on port 53 and @127.0.0.1 resolves."; else echo "WARNING: pihole-FTL DNS check failed. Check healthcheck output."; fi; }
set_port(){ need_root; local p="$1" ftl="$(ftl_bin)"; [[ "$p" =~ ^[0-9]+$ ]] || { echo "ERROR: invalid port"; exit 2; }; [ -n "$ftl" ] || { echo "ERROR: pihole-FTL binary not found. Pi-hole service/path broken."; exit 3; }; backup "before_set_port_${p}" >/dev/null; ensure_leasefile_if_needed; "$ftl" --config webserver.port "$p" >/dev/null 2>&1 || true; save_settings_port "$p"; systemctl restart pihole-FTL >/dev/null 2>&1 || true; for i in $(seq 1 8); do [ "$(display_port)" = "$p" ] && break; sleep 1; done; echo "Pi-hole web port set to $(display_port)"; restart_check_dns; }
enable_dnsmasq_d(){ need_root; local ftl="$(ftl_bin)"; [ -n "$ftl" ] || { echo "ERROR: pihole-FTL binary not found"; exit 3; }; ensure_leasefile_if_needed; "$ftl" --config misc.etc_dnsmasq_d true >/dev/null 2>&1 || true; systemctl restart pihole-FTL >/dev/null 2>&1 || true; echo "misc.etc_dnsmasq_d enabled"; restart_check_dns; }
syntax_test(){ local ftl="$(ftl_bin)"; [ -n "$ftl" ] || { echo "ERROR: pihole-FTL binary not found"; return 1; }; "$ftl" dnsmasq-test 2>&1; }
restart_ftl(){ need_root; ensure_leasefile_if_needed; systemctl restart pihole-FTL >/dev/null 2>&1 || true; sleep 1; echo "pihole-FTL restarted, PID $(ftl_pid)"; restart_check_dns; }
healthcheck(){
  local port="$(display_port)" pid="$(ftl_pid)" outfile="$HEALTHLOG" rc_dns=0 dnsmasq_d="" ftl="$(ftl_bin)"
  [ -n "$ftl" ] && dnsmasq_d="$($ftl --config misc.etc_dnsmasq_d 2>/dev/null | tail -n1)" || true
  {
    echo "<INFO> Pi-hole Manager Healthcheck $(date -Is)"
    pihole_installed && echo "✅ Pi-hole present" || echo "❌ Pi-hole not installed/detected"
    ftl_active && echo "✅ pihole-FTL active, PID ${pid:-unknown}" || echo "❌ pihole-FTL not active"
    [ -n "$ftl" ] && echo "✅ pihole-FTL Binary: $ftl" || echo "❌ pihole-FTL binary not found"
    [ -n "$(pihole_bin)" ] && echo "✅ pihole Binary: $(pihole_bin)" || echo "⚠️ pihole binary not found"
    [ -n "$port" ] && echo "✅ Web port detected: $port" || echo "⚠️ Web port not detected"
    [ "$dnsmasq_d" = true ] && echo "✅ dnsmasq.d enabled" || echo "⚠️ dnsmasq.d disabled or not checkable"
    if dnsmasq_active; then echo "⚠️ dnsmasq.service is active"; else echo "✅ dnsmasq.service is not active"; fi
    if dnsmasq_enabled; then echo "⚠️ dnsmasq.service is enabled"; else echo "✅ dnsmasq.service is not enabled or is masked"; fi
    if dhcp_pxe_conf_present; then
      echo "ℹ️ DHCP/PXE configuration detected in /etc/dnsmasq.d"
      if lease_conf_ok; then
        echo "✅ Pi-hole Manager leasefile configuration OK"
      elif default_leasefile_ok; then
        echo "✅ Standard dnsmasq leasefile /var/lib/misc/dnsmasq.leases is writable by pihole"
      elif port53_has_ftl && local_dns_works; then
        echo "⚠️ No Pi-hole Manager leasefile found, but DNS is currently running through pihole-FTL"
      else
        echo "❌ No writable DHCP leasefile found"
      fi
    fi
    echo "<INFO> Port 53 processes:"; port53_processes || true
    if pihole_installed; then
      if port53_has_dnsmasq && ! port53_has_ftl; then echo "❌ Port 53 conflict: dnsmasq occupies port 53, pihole-FTL does not"; fi
      if port53_has_dnsmasq && port53_has_ftl; then echo "❌ Port 53 conflict: dnsmasq and pihole-FTL detected on port 53"; fi
      if port53_has_ftl && ! port53_has_dnsmasq; then echo "✅ Port 53 is provided by pihole-FTL"; fi
    else
      if dnsmasq_active; then echo "⚠️ Before Pi-hole installation, dnsmasq.service occupies port 53. The installer temporarily disables dnsmasq."; fi
    fi
    if local_dns_works; then echo "✅ Local DNS test @127.0.0.1 successful"; else echo "❌ Local DNS test @127.0.0.1 failed"; fi
    if cmd_exists resolvconf; then echo "<INFO> resolvconf sources:"; resolvconf -l 2>/dev/null || true; fi
    if pihole_installed && [ -n "$ftl" ]; then if syntax_test >/tmp/phm_syntax_$$.log 2>&1; then echo "✅ dnsmasq syntax check successful"; else rc_dns=$?; echo "❌ dnsmasq syntax check failed"; cat /tmp/phm_syntax_$$.log; fi; else echo "⚠️ dnsmasq syntax check skipped because pihole-FTL is not present yet"; fi
    journalctl -u pihole-FTL -n 40 --no-pager -l 2>/dev/null | grep -q 'cannot open or create lease file' && echo "❌ Latest pihole-FTL log contains leasefile error"
    rm -f /tmp/phm_syntax_$$.log
    echo "<OK> Healthcheck finished"
  } | tee "$outfile"
  return "$rc_dns"
}
set_password_file(){ need_root; local f="$1" pass="" cmd="$(pihole_bin)"; [ -f "$f" ] || { echo "ERROR: password file missing"; exit 2; }; pass="$(head -n1 "$f")"; rm -f "$f" 2>/dev/null || true; [ -n "$pass" ] || { echo "ERROR: password is empty"; exit 3; }; [ -n "$cmd" ] || { echo "ERROR: pihole command not installed"; exit 4; }; if "$cmd" setpassword "$pass" >/dev/null 2>&1 || "$cmd" -a -p "$pass" >/dev/null 2>&1; then echo "Pi-hole password changed."; else echo "ERROR: Could not change Pi-hole password."; exit 5; fi; }
write_template(){ need_root; mkdir -p "$DNSMASQ_DIR"; backup before_custom_dns_template >/dev/null; cp "$TEMPLATEDIR/custom-dns.conf" "$DNSMASQ_DIR/99-custom-dns.conf"; chmod 0644 "$DNSMASQ_DIR/99-custom-dns.conf"; ensure_leasefile_if_needed; echo "$DNSMASQ_DIR/99-custom-dns.conf"; }
list_confs(){ [ -d "$DNSMASQ_DIR" ] && find "$DNSMASQ_DIR" -maxdepth 1 -name '*.conf' -printf '%f\n' | sort || true; }
read_conf(){ local f="$1"; valid_conf "$f" || { echo "ERROR: invalid filename"; exit 2; }; [ -f "$DNSMASQ_DIR/$f" ] && cat "$DNSMASQ_DIR/$f" || { echo "ERROR: file not found"; exit 1; }; }
write_conf(){ need_root; local f="$1" tmp="$2"; valid_conf "$f" || { echo "ERROR: invalid filename"; exit 2; }; protected_conf "$f" && { echo "ERROR: $f is a protected system/plugin file and will not be overwritten."; exit 6; }; [ -f "$tmp" ] || { echo "ERROR: temp file missing"; exit 3; }; mkdir -p "$DNSMASQ_DIR"; backup "before_write_${f}" >/dev/null; cp "$tmp" "$DNSMASQ_DIR/$f"; chmod 0644 "$DNSMASQ_DIR/$f"; ensure_leasefile_if_needed; echo "$DNSMASQ_DIR/$f"; }
delete_conf(){ need_root; local f="$1"; valid_conf "$f" || { echo "ERROR: invalid filename"; exit 2; }; protected_conf "$f" && { echo "ERROR: $f is a protected system/plugin file and will not be deleted."; exit 6; }; [ -f "$DNSMASQ_DIR/$f" ] || { echo "ERROR: file not found"; exit 1; }; backup "before_delete_${f}" >/dev/null; rm -f "$DNSMASQ_DIR/$f"; ensure_leasefile_if_needed; echo "deleted $f"; }
action_log_run(){ need_root; local sub="${1:-}"; shift || true; mkdir -p "$LOGDIR"; echo "<INFO> $(date -Is) START $sub $*" >> "$ACTIONLOG"; local out rc; out="$($0 "$sub" "$@" 2>&1)"; rc=$?; echo "$out" >> "$ACTIONLOG"; [ "$rc" -eq 0 ] && echo "<OK> $(date -Is) DONE $sub" >> "$ACTIONLOG" || echo "<ERROR> $(date -Is) FAILED $sub rc=$rc" >> "$ACTIONLOG"; echo "$out"; return "$rc"; }
detect_resolvconf_dns(){ local i="${1:-eth0}"; [ -f "/run/resolvconf/interfaces/$i" ] && awk '/^nameserver /{print $2}' "/run/resolvconf/interfaces/$i" | grep -Ev '^(127\.|::1$|0\.0\.0\.0$)' | head -n1 && return; resolvconf -l 2>/dev/null | awk '/^nameserver /{print $2}' | grep -Ev '^(127\.|::1$|0\.0\.0\.0$)' | head -n1; }
apply_guard(){ local dns1="$1" dom="$2"; if cmd_exists resolvconf; then resolvconf -d lo.dnsmasq 2>/dev/null || true; { [ -n "$dom" ] && echo "domain $dom"; echo "nameserver $dns1"; echo "nameserver 1.1.1.1"; } | resolvconf -a piholemanager.inet 2>/dev/null || true; resolvconf -u 2>/dev/null || true; fi; }
cleanup_guard(){ if cmd_exists resolvconf; then resolvconf -d piholemanager.inet 2>/dev/null || true; resolvconf -u 2>/dev/null || true; fi; }
prepare_dnsmasq_for_install(){ need_root; local state="$DATADIR/install/dnsmasq_preinstall_state.txt"; mkdir -p "$DATADIR/install"; { echo "date=$(date -Is)"; echo "active=$(systemctl is-active dnsmasq 2>/dev/null || true)"; echo "enabled=$(systemctl is-enabled dnsmasq 2>/dev/null || true)"; } > "$state" 2>/dev/null || true; if dnsmasq_active || dnsmasq_enabled; then echo "<INFO> dnsmasq.service occupies/claims port 53 and will be disabled for Pi-hole installation. State saved: $state"; systemctl stop dnsmasq >/dev/null 2>&1 || true; systemctl disable dnsmasq >/dev/null 2>&1 || true; systemctl mask dnsmasq >/dev/null 2>&1 || true; fi; if cmd_exists resolvconf; then resolvconf -d lo.dnsmasq 2>/dev/null || true; resolvconf -u 2>/dev/null || true; fi; }
install_start(){ need_root; pihole_installed && { echo "ABORT: Pi-hole is already present. Installation will not be started again."; echo "Please use healthcheck if you want to verify the current state."; exit 7; }; local port="${1:-8000}" dir="$DATADIR/install" pidfile iface ip4 router dns1 dom passfile; save_settings_port "$port"; mkdir -p "$dir" /etc/pihole; echo "$(date -Is)" > "$dir/install_started_by_piholemanager"; pidfile="$dir/install.pid"; passfile="$dir/initial_web_password.txt"; installer_pid_alive && { echo "Installation already running, pid=$(cat "$pidfile")"; exit 0; }; iface="$(ip route show default 2>/dev/null | awk '{print $5;exit}')"; [ -n "$iface" ] || iface=eth0; ip4="$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet /{print $2;exit}')"; router="$(ip route show default 2>/dev/null | awk '{print $3;exit}')"; [ -n "$router" ] || router=1.1.1.1; dns1="$(detect_resolvconf_dns "$iface")"; [ -n "$dns1" ] || dns1="$router"; dom="$(awk '/^domain /{print $2;exit}' /etc/resolv.conf 2>/dev/null)"; prepare_dnsmasq_for_install; apply_guard "$dns1" "$dom"; cat > /etc/pihole/setupVars.conf <<VARS
PIHOLE_INTERFACE=$iface
IPV4_ADDRESS=$ip4
QUERY_LOGGING=true
INSTALL_WEB_INTERFACE=true
INSTALL_WEB_SERVER=false
LIGHTTPD_ENABLED=false
PIHOLE_DNS_1=$dns1
PIHOLE_DNS_2=1.1.1.1
DNSMASQ_LISTENING=local
BLOCKING_ENABLED=true
WEB_PORTS=$port
VARS
cat > "$dir/install_runner.sh" <<'RUNNER'
#!/usr/bin/env bash
set -o pipefail
LOG="$1"; PORT="$2"; PASSFILE="$3"
exec >> "$LOG" 2>&1
echo "=== Pi-hole Manager installation started $(date -Is) ==="
timeout 3600 bash -c 'curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended'
rc=$?; echo "Installer exit code: $rc"
if command -v pihole-FTL >/dev/null 2>&1; then
  mkdir -p /etc/dnsmasq.d /etc/pihole
  cat > /etc/dnsmasq.d/00-piholemanager-leasefile.conf <<EOF
# Pi-hole Manager: lease file for embedded dnsmasq running as user pihole.
dhcp-leasefile=/etc/pihole/dhcp.leases
EOF
  touch /etc/pihole/dhcp.leases; chown pihole:pihole /etc/pihole/dhcp.leases 2>/dev/null || true; chmod 0644 /etc/pihole/dhcp.leases
  pihole-FTL --config webserver.port "$PORT" >/dev/null 2>&1 || true
  pihole-FTL --config misc.etc_dnsmasq_d true >/dev/null 2>&1 || true
  systemctl restart pihole-FTL >/dev/null 2>&1 || true
fi
if command -v pihole >/dev/null 2>&1; then PASS="$(openssl rand -base64 18 2>/dev/null || date +%s-pihole)"; (pihole setpassword "$PASS" >/dev/null 2>&1 || pihole -a -p "$PASS" >/dev/null 2>&1) && { umask 077; echo "$PASS" > "$PASSFILE"; echo "Initial Pi-hole web password saved to: $PASSFILE"; }; fi
command -v resolvconf >/dev/null 2>&1 && { resolvconf -d piholemanager.inet 2>/dev/null || true; resolvconf -u 2>/dev/null || true; }
echo "=== Pi-hole Manager installation ended $(date -Is) ==="
RUNNER
chmod 700 "$dir/install_runner.sh"; : > "$LOG"; nohup "$dir/install_runner.sh" "$LOG" "$port" "$passfile" >/dev/null 2>&1 & echo $! > "$pidfile"; echo "Installation started in background, pid=$(cat "$pidfile")"; echo "Log: $LOG"; }
install_status(){ [ -f "$LOG" ] && tail -n160 "$LOG" || true; }
case "${1:-status}" in
  status) status;; install-state) install_state;; action-run) action_log_run "${2:-}" "${@:3}";; backup) backup "${2:-manual}";; set-port) set_port "${2:?port required}";; enable-dnsmasq-d) enable_dnsmasq_d;; syntax-test) syntax_test;; restart-ftl) restart_ftl;; healthcheck) healthcheck;; set-password-file) set_password_file "${2:?password file required}";; write-template) write_template;; list-confs) list_confs;; read-conf) read_conf "${2:?file required}";; write-conf) write_conf "${2:?file required}" "${3:?tmp required}";; delete-conf) delete_conf "${2:?file required}";; cleanup-guard) cleanup_guard;; install-start) install_start "${2:-8000}";; install-status) install_status;; *) echo "Usage: $0 status|install-state|action-run|backup|set-port|enable-dnsmasq-d|syntax-test|restart-ftl|healthcheck|set-password-file|write-template|list-confs|read-conf|write-conf|delete-conf|cleanup-guard|install-start|install-status"; exit 1;;
esac
