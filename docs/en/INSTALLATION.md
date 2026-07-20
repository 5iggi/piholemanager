<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="80" height="80">

# Installation

[![Release](https://img.shields.io/github/v/release/5iggi/piholemanager?style=for-the-badge&label=Release)](https://github.com/5iggi/piholemanager/releases)
![LoxBerry](https://img.shields.io/badge/LoxBerry-3%2B%20%2F%204-green?style=for-the-badge)
![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-red?style=for-the-badge)
![Docs](https://img.shields.io/badge/Docs-EN-blue?style=for-the-badge)

[Overview](README.md) · [Installation](INSTALLATION.md) · [Upgrade](UPGRADE.md) · [Usage](USAGE.md) · [Structure](STRUCTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

</div>

---

[← Back to English overview](README.md)

## Requirements

- LoxBerry 3 or newer
- Internet access during Pi-hole installation
- Plugin sudoers permissions through the LoxBerry root hook

## Install the plugin

1. Download the release ZIP.
2. Install the ZIP through the LoxBerry plugin management.
3. Open the plugin in the LoxBerry Web UI.
4. If Pi-hole is not installed yet, start the installation from the plugin UI.

## After installation

Run the healthcheck. A healthy state includes:

- Pi-hole present
- pihole-FTL active
- Port 53 is provided by pihole-FTL
- local DNS test successful
- dnsmasq syntax check successful


---

<div align="center">
  <img src="../../icons/icon.svg" alt="Pi-hole Manager Logo" width="36" height="36"><br>
  <sub>Pi-hole Manager for LoxBerry · Maintained by </sub><a href="https://github.com/5iggi">5iggi</a>
</div>
