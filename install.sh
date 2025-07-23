#!/bin/bash

set -e

APP_NAME="Strict Pomodoro"
SERVICE_NAME="strict-pomodoro"
SCRIPT_NAME="daemon.sh"
DATA_DIR="$HOME/.local/share/$SERVICE_NAME"
INSTALL_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SUDOERS_FILE="/etc/sudoers.d/$SERVICE_NAME"

function uninstall() {
  echo "🗑️ Uninstalling $APP_NAME..."
  systemctl --user stop "$SERVICE_NAME.service" 2>/dev/null || true
  systemctl --user disable "$SERVICE_NAME.service" 2>/dev/null || true
  rm -f "$SYSTEMD_DIR/$SERVICE_NAME.service"
  rm -f "$INSTALL_DIR/$SCRIPT_NAME"
  rm -rf "$DATA_DIR"
  sudo rm -f "$SUDOERS_FILE"
  systemctl --user daemon-reload
  echo "✅ $APP_NAME completely uninstalled."
  exit 0
}

if [[ "$1" == "--uninstall" ]]; then
  uninstall
fi

echo "🛠️ Installing $APP_NAME..."

# 1️⃣ Install dependencies
echo "📦 Installing dependencies..."
sudo apt-get update
sudo apt-get install -y gnome-shell-pomodoro dbus

# 2️⃣ Copy daemon script
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/$SCRIPT_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
echo "✅ Installed $SCRIPT_NAME to $INSTALL_DIR"

# 3️⃣ Copy blocklist
mkdir -p "$DATA_DIR"
cp "$(dirname "$0")/blocklist.txt" "$DATA_DIR/"
echo "✅ Blocklist installed to $DATA_DIR/blocklist.txt"

# 4️⃣ Add sudoers NOPASSWD rule
if sudo grep -q "$SERVICE_NAME" "$SUDOERS_FILE" 2>/dev/null; then
  echo "ℹ️ Sudoers rule exists, skipping..."
else
  echo "🔑 Adding sudoers rule..."
  echo "$USER ALL=(ALL) NOPASSWD: /bin/sed -i /etc/hosts, /usr/bin/tee -a /etc/hosts" | sudo tee "$SUDOERS_FILE" >/dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  echo "✅ Sudoers rule added"
fi

# 5️⃣ Setup systemd user service
mkdir -p "$SYSTEMD_DIR"
cp "$(dirname "$0")/strict-pomodoro.service" "$SYSTEMD_DIR/"
echo "✅ Systemd service installed"

# 6️⃣ Enable & start service
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME.service"
echo "🚀 $APP_NAME is now running"

# Summary
echo ""
echo "🎉 $APP_NAME installed!"
echo "Manage it with:"
echo "  systemctl --user restart $SERVICE_NAME.service"
echo "  systemctl --user stop $SERVICE_NAME.service"
echo "  journalctl --user -u $SERVICE_NAME.service -f"
echo ""
echo "🗑️ To uninstall:"
echo "  ./install.sh --uninstall"
