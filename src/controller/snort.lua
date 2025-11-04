-- LuCI Snort3 Module
-- Copyright (C) 2025 David Dzieciol <david.dzieciol51100@gmail.com>
--
-- This is free software, licensed under the GNU General Public License v2.
-- See /LICENSE for more information.
--

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
