# Contributing to LuCI Snort3 Module

Thank you for your interest in contributing to the LuCI Snort3 Module! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of experience level, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, or nationality.

### Our Standards

**Positive behaviors include:**
- Being respectful and professional
- Accepting constructive criticism gracefully
- Focusing on what's best for the community
- Showing empathy towards others

**Unacceptable behaviors include:**
- Harassment or discriminatory language
- Personal or political attacks
- Publishing others' private information
- Other conduct that could be considered inappropriate

---

## Project Background

This project was born out of **necessity** and **curiosity**. When Snort3 became available on OpenWrt, there was no graphical interface to manage it. Users had to configure everything via command line, which made this powerful IDS/IPS inaccessible to most router owners.

**The Personal Journey:**  
Initially, this was a **personal project** to solve my own need - I wanted to manage Snort3 on my router without SSH. It also became a **learning experience** to understand LuCI development and proper OpenWrt integration.

**Sharing with the Community:**  
Since no such module existed and it worked well for my needs, I decided to **share it with the OpenWrt community** so others could benefit from it.

The goal was clear: **Make Snort3 accessible to everyone**, not just Linux experts, through **proper integration with OpenWrt**.

The project evolved from a simple CGI script (useful as a temporary solution) to a full-featured LuCI module (the preferred and final solution), demonstrating the importance of iterative development while keeping the end goal of proper OpenWrt integration in mind.

**About Maintenance:**  
This module is **fully functional and ready to use**. However, it's important to note:
- This was primarily a **learning project** and personal tool
- **Bug fixes** may be provided for critical issues
- **Long-term active maintenance is not guaranteed**
- **Community contributions are welcome** - feel free to fork and enhance!

If you're considering contributing, please understand this context. Your improvements are appreciated, and you're welcome to take the project in new directions!

---

## Getting Started

### Prerequisites

- Experience with OpenWrt
- Basic knowledge of Lua programming
- Familiarity with LuCI framework
- Understanding of Snort3 IDS/IPS

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **Pull Requests**: Code contributions
- **Discussions**: General questions and ideas

---

## How to Contribute

### Reporting Bugs

Before creating a bug report:
1. Check existing issues to avoid duplicates
2. Verify the bug on the latest version
3. Collect relevant information (logs, configuration, environment)

**Bug Report Template:**

```markdown
**Description:**
Clear description of the bug

**Steps to Reproduce:**
1. Step one
2. Step two
3. ...

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Environment:**
- OpenWrt Version: 
- Snort Version: 
- Module Version: 
- Router Model: 

**Logs:**
```
Paste relevant logs here
```

**Screenshots:**
If applicable
```

### Suggesting Features

Feature requests are welcome! Please:
1. Check if the feature was already requested
2. Explain the use case clearly
3. Provide examples if possible
4. Consider implementation complexity

**Feature Request Template:**

```markdown
**Feature Description:**
Clear description of the proposed feature

**Use Case:**
Why is this feature needed?

**Proposed Solution:**
How would you implement this?

**Alternatives:**
Any alternative approaches considered?

**Additional Context:**
Any other relevant information
```

### Contributing Code

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

---

## Development Setup

### Environment Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/luci-snort3.git
cd luci-snort3

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/luci-snort3.git

