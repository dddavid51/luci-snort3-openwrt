#!/bin/sh
# Snort3 CGI Web Interface for OpenWrt
# Copyright (C) 2025 David Dzieciol <david.dzieciol51100@gmail.com>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# Place this file in /www/cgi-bin/snort.sh and make it executable

echo "Content-type: text/html"
echo ""

# Récupérer l'action demandée
eval $(echo "$QUERY_STRING" | awk -F'&' '{for(i=1;i<=NF;i++){print $i}}' | sed 's/=/ /')

# Fonction pour obtenir le statut
get_status() 
{
    if /etc/init.d/snort status 2>&1 | grep -q "running"; then
        echo "running"
    else
        echo "stopped"
    fi
}

# Traiter les actions
if [ "$action" = "start" ]; then
    /etc/init.d/snort start >/dev/null 2>&1
    sleep 2
elif [ "$action" = "stop" ]; then
    /etc/init.d/snort stop >/dev/null 2>&1
    sleep 2
elif [ "$action" = "restart" ]; then
    /etc/init.d/snort restart >/dev/null 2>&1
    sleep 3
elif [ "$action" = "update" ]; then
    if [ ! -e /var/snort.d/rules ] && [ ! -e /etc/snort/rules ]; then
    rm -fr /etc/snort/rules && mkdir -p /var/snort.d/rules && ln -sf /var/snort.d/rules /etc/snort
else
    /usr/bin/snort-rules >/dev/null 2>&1 &
    UPDATE_MSG="Mise à jour des règles lancée en arrière-plan..."
fi
fi

STATUS=$(get_status)
[ "$STATUS" = "running" ] && STATUS_COLOR="green" || STATUS_COLOR="red"
[ "$STATUS" = "running" ] && STATUS_TEXT="En cours d'exécution" || STATUS_TEXT="Arrêté"

# Récupérer les informations système
MEM_INFO=$(awk '/MemTotal|MemFree/ {printf "%s ", $2}' /proc/meminfo)
MEM_TOTAL=$(echo $MEM_INFO | awk '{print $1}')
MEM_FREE=$(echo $MEM_INFO | awk '{print $2}')
MEM_USED=$((MEM_TOTAL - MEM_FREE))
MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

# Vérifier si Snort tourne et obtenir son PID
SNORT_PID=$(ps | grep '/usr/bin/snort' | grep -v grep | awk '{print $1}')
if [ -n "$SNORT_PID" ]; then
    SNORT_MEM=$(ps | grep "^[ ]*$SNORT_PID" | awk '{print $5}')
else
    SNORT_MEM="N/A"
fi

# Récupérer les dernières alertes
if [ -f /var/log/alert_fast.txt ]; then
    ALERTS=$(tail -20 /var/log/alert_fast.txt | tac)
    ALERT_COUNT=$(wc -l < /var/log/alert_fast.txt)
else
    ALERTS="Aucune alerte enregistrée"
    ALERT_COUNT=0
fi

