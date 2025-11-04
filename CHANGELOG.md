# Changelog

All notable changes to the LuCI Snort3 Module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.6.0] - 2025-11-03

### Added
- Complete English translation for installation script
- Comprehensive installation script with detailed progress tracking
- Color-coded output for better readability
- Installation verification with component checking
- Detailed post-installation summary with file listings
- Component descriptions in installation output
- Error tracking and reporting
- Installation log file generation
- Support for OpenWrt version detection
- Modular source file structure for GitHub
- Complete documentation (Installation and Usage guides)
- README with bilingual support (English/French)
- GPL v2 License (compatible with OpenWrt/LuCI)
- Changelog file
- Author information (David Dzieciol)

### Changed
- Converted all echo messages from French to English
- Improved installation script structure with step tracking
- Enhanced error handling and verification
- Reorganized file structure for GitHub distribution
- Better separation of concerns (source files vs installation script)

### Improved
- Installation feedback with success/warning/error indicators
- Post-installation instructions clarity
- Troubleshooting information
- Access information presentation
- Component description accuracy

### Fixed
- Translation compilation warnings handling
- Directory creation verification
- File existence checks
- Cache clearing process
- Service restart reliability

## [3.5.0] - 2024

### Added
- Rules update monitoring with progress tracking
- Background rules update process
- Temporary file cleanup functionality
- Update status checking endpoint
- Lock file mechanism to prevent concurrent updates

### Changed
- Improved rules update workflow
- Better handling of temporary archives

### Fixed
- Rules update not completing properly
- Temporary files accumulation
- Concurrent update issues

## [3.4.0] - 2024

### Added
- Symbolic link management for rules
- Fix rules functionality
- Directory existence checking

### Changed
- Rules directory handling

### Fixed
- Rules not found after update
- Symbolic link creation errors

## [3.3.0] - 2024

### Added
- Real-time status dashboard with auto-refresh
- JSON API for status retrieval
- Memory usage monitoring
- Alert counting
- Recent alerts widget

### Changed
- Status page now updates every 5 seconds
- Improved UI responsiveness

### Fixed
- Status not updating in real-time
- Memory usage display issues

## [3.2.0] - 2024

### Added
- Full bilingual support (French/English)
- Translation files (.po format)
- Compiled translations (.lmo format)
- Translation compilation in installation script

### Changed
- All interface strings now translatable
- Language selection support

## [3.1.0] - 2024

### Added
- Alerts page with last 50 alerts
- System logs integration
- Log viewing functionality
- Refresh button for alerts

### Changed
- Alert display format
- Log filtering

### Fixed
- Empty alerts handling
- Log file permissions

## [3.0.0] - 2024

### Added
- Complete LuCI web interface
- Service control buttons (Start/Stop/Restart)
- Auto-start management (Enable/Disable at boot)
- Configuration interface with UCI integration
- Network interface selection
- Operating mode selection (IDS/IPS)
- DAQ method configuration
- Alert configuration options
- Home network configuration
- Performance tuning options
- Port configuration
- Directory management

### Changed
- Moved from command-line only to full web interface
- Configuration now via LuCI instead of editing files

## [2.0.0] - 2024

### Added
- UCI configuration support
- Init script for service management
- Basic configuration options

### Changed
- Configuration method from direct file editing to UCI

## [1.0.0] - 2024

### Added
- Initial release
- Basic Snort3 integration with OpenWrt
- Manual configuration support

---

## [0.5.0] - Early 2025 (Legacy CGI Version)

### Added
- Initial web interface as CGI script
- Basic service controls (start/stop/restart)
- Real-time status monitoring
- Alert viewing (last 20 alerts)
- System information display
- Rules update functionality
- Memory usage monitoring
- Auto-refresh capability

### Characteristics
- Lightweight CGI shell script
- French interface only
- Standalone (no LuCI integration)
- Basic functionality
- Manual configuration required

### Why It Was Created
- No existing web interface for Snort3 on OpenWrt
- Command-line management was too complex for most users
- Need for accessible security monitoring
- **Personal need**: Managing Snort3 on my own router
- **Learning experience**: Understanding CGI and OpenWrt development
- **Served as useful temporary solution** while developing full LuCI integration

### Limitations (Why LuCI Module Was Preferred)
- No proper LuCI integration
- Separate from OpenWrt's main interface
- No configuration interface
- French only
- Limited features
- Security concerns with basic CGI
- **Goal was always to have proper OpenWrt/LuCI integration**

### 📝 Project Origin Note

This project started as a **personal solution** to manage Snort3 on my own OpenWrt router, combined with a desire to **learn LuCI development**. The CGI version was quick and functional for personal use, but I wanted to do it properly with full LuCI integration.

It's shared with the community in case others find it useful, but was never intended as a long-term commercial project. Bug fixes may be provided, but extensive future development is not planned.

### Note
This version is kept in `legacy/v0-cgi-interface/` for historical reference.  
See v3.0+ for the full LuCI module (preferred solution).

---

## Version Numbering

- Major version (X.0.0): Breaking changes, major new features
- Minor version (0.X.0): New features, backwards compatible
- Patch version (0.0.X): Bug fixes, minor improvements

## Categories

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security fixes or improvements

## Roadmap

### Planned for 4.0.0
- Multi-interface monitoring support
- Advanced filtering rules in UI
- Alert email notifications
- Integration with external SIEM systems
- Dashboard widgets for OpenWrt overview page
- Mobile-responsive interface improvements

### Under Consideration
- Scheduled rules updates
- Custom rule set management
- Performance metrics dashboard
- Integration with threat intelligence feeds
- Automated backup and restore
- Rule testing sandbox

---

**Current Version:** 3.6.0  
**Release Date:** November 3, 2025  
**Status:** Stable
