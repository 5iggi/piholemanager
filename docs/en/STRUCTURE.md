<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# File and folder structure

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-EN-blue?style=for-the-badge)

[Overview](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Usage](USAGE.md) · [Structure](STRUCTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

---

[← Back to English overview](README.md)

## Repository structure

```text
plugin.cfg                         LoxBerry plugin metadata
release.cfg                        Autoupdate information for stable releases
prerelease.cfg                     Autoupdate information for prereleases
preinstall.sh                      Hook before plugin installation
postinstall.sh                     Hook after plugin installation
preupgrade.sh                      Hook before plugin upgrade
postupgrade.sh                     Hook after plugin upgrade
postroot.sh                        Root hook, creates sudoers entry
preremove.sh                       Hook before plugin removal
uninstall.sh                       Hook during plugin uninstallation
bin/piholemanager.sh               Root helper for Pi-hole, DNS, backups and health checks
webfrontend/htmlauth/index.php     PHP Web UI
webfrontend/htmlauth/index.cgi     Redirect to index.php
webfrontend/html/css/...           Plugin CSS with LoxBerry styling
templates/main.html                HTML template for the Web UI
templates/lang/language_de.ini     German language file
templates/lang/language_en.ini     English language file
templates/dnsmasq_templates/...    Templates for dnsmasq.d files
icons/                             Plugin icons
```

## Runtime paths on LoxBerry

```text
/opt/loxberry/config/plugins/piholemanager    Plugin configuration
/opt/loxberry/data/plugins/piholemanager      Plugin data, backups and installation data
/opt/loxberry/log/plugins/piholemanager       Plugin logs
```

## Pi-hole system paths

Pi-hole stays natively installed and uses its own system paths:

```text
/etc/pihole
/etc/dnsmasq.d
/opt/pihole
/var/log/pihole
```


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager for LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