# Interface HTML
cat <<EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="refresh" content="30">
    <title>Snort3 - Interface de gestion</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 2em;
            margin-bottom: 10px;
        }
        .status-bar {
            display: flex;
            justify-content: space-around;
            padding: 20px;
            background: #f9f9f9;
            border-bottom: 1px solid #ddd;
        }
        .status-item {
            text-align: center;
        }
        .status-item .label {
            font-size: 0.9em;
            color: #666;
            margin-bottom: 5px;
        }
        .status-item .value {
            font-size: 1.5em;
            font-weight: bold;
        }
        .status-badge {
            display: inline-block;
            padding: 8px 20px;
            border-radius: 20px;
            font-weight: bold;
            color: white;
        }
        .status-running { background: green; }
        .status-stopped { background: red; }
        .controls {
            padding: 20px;
            text-align: center;
            border-bottom: 1px solid #ddd;
        }
        .btn {
            display: inline-block;
            padding: 12px 25px;
            margin: 5px;
            border: none;
            border-radius: 5px;
            font-size: 1em;
            cursor: pointer;
            text-decoration: none;
            color: white;
            transition: all 0.3s;
        }
        .btn:hover { opacity: 0.8; transform: translateY(-2px); }
        .btn-start { background: #28a745; }
        .btn-stop { background: #dc3545; }
        .btn-restart { background: #ffc107; color: #333; }
        .btn-update { background: #17a2b8; }
        .btn-refresh { background: #6c757d; }
        .section {
            padding: 20px;
            border-bottom: 1px solid #ddd;
        }
        .section:last-child { border-bottom: none; }
        .section h2 {
            margin-bottom: 15px;
            color: #333;
            font-size: 1.3em;
        }
        .alert-box {
            background: #f8f9fa;
            border-left: 4px solid #dc3545;
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
            font-family: monospace;
            font-size: 0.9em;
            max-height: 400px;
            overflow-y: auto;
        }
        .alert-line {
            padding: 5px 0;
            border-bottom: 1px solid #e0e0e0;
        }
        .alert-line:last-child { border-bottom: none; }
        .info-box {
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .success-box {
            background: #d4edda;
            border-left: 4px solid #28a745;
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
            color: #155724;
        }
        .footer {
            padding: 15px;
            text-align: center;
            background: #f9f9f9;
            color: #666;
            font-size: 0.9em;
        }
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 5px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            transition: width 0.3s;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Snort3 IDS/IPS</h1>
            <p>Interface de gestion pour OpenWrt</p>
        </div>

        <div class="status-bar">
            <div class="status-item">
                <div class="label">Statut du service</div>
                <div class="value">
                    <span class="status-badge status-$STATUS">$STATUS_TEXT</span>
                </div>
            </div>
            <div class="status-item">
                <div class="label">Alertes totales</div>
                <div class="value" style="color: #dc3545;">$ALERT_COUNT</div>
            </div>
            <div class="status-item">
                <div class="label">Mémoire système</div>
                <div class="value" style="color: #667eea;">$MEM_PERCENT%</div>
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${MEM_PERCENT}%;"></div>
                </div>
            </div>
            <div class="status-item">
                <div class="label">RAM Snort</div>
                <div class="value" style="color: #764ba2;">$SNORT_MEM</div>
            </div>
        </div>

        <div class="controls">
            <a href="?action=start" class="btn btn-start">▶ Démarrer</a>
            <a href="?action=stop" class="btn btn-stop">⏹ Arrêter</a>
            <a href="?action=restart" class="btn btn-restart">🔄 Redémarrer</a>
            <a href="?action=update" class="btn btn-update">📥 Mettre à jour les règles</a>
            <a href="?" class="btn btn-refresh">🔃 Rafraîchir</a>
        </div>
EOF

# Message de mise à jour si présent
if [ -n "$UPDATE_MSG" ]; then
    cat <<EOF
        <div class="section">
            <div class="success-box">
                ✓ $UPDATE_MSG
            </div>
        </div>
EOF
fi

cat <<EOF
        <div class="section">
            <h2>📊 Informations système</h2>
            <div class="info-box">
                <strong>Interface surveillée:</strong> $(uci get snort.snort.interface 2>/dev/null || echo "N/A")<br>
                <strong>Mode:</strong> $(uci get snort.snort.mode 2>/dev/null || echo "N/A")<br>
                <strong>Méthode DAQ:</strong> $(uci get snort.snort.method 2>/dev/null || echo "N/A")<br>
                <strong>Répertoire de configuration:</strong> $(uci get snort.snort.config_dir 2>/dev/null || echo "N/A")<br>
                <strong>PID Snort:</strong> ${SNORT_PID:-Non actif}<br>
                <strong>Mémoire totale:</strong> $((MEM_TOTAL / 1024)) MB<br>
                <strong>Mémoire utilisée:</strong> $((MEM_USED / 1024)) MB<br>
                <strong>Mémoire libre:</strong> $((MEM_FREE / 1024)) MB
            </div>
        </div>

        <div class="section">
            <h2>🚨 Dernières alertes (20 plus récentes)</h2>
            <div class="alert-box">
EOF

if [ "$ALERTS" = "Aucune alerte enregistrée" ]; then
    echo "                <div class='alert-line'>$ALERTS</div>"
else
    echo "$ALERTS" | while IFS= read -r line; do
        [ -n "$line" ] && echo "                <div class='alert-line'>$line</div>"
    done
fi

cat <<EOF
            </div>
        </div>

        <div class="section">
            <h2>📝 Logs système récents</h2>
            <div class="alert-box">
EOF

logread | grep snort | tail -10 | tac | while IFS= read -r line; do
    echo "                <div class='alert-line'>$line</div>"
done

cat <<EOF
            </div>
        </div>

        <div class="footer">
            Interface Snort3 pour OpenWrt | Rafraîchissement automatique toutes les 30 secondes | 
            <a href="?" style="color: #667eea;">Actualiser maintenant</a>
        </div>
    </div>
</body>
</html>
EOF
