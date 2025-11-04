# Usage Guide - LuCI Snort3 Module

## Table of Contents
- [Getting Started](#getting-started)
- [Dashboard Overview](#dashboard-overview)
- [Configuration](#configuration)
- [Service Management](#service-management)
- [Alert Management](#alert-management)
- [Rules Management](#rules-management)
- [Best Practices](#best-practices)
- [Advanced Usage](#advanced-usage)

---

## Getting Started

### Accessing the Interface

1. Open your browser and navigate to your router (e.g., http://192.168.1.1)
2. Log in to LuCI with your credentials
3. Navigate to: **Services → Snort IDS/IPS**

### First Time Setup

#### 1. Network Interface Configuration

Select the interface you want Snort to monitor:

- **br-lan**: For monitoring internal network (common for home routers)
- **eth0/eth1**: For specific physical interfaces
- **wan**: For monitoring incoming internet traffic

**Recommendation:** Start with `br-lan` for home networks

#### 2. Operating Mode

Choose between:

- **IDS (Detection)**: Only alerts, no blocking
  - Good for testing and learning
  - No impact on network traffic
  - Recommended for beginners

- **IPS (Prevention)**: Actively blocks threats
  - Requires inline mode
  - Can affect performance
  - Recommended after testing in IDS mode

#### 3. DAQ Method

Select the Data Acquisition method:

- **pcap**: Standard packet capture (most compatible)
- **afpacket**: Linux-specific, better performance
- **nfq**: Netfilter queue for IPS mode
- **dump**: File replay for testing

**Recommendation:** Use `afpacket` for best performance on Linux

#### 4. Initial Configuration

```
Network Interface: br-lan
Operating Mode: IDS
DAQ Method: afpacket
Enable Snort: Yes
Manual Mode: No (use UCI configuration)
```

---

## Dashboard Overview

### Service Status Section

The top section displays real-time information:

#### Status Indicators

- **Running (Green)**: Snort is active and monitoring
- **Stopped (Red)**: Snort is not running
- **PID**: Process ID of running Snort instance
- **Memory Usage**: Current memory consumption
- **System Memory**: Total/Used/Free RAM
- **Alert Count**: Total alerts detected
- **Interface**: Currently monitored interface
- **Mode**: Current operating mode (IDS/IPS)
- **DAQ Method**: Active data acquisition method

#### Quick Actions

- **Start**: Launch Snort service
- **Stop**: Terminate Snort service
- **Restart**: Reload Snort with new configuration
- **Enable at boot**: Auto-start on system boot
- **Disable at boot**: Prevent auto-start

#### Recent Alerts Widget

Shows the last 5 detected alerts with:
- Timestamp
- Alert classification
- Source/destination IPs
- Protocol information

---

## Configuration

### Basic Configuration

#### Service Settings

| Setting | Description | Recommended |
|---------|-------------|-------------|
| **Enable Snort** | Master on/off switch | Enable |
| **Manual mode** | Use snort.lua directly | Disable for UCI control |
| **Interface** | Network interface to monitor | br-lan |
| **IDS/IPS mode** | Detection or prevention | IDS (start) |
| **DAQ method** | Packet capture method | afpacket |

#### Alert Configuration

| Setting | Description | Recommended |
|---------|-------------|-------------|
| **Alert mode** | How alerts are logged | Fast |
| **Log directory** | Where to store alerts | /var/log |
| **Alert file** | Filename for alerts | alert_fast.txt |

**Alert Modes:**
- **Fast**: Quick single-line alerts
- **Full**: Detailed packet information
- **CMG**: Computer Misuse Grid format
- **JH**: Snort 2 compatible format

#### Home Network Configuration

Specify your internal networks for proper direction detection:

```
192.168.1.0/24  # Your LAN subnet
10.0.0.0/8      # Private network range
172.16.0.0/12   # Another private range
```

**Why is this important?**
- Determines inbound vs outbound traffic
- Helps identify attack direction
- Improves alert accuracy

### Advanced Configuration

#### Detection Engine

| Setting | Description | Impact |
|---------|-------------|--------|
| **Search method** | Pattern matching algorithm | Performance |
| **Search optimize** | Enable optimizations | Speed vs memory |
| **Split any-any** | Split rules for bidirectional | Memory |

**Search Methods:**
- **ac**: Aho-Corasick (balanced)
- **ac-bnfa**: Better performance
- **ac-q**: Queue-based (faster)
- **lowmem**: Low memory usage

#### Performance Tuning

| Setting | Description | Notes |
|---------|-------------|-------|
| **Max packet** | Maximum packet size | 65535 default |
| **Snaplen** | Capture length | Match max_packet |

#### Port Configuration

Configure ports for different services:

- **HTTP**: 80, 8080, 8000
- **HTTPS**: 443, 8443
- **FTP**: 21, 2100, 3535
- **SSH**: 22
- **Telnet**: 23
- **SMTP**: 25, 465, 587
- **DNS**: 53
- **Others**: As needed

### Configuration Tips

1. **Start Simple**: Use default settings initially
2. **Monitor Performance**: Watch CPU and memory usage
3. **Tune Gradually**: Adjust one setting at a time
4. **Test Changes**: Use IDS mode before IPS
5. **Document Changes**: Keep notes on modifications

---

## Service Management

### Starting Snort

**Via Web Interface:**
1. Go to Services → Snort IDS/IPS
2. Click **Start** button
3. Wait for status to show "Running"

**Via Command Line:**
```bash
/etc/init.d/snort start
```

### Stopping Snort

**Via Web Interface:**
1. Click **Stop** button
2. Wait for status to show "Stopped"

**Via Command Line:**
```bash
/etc/init.d/snort stop
```

### Restarting Snort

Use after configuration changes:

**Via Web Interface:**
1. Click **Restart** button

**Via Command Line:**
```bash
/etc/init.d/snort restart
```

### Auto-Start Configuration

**Enable auto-start:**
- Click **Enable at boot** button
- Or: `/etc/init.d/snort enable`

**Disable auto-start:**
- Click **Disable at boot** button
- Or: `/etc/init.d/snort disable`

### Service Status Check

**Via Command Line:**
```bash
# Check if running
/etc/init.d/snort status

# View process details
ps | grep snort

# Check logs
logread | grep snort
```

---

## Alert Management

### Viewing Alerts

#### Recent Alerts Widget

The dashboard shows the last 5 alerts in real-time with auto-refresh every 5 seconds.

#### Full Alerts Page

1. Navigate to **Services → Snort IDS/IPS**
2. Click **Status** tab
3. Click **See alerts** or **View all alerts**

Shows:
- Last 50 alerts (most recent first)
- Full alert details
- System logs related to Snort

#### Manual Refresh

Click the **Refresh** button to update alerts immediately.

### Understanding Alerts

#### Alert Format

```
[**] [Classification: Description] [**]
Priority: X
MM/DD-HH:MM:SS.XXXXXX
Protocol SRC_IP:PORT -> DST_IP:PORT
```

**Example:**
```
[**] [1:2100498:7] GPL ATTACK_RESPONSE id check returned root [**]
[Classification: Potentially Bad Traffic] [Priority: 2]
11/03-14:23:45.123456 192.168.1.100:45678 -> 8.8.8.8:80
TCP TTL:64 TOS:0x0 ID:54321 IpLen:20 DgmLen:60
```

#### Classification Types

- **Attempted Information Leak**: Data exfiltration attempts
- **Potentially Bad Traffic**: Suspicious but not confirmed malicious
- **Attempted User Privilege Gain**: Privilege escalation attempts
- **Successful User Privilege Gain**: Confirmed privilege escalation
- **Attempted Admin Privilege Gain**: Admin access attempts
- **Web Application Attack**: Attacks on web services
- **Denial of Service**: DoS/DDoS attempts
- **Misc activity**: General suspicious activity
- **Network Scan**: Port scanning or reconnaissance

#### Priority Levels

- **Priority 1**: High priority - immediate attention required
- **Priority 2**: Medium priority - investigate soon
- **Priority 3**: Low priority - informational

### Alert Actions

#### View Details

For detailed analysis:

```bash
# View full alert file
cat /var/log/alert_fast.txt

# View last 100 alerts
tail -100 /var/log/alert_fast.txt

# Search for specific IP
grep "192.168.1.100" /var/log/alert_fast.txt

# Count alerts by type
grep -o '\[Classification:.*\]' /var/log/alert_fast.txt | sort | uniq -c
```

#### Export Alerts

```bash
# Copy to USB
cp /var/log/alert_fast.txt /mnt/usb/snort_alerts_$(date +%Y%m%d).txt

# Download via SCP
scp root@router:/var/log/alert_fast.txt ./
```

#### Clear Old Alerts

```bash
# Backup first
cp /var/log/alert_fast.txt /var/log/alert_fast.txt.backup

# Clear current alerts
> /var/log/alert_fast.txt

# Or rotate logs
mv /var/log/alert_fast.txt /var/log/alert_fast.txt.$(date +%Y%m%d)
```

---

## Rules Management

### Updating Rules

#### Via Web Interface

1. Navigate to **Services → Snort IDS/IPS → Configuration**
2. Scroll to **Rules Management** section
3. Click **Update** button
4. Monitor progress in the status window
5. Wait for "Update completed!" message

The update process:
- Downloads latest community rules
- Extracts rule files
- Places them in `/var/snort.d/rules/`
- Cleans up temporary files automatically

#### Via Command Line

```bash
# Run rules update script
/usr/bin/snort-rules

# Monitor progress
tail -f /tmp/snort_rules_update.log

# Clean temporary files
rm -f /var/snort.d/*.tar.gz /tmp/snort*.tar.gz
```

### Rule Locations

| Location | Purpose |
|----------|---------|
| `/etc/snort/rules/` | Active rules (symlink) |
| `/var/snort.d/rules/` | Downloaded rules |
| `/etc/snort/rules/local.rules` | Custom rules |

### Using Oinkcode

If you have a registered Snort account:

1. Get your Oinkcode from https://www.snort.org/
2. In LuCI, go to **Rules Management**
3. Enter your Oinkcode in the field
4. Click **Update**

Benefits:
- Access to registered rule sets
- More comprehensive detection
- Faster updates
- Official rule sets

### Symbolic Link Management

The module can create a symbolic link to use downloaded rules:

1. Update rules first
2. Click **Create symbolic link** button
3. Confirms: `/etc/snort/rules` → `/var/snort.d/rules/`

**Why use symbolic links?**
- Automatic rule updates without moving files
- Preserves original configuration
- Easier rule management
- Cleaner directory structure

### Rule Files

Common rule categories:

- **local.rules**: Custom user rules
- **community.rules**: Community rules
- **snort3-*.rules**: Official Snort 3 rules
- **emerging-*.rules**: Emerging Threats rules

### Custom Rules

Create custom rules in `/etc/snort/rules/local.rules`:

```bash
# Example: Alert on ping to router
alert icmp any any -> 192.168.1.1 any (msg:"ICMP Ping to Router"; sid:1000001; rev:1;)

# Example: Alert on HTTP to suspicious domain
alert tcp any any -> any 80 (msg:"HTTP to suspicious domain"; content:"bad-site.com"; sid:1000002; rev:1;)

# Example: Alert on SSH brute force attempts
alert tcp any any -> 192.168.1.0/24 22 (msg:"Possible SSH brute force"; flags:S; threshold:type both, track by_src, count 5, seconds 60; sid:1000003; rev:1;)
```

**Important:** 
- Use SID >= 1000000 for custom rules
- Restart Snort after adding rules
- Test rules in IDS mode first

### Disabling Rule Categories

Edit `/etc/snort/snort.lua` to comment out unwanted rules:

```lua
-- Disable specific rule file
-- ips = { include = 'rules/emerging-dos.rules' }

-- Enable specific rule file
ips = { include = 'rules/local.rules' }
```

---

## Best Practices

### Security Recommendations

1. **Start in IDS Mode**
   - Learn what's normal for your network
   - Identify false positives
   - Tune before enabling IPS

2. **Regular Updates**
   - Update rules weekly
   - Check for Snort updates monthly
   - Review new rule categories

3. **Monitor Performance**
   - Watch memory usage
   - Check packet drop rates
   - Adjust if performance degrades

4. **Review Alerts Daily**
   - Check for patterns
   - Investigate high-priority alerts
   - Keep records of incidents

5. **Backup Configuration**
   ```bash
   # Backup UCI config
   cp /etc/config/snort /etc/config/snort.backup
   
   # Backup custom rules
   cp /etc/snort/rules/local.rules /etc/snort/rules/local.rules.backup
   ```

### Performance Optimization

1. **Disable Unused Rules**
   - Only enable needed categories
   - Comment out unnecessary rules
   - Focus on your threat model

2. **Adjust Search Method**
   - Try different algorithms
   - Balance speed vs accuracy
   - Test under load

3. **Limit Monitored Traffic**
   - Use specific interfaces
   - Set HOME_NET correctly
   - Filter irrelevant traffic

4. **Hardware Considerations**
   - Minimum 256MB RAM
   - Faster CPU helps
   - Consider SSD for logs

### Network Segmentation

For better security:

```
Internet → WAN → Router/Snort → DMZ (servers)
                            └─→ LAN (users)
```

Monitor:
- WAN interface for incoming threats
- DMZ-to-LAN for lateral movement
- LAN-to-Internet for data exfiltration

### Logging Strategy

1. **Alert Levels**
   - High priority: Investigate immediately
   - Medium priority: Daily review
   - Low priority: Weekly summary

2. **Log Rotation**
   ```bash
   # Add to cron
   0 0 * * 0 mv /var/log/alert_fast.txt /var/log/alert_fast.txt.$(date +\%Y\%m\%d)
   ```

3. **Remote Logging**
   - Send alerts to syslog server
   - Use SIEM if available
   - Keep local backup

---

## Advanced Usage

### Command Line Management

#### Manual Snort Execution

```bash
# Test configuration
snort -c /etc/snort/snort.lua -T

# Run in console mode
snort -c /etc/snort/snort.lua -i br-lan -A console

# Verbose mode
snort -c /etc/snort/snort.lua -i br-lan -A console -v

# Debug mode
snort -c /etc/snort/snort.lua -i br-lan -A console -v -d
```

#### Statistics

```bash
# View packet statistics
snort -c /etc/snort/snort.lua -i br-lan -A console --lua 'daq = { stats = 1 }'

# Rule statistics
snort --rule-to-text /etc/snort/rules/*.rules | wc -l
```

### UCI Configuration

Direct UCI manipulation:

```bash
# View current configuration
uci show snort

# Change interface
uci set snort.snort.interface='eth1'

# Enable IPS mode
uci set snort.snort.mode='inline'

# Save and apply
uci commit snort
/etc/init.d/snort restart
```

### Integration with Other Services

#### Firewall Integration

```bash
# Add iptables rule for IPS mode
iptables -I FORWARD -j NFQUEUE --queue-num 0

# Make persistent in /etc/firewall.user
```

#### Notification Scripts

Create `/etc/snort/alert-script.sh`:

```bash
#!/bin/sh
# Send email on high-priority alerts
if grep -q "Priority: 1" /var/log/alert_fast.txt; then
    # Send notification (implement your preferred method)
    logger -t snort "HIGH PRIORITY ALERT DETECTED"
fi
```

#### Automated Response

Example: Block attacker IPs automatically

```bash
#!/bin/sh
# Parse alerts and block IPs
tail -f /var/log/alert_fast.txt | while read line; do
    if echo "$line" | grep -q "Priority: 1"; then
        IP=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
        iptables -I INPUT -s $IP -j DROP
        logger -t snort "Blocked IP: $IP"
    fi
done
```

### Troubleshooting Advanced Issues

#### High False Positive Rate

1. Tune rule thresholds
2. Add suppression for known-good traffic
3. Adjust HOME_NET and EXTERNAL_NET
4. Review rule documentation

#### Performance Issues

```bash
# Check packet drop rate
snort -c /etc/snort/snort.lua -i br-lan -A console --lua 'daq = { stats = 1 }'

# Monitor CPU usage
top | grep snort

# Check memory
free -m
```

#### Debug Logging

Enable verbose logging in `/etc/snort/snort.lua`:

```lua
output = {
    logging = {
        enable = true,
        level = 'debug',
    }
}
```

---

## Quick Reference

### Essential Commands

```bash
# Service control
/etc/init.d/snort start|stop|restart|status|enable|disable

# View alerts
tail -f /var/log/alert_fast.txt

# Test configuration
snort -c /etc/snort/snort.lua -T

# Update rules
/usr/bin/snort-rules

# View logs
logread | grep snort

# Check process
ps | grep snort
```

### Important Files

```
/etc/config/snort                    # UCI configuration
/etc/snort/snort.lua                 # Main Snort config
/etc/snort/rules/                    # Rule files
/var/log/alert_fast.txt              # Alerts log
/etc/init.d/snort                    # Init script
/usr/lib/lua/luci/controller/snort.lua  # LuCI controller
```

### Support Resources

- Snort3 Documentation: https://www.snort.org/documents
- OpenWrt Documentation: https://openwrt.org/docs
- Community Forums: https://www.snort.org/community

---

**Version:** 3.6  
**Last Updated:** November 2025
