<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Datei- und Ordnerstruktur

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-DE-blue?style=for-the-badge)

[Übersicht](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Benutzung](USAGE.md) · [Struktur](STRUCTURE.md) · [Fehlerbehebung](TROUBLESHOOTING.md)

</div>

---

[← Zurück zur deutschen Übersicht](README.md)

## Projektstruktur im Repository

```text
plugin.cfg                         Plugin-Metadaten für LoxBerry
release.cfg                        Autoupdate-Information für stabile Releases
prerelease.cfg                     Autoupdate-Information für Vorabversionen
preinstall.sh                      Hook vor Plugin-Installation
postinstall.sh                     Hook nach Plugin-Installation
preupgrade.sh                      Hook vor Plugin-Upgrade
postupgrade.sh                     Hook nach Plugin-Upgrade
postroot.sh                        Root-Hook, richtet sudoers ein
preremove.sh                       Hook vor Plugin-Entfernung
uninstall.sh                       Hook bei Plugin-Deinstallation
bin/piholemanager.sh               Root-Helper für Pi-hole, DNS, Backups und Healthchecks
webfrontend/htmlauth/index.php     PHP-Webfrontend des Plugins
webfrontend/htmlauth/index.cgi     Weiterleitung auf index.php
webfrontend/html/css/...           Plugin-CSS im LoxBerry Stil
templates/main.html                HTML-Template für das Webfrontend
templates/lang/language_de.ini     Deutsche Sprachdatei
templates/lang/language_en.ini     Englische Sprachdatei
templates/dnsmasq_templates/...    Vorlagen für dnsmasq.d Dateien
icons/                             Plugin-Icons
```

## Laufzeitpfade auf LoxBerry

```text
/opt/loxberry/config/plugins/piholemanager    Plugin-Konfiguration
/opt/loxberry/data/plugins/piholemanager      Plugin-Daten, Backups und Installationsdaten
/opt/loxberry/log/plugins/piholemanager       Plugin-Logs
```

## Pi-hole Systempfade

Pi-hole bleibt nativ installiert und nutzt eigene Systempfade:

```text
/etc/pihole
/etc/dnsmasq.d
/opt/pihole
/var/log/pihole
```


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager für LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
