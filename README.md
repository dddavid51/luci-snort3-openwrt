# LuCI Snort3 Module for OpenWrt

[English](#english) | [Français](#français)

---

## English

### 📋 Description

Complete LuCI web interface module for Snort3 IDS/IPS on OpenWrt. This module provides an intuitive web interface to configure, monitor, and manage Snort3 directly from your OpenWrt router's LuCI interface.

### ✨ Features

- **Real-time Status Dashboard**
  - Service status (running/stopped)
  - Process ID and memory usage
  - System memory monitoring
  - Alert counter
  - Network interface monitoring

- **Complete Configuration Interface**
  - Network interface selection
  - Operating mode (IDS/IPS)
  - DAQ method configuration
  - Rule management
  - Custom Snort configuration

- **Alert Management**
  - View recent alerts (last 50)
  - System log monitoring
  - Auto-refresh every 5 seconds
  - Alert statistics

- **Service Controls**
  - Start/Stop/Restart Snort
  - Enable/Disable auto-start
  - Rules update with progress monitoring
  - Symbolic link management for rules

- **Bilingual Interface**
  - Full French support
  - Full English support

#---

## 📖 Project History & Motivation

### The Problem

When Snort3 was initially available on OpenWrt, there was **no web interface** to manage it. Users had to:
- Configure everything via command line
- Edit configuration files manually through SSH
- Monitor alerts by tailing log files
- Restart the service using init scripts

This made Snort3 **difficult to use** for most OpenWrt users, especially those not comfortable with command-line tools.

### The Solution Evolution

**Version 0.5 (CGI Interface)** - *First Attempt (Early 2025)*
- Created a simple CGI script for basic web management
- Provided start/stop/restart controls
- Displayed alerts and system status
- Lightweight and **useful as a temporary solution**
- But lacked proper integration with OpenWrt
- See [legacy/v0-cgi-interface](legacy/v0-cgi-interface) for the original version

**Version 3.0+ (Full LuCI Module)** - *Preferred Solution (2025)*
- Complete integration with OpenWrt's LuCI framework
- **Proper integration with the OpenWrt ecosystem**
- UCI-based configuration system
- Advanced features (rules management, real-time monitoring)
- Bilingual support (French/English)
- Professional interface following LuCI standards

### Why This Project Matters

This module fills a **critical gap** in the OpenWrt ecosystem by making Snort3 accessible to everyone, not just command-line experts. While the CGI script was useful initially, a **properly integrated LuCI module** was necessary for a professional, maintainable solution. It transforms Snort3 from a powerful but complex tool into a user-friendly security solution that fits naturally within OpenWrt's interface.

### 🎓 Project Status & Motivation

**Personal Journey:**  
This project was initially created to meet a **personal need** - I wanted an easy way to manage Snort3 on my own OpenWrt router. It started as a learning experience to understand LuCI development and OpenWrt integration.

**Sharing with the Community:**  
Since no such module existed, I decided to **share it with the OpenWrt community** so others facing the same challenge could benefit from it.

**Maintenance & Future:**  
- ✅ The module is **functional and usable** as-is
- 🐛 **Bug fixes** may be provided if critical issues are found
- ⚠️ **Long-term maintenance is not guaranteed** - this was primarily a learning project
- 🤝 **Community contributions are welcome** if others want to enhance or maintain it

**Bottom line:** This is a working solution shared freely, but it was created for personal use and learning, not as a long-term commitment. Use it, enjoy it, and feel free to fork it if you want to take it further!

---

## ⚠️ Project Status & Disclaimer

### 📌 Important Information

This project was created to **solve a personal need** - managing Snort3 on my OpenWrt router without command-line tools. It also served as a **learning experience** for LuCI development and OpenWrt integration.

### 🎯 Current Status

- ✅ **Fully functional** - The module works as intended
- ✅ **Production ready** - You can use it on your router
- ✅ **Well documented** - Complete guides provided
- 🐛 **Bug fixes possible** - Critical issues may be addressed
- ⚠️ **Limited maintenance** - Long-term active development not guaranteed

### 🤝 Community Approach

This module is **shared freely with the OpenWrt community** because it might help others facing the same challenges. 

**What this means:**
- Use it, modify it, fork it - it's yours!
- Contributions are welcome if you want to improve it
- No guarantee of long-term maintenance or feature additions
- Created as a personal/learning project, not a commercial product

### 💡 For Users

If this module solves your problem, great! If you need additional features or long-term support, feel free to:
- Fork the project and maintain your own version
- Submit pull requests with improvements
- Create your own derivative work

**Bottom line:** This is a working tool shared in the spirit of open source. Use at your own risk, contribute if you wish, and enjoy! 🚀

---

## 📦 Requirements

- OpenWrt 21.02 or later
- Snort3 installed (`snort` package)
- LuCI web interface
- Root access

### 🚀 Quick Installation

```bash
# Download the installation script
wget https://raw.githubusercontent.com/dddavid51/luci-snort3/main/install.sh

# Make it executable
chmod +x install.sh

# Run as root
./install.sh
```

### 📖 Detailed Documentation

- [Installation Guide](docs/INSTALLATION.md)
- [Usage Guide](docs/USAGE.md)

### 🔧 Manual Installation

If you prefer to install files manually, see the [detailed installation guide](docs/INSTALLATION.md).

### 📂 File Structure

```
/usr/lib/lua/luci/
├── controller/
│   └── snort.lua                    # Main controller
├── model/cbi/snort/
│   └── config.lua                   # Configuration interface
├── view/snort/
│   ├── status.htm                   # Status widget
│   ├── status_page.htm              # Full status page
│   ├── control.htm                  # Service controls
│   ├── alerts.htm                   # Alerts page
│   └── recent_alerts.htm            # Recent alerts widget
└── i18n/
    ├── snort.fr.po / snort.fr.lmo  # French translations
    └── snort.en.po / snort.en.lmo  # English translations
```

### 🌐 Accessing the Interface

After installation, access the interface via:

**Services → Snort IDS/IPS**

### 🔄 Post-Installation Steps

1. **Reconnect to LuCI** (logout and login again)
2. **Clear browser cache** (Ctrl+Shift+R or Cmd+Shift+R)
3. **Change language if needed** (System → System → Language)
4. **Configure Snort** (Services → Snort IDS/IPS)

### 📝 Configuration

The module integrates with OpenWrt's UCI configuration system. Configuration file: `/etc/config/snort`

### 🐛 Troubleshooting

**Interface doesn't appear:**
- Clear LuCI cache: `rm -rf /tmp/luci-*`
- Restart uhttpd: `/etc/init.d/uhttpd restart`
- Clear browser cache

**Translations not working:**
- Check if po2lmo is installed
- Verify translation files in `/usr/lib/lua/luci/i18n/`
- Restart LuCI

**Rules update fails:**
- Check network connectivity
- Verify Oinkcode if using official rules
- Check logs: `logread | grep snort`

### 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### 📄 License

GPL v2 - Compatible with OpenWrt and LuCI

### 👤 Author

**David Dzieciol**  
Email: david.dzieciol51100@gmail.com  
GitHub: https://github.com/YOUR_USERNAME/luci-snort3

### 🙏 Acknowledgments

- OpenWrt project
- LuCI developers
- Snort3 team

---

## Français

### 📋 Description

Module d'interface web LuCI complet pour Snort3 IDS/IPS sur OpenWrt. Ce module fournit une interface web intuitive pour configurer, surveiller et gérer Snort3 directement depuis l'interface LuCI de votre routeur OpenWrt.

### ✨ Fonctionnalités

- **Tableau de bord en temps réel**
  - État du service (en cours/arrêté)
  - ID du processus et utilisation mémoire
  - Surveillance de la mémoire système
  - Compteur d'alertes
  - Surveillance de l'interface réseau

- **Interface de configuration complète**
  - Sélection de l'interface réseau
  - Mode de fonctionnement (IDS/IPS)
  - Configuration de la méthode DAQ
  - Gestion des règles
  - Configuration Snort personnalisée

- **Gestion des alertes**
  - Visualisation des alertes récentes (50 dernières)
  - Surveillance des logs système
  - Auto-actualisation toutes les 5 secondes
  - Statistiques des alertes

- **Contrôles du service**
  - Démarrer/Arrêter/Redémarrer Snort
  - Activer/Désactiver le démarrage automatique
  - Mise à jour des règles avec suivi de progression
  - Gestion des liens symboliques pour les règles

- **Interface bilingue**
  - Support complet du français
  - Support complet de l'anglais

### 📦 Prérequis

- OpenWrt 21.02 ou ultérieur
- Snort3 installé (paquet `snort`)
- Interface web LuCI
- Accès root

### 🚀 Installation rapide

```bash
# Télécharger le script d'installation
wget https://raw.githubusercontent.com/YOUR_USERNAME/luci-snort3/main/install.sh

# Le rendre exécutable
chmod +x install.sh

# Exécuter en tant que root
./install.sh
```

### 📖 Documentation détaillée

- [Guide d'installation](docs/INSTALLATION.md)
- [Guide d'utilisation](docs/USAGE.md)

### 🌐 Accès à l'interface

Après l'installation, accédez à l'interface via :

**Services → Snort IDS/IPS**

### 🔄 Étapes post-installation

1. **Reconnectez-vous à LuCI** (déconnexion puis reconnexion)
2. **Videz le cache du navigateur** (Ctrl+Shift+R ou Cmd+Shift+R)
3. **Changez la langue si nécessaire** (Système → Système → Langue)
4. **Configurez Snort** (Services → Snort IDS/IPS)

### 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à soumettre une Pull Request.

### 📄 Licence

GPL v2 - Compatible avec OpenWrt et LuCI

---

**Version:** 3.6  
**Last Update:** November 2025
