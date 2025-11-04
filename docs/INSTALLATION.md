# Installation Guide - LuCI Snort3 Module

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Installation](#quick-installation)
- [Manual Installation](#manual-installation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)

---

## Prerequisites

### Required Packages

1. **OpenWrt** version 21.02 or later
2. **Snort3** package installed:
   ```bash
   opkg update
   opkg install snort3
   ```
3. **LuCI** web interface installed (usually pre-installed)
4. **Root access** to your router

### Optional Packages

- `po2lmo`: For compiled translations (usually included in LuCI)
- `wget` or `curl`: For downloading the installation script

### System Requirements

- Minimum 128MB RAM (256MB recommended)
- At least 10MB free storage space
- Working network connection

---

## Quick Installation

### Method 1: One-line Installation

```bash
wget -O - https://raw.githubusercontent.com/YOUR_USERNAME/luci-snort3/main/install.sh | sh
```

### Method 2: Download and Execute

```bash
# Download the script
wget https://raw.githubusercontent.com/YOUR_USERNAME/luci-snort3/main/install.sh

# Make it executable
chmod +x install.sh

# Run as root
./install.sh
```

### Method 3: Using curl

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/luci-snort3/main/install.sh | sh
```

---

## Manual Installation

If you prefer to install files manually or the automatic script fails:

### Step 1: Create Directories

```bash
mkdir -p /usr/lib/lua/luci/controller
mkdir -p /usr/lib/lua/luci/model/cbi/snort
mkdir -p /usr/lib/lua/luci/view/snort
mkdir -p /usr/lib/lua/luci/i18n
```

### Step 2: Download Source Files

Clone the repository:

```bash
cd /tmp
git clone https://github.com/YOUR_USERNAME/luci-snort3.git
cd luci-snort3
```

Or download individual files from the `src/` directory.

### Step 3: Copy Files

```bash
# Controller
cp src/controller/snort.lua /usr/lib/lua/luci/controller/

# Configuration interface
cp src/model/cbi/snort/config.lua /usr/lib/lua/luci/model/cbi/snort/

# Views
cp src/view/snort/*.htm /usr/lib/lua/luci/view/snort/

# Translations
cp src/i18n/*.po /usr/lib/lua/luci/i18n/
```

### Step 4: Compile Translations (Optional)

If `po2lmo` is available:

```bash
po2lmo /usr/lib/lua/luci/i18n/snort.fr.po /usr/lib/lua/luci/i18n/snort.fr.lmo
po2lmo /usr/lib/lua/luci/i18n/snort.en.po /usr/lib/lua/luci/i18n/snort.en.lmo
```

### Step 5: Clear Cache and Restart

```bash
# Clear LuCI cache
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache /tmp/luci-sessions/*

# Restart web server
/etc/init.d/uhttpd restart
```

---

## Verification

### Check Installed Files

```bash
# Controller
ls -la /usr/lib/lua/luci/controller/snort.lua

# Configuration
ls -la /usr/lib/lua/luci/model/cbi/snort/config.lua

# Views
ls -la /usr/lib/lua/luci/view/snort/

# Translations
ls -la /usr/lib/lua/luci/i18n/snort.*
```

### Access the Interface

1. Open your browser and navigate to your router's IP (e.g., http://192.168.1.1)
2. Log in to LuCI
3. Go to **Services → Snort IDS/IPS**

If the menu doesn't appear:
- Logout and login again
- Clear browser cache (Ctrl+Shift+R)
- Clear LuCI cache and restart uhttpd

### Check Snort Configuration

```bash
# Verify Snort is installed
snort -V

# Check UCI configuration
uci show snort

# View service status
/etc/init.d/snort status
```

---

## Troubleshooting

### Interface Not Appearing

**Problem:** Snort IDS/IPS menu doesn't appear in Services

**Solutions:**
1. Clear LuCI cache:
   ```bash
   rm -rf /tmp/luci-*
   /etc/init.d/uhttpd restart
   ```

2. Check if files exist:
   ```bash
   ls -la /usr/lib/lua/luci/controller/snort.lua
   ```

3. Check LuCI logs:
   ```bash
   logread | grep luci
   ```

4. Verify Snort UCI configuration exists:
   ```bash
   ls -la /etc/config/snort
   ```

### Translation Issues

**Problem:** Interface is not in the expected language

**Solutions:**
1. Change language in LuCI:
   - Go to **System → System → Language & Style**
   - Select your preferred language
   - Save & Apply

2. Check translation files:
   ```bash
   ls -la /usr/lib/lua/luci/i18n/snort.*
   ```

3. Recompile translations:
   ```bash
   po2lmo /usr/lib/lua/luci/i18n/snort.fr.po /usr/lib/lua/luci/i18n/snort.fr.lmo
   po2lmo /usr/lib/lua/luci/i18n/snort.en.po /usr/lib/lua/luci/i18n/snort.en.lmo
   ```

### Permission Errors

**Problem:** Installation fails with permission errors

**Solutions:**
1. Ensure you're running as root:
   ```bash
   whoami  # Should return 'root'
   ```

2. If not root, use `sudo` or login as root:
   ```bash
   sudo sh install.sh
   ```

### Snort Not Starting

**Problem:** Snort service won't start from LuCI

**Solutions:**
1. Check Snort configuration:
   ```bash
   snort -c /etc/snort/snort.lua -T
   ```

2. View logs:
   ```bash
   logread | grep snort
   ```

3. Check network interface:
   ```bash
   uci get snort.snort.interface
   ip link show
   ```

4. Verify rules exist:
   ```bash
   ls -la /etc/snort/rules/
   ```

### Rules Update Fails

**Problem:** Rules update doesn't complete

**Solutions:**
1. Check network connectivity:
   ```bash
   ping -c 3 www.snort.org
   ```

2. Check available space:
   ```bash
   df -h
   ```

3. Check update log:
   ```bash
   cat /tmp/snort_rules_update.log
   ```

4. Clean temporary files:
   ```bash
   rm -f /var/snort.d/*.tar.gz
   rm -f /tmp/snort*.tar.gz
   rm -f /tmp/snort_rules_update.*
   ```

### Memory Issues

**Problem:** Snort uses too much memory

**Solutions:**
1. Adjust detection settings in the configuration interface
2. Reduce loaded rule sets
3. Increase swap space
4. Upgrade router hardware if necessary

---

## Uninstallation

### Complete Removal

```bash
# Remove files
rm -f /usr/lib/lua/luci/controller/snort.lua
rm -rf /usr/lib/lua/luci/model/cbi/snort
rm -rf /usr/lib/lua/luci/view/snort
rm -f /usr/lib/lua/luci/i18n/snort.*

# Clear cache
rm -rf /tmp/luci-*

# Restart web server
/etc/init.d/uhttpd restart
```

### Keep Snort, Remove LuCI Module Only

The above commands only remove the LuCI interface. Snort itself remains installed and can still be configured via UCI or configuration files.

---

## Post-Installation

After successful installation:

1. **Reconnect to LuCI** (logout and login)
2. **Clear browser cache** (Ctrl+Shift+R)
3. **Configure Snort** (Services → Snort IDS/IPS)
4. **Set network interface** and operating mode
5. **Update rules** if desired
6. **Start the service**

---

## Support

If you encounter issues not covered here:

1. Check the [main README](../README.md)
2. Review [Usage Guide](USAGE.md)
3. Check Snort logs: `logread | grep snort`
4. Open an issue on GitHub

---

**Version:** 3.6  
**Last Updated:** November 2025
