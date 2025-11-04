#!/bin/sh
# LuCI Snort3 Module - Installation Verification Script
# Copyright (C) 2025 David Dzieciol <david.dzieciol51100@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# Run this script to verify your installation
# LuCI Snort3 Module - Installation Verification Script
# Run this script to verify your installation

echo "================================================"
echo "LuCI Snort3 Module - Installation Verification"
echo "================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

check() {
    if [ $1 -eq 0 ]; then
        echo "${GREEN}✓${NC} $2"
    else
        echo "${RED}✗${NC} $2"
        ERRORS=$((ERRORS + 1))
    fi
}

warn() {
    echo "${YELLOW} ${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

echo "Checking system requirements..."
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    warn "Not running as root (some checks may fail)"
else
    check 0 "Running as root"
fi

# Check Snort3 installation
if command -v snort >/dev/null 2>&1; then
    VERSION=$(snort -V 2>&1 | grep -oP 'Version \K[0-9.]+' | head -1)
    check 0 "Snort3 installed (Version: ${VERSION:-Unknown})"
else
    check 1 "Snort3 not found"
fi

# Check OpenWrt version
if [ -f /etc/openwrt_release ]; then
    OPENWRT_VER=$(cat /etc/openwrt_release | grep DISTRIB_RELEASE | cut -d"'" -f2)
    check 0 "OpenWrt detected (Version: $OPENWRT_VER)"
else
    check 1 "Not running on OpenWrt"
fi

echo ""
echo "Checking LuCI installation..."
echo ""

# Check LuCI directories
if [ -d /usr/lib/lua/luci ]; then
    check 0 "LuCI directory exists"
else
    check 1 "LuCI directory missing"
fi

echo ""
echo "Checking Snort module files..."
echo ""

# Check controller
if [ -f /usr/lib/lua/luci/controller/snort.lua ]; then
    check 0 "Controller installed"
else
    check 1 "Controller missing"
fi

# Check CBI configuration
if [ -f /usr/lib/lua/luci/model/cbi/snort/config.lua ]; then
    check 0 "Configuration interface installed"
else
    check 1 "Configuration interface missing"
fi

# Check view templates
VIEW_FILES="status.htm status_page.htm control.htm alerts.htm recent_alerts.htm"
VIEW_COUNT=0
for file in $VIEW_FILES; do
    if [ -f "/usr/lib/lua/luci/view/snort/$file" ]; then
        VIEW_COUNT=$((VIEW_COUNT + 1))
    fi
done

if [ $VIEW_COUNT -eq 5 ]; then
    check 0 "All view templates installed (5/5)"
else
    check 1 "Some view templates missing ($VIEW_COUNT/5)"
fi

# Check translations
TRANS_FR=0
TRANS_EN=0

if [ -f /usr/lib/lua/luci/i18n/snort.fr.po ] || [ -f /usr/lib/lua/luci/i18n/snort.fr.lmo ]; then
    TRANS_FR=1
fi

if [ -f /usr/lib/lua/luci/i18n/snort.en.po ] || [ -f /usr/lib/lua/luci/i18n/snort.en.lmo ]; then
    TRANS_EN=1
fi

if [ $TRANS_FR -eq 1 ] && [ $TRANS_EN -eq 1 ]; then
    check 0 "Translations installed (French, English)"
elif [ $TRANS_FR -eq 1 ] || [ $TRANS_EN -eq 1 ]; then
    warn "Only partial translations installed"
else
    check 1 "Translations missing"
fi

echo ""
echo "Checking Snort configuration..."
echo ""

# Check UCI configuration
if [ -f /etc/config/snort ]; then
    check 0 "Snort UCI configuration exists"
    
    # Check specific settings
    INTERFACE=$(uci get snort.snort.interface 2>/dev/null)
    if [ -n "$INTERFACE" ]; then
        check 0 "Network interface configured: $INTERFACE"
    else
        warn "Network interface not configured"
    fi
    
    MODE=$(uci get snort.snort.mode 2>/dev/null)
    if [ -n "$MODE" ]; then
        check 0 "Operating mode set: $MODE"
    else
        warn "Operating mode not set"
    fi
else
    check 1 "Snort UCI configuration missing"
fi

# Check Snort directories
if [ -d /etc/snort ]; then
    check 0 "Snort configuration directory exists"
else
    check 1 "Snort configuration directory missing"
fi

if [ -d /etc/snort/rules ] || [ -L /etc/snort/rules ]; then
    if [ -L /etc/snort/rules ]; then
        TARGET=$(readlink /etc/snort/rules)
        check 0 "Rules directory is symbolic link to: $TARGET"
    else
        check 0 "Rules directory exists"
    fi
else
    warn "Rules directory not found"
fi

# Check log directory
if [ -d /var/log ]; then
    check 0 "Log directory exists"
    if [ -f /var/log/alert_fast.txt ]; then
        ALERT_COUNT=$(wc -l < /var/log/alert_fast.txt 2>/dev/null || echo 0)
        check 0 "Alert log exists ($ALERT_COUNT alerts)"
    else
        warn "No alert log found (normal for new installation)"
    fi
else
    check 1 "Log directory missing"
fi

echo ""
echo "Checking service status..."
echo ""

# Check init script
if [ -f /etc/init.d/snort ]; then
    check 0 "Init script exists"
    
    # Check if service is running
    if /etc/init.d/snort status >/dev/null 2>&1; then
        check 0 "Snort service is running"
        
        # Get PID
        PID=$(ps | grep '/usr/bin/snort' | grep -v grep | awk '{print $1}')
        if [ -n "$PID" ]; then
            check 0 "Snort process found (PID: $PID)"
        fi
    else
        warn "Snort service is not running"
    fi
    
    # Check auto-start
    if ls /etc/rc.d/S*snort* >/dev/null 2>&1; then
        check 0 "Auto-start enabled"
    else
        warn "Auto-start disabled"
    fi
else
    check 1 "Init script missing"
fi

# Check uhttpd
if /etc/init.d/uhttpd status >/dev/null 2>&1; then
    check 0 "Web server (uhttpd) is running"
else
    check 1 "Web server (uhttpd) is not running"
fi

echo ""
echo "Checking system resources..."
echo ""

# Check memory
TOTAL_MEM=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
FREE_MEM=$(awk '/MemFree/ {print $2}' /proc/meminfo)
TOTAL_MB=$((TOTAL_MEM / 1024))
FREE_MB=$((FREE_MEM / 1024))

if [ $TOTAL_MB -lt 128 ]; then
    warn "Low total memory: ${TOTAL_MB}MB (128MB+ recommended)"
else
    check 0 "Sufficient memory: ${TOTAL_MB}MB total, ${FREE_MB}MB free"
fi

# Check disk space
ROOT_SPACE=$(df / | tail -1 | awk '{print $4}')
ROOT_MB=$((ROOT_SPACE / 1024))

if [ $ROOT_MB -lt 10 ]; then
    warn "Low disk space: ${ROOT_MB}MB free (10MB+ recommended)"
else
    check 0 "Sufficient disk space: ${ROOT_MB}MB free"
fi

echo ""
echo "================================================"
echo "Verification Summary"
echo "================================================"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "${GREEN}✓ All checks passed! Installation is complete and healthy.${NC}"
    echo ""
    echo "You can access the interface at:"
    echo "  Services → Snort IDS/IPS"
    EXIT_CODE=0
elif [ $ERRORS -eq 0 ]; then
    echo "${YELLOW} Installation complete with $WARNINGS warning(s)${NC}"
    echo ""
    echo "The module should work, but review warnings above."
    EXIT_CODE=0
else
    echo "${RED}✗ Installation incomplete: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please address the errors above and run the verification again."
    EXIT_CODE=1
fi

echo ""
echo "Recommended actions:"
echo "  1. Reconnect to LuCI (logout and login)"
echo "  2. Clear browser cache (Ctrl+Shift+R)"
echo "  3. Navigate to Services → Snort IDS/IPS"
echo "  4. Configure network interface"
echo "  5. Start Snort service"
echo ""

exit $EXIT_CODE
