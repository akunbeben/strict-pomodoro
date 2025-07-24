#!/bin/bash

parent_cmd=$(ps -o comm= -p $PPID 2>/dev/null)
if [[ "$parent_cmd" != "systemd" && "$parent_cmd" != "bash" ]]; then
  echo "[ERROR] This script must run as a daemon." >&2
  logger -t strict-pomodoro "Rejected execution attempt: parent process '$parent_cmd'"
  exit 1
fi

BLOCKLIST="$HOME/.local/share/strict-pomodoro/blocklist.txt"
HOSTS_MANAGER="/usr/local/bin/strict-pomodoro-hosts-manager"
CHROME_REMOTE_URL="http://localhost:9222/json"

close_blocked_tabs() {
  echo "[INFO] Checking and closing blocked tabs..."

  local urls
  urls=$(curl -s "$CHROME_REMOTE_URL" | jq -r '.[] | select(.type == "page") | "\(.id) \(.url)"')

  while IFS= read -r site; do
    [[ -z "$site" || "$site" =~ ^[[:space:]]*# ]] && continue
    site="${site#"${site%%[![:space:]]*}"}"
    site="${site%"${site##*[![:space:]]}"}"

    while IFS= read -r line; do
      tab_id=$(awk '{print $1}' <<<"$line")
      tab_url=$(awk '{print $2}' <<<"$line")

      if [[ "$tab_url" == *"$site"* ]]; then
        echo "[TAB] Closing $tab_url"
        curl -s "$CHROME_REMOTE_URL/close/$tab_id" >/dev/null
        logger -t strict-pomodoro "Closed tab for $tab_url"
      fi
    done <<<"$urls"

  done <"$BLOCKLIST"
}

block_sites() {
  echo "[INFO] Blocking distracting sites..."

  while IFS= read -r site; do
    # Skip empty lines and comments
    [[ -z "$site" || "$site" =~ ^[[:space:]]*# ]] && continue

    # Remove leading/trailing whitespace
    site="${site#"${site%%[![:space:]]*}"}"
    site="${site%"${site##*[![:space:]]}"}"

    [[ -z "$site" ]] && continue

    if ! sudo -n "$HOSTS_MANAGER" block "$site"; then
      echo "[ERROR] Failed to block $site. Check sudoers configuration."
      echo ""
      logger -t strict-pomodoro "Failed to block $site."
    fi
  done <"$BLOCKLIST"

  close_blocked_tabs

  echo "[INFO] Websites BLOCKED (Work phase)"
  echo ""
  logger -t strict-pomodoro "Blocked distracting sites (Work phase)."
}

unblock_sites() {
  if ! sudo -n "$HOSTS_MANAGER" unblock; then
    echo "[ERROR] Failed to unblock sites. Check sudoers configuration."
    echo ""
    logger -t strict-pomodoro "Failed to unblock sites."
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

get_state_from_dbus() {
  local dbus_output="$1"
  local temp="${dbus_output#*\'}"
  echo "${temp%%\'*}"
}

# Get initial state
current_state_raw=$(gdbus call --session \
  --dest org.gnome.Pomodoro \
  --object-path /org/gnome/Pomodoro \
  --method org.freedesktop.DBus.Properties.Get \
  org.gnome.Pomodoro State 2>/dev/null)

current_state=$(get_state_from_dbus "$current_state_raw")
echo "[INIT] Initial Pomodoro state: $current_state"
handle_state "$current_state"

echo "[DAEMON] Monitoring Pomodoro StateChanged signals..."
gdbus monitor --session \
  --dest org.gnome.Pomodoro \
  --object-path /org/gnome/Pomodoro |
  while IFS= read -r line; do
    if [[ "$line" == *"org.gnome.Pomodoro.StateChanged"* ]]; then
      if [[ "$line" =~ name\':[[:space:]]*\<\'([^\']+)\' ]]; then
        new_state="${BASH_REMATCH[1]}"
        echo "[EVENT] StateChanged detected: $new_state"
        handle_state "$new_state"
      fi
    fi
  done
