<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Installation

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-DE-blue?style=for-the-badge)

[Übersicht](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Benutzung](USAGE.md) · [Struktur](STRUCTURE.md) · [Fehlerbehebung](TROUBLESHOOTING.md)

</div>

---

[← Zurück zur deutschen Übersicht](README.md)

## Voraussetzungen

- LoxBerry 3 oder neuer
- Internetzugang während der Pi-hole Installation
- Rechtefreigabe über die LoxBerry sudoers-Integration des Plugins

## Plugin installieren

1. Release-ZIP herunterladen.
2. ZIP über die LoxBerry Plugin-Verwaltung installieren.
3. Plugin im LoxBerry Webinterface öffnen.
4. Falls Pi-hole noch nicht installiert ist, die Installation über die Plugin-Oberfläche starten.

## Nach der Installation

Den Healthcheck ausführen. Ein gesunder Zustand zeigt unter anderem:

- Pi-hole vorhanden
- pihole-FTL aktiv
- Port 53 wird von pihole-FTL bereitgestellt
- lokaler DNS-Test erfolgreich
- dnsmasq Syntaxprüfung erfolgreich


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager für LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