# Create development branch
git checkout -b dev/my-feature
```

### Local Testing

#### On Real Hardware

```bash
# Copy files to router
scp -r src/* root@router:/usr/lib/lua/luci/

# Clear cache
ssh root@router "rm -rf /tmp/luci-* && /etc/init.d/uhttpd restart"
```

#### With OpenWrt VM

Use QEMU or VirtualBox with OpenWrt image for safer testing.

### File Structure

```
luci-snort3/
├── README.md                 # Main documentation
├── LICENSE                   # License file
├── CHANGELOG.md             # Version history
├── CONTRIBUTING.md          # This file
├── .gitignore               # Git ignore rules
├── install.sh               # Installation script
├── generate_install.py      # Script generator
├── src/                     # Source files
│   ├── controller/
│   │   └── snort.lua        # Main controller
│   ├── model/cbi/snort/
│   │   └── config.lua       # Configuration interface
│   ├── view/snort/
│   │   ├── *.htm            # View templates
│   └── i18n/
│       ├── snort.fr.po      # French translations
│       └── snort.en.po      # English translations
└── docs/                    # Documentation
    ├── INSTALLATION.md      # Installation guide
    └── USAGE.md            # Usage guide
```

---

## Coding Standards

### Lua Code Style

#### Indentation and Spacing

```lua
-- Use tabs for indentation (4 spaces equivalent)
-- Space after keywords
if condition then
    do_something()
end

-- No space before function parameters
function my_function(param1, param2)
    return param1 + param2
end

-- Space around operators
local result = value1 + value2
```

#### Naming Conventions

```lua
-- Variables: snake_case
local my_variable = "value"

-- Functions: snake_case
function get_status()
    return status
end

-- Constants: UPPER_CASE
local MAX_ATTEMPTS = 3

-- Private functions: leading underscore
local function _internal_helper()
    -- ...
end
```

#### Comments

```lua
-- Single line comments for brief explanations

--[[
Multi-line comments for longer
documentation blocks
]]

--- Documentation comment for functions
-- @param interface Network interface name
-- @return Status table or nil
function get_interface_status(interface)
    -- Implementation
end
```

### HTML/HTM Templates

```html
<!-- Use proper indentation -->
<div class="container">
    <h3><%:Title%></h3>
    <% if condition then %>
        <p><%:Content%></p>
    <% end %>
</div>

<!-- Translation strings use <%:String%> -->
<label><%:Network Interface%></label>
```

### Translation Files (.po)

```po
# Use consistent formatting
msgid "Original English string"
msgstr "Translated string"

# Maintain context
msgid "Status"
msgstr "État"  # French

# Use proper punctuation
msgid "Service started successfully!"
msgstr "Service démarré avec succès !"
```

---

## Testing

### Manual Testing Checklist

Before submitting, verify:

- [ ] Installation script works on clean system
- [ ] All menu items appear correctly
- [ ] Service controls (start/stop/restart) work
- [ ] Configuration changes persist
- [ ] Translations display correctly
- [ ] Alerts page loads and refreshes
- [ ] Status updates in real-time
- [ ] Rules update completes successfully
- [ ] No Lua errors in logs
- [ ] Browser cache clearing not required for updates

### Testing Commands

```bash
# Test Lua syntax
luac -p /usr/lib/lua/luci/controller/snort.lua

# Check for errors
logread | grep -i error

# Monitor in real-time
logread -f

# Test configuration
snort -c /etc/snort/snort.lua -T

# Check UCI configuration
uci show snort
```

### Test Scenarios

1. **Fresh Installation**
   - Clean OpenWrt installation
   - Run installation script
   - Verify all components installed

2. **Upgrade Path**
   - Install older version
   - Upgrade to new version
   - Verify configuration preserved

3. **Configuration Changes**
   - Change settings via UI
   - Verify UCI updated
   - Verify Snort uses new settings

4. **Service Management**
   - Start/stop/restart via UI
   - Check process status
   - Verify logs generated

5. **Rules Update**
   - Initiate update via UI
   - Monitor progress
   - Verify rules downloaded
   - Check symbolic link

6. **Multi-Language**
   - Switch between French/English
   - Verify all strings translated
   - Check for untranslated text

---

## Submitting Changes

### Pull Request Process

1. **Update Documentation**
   - Update README if needed
   - Add entry to CHANGELOG
   - Update usage guide if applicable

2. **Self-Review**
   - Check code follows style guidelines
   - Verify no debug code left
   - Ensure no hardcoded values
   - Test thoroughly

3. **Create Pull Request**
   - Use descriptive title
   - Reference related issues
   - Provide detailed description
   - Include testing performed

4. **Pull Request Template**

```markdown
## Description
Describe your changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Comments added where needed
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tested on real hardware
- [ ] CHANGELOG updated
```

### Review Process

1. Maintainer will review your PR
2. Address any requested changes
3. Once approved, maintainer will merge

### After Merge

- Your contribution will be included in the next release
- You'll be credited in CHANGELOG
- Thank you for contributing!

---

## Development Guidelines

### Adding New Features

1. **Plan First**
   - Discuss in an issue first
   - Consider impact on existing code
   - Think about backwards compatibility

2. **Implement Incrementally**
   - Create feature branch
   - Make small, logical commits
   - Test after each change

3. **Document**
   - Add code comments
   - Update user documentation
   - Include usage examples

### Modifying Existing Code

1. **Understand First**
   - Read existing code thoroughly
   - Understand why it works that way
   - Consider backwards compatibility

2. **Test Thoroughly**
   - Test modified functionality
   - Test related functionality
   - Test on different OpenWrt versions

### Adding Translations

1. **Update Source Strings**
   - Add msgid in English
   - Provide French translation
   - Use clear, concise language

2. **Context Matters**
   - Consider where string appears
   - Maintain consistent terminology
   - Follow existing patterns

---

## Getting Help

- **Questions?** Open a GitHub Discussion
- **Bug?** Create an Issue
- **Security Issue?** Email maintainer directly (don't create public issue)

---

## Recognition

Contributors will be recognized in:
- CHANGELOG (release notes)
- README (contributors section)
- Project website (if applicable)

---

## License

By contributing, you agree that your contributions will be licensed under the GPL v2 License, compatible with OpenWrt and LuCI.

---

Thank you for contributing to LuCI Snort3 Module! 🎉
