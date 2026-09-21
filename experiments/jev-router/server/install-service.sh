#!/bin/zsh
# Install (or re-install) the Jev Router launchd service.
# Run ONCE by the user, from THEIR Terminal (launchctl is deliberately
# restricted inside supervised agents).
#
#   bash ~/Documents/Github/jev-codex-router/server/install-service.sh
#
set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON="${JEV_ROUTER_PYTHON:-$(command -v python3.13 || command -v python3.12 || command -v python3.11 || command -v python3)}"
LABEL="${JEV_ROUTER_LABEL:-com.thibaultsaintjean.jev-router}"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOGDIR="$HOME/Library/Logs"

[ -x "$PYTHON" ] || { echo "Python 3.11+ not found"; exit 1; }
"$PYTHON" -c 'import sys; raise SystemExit(sys.version_info < (3, 11))' || {
  echo "Python 3.11+ required (found: $($PYTHON -V 2>&1))"; exit 1;
}
mkdir -p "$LOGDIR"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>-i</string>
    <string>HOME=$HOME</string>
    <string>PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    <string>$PYTHON</string>
    <string>$REPO/server/jev_server.py</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$LOGDIR/jev-router.out.log</string>
  <key>StandardErrorPath</key><string>$LOGDIR/jev-router.err.log</string>
  <key>WorkingDirectory</key><string>$REPO</string>
</dict>
</plist>
EOF

# Replace any existing instance (watchdog / former label) with the service.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/io.0xnatoshi.jev-router.plist"
launchctl bootout "gui/$(id -u)/io.0xnatoshi.jev-router" 2>/dev/null || true
pkill -f "jev_server.py" 2>/dev/null || true
sleep 1
launchctl bootstrap "gui/$(id -u)" "$PLIST"
sleep 1.5
if curl -s -m 5 http://127.0.0.1:4319/health; then
  echo ""
  echo "— Jev Router service OK ($LABEL)"
fi
echo "Uninstall: launchctl bootout gui/\$(id -u)/$LABEL"
