<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Benutzung

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-DE-blue?style=for-the-badge)

[Übersicht](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Benutzung](USAGE.md) · [Struktur](STRUCTURE.md) · [Fehlerbehebung](TROUBLESHOOTING.md)

</div>

---

[← Zurück zur deutschen Übersicht](README.md)

## Statuskarten

Die Weboberfläche zeigt:

- Pi-hole Installationsstatus
- pihole-FTL Status und PID
- Pi-hole Versionen
- Web-Port
- DHCP-Status
- dnsmasq.d Status
- Gravity-Status

## Aktionen

Die Aktionen umfassen:

- Pi-hole/dnsmasq Konfiguration sichern
- Healthcheck ausführen
- `/etc/dnsmasq.d` aktivieren
- pihole-FTL neu starten

## dnsmasq.d Editor

Konfigurationsdateien können angezeigt, bearbeitet, hochgeladen oder aus einer Vorlage erstellt werden. Geschützte System- und Plugin-Dateien werden nicht überschrieben oder gelöscht.

## DHCP/PXE

Wenn DHCP/PXE-Direktiven erkannt werden, prüft der Healthcheck, ob ein nutzbares Leasefile vorhanden ist.


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager für LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
