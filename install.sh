#!/bin/bash

SERVICE_NAME="strict-pomodoro"
INSTALL_DIR="$HOME/.local/share/$SERVICE_NAME"
BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
BLOCKLIST_FILE="$INSTALL_DIR/blocklist.txt"
DAEMON_FILE="$BIN_DIR/strict-pomodoro.sh"
SERVICE_FILE="$SYSTEMD_USER_DIR/$SERVICE_NAME.service"
SUDOERS_FILE="/etc/sudoers.d/$SERVICE_NAME"

ensure_dirs() {
  mkdir -p "$INSTALL_DIR" "$BIN_DIR" "$SYSTEMD_USER_DIR"
}

install_dependencies() {
  echo "[INFO] Installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y gnome-shell-pomodoro dbus
}

copy_files() {
  cp daemon.sh "$DAEMON_FILE"
  chmod +x "$DAEMON_FILE"
  cp blocklist.txt "$BLOCKLIST_FILE"
  cp strict-pomodoro.service "$SERVICE_FILE"
}

configure_sudoers() {
  echo "[INFO] Configuring sudoers for NOPASSWD..."
  sudo bash -c "cat > $SUDOERS_FILE" <<EOF
$(whoami) ALL=(ALL) NOPASSWD: $(which sed), $(which tee)
EOF
  sudo chmod 440 $SUDOERS_FILE
}

enable_service() {
  systemctl --user daemon-reload
  systemctl --user enable --now $SERVICE_NAME.service
  echo "[INFO] $SERVICE_NAME service enabled and started."
}

uninstall() {
  echo "[INFO] Uninstalling Strict Pomodoro..."
  systemctl --user stop $SERVICE_NAME.service
  systemctl --user disable $SERVICE_NAME.service
  rm -f "$SERVICE_FILE" "$DAEMON_FILE" "$BLOCKLIST_FILE"
  sudo rm -f "$SUDOERS_FILE"
  systemctl --user daemon-reload
  echo "[INFO] Uninstall complete."
  exit 0
}

if [[ "$1" == "--uninstall" ]]; then
  uninstall
fi

ensure_dirs
install_dependencies
copy_files
configure_sudoers
enable_service
