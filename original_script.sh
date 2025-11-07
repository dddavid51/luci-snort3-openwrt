#!/bin/sh
# Installation automatique complète du module LuCI pour Snort3
# Téléchargez ce script et exécutez-le : sh install_luci_snort.sh

set -e

echo "================================================"
echo "Installation automatique LuCI Snort3"
echo "================================================"

# Vérifier root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERREUR: Ce script doit être exécuté en tant que root"
    exit 1
fi

# Vérifier Snort
if ! command -v snort >/dev/null 2>&1; then
    echo "ERREUR: Snort3 non installé"
    exit 1
fi

echo ""
echo "Création des répertoires..."
mkdir -p /usr/lib/lua/luci/controller
mkdir -p /usr/lib/lua/luci/model/cbi/snort
mkdir -p /usr/lib/lua/luci/view/snort
mkdir -p /usr/lib/lua/luci/i18n

echo ""
echo "Installation du contrôleur..."
cat > /usr/lib/lua/luci/controller/snort.lua << 'EOF_CONTROLLER'
-- /usr/lib/lua/luci/controller/snort.lua
module("luci.controller.snort", package.seeall)

function index()
    if not nixio.fs.access("/etc/config/snort") then
        return
    end
    local page
    page = entry({"admin", "services", "snort"}, cbi("snort/config"), _("Snort IDS/IPS"), 60)
    page.dependent = true
    entry({"admin", "services", "snort", "status"}, call("action_status_page"), _("Status"), 1)
    entry({"admin", "services", "snort", "alerts"}, call("action_alerts"), _("Alerts"), 2)
    entry({"admin", "services", "snort", "action"}, call("action_service"))
    entry({"admin", "services", "snort", "update_rules"}, call("action_update_rules"))
    entry({"admin", "services", "snort", "check_update_status"}, call("action_check_update_status"))
    entry({"admin", "services", "snort", "cleanup_temp"}, call("action_cleanup_temp"))
    entry({"admin", "services", "snort", "fix_rules"}, call("action_fix_rules"))
    entry({"admin", "services", "snort", "get_status"}, call("action_get_status"))
end

function action_status_page()
	luci.template.render("snort/status_page")
end

function action_get_status()
	local sys = require "luci.sys"
	local util = require "luci.util"
	local uci = require "luci.model.uci".cursor()
	local status = sys.call("/etc/init.d/snort status >/dev/null 2>&1") == 0
	local pid = util.trim(sys.exec("ps | grep '/usr/bin/snort' | grep -v grep | awk '{print $1}'"))
	local mem_usage = "N/A"
	if pid ~= "" then
		mem_usage = util.trim(sys.exec("ps | grep '^[ ]*" .. pid .. "' | awk '{print $5}'"))
	end
	local mem_total = tonumber(util.trim(sys.exec("awk '/MemTotal/ {print $2}' /proc/meminfo")))
	local mem_free = tonumber(util.trim(sys.exec("awk '/MemFree/ {print $2}' /proc/meminfo")))
	local mem_used = mem_total - mem_free
	local mem_percent = math.floor((mem_used / mem_total) * 100)
	local alert_count = tonumber(util.trim(sys.exec("[ -f /var/log/alert_fast.txt ] && wc -l < /var/log/alert_fast.txt || echo 0")))
	local interface = uci:get("snort", "snort", "interface") or "N/A"
	local mode = uci:get("snort", "snort", "mode") or "N/A"
	local method = uci:get("snort", "snort", "method") or "N/A"
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		running = status,
		pid = pid,
		mem_usage = mem_usage,
		mem_total = math.floor(mem_total / 1024),
		mem_used = math.floor(mem_used / 1024),
		mem_free = math.floor(mem_free / 1024),
		mem_percent = mem_percent,
		alert_count = alert_count,
		interface = interface,
		mode = mode,
		method = method
	})
end

function action_alerts()
	local sys = require "luci.sys"
	local i18n = require "luci.i18n"
	luci.template.render("snort/alerts", {
		alerts = sys.exec("[ -f /var/log/alert_fast.txt ] && tail -50 /var/log/alert_fast.txt | tac || echo '" .. i18n.translate("No alerts") .. "'"),
		logs = sys.exec("logread | grep snort | tail -20 | tac")
	})
end

function action_service()
	local sys = require "luci.sys"
	local i18n = require "luci.i18n"
	local action = luci.http.formvalue("action")
	local result = {success = false, message = ""}
	if action == "start" then
		sys.call("/etc/init.d/snort start >/dev/null 2>&1")
		result.success = true
		result.message = i18n.translate("Snort started")
	elseif action == "stop" then
		sys.call("/etc/init.d/snort stop >/dev/null 2>&1")
		result.success = true
		result.message = i18n.translate("Snort stopped")
	elseif action == "restart" then
		sys.call("/etc/init.d/snort restart >/dev/null 2>&1")
		result.success = true
		result.message = i18n.translate("Snort restarted")
	elseif action == "enable" then
		sys.call("/etc/init.d/snort enable >/dev/null 2>&1")
		result.success = true
		result.message = i18n.translate("Auto-start enabled")
	elseif action == "disable" then
		sys.call("/etc/init.d/snort disable >/dev/null 2>&1")
		result.success = true
		result.message = i18n.translate("Auto-start disabled")
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json(result)
end

function action_update_rules()
    local sys = require "luci.sys"
    local nixio = require "nixio"
    local i18n = require "luci.i18n"
    local result = {success = false, message = ""}
    
    -- Créer un fichier de lock pour éviter les exécutions multiples
    local lock_file = "/tmp/snort_rules_update.lock"
    
    if nixio.fs.access(lock_file) then
        result.message = i18n.translate("Update already in progress...")
        luci.http.prepare_content("application/json")
        luci.http.write_json(result)
        return
    end
    
    -- Créer le fichier lock
    sys.exec("touch " .. lock_file)
    
    -- Lancer la mise à jour en arrière-plan avec un suivi et nettoyage
    local cmd = "/usr/bin/snort-rules > /tmp/snort_rules_update.log 2>&1; "
    cmd = cmd .. "rm -f /var/snort.d/*.tar.gz /tmp/snort*.tar.gz 2>/dev/null; "
    cmd = cmd .. "rm -f /var/snort.d/rules/*.tar.gz 2>/dev/null; "
    cmd = cmd .. "rm -f " .. lock_file .. "; "
    cmd = cmd .. "echo 'FINISHED' >> /tmp/snort_rules_update.log"
    
    -- Exécuter en arrière-plan
    sys.call("(" .. cmd .. ") &")
    
    result.success = true
    result.message = i18n.translate("Update launched in background. Monitoring starts automatically.")
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_check_update_status()
    local sys = require "luci.sys"
    local nixio = require "nixio"
    local util = require "luci.util"
    
    local lock_file = "/tmp/snort_rules_update.lock"
    local log_file = "/tmp/snort_rules_update.log"
    
    local is_running = nixio.fs.access(lock_file)
    local log_content = ""
    local is_finished = false
    
    if nixio.fs.access(log_file) then
        log_content = util.trim(sys.exec("tail -20 " .. log_file))
        is_finished = string.find(log_content, "FINISHED") ~= nil
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({
        running = is_running and not is_finished,
        finished = is_finished,
        log = log_content
    })
