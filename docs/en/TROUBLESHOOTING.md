<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Troubleshooting

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-EN-blue?style=for-the-badge)

[Overview](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Usage](USAGE.md) · [Structure](STRUCTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

---

[← Back to English overview](README.md)

## Run healthcheck manually

```bash
sudo -n /opt/loxberry/bin/plugins/piholemanager/piholemanager.sh healthcheck
```

## Check Port 53

```bash
sudo ss -ltnup | grep ':53'
systemctl status pihole-FTL
systemctl status dnsmasq
```

## Check DHCP/PXE leasefile

```bash
sudo grep -R -nE '^[[:space:]]*(dhcp-range|dhcp-boot|pxe-service|dhcp-leasefile)=' /etc/dnsmasq.d /etc/pihole/dnsmasq.conf 2>/dev/null
sudo -u pihole test -w /var/lib/misc/dnsmasq.leases && echo writable
sudo -u pihole test -w /etc/pihole/dhcp.leases && echo writable
```

## Plugin logs

```text
/opt/loxberry/log/plugins/piholemanager/install.log
/opt/loxberry/log/plugins/piholemanager/actions.log
/opt/loxberry/log/plugins/piholemanager/healthcheck.log
```


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager for LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
