# Snort3 CGI Interface - Version 0.5 (Legacy)

## 🏛️ Historical Version

This is the **original web interface** created for Snort3 on OpenWrt before the full LuCI module was developed.

## 📅 Context (Early 2025)

When this script was created, **there was no graphical interface** for Snort3 on OpenWrt. Users could only manage Snort through:
- SSH command line
- Manual configuration file editing
- Init scripts

This made Snort3 **inaccessible** to many OpenWrt users who wanted network security but weren't comfortable with command-line tools.

**Personal Note:** This CGI script was created to solve a **personal need** - managing Snort3 on my own router. It also served as a **learning experience** to understand CGI development on OpenWrt. While functional, I preferred to have **proper OpenWrt/LuCI integration**, which led to the development of the full module.

**Note:** While this CGI script was useful as an initial solution, a **properly integrated LuCI module** was always the preferred goal for better OpenWrt integration.

## 🎯 What This Script Did

This CGI script provided a **basic web interface** with:
- ✅ Service control (start/stop/restart)
- ✅ Real-time status display
- ✅ Alert viewing (last 20 alerts)
- ✅ System information
- ✅ Rules update capability
- ✅ Memory usage monitoring
- ✅ Auto-refresh every 30 seconds

## 📝 Technical Details

**Type:** Simple CGI shell script  
**Language:** POSIX shell script  
**Location:** `/www/cgi-bin/snort.sh`  
**Size:** Lightweight (~8KB)  
**Dependencies:** Only standard OpenWrt tools  
**Interface:** French only

## 🔧 Installation (Historical)

```bash
# Copy script to CGI directory
cp snort-interface-openwrt.sh /www/cgi-bin/snort.sh

# Make executable
chmod +x /www/cgi-bin/snort.sh

# Access via browser
http://your-router-ip/cgi-bin/snort.sh
```

## ⚠️ Limitations

This version had several limitations that led to the creation of the full LuCI module:

1. **No LuCI Integration**
   - Separate from OpenWrt's main interface
   - No consistent look and feel
   - Required separate access URL

2. **Limited Configuration**
   - No configuration interface
   - Still required manual file editing
   - No UCI integration

3. **Basic Features Only**
   - Simple start/stop controls
   - Read-only alert viewing
   - No advanced rule management

4. **French Only**
   - Interface only in French
   - No internationalization

5. **Security Concerns**
   - Basic CGI script
   - Limited input validation
   - No session management

## 🚀 Evolution to LuCI Module

While this CGI script **served its purpose as a temporary solution**, the goal was always to create a **properly integrated LuCI module**.

The full LuCI module (v3.0+) was developed to provide:
- ✨ **Proper OpenWrt integration** (the main goal)
- ✨ Complete LuCI framework integration
- ✨ UCI-based configuration
- ✨ Advanced features (rules management, real-time updates)
- ✨ Bilingual support (FR/EN)
- ✨ Professional interface
- ✨ Better security and maintainability

The LuCI module represents the **preferred and final solution** for Snort3 management on OpenWrt.

See the [main project](../../README.md) for the current version.

## 🎓 Learning Value

This script demonstrates:
- How to create simple web interfaces for OpenWrt
- CGI scripting on embedded systems
- Working with limited resources
- Practical problem-solving approach
- Iterative development process

## 📜 License

GPL v2 - Compatible with OpenWrt

## 👤 Author

David Dzieciol <david.dzieciol51100@gmail.com>

---

**This is a historical version kept for reference and documentation purposes.**  
**For production use, please use the [full LuCI module](../../README.md).**

---

## 💭 Reflection

Looking back, this CGI script was a valuable stepping stone:
- It solved an immediate personal need
- It provided a learning opportunity for OpenWrt development
- It validated the concept of web-based Snort management
- It informed the design of the full LuCI module

The experience gained from this simple script was essential in creating the more sophisticated LuCI integration that exists today.