end

function action_cleanup_temp()
    local sys = require "luci.sys"
    local i18n = require "luci.i18n"
    local result = {success = false, message = ""}
    
    -- Nettoyage des fichiers tar.gz
    sys.call("rm -f /var/snort.d/*.tar.gz /tmp/snort*.tar.gz 2>/dev/null")
    sys.call("rm -f /var/snort.d/rules/*.tar.gz 2>/dev/null")
    sys.call("rm -f /tmp/snort_rules_update.log 2>/dev/null")
    sys.call("rm -f /tmp/snort_rules_update.lock 2>/dev/null")
    
    result.success = true
    result.message = i18n.translate("Temporary files cleaned")
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)
end

function action_fix_rules()
	local sys = require "luci.sys"
	local i18n = require "luci.i18n"
	local config_dir = "/etc/snort"
	local temp_dir = "/var/snort.d"
	local config_rules = config_dir .. "/rules"
	local temp_rules = temp_dir .. "/rules"
	local success = false
	local message = ""
	if sys.call("[ -d " .. temp_rules .. " ]") == 0 then
		if sys.call("[ -d " .. config_rules .. " ] && [ ! -L " .. config_rules .. " ]") == 0 then
			sys.call("mv " .. config_rules .. " " .. config_rules .. ".backup")
			message = i18n.translate("Old directory backed up. ")
		elseif sys.call("[ -L " .. config_rules .. " ]") == 0 then
			sys.call("rm " .. config_rules)
		end
		if sys.call("ln -sf " .. temp_rules .. " " .. config_rules) == 0 then
			success = true
			message = message .. i18n.translate("Symbolic link created successfully")
		else
			message = message .. i18n.translate("Error creating symbolic link")
		end
	else
		message = i18n.translate("Directory does not exist: ") .. temp_rules
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		success = success,
		message = message
	})
end
EOF_CONTROLLER

echo "Installation de la configuration CBI..."
cat > /usr/lib/lua/luci/model/cbi/snort/config.lua << 'EOF_CBI'
-- /usr/lib/lua/luci/model/cbi/snort/config.lua
local sys = require "luci.sys"
local util = require "luci.util"

m = Map("snort", translate("Snort IDS/IPS"), 
	translate("Snort is an open source intrusion detection and prevention system."))

s = m:section(TypedSection, "snort", translate("Service Status"))
s.anonymous = true
s.addremove = false
st = s:option(DummyValue, "_status", translate("State"))
st.template = "snort/status"
btn = s:option(Button, "_control")
btn.template = "snort/control"
alerts = s:option(DummyValue, "_alerts", translate("Recent Alerts"))
alerts.template = "snort/recent_alerts"

