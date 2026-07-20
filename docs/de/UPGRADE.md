<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Upgrade

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-DE-blue?style=for-the-badge)

[Übersicht](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Benutzung](USAGE.md) · [Struktur](STRUCTURE.md) · [Fehlerbehebung](TROUBLESHOOTING.md)

</div>

---

[← Zurück zur deutschen Übersicht](README.md)

## Upgrade-Hooks

Das Plugin enthält:

```text
preupgrade.sh
postupgrade.sh
```

## preupgrade.sh

Der Hook sichert vorhandene Plugin-Konfiguration, Plugin-Daten und Plugin-Logs temporär nach:

```text
/tmp/piholemanager_upgrade_<timestamp>
```

## postupgrade.sh

Der Hook stellt fehlende Dateien wieder her, überschreibt vorhandene Dateien nicht, setzt Rechte und legt Logdateien sowie Template-Ordner wieder an.

## Nicht verändert durch ein Plugin-Upgrade

Das Plugin-Upgrade ändert keine Pi-hole-Systemdaten direkt:

```text
/etc/pihole
/etc/dnsmasq.d
/var/lib/misc/dnsmasq.leases
/etc/pihole/dhcp.leases
```


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager für LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
