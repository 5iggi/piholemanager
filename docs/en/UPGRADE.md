<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Upgrade

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-EN-blue?style=for-the-badge)

[Overview](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Usage](USAGE.md) · [Structure](STRUCTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

---

[← Back to English overview](README.md)

## Upgrade hooks

The plugin includes:

```text
preupgrade.sh
postupgrade.sh
```

## preupgrade.sh

The hook stores existing plugin configuration, plugin data and plugin logs in:

```text
/tmp/piholemanager_upgrade_<timestamp>
```

## postupgrade.sh

The hook restores missing files without overwriting existing files, refreshes permissions and ensures log files and template folders exist.

## Not changed by plugin upgrades

The plugin upgrade does not directly modify Pi-hole system data:

```text
/etc/pihole
/etc/dnsmasq.d
/var/lib/misc/dnsmasq.leases
/etc/pihole/dhcp.leases
```


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager for LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