s = m:section(TypedSection, "snort", translate("Configuration"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "enabled", translate("Enable Snort"),
	translate("Enable or disable Snort service"))
o.default = "0"
o.rmempty = false

o = s:option(Flag, "manual", translate("Manual mode"),
	translate("Use manual configuration (snort.lua)"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "interface", translate("Network interface"),
	translate("Network interface to monitor (e.g. br-lan, eth0)"))
o.placeholder = "br-lan"
o.datatype = "string"

o = s:option(Value, "home_net", translate("Local network"),
	translate("IP address range to protect"))
o.placeholder = "192.168.1.0/24"
o.default = "192.168.1.0/24"
o.datatype = "string"

o = s:option(Value, "external_net", translate("External network"),
	translate("External IP address range"))
o.placeholder = "any"
o.default = "any"
o.datatype = "string"

o = s:option(ListValue, "mode", translate("Operating mode"),
	translate("IDS = Detection only, IPS = Active prevention"))
o:value("ids", "IDS (Detection)")
o:value("ips", "IPS (Prevention)")
o.default = "ids"

o = s:option(ListValue, "method", translate("DAQ method"),
	translate("Packet acquisition method"))
o:value("pcap", "PCAP (Recommended)")
o:value("afpacket", "AF_PACKET")
o:value("nfq", "NFQ (for IPS)")
o.default = "pcap"

o = s:option(Value, "snaplen", translate("Capture Length"),
	translate("Maximum packet capture size"))
o.placeholder = "1518"
o.default = "1518"
o.datatype = "range(1518,65535)"

s = m:section(TypedSection, "snort", translate("Logging configuration"))
s.anonymous = true
s.addremove = false

o = s:option(Flag, "logging", translate("Enable logging"),
	translate("Enable event logging"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "log_dir", translate("Log directory"),
	translate("Path where logs will be stored"))
o.placeholder = "/var/log"
o.default = "/var/log"
o.datatype = "directory"

o = s:option(Value, "config_dir", translate("Configuration directory"),
	translate("Snort configuration directory path"))
o.placeholder = "/etc/snort"
o.default = "/etc/snort"
o.datatype = "directory"

o = s:option(Value, "temp_dir", translate("Temporary directory"),
	translate("Directory for temporary files and downloaded rules"))
o.placeholder = "/var/snort.d"
o.default = "/var/snort.d"
o.datatype = "directory"

s = m:section(TypedSection, "snort", translate("Rules management"))
s.anonymous = true
s.addremove = false

update_status = s:option(DummyValue, "_update_status", translate("Update status"))
update_status.rawhtml = true
function update_status.cfgvalue(self, section)
    return [[
        <div id="update_status" style="margin: 10px 0;">
            <em>]] .. translate("Click on \"Update\" to start the rules update") .. [[</em>
        </div>
        <script type="text/javascript">
        // Vérifier automatiquement si une mise à jour est en cours
        function checkUpdateStatus() {
            XHR.get(']] .. luci.dispatcher.build_url("admin/services/snort/check_update_status") .. [[', null,
                function(x, status) {
                    var statusDiv = document.getElementById('update_status');
                    if (status.running) {
                        statusDiv.innerHTML = '<span style="color:orange">&#9888; ]] .. translate("Update in progress...") .. [[</span>';
                        setTimeout(checkUpdateStatus, 3000);
                    } else if (status.finished) {
                        statusDiv.innerHTML = '<span style="color:green">&#10003; ]] .. translate("Update completed!") .. [[</span>';
                        // Nettoyage automatique après réussite
                        XHR.get(']] .. luci.dispatcher.build_url("admin/services/snort/cleanup_temp") .. [[', null, function() {});
                    }
                }
            );
        }
        
        // Vérifier au chargement de la page si une mise à jour est en cours
        window.onload = function() {
            XHR.get(']] .. luci.dispatcher.build_url("admin/services/snort/check_update_status") .. [[', null,
                function(x, status) {
                    if (status.running) {
                        checkUpdateStatus();
                    }
                }
            );
        };
        </script>
    ]]
end

local function check_and_fix_rules_symlink()
	local config_dir = "/etc/snort"
	local temp_dir = "/var/snort.d"
	local config_rules = config_dir .. "/rules"
	local temp_rules = temp_dir .. "/rules"
	if sys.call("[ -d " .. temp_rules .. " ]") == 0 then
		if sys.call("[ -d " .. config_rules .. " ] && [ ! -L " .. config_rules .. " ]") == 0 then
			sys.call("mv " .. config_rules .. " " .. config_rules .. ".backup 2>/dev/null")
		elseif sys.call("[ -L " .. config_rules .. " ]") == 0 then
			sys.call("rm " .. config_rules)
		end
		sys.call("ln -sf " .. temp_rules .. " " .. config_rules)
		return true
	end
	return false
end

rules_info = s:option(DummyValue, "_rules_info", translate("Rules location"))
rules_info.rawhtml = true
function rules_info.cfgvalue(self, section)
	local config_rules = "/etc/snort/rules"
	local temp_rules = "/var/snort.d/rules"
	local status = ""
	if sys.call("[ -L " .. config_rules .. " ]") == 0 then
		local target = util.trim(sys.exec("readlink " .. config_rules))
		status = '<span style="color:green">&#10003; ' .. translate("Active symbolic link") .. ': ' .. config_rules .. ' &#8594; ' .. target .. '</span>'
	elseif sys.call("[ -d " .. temp_rules .. " ]") == 0 then
		status = '<span style="color:orange">&#9888; ' .. translate("Rules are in") .. ' ' .. temp_rules .. '<br>' ..
		         '<a href="javascript:fixRulesSymlink()" class="cbi-button cbi-button-apply">' .. translate("Create symbolic link") .. '</a></span>'
	else
		status = '<span style="color:red">&#10007; ' .. translate("No rules directory found") .. '</span>'
	end
	local rule_count = util.trim(sys.exec("find /etc/snort/rules -name '*.rules' 2>/dev/null | wc -l"))
	if tonumber(rule_count) > 0 then
		status = status .. '<br><span style="color:#666">' .. translate("Rule files:") .. ' ' .. rule_count .. '</span>'
	end
	return status
end

rules_script = s:option(DummyValue, "_rules_script")
rules_script.rawhtml = true
function rules_script.cfgvalue()
	return [[<script type="text/javascript">
	function fixRulesSymlink() {
		if (confirm(']] .. translate("Create a symbolic link from /var/snort.d/rules to /etc/snort/rules?") .. [[')) {
			XHR.get(']] .. luci.dispatcher.build_url("admin/services/snort/fix_rules") .. [[', null,
				function(x, result) {
					if (result && result.success) {
						alert(']] .. translate("Symbolic link created successfully!") .. [[');
						location.reload();
					} else {
						alert(']] .. translate("Error creating symbolic link") .. [[');
					}
				}
			);
		}
	}
	</script>]]
end

o = s:option(Value, "oinkcode", translate("Oinkcode"),
	translate("Access code to download official Snort rules (optional)"))
o.password = true
o.placeholder = translate("Enter your Oinkcode if you have one")

o = s:option(ListValue, "action", translate("Rule action"),
	translate("Default action for rules"))
o:value("default", translate("Default"))
o:value("alert", translate("Alert"))
o:value("block", translate("Block"))
o:value("drop", translate("Drop"))
o:value("reject", translate("Reject"))
o.default = "default"

btn = s:option(Button, "_update_rules", translate("Update rules"))
btn.inputtitle = translate("Update")
btn.inputstyle = "apply"
function btn.write(self, section)
    -- Lancer la mise à jour en arrière-plan
    luci.sys.call("(/usr/bin/snort-rules > /tmp/snort_rules_update.log 2>&1; " ..
                  "rm -f /var/snort.d/*.tar.gz /tmp/snort*.tar.gz 2>/dev/null; " ..
                  "rm -f /var/snort.d/rules/*.tar.gz 2>/dev/null; " ..
                  "echo 'FINISHED' >> /tmp/snort_rules_update.log) &")
    
    -- Créer le fichier lock
    luci.sys.call("touch /tmp/snort_rules_update.lock")
    
    -- Réparer le lien symbolique si nécessaire
    check_and_fix_rules_symlink()
    
    -- Message de confirmation
    luci.http.redirect(luci.dispatcher.build_url("admin/services/snort"))
end

return m
EOF_CBI

echo "Installation des vues..."
cat > /usr/lib/lua/luci/view/snort/status.htm << 'EOF_STATUS'
<%+cbi/valueheader%>
<script type="text/javascript">//<![CDATA[
XHR.poll(3, '<%=url("admin/services/snort/get_status")%>', null,
	function(x, status) {
		var statusDiv = document.getElementById('snort_status');
		if (status.running) {
			statusDiv.innerHTML = '<span style="color:green; font-weight:bold">&#9679; <%:Running%></span>';
		} else {
			statusDiv.innerHTML = '<span style="color:red; font-weight:bold">&#9679; <%:Stopped%></span>';
		}
		document.getElementById('snort_pid').innerHTML = status.pid || 'N/A';
		document.getElementById('snort_mem').innerHTML = status.mem_usage;
		document.getElementById('snort_alerts').innerHTML = status.alert_count;
		document.getElementById('snort_interface').innerHTML = status.interface;
		document.getElementById('snort_mode').innerHTML = status.mode.toUpperCase();
		document.getElementById('snort_method').innerHTML = status.method.toUpperCase();
		var memPercent = status.mem_percent;
		var memColor = memPercent > 80 ? 'red' : (memPercent > 60 ? 'orange' : 'green');
		document.getElementById('sys_mem').innerHTML = 
			'<span style="color:' + memColor + '">' + 
			status.mem_used + ' MB / ' + status.mem_total + ' MB (' + memPercent + '%)</span>';
	}
);
//]]></script>
<div style="background: #f9f9f9; padding: 15px; border-radius: 5px; border: 1px solid #ddd;">
	<table style="width: 100%;">
		<tr><td style="width: 30%; font-weight: bold;"><%:Status%>:</td><td id="snort_status"><em><%:Loading...%></em></td></tr>
		<tr><td style="font-weight: bold;">PID:</td><td id="snort_pid">-</td></tr>
		<tr><td style="font-weight: bold;"><%:Snort memory%>:</td><td id="snort_mem">-</td></tr>
		<tr><td style="font-weight: bold;"><%:System memory%>:</td><td id="sys_mem">-</td></tr>
		<tr><td style="font-weight: bold;"><%:Total alerts%>:</td><td id="snort_alerts">-</td></tr>
		<tr><td style="font-weight: bold;"><%:Interface%>:</td><td id="snort_interface">-</td></tr>
		<tr><td style="font-weight: bold;"><%:Mode%>:</td><td id="snort_mode">-</td></tr>
		<tr><td style="font-weight: bold;"><%:DAQ method%>:</td><td id="snort_method">-</td></tr>
	</table>
</div>
<%+cbi/valuefooter%>
EOF_STATUS

cat > /usr/lib/lua/luci/view/snort/control.htm << 'EOF_CONTROL'
<%+cbi/valueheader%>
<script type="text/javascript">//<![CDATA[
function snortAction(action) {
	var btn = document.getElementById('btn_' + action);
	btn.disabled = true;
	btn.value = '<%:In progress...%>';
	XHR.get('<%=url("admin/services/snort/action")%>', { action: action },
		function(x, result) {
			if (result.success) {
				alert(result.message);
			} else {
				alert('<%:Error%>: ' + result.message);
			}
			btn.disabled = false;
			btn.value = btn.getAttribute('data-original');
			location.reload();
		}
	);
}
//]]></script>
<div style="padding: 10px 0;">
	<input type="button" id="btn_start" class="cbi-button cbi-button-apply" value="&#9654; <%:Start%>" 
		data-original="&#9654; <%:Start%>" onclick="snortAction('start')" style="margin: 5px;" />
	<input type="button" id="btn_stop" class="cbi-button cbi-button-reset" value="&#9632; <%:Stop%>" 
		data-original="&#9632; <%:Stop%>" onclick="snortAction('stop')" style="margin: 5px;" />
	<input type="button" id="btn_restart" class="cbi-button cbi-button-reload" value="&#8635; <%:Restart%>" 
		data-original="&#8635; <%:Restart%>" onclick="snortAction('restart')" style="margin: 5px;" />
	<input type="button" id="btn_enable" class="cbi-button cbi-button-save" value="<%:Enable at boot%>" 
		data-original="<%:Enable at boot%>" onclick="snortAction('enable')" style="margin: 5px;" />
	<input type="button" id="btn_disable" class="cbi-button cbi-button-remove" value="<%:Disable at boot%>" 
		data-original="<%:Disable at boot%>" onclick="snortAction('disable')" style="margin: 5px;" />
</div>
<%+cbi/valuefooter%>
EOF_CONTROL

cat > /usr/lib/lua/luci/view/snort/status_page.htm << 'EOF_STATUS_PAGE'
<%+header%>
<h2 name="content"><%:Snort IDS/IPS%></h2>

<script type="text/javascript">//<![CDATA[
XHR.poll(3, '<%=url("admin/services/snort/get_status")%>', null,
	function(x, status) {
		if (!status) return;
		var st = document.getElementById('snort_status');
		if (st) st.innerHTML = status.running ? '<span style="color:green;font-weight:bold">&#9679; <%:Running%></span>' : '<span style="color:red;font-weight:bold">&#9679; <%:Stopped%></span>';
		var el = document.getElementById;
		if (document.getElementById('snort_pid')) document.getElementById('snort_pid').innerHTML = status.pid || 'N/A';
		if (document.getElementById('snort_mem')) document.getElementById('snort_mem').innerHTML = status.mem_usage;
		if (document.getElementById('snort_alerts')) document.getElementById('snort_alerts').innerHTML = status.alert_count;
		if (document.getElementById('snort_interface')) document.getElementById('snort_interface').innerHTML = status.interface;
		if (document.getElementById('snort_mode')) document.getElementById('snort_mode').innerHTML = status.mode.toUpperCase();
		if (document.getElementById('snort_method')) document.getElementById('snort_method').innerHTML = status.method.toUpperCase();
		var p = status.mem_percent;
		var c = p > 80 ? 'red' : (p > 60 ? 'orange' : 'green');
		if (document.getElementById('sys_mem')) document.getElementById('sys_mem').innerHTML = '<span style="color:'+c+'">'+status.mem_used+' MB / '+status.mem_total+' MB ('+p+'%)</span>';
	}
);
function snortAction(action) {
	XHR.get('<%=url("admin/services/snort/action")%>', {action: action}, function(x, result) {
		if (result && result.success) alert(result.message);
		else alert('<%:Error%>: ' + (result ? result.message : ''));
		location.reload();
	});
}
//]]></script>

<fieldset class="cbi-section">
	<legend><%:Service Status%></legend>
	<div style="background: #f9f9f9; padding: 15px; border-radius: 5px; border: 1px solid #ddd;">
		<table style="width: 100%;">
			<tr><td style="width: 30%; font-weight: bold;"><%:Status%>:</td><td id="snort_status"><em><%:Loading...%></em></td></tr>
			<tr><td style="font-weight: bold;">PID:</td><td id="snort_pid">-</td></tr>
			<tr><td style="font-weight: bold;"><%:Snort memory%>:</td><td id="snort_mem">-</td></tr>
			<tr><td style="font-weight: bold;"><%:System memory%>:</td><td id="sys_mem">-</td></tr>
			<tr><td style="font-weight: bold;"><%:Total alerts%>:</td><td id="snort_alerts">-</td></tr>
			<tr><td style="font-weight: bold;"><%:Interface%>:</td><td id="snort_interface">-</td></tr>
			<tr><td style="font-weight: bold;"><%:Mode%>:</td><td id="snort_mode">-</td></tr>
			<tr><td style="font-weight: bold;"><%:DAQ method%>:</td><td id="snort_method">-</td></tr>
		</table>
	</div>
</fieldset>

<fieldset class="cbi-section">
	<legend><%:Controls%></legend>
	<div style="padding: 10px 0;">
		<input type="button" class="cbi-button cbi-button-apply" value="&#9654; <%:Start%>" onclick="snortAction('start')" style="margin: 5px;" />
		<input type="button" class="cbi-button cbi-button-reset" value="&#9632; <%:Stop%>" onclick="snortAction('stop')" style="margin: 5px;" />
		<input type="button" class="cbi-button cbi-button-reload" value="&#8635; <%:Restart%>" onclick="snortAction('restart')" style="margin: 5px;" />
		<input type="button" class="cbi-button cbi-button-save" value="<%:Enable at boot%>" onclick="snortAction('enable')" style="margin: 5px;" />
		<input type="button" class="cbi-button cbi-button-remove" value="<%:Disable at boot%>" onclick="snortAction('disable')" style="margin: 5px;" />
	</div>
</fieldset>

<fieldset class="cbi-section">
	<legend><%:Quick actions%></legend>
	<div style="padding: 15px;">
		<a href="<%=url('admin/services/snort/alerts')%>" class="cbi-button cbi-button-apply"><%:See alerts%></a>
		<a href="<%=url('admin/services/snort')%>" class="cbi-button cbi-button-neutral"><%:Full configuration%></a>
	</div>
</fieldset>

<%+footer%>
EOF_STATUS_PAGE

cat > /usr/lib/lua/luci/view/snort/alerts.htm << 'EOF_ALERTS'
<%+header%>
<h2 name="content"><%:Snort - Alerts and Logs%></h2>
<style>
.alert-box {
	background: #f8f9fa;
	border-left: 4px solid #dc3545;
	padding: 15px;
	margin: 15px 0;
	border-radius: 4px;
	font-family: monospace;
	font-size: 0.9em;
	max-height: 500px;
	overflow-y: auto;
}
.log-box {
	background: #f0f0f0;
	border-left: 4px solid #007bff;
	padding: 15px;
	margin: 15px 0;
	border-radius: 4px;
	font-family: monospace;
	font-size: 0.9em;
	max-height: 400px;
	overflow-y: auto;
}
.alert-line, .log-line {
	padding: 5px 0;
	border-bottom: 1px solid #e0e0e0;
	word-wrap: break-word;
}
.alert-line:last-child, .log-line:last-child {
	border-bottom: none;
}
</style>
<fieldset class="cbi-section">
	<legend><%:Recent alerts (50 most recent)%></legend>
	<div class="alert-box">
		<% 
		local alerts = alerts or translate("No alerts recorded")
		for line in alerts:gmatch("[^\n]+") do 
		%>
			<div class="alert-line"><%=pcdata(line)%></div>
		<% end %>
	</div>
	<div style="text-align: right; margin-top: 10px;">
		<input type="button" class="cbi-button cbi-button-reload" value="<%:Refresh%>" onclick="location.reload()" />
	</div>
</fieldset>
<fieldset class="cbi-section">
	<legend><%:Snort system logs (20 most recent)%></legend>
	<div class="log-box">
		<% 
		local logs = logs or translate("No logs")
		for line in logs:gmatch("[^\n]+") do 
		%>
			<div class="log-line"><%=pcdata(line)%></div>
		<% end %>
	</div>
</fieldset>
<fieldset class="cbi-section">
	<legend><%:Actions%></legend>
	<div style="padding: 10px;">
		<p><%:View detailed reports via SSH with the command:%></p>
		<pre style="background: #f0f0f0; padding: 10px; border-radius: 4px;">snort-mgr report -v (requires coreutils-sort package)</pre>
		<p style="margin-top: 15px;"><%:Log files:%></p>
		<ul>
			<li><code>/var/log/alert_fast.txt</code> - <%:Fast alerts%></li>
			<li><code>/var/log/*alert_json.txt</code> - <%:Detailed JSON alerts%></li>
		</ul>
	</div>
</fieldset>
<%+footer%>
EOF_ALERTS

cat > /usr/lib/lua/luci/view/snort/recent_alerts.htm << 'EOF_RECENT'
<%+cbi/valueheader%>
<style>
.recent-alerts-box {
	background: #fff8e1;
	border-left: 4px solid #ff9800;
	padding: 15px;
	margin: 10px 0;
	border-radius: 5px;
	font-family: monospace;
	font-size: 0.85em;
	max-height: 300px;
	overflow-y: auto;
}
.alert-item {
	padding: 8px;
	margin: 5px 0;
	background: white;
	border-left: 3px solid #dc3545;
	border-radius: 3px;
}
.alert-item:hover {
	background: #f5f5f5;
}
.alert-message {
	color: #d32f2f;
	font-weight: bold;
	margin: 5px 0;
}
.no-alerts {
	text-align: center;
	color: #4caf50;
	padding: 20px;
	font-weight: bold;
}
.alert-count {
	background: #dc3545;
	color: white;
	padding: 2px 8px;
	border-radius: 10px;
	font-size: 0.9em;
	margin-left: 10px;
}
</style>
<script type="text/javascript">//<![CDATA[
function updateRecentAlerts() {
	XHR.get('<%=url("admin/services/snort/get_status")%>', null,
		function(x, status) {
			var alertCount = document.getElementById('alert_count_badge');
			if (alertCount) {
				alertCount.innerHTML = status.alert_count || '0';
			}
		}
	);
}
XHR.poll(5, null, null, updateRecentAlerts);
updateRecentAlerts();
//]]></script>
<div style="margin: 10px 0;">
	<strong><%:Detected alerts%>: <span id="alert_count_badge" class="alert-count">0</span></strong>
	<a href="/cgi-bin/luci/admin/services/snort/alerts" class="cbi-button cbi-button-apply" style="float: right; margin-left: 10px; color: white;">
		<%:View all alerts%>
	</a>
</div>
<div class="recent-alerts-box">
<%
	local sys = require "luci.sys"
	local alerts = sys.exec("[ -f /var/log/alert_fast.txt ] && tail -10 /var/log/alert_fast.txt | tac || echo ''")
	
	local line_count = 0
	for line in string.gmatch(alerts, "[^\r\n]+") do
		if line ~= "" then
			line_count = line_count + 1
		end
	end
	
	if line_count == 0 then
%>
		<div class="no-alerts">&#10003; <%:No recent alerts - Your network is secure%></div>
<%
	else
		local displayed = 0
		for line in string.gmatch(alerts, "[^\r\n]+") do
			if line ~= "" and displayed < 10 then
				displayed = displayed + 1
%>
				<div class="alert-item">
					<div class="alert-message">&#128680; <%=pcdata(line)%></div>
				</div>
<%
			end
		end
	end
%>
</div>
<div style="text-align: right; margin-top: 5px; font-size: 0.9em; color: #666;">
	<%:Auto-refresh every 5 seconds%>
</div>
<%+cbi/valuefooter%>
EOF_RECENT

echo ""
echo "Vérification et création du lien symbolique pour les règles..."
if [ -d /var/snort.d/rules ]; then
	if [ -d /etc/snort/rules ] && [ ! -L /etc/snort/rules ]; then
		echo "  Sauvegarde de l'ancien répertoire..."
		mv /etc/snort/rules /etc/snort/rules.backup
	elif [ -L /etc/snort/rules ]; then
		echo "  Suppression de l'ancien lien..."
		rm /etc/snort/rules
	fi
	echo "  Création du lien symbolique..."
	ln -sf /var/snort.d/rules /etc/snort/rules
	echo "  [OK] Lien symbolique cree: /etc/snort/rules -> /var/snort.d/rules"
else
	echo "  ℹ Le répertoire /var/snort.d/rules n'existe pas encore"
	echo "  Il sera créé lors de la première mise à jour des règles"
fi

echo ""
echo "Installation des traductions..."
cat > /usr/lib/lua/luci/i18n/snort.fr.po << 'EOF_TRANSLATION_FR'
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
"Language: fr\n"

msgid "Snort IDS/IPS"
msgstr "Snort IDS/IPS"

msgid "Snort is an open source intrusion detection and prevention system."
msgstr "Snort est un système de détection et prévention d'intrusions open source."

msgid "Service Status"
msgstr "Statut du service"

msgid "State"
msgstr "État"

msgid "Status"
msgstr "Statut"

msgid "Alerts"
msgstr "Alertes"

msgid "Recent Alerts"
msgstr "Dernières alertes"

msgid "Configuration"
msgstr "Configuration"

msgid "Enable Snort"
msgstr "Activer Snort"

msgid "Enable or disable Snort service"
msgstr "Active ou désactive le service Snort"

msgid "Manual mode"
msgstr "Mode manuel"

msgid "Use manual configuration (snort.lua)"
msgstr "Utilise la configuration manuelle (snort.lua)"

msgid "Network interface"
msgstr "Interface réseau"

msgid "Network interface to monitor (e.g. br-lan, eth0)"
msgstr "Interface réseau à surveiller (ex: br-lan, eth0)"

msgid "Local network"
msgstr "Réseau local"

msgid "IP address range to protect"
msgstr "Plage d'adresses IP à protéger"

msgid "External network"
msgstr "Réseau externe"

msgid "External IP address range"
msgstr "Plage d'adresses IP externes"

msgid "Operating mode"
msgstr "Mode de fonctionnement"

msgid "IDS = Detection only, IPS = Active prevention"
msgstr "IDS = Détection uniquement, IPS = Prévention active"

msgid "DAQ method"
msgstr "Méthode DAQ"

msgid "Packet acquisition method"
msgstr "Méthode d'acquisition des paquets"

msgid "Capture Length"
msgstr "Taille de capture"

msgid "Maximum packet capture size"
msgstr "Taille maximale de capture des paquets"

msgid "Logging configuration"
msgstr "Configuration des logs"

msgid "Enable logging"
msgstr "Activer les logs"

msgid "Enable event logging"
msgstr "Active l'enregistrement des événements"

msgid "Log directory"
msgstr "Répertoire des logs"

msgid "Path where logs will be stored"
msgstr "Chemin où seront stockés les logs"

msgid "Configuration directory"
msgstr "Répertoire de configuration"

msgid "Snort configuration directory path"
msgstr "Chemin du répertoire de configuration Snort"

msgid "Temporary directory"
msgstr "Répertoire temporaire"

msgid "Directory for temporary files and downloaded rules"
msgstr "Répertoire pour les fichiers temporaires et règles téléchargées"

msgid "Rules management"
msgstr "Gestion des règles"

msgid "Rules location"
msgstr "Emplacement des règles"

msgid "Oinkcode"
msgstr "Oinkcode"

msgid "Access code to download official Snort rules (optional)"
msgstr "Code d'accès pour télécharger les règles officielles Snort (optionnel)"

msgid "Enter your Oinkcode if you have one"
msgstr "Entrez votre Oinkcode si vous en avez un"

msgid "Rule action"
msgstr "Action des règles"

msgid "Default action for rules"
msgstr "Action par défaut pour les règles"

msgid "Default"
msgstr "Par défaut"

msgid "Alert"
msgstr "Alerter"

msgid "Block"
msgstr "Bloquer"

msgid "Drop"
msgstr "Rejeter"

msgid "Reject"
msgstr "Refuser"

msgid "Update rules"
msgstr "Mettre à jour les règles"

msgid "Update"
msgstr "Mettre à jour"

msgid "Rules update launched in background."
msgstr "Mise à jour des règles lancée en arrière-plan."

msgid "Snort - Alerts and Logs"
msgstr "Snort - Alertes et Logs"

msgid "Recent alerts (50 most recent)"
msgstr "Dernières alertes (50 plus récentes)"

msgid "Refresh"
msgstr "Actualiser"

msgid "Snort system logs (20 most recent)"
msgstr "Logs système Snort (20 plus récents)"

msgid "No logs"
msgstr "Aucun log"

msgid "Actions"
msgstr "Actions"

msgid "View detailed reports via SSH with the command:"
msgstr "Consultez les rapports détaillés via SSH avec la commande:"

msgid "Log files:"
msgstr "Fichiers de logs:"

msgid "Controls"
msgstr "Contrôles"

msgid "Quick actions"
msgstr "Actions rapides"

msgid "Update status"
msgstr "Statut mise à jour"

msgid "Click on \"Update\" to start the rules update"
msgstr "Cliquez sur \"Mettre à jour\" pour lancer la mise à jour des règles"

msgid "Update in progress..."
msgstr "Mise à jour en cours..."

msgid "Update completed!"
msgstr "Mise à jour terminée !"

msgid "Active symbolic link"
msgstr "Lien symbolique actif"

msgid "Create a symbolic link from /var/snort.d/rules to /etc/snort/rules?"
msgstr "Créer un lien symbolique de /var/snort.d/rules vers /etc/snort/rules ?"

msgid "Symbolic link created successfully!"
msgstr "Lien symbolique créé avec succès !"

msgid "Error creating symbolic link"
msgstr "Erreur lors de la création du lien symbolique"

msgid "Directory does not exist: "
msgstr "Le répertoire n'existe pas : "

msgid "Rules are in"
msgstr "Les règles sont dans"

msgid "Create symbolic link"
msgstr "Créer le lien symbolique"

msgid "No rules directory found"
msgstr "Aucun répertoire de règles trouvé"

msgid "Rule files:"
msgstr "Fichiers de règles:"

msgid "Fast alerts"
msgstr "Alertes rapides"

msgid "Detailed JSON alerts"
msgstr "Alertes JSON détaillées"

msgid "No alerts"
msgstr "Aucune alerte"

msgid "No alerts recorded"
msgstr "Aucune alerte enregistrée"

msgid "Update already in progress..."
msgstr "Mise à jour déjà en cours..."

msgid "Update launched in background. Monitoring starts automatically."
msgstr "Mise à jour lancée en arrière-plan. Le suivi démarre automatiquement."

msgid "Temporary files cleaned"
msgstr "Fichiers temporaires nettoyés"

msgid "Old directory backed up. "
msgstr "Ancien répertoire sauvegardé. "

msgid "In progress..."
msgstr "En cours..."

msgid "Error"
msgstr "Erreur"

msgid "Running"
msgstr "En cours d'exécution"

msgid "Stopped"
msgstr "Arrêté"

msgid "Snort memory"
msgstr "Mémoire Snort"

msgid "System memory"
msgstr "Mémoire système"

msgid "Total alerts"
msgstr "Alertes totales"

msgid "Interface"
msgstr "Interface"

msgid "Mode"
msgstr "Mode"

msgid "DAQ method"
msgstr "Méthode DAQ"

msgid "Start"
msgstr "Démarrer"

msgid "Stop"
msgstr "Arrêter"

msgid "Restart"
msgstr "Redémarrer"

msgid "Enable at boot"
msgstr "Activer au démarrage"

msgid "Disable at boot"
msgstr "Désactiver au démarrage"

msgid "Detected alerts"
msgstr "Alertes détectées"

msgid "View all alerts"
msgstr "Voir toutes les alertes"

msgid "No recent alerts - Your network is secure"
msgstr "Aucune alerte récente - Votre réseau est sécurisé"

msgid "Auto-refresh every 5 seconds"
msgstr "Actualisation automatique toutes les 5 secondes"

msgid "Loading..."
msgstr "Chargement..."

msgid "See alerts"
msgstr "Voir les alertes"

msgid "Full configuration"
msgstr "Configuration complète"

msgid "Snort started"
msgstr "Snort démarré"

msgid "Snort stopped"
msgstr "Snort arrêté"

msgid "Snort restarted"
msgstr "Snort redémarré"

msgid "Auto-start enabled"
msgstr "Démarrage automatique activé"

msgid "Auto-start disabled"
msgstr "Démarrage automatique désactivé"
EOF_TRANSLATION_FR

cat > /usr/lib/lua/luci/i18n/snort.en.po << 'EOF_TRANSLATION_EN'
msgid ""
msgstr ""
"Content-Type: text/plain; charset=UTF-8\n"
"Language: en\n"

msgid "Snort IDS/IPS"
msgstr "Snort IDS/IPS"

msgid "Snort is an open source intrusion detection and prevention system."
msgstr "Snort is an open source intrusion detection and prevention system."

msgid "Service Status"
msgstr "Service Status"

msgid "State"
msgstr "State"

msgid "Status"
msgstr "Status"

msgid "Alerts"
msgstr "Alerts"

msgid "Recent Alerts"
msgstr "Recent Alerts"

msgid "Configuration"
msgstr "Configuration"

msgid "Enable Snort"
msgstr "Enable Snort"

msgid "Enable or disable Snort service"
msgstr "Enable or disable Snort service"

msgid "Manual mode"
msgstr "Manual mode"

msgid "Use manual configuration (snort.lua)"
msgstr "Use manual configuration (snort.lua)"

msgid "Network interface"
msgstr "Network interface"

msgid "Network interface to monitor (e.g. br-lan, eth0)"
msgstr "Network interface to monitor (e.g. br-lan, eth0)"

msgid "Local network"
msgstr "Local network"

msgid "IP address range to protect"
msgstr "IP address range to protect"

msgid "External network"
msgstr "External network"

msgid "External IP address range"
msgstr "External IP address range"

msgid "Operating mode"
msgstr "Operating mode"

msgid "IDS = Detection only, IPS = Active prevention"
msgstr "IDS = Detection only, IPS = Active prevention"

msgid "DAQ method"
msgstr "DAQ method"

msgid "Packet acquisition method"
msgstr "Packet acquisition method"

msgid "Capture Length"
msgstr "Capture Length"

msgid "Maximum packet capture size"
msgstr "Maximum packet capture size"

msgid "Logging configuration"
msgstr "Logging configuration"

msgid "Enable logging"
msgstr "Enable logging"

msgid "Enable event logging"
msgstr "Enable event logging"

msgid "Log directory"
msgstr "Log directory"

msgid "Path where logs will be stored"
msgstr "Path where logs will be stored"

msgid "Configuration directory"
msgstr "Configuration directory"

msgid "Snort configuration directory path"
msgstr "Snort configuration directory path"

msgid "Temporary directory"
msgstr "Temporary directory"

msgid "Directory for temporary files and downloaded rules"
msgstr "Directory for temporary files and downloaded rules"

msgid "Rules management"
msgstr "Rules management"

msgid "Rules location"
msgstr "Rules location"

msgid "Oinkcode"
msgstr "Oinkcode"

msgid "Access code to download official Snort rules (optional)"
msgstr "Access code to download official Snort rules (optional)"

msgid "Enter your Oinkcode if you have one"
msgstr "Enter your Oinkcode if you have one"

msgid "Rule action"
msgstr "Rule action"

msgid "Default action for rules"
msgstr "Default action for rules"

msgid "Default"
msgstr "Default"

msgid "Alert"
msgstr "Alert"

msgid "Block"
msgstr "Block"

msgid "Drop"
msgstr "Drop"

msgid "Reject"
msgstr "Reject"

msgid "Update rules"
msgstr "Update rules"

msgid "Update"
msgstr "Update"

msgid "Rules update launched in background."
msgstr "Rules update launched in background."

msgid "Snort - Alerts and Logs"
msgstr "Snort - Alerts and Logs"

msgid "Recent alerts (50 most recent)"
msgstr "Recent alerts (50 most recent)"

msgid "Refresh"
msgstr "Refresh"

msgid "Snort system logs (20 most recent)"
msgstr "Snort system logs (20 most recent)"

msgid "No logs"
msgstr "No logs"

msgid "Actions"
msgstr "Actions"

msgid "View detailed reports via SSH with the command:"
msgstr "View detailed reports via SSH with the command:"

msgid "Log files:"
msgstr "Log files:"

msgid "Controls"
msgstr "Controls"

msgid "Quick actions"
msgstr "Quick actions"

msgid "Update status"
msgstr "Update status"

msgid "Click on \"Update\" to start the rules update"
msgstr "Click on \"Update\" to start the rules update"

msgid "Update in progress..."
msgstr "Update in progress..."

msgid "Update completed!"
msgstr "Update completed!"

msgid "Active symbolic link"
msgstr "Active symbolic link"

msgid "Create a symbolic link from /var/snort.d/rules to /etc/snort/rules?"
msgstr "Create a symbolic link from /var/snort.d/rules to /etc/snort/rules?"

msgid "Symbolic link created successfully!"
msgstr "Symbolic link created successfully!"

msgid "Error creating symbolic link"
msgstr "Error creating symbolic link"

msgid "Directory does not exist: "
msgstr "Directory does not exist: "

msgid "Rules are in"
msgstr "Rules are in"

msgid "Create symbolic link"
msgstr "Create symbolic link"

msgid "No rules directory found"
msgstr "No rules directory found"

msgid "Rule files:"
msgstr "Rule files:"

msgid "Fast alerts"
msgstr "Fast alerts"

msgid "Detailed JSON alerts"
msgstr "Detailed JSON alerts"

msgid "No alerts"
msgstr "No alerts"

msgid "No alerts recorded"
msgstr "No alerts recorded"

msgid "Update already in progress..."
msgstr "Update already in progress..."

msgid "Update launched in background. Monitoring starts automatically."
msgstr "Update launched in background. Monitoring starts automatically."

msgid "Temporary files cleaned"
msgstr "Temporary files cleaned"

msgid "Old directory backed up. "
msgstr "Old directory backed up. "

msgid "In progress..."
msgstr "In progress..."

msgid "Error"
msgstr "Error"

msgid "Running"
msgstr "Running"

msgid "Stopped"
msgstr "Stopped"

msgid "Snort memory"
msgstr "Snort memory"

msgid "System memory"
msgstr "System memory"

msgid "Total alerts"
msgstr "Total alerts"

msgid "Interface"
msgstr "Interface"

msgid "Mode"
msgstr "Mode"

msgid "DAQ method"
msgstr "DAQ method"

msgid "Start"
msgstr "Start"

msgid "Stop"
msgstr "Stop"

msgid "Restart"
msgstr "Restart"

msgid "Enable at boot"
msgstr "Enable at boot"

msgid "Disable at boot"
msgstr "Disable at boot"

msgid "Detected alerts"
msgstr "Detected alerts"

msgid "View all alerts"
msgstr "View all alerts"

msgid "No recent alerts - Your network is secure"
msgstr "No recent alerts - Your network is secure"

msgid "Auto-refresh every 5 seconds"
msgstr "Auto-refresh every 5 seconds"

msgid "Loading..."
msgstr "Loading..."

msgid "See alerts"
msgstr "See alerts"

msgid "Full configuration"
msgstr "Full configuration"

msgid "Snort started"
msgstr "Snort started"

msgid "Snort stopped"
msgstr "Snort stopped"

msgid "Snort restarted"
msgstr "Snort restarted"

msgid "Auto-start enabled"
msgstr "Auto-start enabled"

msgid "Auto-start disabled"
msgstr "Auto-start disabled"
EOF_TRANSLATION_EN

echo ""
echo "Compilation des traductions..."
# Vérifier si po2lmo est disponible
if command -v po2lmo >/dev/null 2>&1; then
	echo "  Compilation avec po2lmo..."
	po2lmo /usr/lib/lua/luci/i18n/snort.fr.po /usr/lib/lua/luci/i18n/snort.fr.lmo 2>/dev/null && echo "  [OK] Francais compile"
	po2lmo /usr/lib/lua/luci/i18n/snort.en.po /usr/lib/lua/luci/i18n/snort.en.lmo 2>/dev/null && echo "  [OK] Anglais compile"
else
	echo "  po2lmo non disponible, traductions en mode texte"
	echo "  Les traductions fonctionneront quand même"
fi

echo ""
echo "Nettoyage du cache LuCI..."
rm -rf /tmp/luci-indexcache /tmp/luci-modulecache /tmp/luci-sessions/*

echo "Redémarrage de uhttpd..."
/etc/init.d/uhttpd restart

echo ""
echo "================================================"
echo "Installation terminée avec succès !"
echo "================================================"
echo ""
echo "Fichiers installes:"
echo "  [OK] Controleur LuCI"
echo "  [OK] Interface de configuration"
echo "  [OK] Vues (status, status_page, controles, alertes)"
echo "  [OK] Traductions (francais, anglais)"
echo "  [OK] Lien symbolique des regles (si applicable)"
echo ""
echo "Accédez à l'interface via:"
echo "  Services → Snort IDS/IPS"
echo ""
echo "Actions recommandées:"
echo "  1. Reconnectez-vous à LuCI"
echo "  2. Videz le cache du navigateur (Ctrl+Shift+R)"
echo "  3. Changez la langue si nécessaire (System → System → Language)"
echo "  4. Configurez Snort (Services → Snort IDS/IPS)"
echo ""
