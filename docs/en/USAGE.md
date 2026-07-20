<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Usage

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-EN-blue?style=for-the-badge)

[Overview](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Usage](USAGE.md) · [Structure](STRUCTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

---

[← Back to English overview](README.md)

## Status cards

The Web UI shows:

- Pi-hole installation state
- pihole-FTL state and PID
- Pi-hole versions
- web port
- DHCP state
- dnsmasq.d state
- Gravity state

## Actions

Available actions include:

- back up Pi-hole/dnsmasq configuration
- run healthcheck
- enable `/etc/dnsmasq.d`
- restart pihole-FTL

## dnsmasq.d editor

Configuration files can be viewed, edited, uploaded or created from a template. Protected system and plugin files cannot be overwritten or deleted.

## DHCP/PXE

When DHCP/PXE directives are detected, the healthcheck verifies whether a usable leasefile is available.


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager for LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
