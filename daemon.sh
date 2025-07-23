#!/bin/bash

parent_cmd=$(ps -o comm= -p $PPID 2>/dev/null)
if [[ "$parent_cmd" != "systemd" && "$parent_cmd" != "bash" ]]; then
  echo "❌ ERROR: This script must run as a daemon." >&2
  logger -t strict-pomodoro "Rejected execution attempt: parent process '$parent_cmd'"
  exit 1
fi

BLOCKLIST="$HOME/.local/share/strict-pomodoro/blocklist.txt"
HOSTS_FILE="/etc/hosts"
BLOCK_MARKER="# STRICT_POMODORO_BLOCK"

block_sites() {
  echo "[INFO] Blocking distracting sites..."
  while read -r site; do
    [[ -z "$site" || "$site" =~ ^# ]] && continue
    if ! grep -q "$site $BLOCK_MARKER" $HOSTS_FILE; then
      if ! echo "127.0.0.1 $site $BLOCK_MARKER" | sudo -n tee -a $HOSTS_FILE >/dev/null; then
        echo "[ERROR] Failed to block $site. Check sudoers NOPASSWD."
        echo ""
        logger -t strict-pomodoro "Failed to block $site (missing NOPASSWD?)."
      fi
    fi
  done <"$BLOCKLIST"
  echo "[INFO] Websites BLOCKED (Work phase)"
  echo ""
  logger -t strict-pomodoro "Blocked distracting sites (Work phase)."
}

unblock_sites() {
  if ! sudo -n sed -i "/$BLOCK_MARKER/d" $HOSTS_FILE; then
    echo "[ERROR] Failed to unblock sites. Check sudoers NOPASSWD."
    echo ""
    logger -t strict-pomodoro "Failed to unblock sites (missing NOPASSWD?)."
  else
    echo "[INFO] Websites UNBLOCKED (Break/Idle phase)"
    echo ""
    logger -t strict-pomodoro "Unblocked distracting sites (Break/Idle phase)."
  fi
}

handle_state() {
  case "$1" in
  pomodoro)
    echo "[STATE] Work phase: $1"
    block_sites
    ;;
  short-break | long-break | null)
    echo "[STATE] Break/Idle phase: $1"
    unblock_sites
    ;;
  *)
    echo "[WARN] Unknown state detected: $1"
    logger -t strict-pomodoro "Unknown state: $1"
    ;;
  esac
}

current_state=$(gdbus call --session \
  --dest org.gnome.Pomodoro \
  --object-path /org/gnome/Pomodoro \
  --method org.freedesktop.DBus.Properties.Get \
  org.gnome.Pomodoro State 2>/dev/null |
  awk -F"'" '{print $2}')
echo "[INIT] Initial Pomodoro state: $current_state"
handle_state "$current_state"

echo "[DAEMON] Monitoring Pomodoro StateChanged signals..."
gdbus monitor --session \
  --dest org.gnome.Pomodoro \
  --object-path /org/gnome/Pomodoro |
  while read -r line; do
    if [[ "$line" == *"org.gnome.Pomodoro.StateChanged"* ]]; then
      new_state=$(echo "$line" | awk -F"name': <'" '{print $2}' | awk -F"'>" '{print $1}')
      echo "[EVENT] StateChanged detected: $new_state"
      handle_state "$new_state"
    fi
  done
