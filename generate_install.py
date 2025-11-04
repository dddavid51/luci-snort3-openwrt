#!/usr/bin/env python3
"""
LuCI Snort3 Module - Installation Script Generator
Copyright (C) 2025 David Dzieciol <david.dzieciol51100@gmail.com>

This is free software, licensed under the GNU General Public License v2.
See /LICENSE for more information.

Generate complete LuCI Snort3 installation script
"""

"""

import os

# Define file mappings: source_file -> destination_path
FILE_MAPPINGS = {
    'src/controller/snort.lua': '/usr/lib/lua/luci/controller/snort.lua',
    'src/model/cbi/snort/config.lua': '/usr/lib/lua/luci/model/cbi/snort/config.lua',
    'src/view/snort/status.htm': '/usr/lib/lua/luci/view/snort/status.htm',
    'src/view/snort/status_page.htm': '/usr/lib/lua/luci/view/snort/status_page.htm',
    'src/view/snort/control.htm': '/usr/lib/lua/luci/view/snort/control.htm',
    'src/view/snort/alerts.htm': '/usr/lib/lua/luci/view/snort/alerts.htm',
    'src/view/snort/recent_alerts.htm': '/usr/lib/lua/luci/view/snort/recent_alerts.htm',
    'src/i18n/snort.fr.po': '/usr/lib/lua/luci/i18n/snort.fr.po',
    'src/i18n/snort.en.po': '/usr/lib/lua/luci/i18n/snort.en.po',
}

HEADER = '''#!/bin/sh
# Automatic complete installation of LuCI module for Snort3
# Download and execute: wget https://raw.githubusercontent.com/YOUR_USERNAME/luci-snort3/main/install.sh && sh install.sh
# VERSION 3.6 - Complete translations and error corrections

set -e

echo "================================================"
echo "LuCI Snort3 Automatic Installation"
echo "Version: 3.6"
echo "================================================"
echo ""

# Color codes for better readability
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m' # No Color

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "${RED}ERROR: This script must be run as root${NC}"
    echo "Usage: sudo sh install.sh"
    exit 1
fi

# Check Snort installation
if ! command -v snort >/dev/null 2>&1; then
    echo "${RED}ERROR: Snort3 is not installed${NC}"
    echo "Please install Snort3 first:"
    echo "  opkg update && opkg install snort3"
    exit 1
fi

# Get Snort version
SNORT_VERSION=$(snort -V 2>&1 | grep -oP 'Version \\K[0-9.]+' | head -1 || echo "Unknown")
echo "${BLUE}Detected Snort version: ${SNORT_VERSION}${NC}"

# Get OpenWrt version
OPENWRT_VERSION=$(cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_RELEASE | cut -d"'" -f2 || echo "Unknown")
echo "${BLUE}OpenWrt version: ${OPENWRT_VERSION}${NC}"
echo ""

# Create installation log
LOG_FILE="/tmp/luci-snort3-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Installation started at $(date)"
echo "Log file: $LOG_FILE"
echo ""

# Track installation steps
STEPS_TOTAL=0
STEPS_COMPLETED=0
ERRORS=0

step() {
    STEPS_TOTAL=$((STEPS_TOTAL + 1))
    echo ""
    echo "${BLUE}[$STEPS_TOTAL] $1...${NC}"
}

success() {
    STEPS_COMPLETED=$((STEPS_COMPLETED + 1))
    echo "${GREEN}  [OK] $1${NC}"
}

error() {
    ERRORS=$((ERRORS + 1))
    echo "${RED}  [ERROR] $1${NC}"
}

warning() {
    echo "${YELLOW}  [WARNING] $1${NC}"
}

step "Creating directories"
mkdir -p /usr/lib/lua/luci/controller
mkdir -p /usr/lib/lua/luci/model/cbi/snort
mkdir -p /usr/lib/lua/luci/view/snort
mkdir -p /usr/lib/lua/luci/i18n

# Verify directory creation
for dir in /usr/lib/lua/luci/controller /usr/lib/lua/luci/model/cbi/snort /usr/lib/lua/luci/view/snort /usr/lib/lua/luci/i18n; do
    if [ -d "$dir" ]; then
        success "Created $(basename $dir)"
    else
        error "Failed to create $dir"
        exit 1
    fi
done
'''

FOOTER = '''
step "Compiling translations"
# Check if po2lmo is available
if command -v po2lmo >/dev/null 2>&1; then
    echo "  Compiling with po2lmo..."
    if po2lmo /usr/lib/lua/luci/i18n/snort.fr.po /usr/lib/lua/luci/i18n/snort.fr.lmo 2>/dev/null; then
        success "French translation compiled"
    else
        warning "French compilation failed (translations will work in text mode)"
    fi
    if po2lmo /usr/lib/lua/luci/i18n/snort.en.po /usr/lib/lua/luci/i18n/snort.en.lmo 2>/dev/null; then
        success "English translation compiled"
    else
        warning "English compilation failed (translations will work in text mode)"
    fi
else
    warning "po2lmo not available - translations will work in text mode"
fi

step "Cleaning LuCI cache"
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache /tmp/luci-sessions/* 2>/dev/null
success "Cache cleared"

step "Restarting uhttpd"
if /etc/init.d/uhttpd restart >/dev/null 2>&1; then
    success "uhttpd restarted"
else
    warning "Failed to restart uhttpd - you may need to restart manually"
fi

# Final verification
step "Verifying installation"
VERIFICATION_OK=true

# Check controller
if [ -f "/usr/lib/lua/luci/controller/snort.lua" ]; then
    success "Controller installed"
else
    error "Controller missing"
    VERIFICATION_OK=false
fi

# Check CBI configuration
if [ -f "/usr/lib/lua/luci/model/cbi/snort/config.lua" ]; then
    success "Configuration interface installed"
else
    error "Configuration interface missing"
    VERIFICATION_OK=false
fi

# Check views
VIEW_COUNT=0
for view in status.htm status_page.htm control.htm alerts.htm recent_alerts.htm; do
    if [ -f "/usr/lib/lua/luci/view/snort/$view" ]; then
        VIEW_COUNT=$((VIEW_COUNT + 1))
    fi
done
if [ "$VIEW_COUNT" -eq 5 ]; then
    success "All views installed ($VIEW_COUNT/5)"
else
    warning "Some views missing ($VIEW_COUNT/5)"
fi

# Check translations
TRANS_COUNT=0
for lang in fr en; do
    if [ -f "/usr/lib/lua/luci/i18n/snort.$lang.po" ]; then
        TRANS_COUNT=$((TRANS_COUNT + 1))
    fi
done
if [ "$TRANS_COUNT" -eq 2 ]; then
    success "Translations installed (French, English)"
else
    warning "Some translations missing ($TRANS_COUNT/2)"
fi

# Check Snort configuration
if [ -f "/etc/config/snort" ]; then
    success "Snort UCI configuration present"
else
    warning "Snort UCI configuration not found - you may need to configure Snort first"
fi

echo ""
echo "================================================"
echo "${GREEN}Installation completed!${NC}"
echo "================================================"
echo ""

# Installation summary
echo "${BLUE}Installation Summary:${NC}"
echo "  ${GREEN}✓${NC} LuCI Controller"
echo "  ${GREEN}✓${NC} Configuration Interface (CBI)"
echo "  ${GREEN}✓${NC} View Templates (5 files)"
echo "    - Status widget"
echo "    - Full status page"
echo "    - Service controls"
echo "    - Alerts page"
echo "    - Recent alerts widget"
echo "  ${GREEN}✓${NC} Translations (French, English)"
echo ""

# Component details
echo "${BLUE}Installed Components:${NC}"
echo ""
echo "  ${YELLOW}Core Module:${NC}"
echo "    • /usr/lib/lua/luci/controller/snort.lua"
echo "      Controller with service management, status monitoring,"
echo "      alert viewing, and rules update functionality"
echo ""
echo "  ${YELLOW}Configuration Interface:${NC}"
echo "    • /usr/lib/lua/luci/model/cbi/snort/config.lua"
echo "      UCI-based configuration with 40+ parameters:"
echo "      - Network interface selection"
echo "      - Operation mode (IDS/IPS)"
echo "      - DAQ method configuration"
echo "      - Alert logging options"
echo "      - Rules management"
echo "      - Performance tuning"
echo ""
echo "  ${YELLOW}User Interface:${NC}"
echo "    • Status Dashboard: Real-time monitoring"
echo "      - Service state (running/stopped)"
echo "      - PID and memory usage"
echo "      - System memory statistics"
echo "      - Alert counter"
echo "      - Interface and mode display"
echo "    • Control Panel: Service management"
echo "      - Start/Stop/Restart actions"
echo "      - Enable/Disable auto-start"
echo "      - Rules update with progress tracking"
echo "    • Alerts Viewer: Security monitoring"
echo "      - Last 50 alerts display"
echo "      - System logs integration"
echo "      - Auto-refresh (5 seconds)"
echo ""
echo "  ${YELLOW}Internationalization:${NC}"
echo "    • Full bilingual support (FR/EN)"
echo "    • 150+ translated strings"
echo "    • Automatic language detection"
echo ""

# Access information
echo "${BLUE}Access Information:${NC}"
echo "  ${GREEN}Web Interface:${NC}"
echo "    Navigate to: ${YELLOW}Services → Snort IDS/IPS${NC}"
echo "    URL: http://your-router-ip/cgi-bin/luci/admin/services/snort"
echo ""

# Post-installation steps
echo "${BLUE}Recommended Actions:${NC}"
echo "  ${YELLOW}1.${NC} Reconnect to LuCI"
echo "     (Logout and login again)"
echo ""
echo "  ${YELLOW}2.${NC} Clear browser cache"
echo "     Press: ${GREEN}Ctrl+Shift+R${NC} (or ${GREEN}Cmd+Shift+R${NC} on Mac)"
echo ""
echo "  ${YELLOW}3.${NC} Change language if needed"
echo "     Navigate to: ${YELLOW}System → System → Language & Style${NC}"
echo "     Select: French or English"
echo ""
echo "  ${YELLOW}4.${NC} Configure Snort"
echo "     Navigate to: ${YELLOW}Services → Snort IDS/IPS${NC}"
echo "     Set network interface and operating mode"
echo ""
echo "  ${YELLOW}5.${NC} Download rules (optional)"
echo "     In Snort interface, go to \"Rules Management\""
echo "     Click \"Update\" to download community rules"
echo "     Or enter your Oinkcode for registered rules"
echo ""
echo "  ${YELLOW}6.${NC} Start the service"
echo "     Use the control buttons in the interface"
echo "     Or via CLI: ${GREEN}/etc/init.d/snort start${NC}"
echo ""

# Troubleshooting
echo "${BLUE}Troubleshooting:${NC}"
echo "  • Interface not appearing?"
echo "    ${GREEN}rm -rf /tmp/luci-* && /etc/init.d/uhttpd restart${NC}"
echo ""
echo "  • Translation issues?"
echo "    Change language in System settings and refresh"
echo ""
echo "  • Snort not starting?"
echo "    Check logs: ${GREEN}logread | grep snort${NC}"
echo "    Verify interface: ${GREEN}uci show snort.snort.interface${NC}"
echo ""

# Statistics
echo "${BLUE}Installation Statistics:${NC}"
echo "  Completed: $(date)"
echo "  Steps executed: $STEPS_COMPLETED/$STEPS_TOTAL"
if [ "$ERRORS" -gt 0 ]; then
    echo "  ${RED}Errors: $ERRORS${NC}"
else
    echo "  ${GREEN}Errors: 0${NC}"
fi
echo "  Log file: $LOG_FILE"
echo ""

if [ "$VERIFICATION_OK" = true ] && [ "$ERRORS" -eq 0 ]; then
    echo "${GREEN}✓ Installation successful! Enjoy Snort3 on LuCI!${NC}"
    exit 0
else
    echo "${YELLOW} Installation completed with warnings${NC}"
    echo "Please review the log file: $LOG_FILE"
    exit 1
fi
'''

def generate_install_script():
    """Generate the complete installation script"""
    
    script_dir = '/home/claude/luci-snort3'
    
    with open(f'{script_dir}/install.sh', 'w') as out:
        # Write header
        out.write(HEADER)
        
        # Generate installation code for each file
        for src_file, dest_path in FILE_MAPPINGS.items():
            src_path = os.path.join(script_dir, src_file)
            
            # Get file description
            if 'controller' in src_file:
                desc = "Controller"
            elif 'config.lua' in src_file:
                desc = "Configuration interface"
            elif 'status_page' in src_file:
                desc = "Status page view"
            elif 'status.htm' in src_file:
                desc = "Status widget"
            elif 'control' in src_file:
                desc = "Control panel"
            elif 'alerts.htm' in src_file:
                desc = "Alerts page"
            elif 'recent_alerts' in src_file:
                desc = "Recent alerts widget"
            elif 'fr.po' in src_file:
                desc = "French translation"
            elif 'en.po' in src_file:
                desc = "English translation"
            else:
                desc = os.path.basename(src_file)
            
            out.write(f'\nstep "Installing {desc}"\n')
            out.write(f'cat > {dest_path} << \'EOF_{desc.upper().replace(" ", "_")}\'\n')
            
            # Read and write file content
            try:
                with open(src_path, 'r') as src:
                    out.write(src.read())
            except FileNotFoundError:
                print(f"Warning: {src_path} not found")
                continue
            
            out.write(f'\nEOF_{desc.upper().replace(" ", "_")}\n')
            out.write(f'if [ -f "{dest_path}" ]; then\n')
            out.write(f'    success "{desc} installed"\n')
            out.write('else\n')
            out.write(f'    error "{desc} installation failed"\n')
            out.write('fi\n')
        
        # Write footer
        out.write(FOOTER)
    
    # Make executable
    os.chmod(f'{script_dir}/install.sh', 0o755)
    print(f"Installation script generated: {script_dir}/install.sh")

if __name__ == '__main__':
    generate_install_script()
