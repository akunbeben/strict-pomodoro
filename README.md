# 🕒 Strict Pomodoro

**Strict Pomodoro** is a powerful daemon for Linux that enforces a distraction-free work environment by blocking websites during Pomodoro sessions. It integrates directly with [**GNOME Pomodoro**](https://github.com/gnome-pomodoro/gnome-pomodoro) via D-Bus to automatically block sites when you start working and unblock them when you're on a break.

---

## 📖 How It Works

Strict Pomodoro uses a secure, modular approach to manage focus time:

1.  **Daemon (`daemon.sh`):** A systemd user service runs in the background, monitoring GNOME Pomodoro's state via D-Bus.
2.  **State Change:** When the daemon detects a state change (e.g., from `break` to `pomodoro`), it triggers the appropriate action.
3.  **Hosts Manager (`hosts-manager`):**
    *   **Block:** During a `pomodoro` state, the daemon invokes the `hosts-manager` script with `sudo` to add entries for each site in your blocklist to `/etc/hosts`, redirecting them to `127.0.0.1`.
    *   **Unblock:** During `short-break`, `long-break`, or idle states, it removes *only* the lines it added, leaving the rest of `/etc/hosts` untouched.
4.  **Tab Closing (Optional):** If enabled, the daemon will also close any open browser tabs that match the sites in your blocklist.

This design ensures that `/etc/hosts` is modified in a safe and controlled manner, without giving the main daemon script broad root permissions.

---

## 🚀 Features

*   🔒 **Secure Host File Management:** Uses a dedicated, restricted script (`hosts-manager`) to safely block and unblock sites.
*   🛡️ **Restricted Permissions:** The installer configures a `sudoers` rule to grant passwordless execution *only* for the specific `hosts-manager` script, preventing escalation.
*   📡 **Real-time Monitoring:** Instantly reacts to GNOME Pomodoro state changes using D-Bus signals.
*   탭 **Closes Distracting Tabs:** Prevents you from getting sidetracked by already-open sites (requires browser setup).
*   📝 **Simple Blocklist:** Customize your list of blocked sites in a plain text file.
*   ⚙️ **Systemd Integration:** Runs as a reliable systemd user service.
*   🚀 **Automated Installer:** Quick setup and configuration with a single command.

---

## 📦 Installation

### Dependencies
The installer will attempt to install these for you, but you can install them manually:
*   `gnome-shell-pomodoro`
*   `dbus` (usually pre-installed)
*   `jq` (for the optional tab-closing feature)

### 1. Clone the Repository

```bash
git clone https://github.com/akunbeben/strict-pomodoro.git
cd strict-pomodoro
```

### 2. Run the Installer

```bash
chmod +x install.sh
./install.sh
```

The installer automates the following steps:
1.  **Installs Dependencies:** Ensures `gnome-shell-pomodoro` and `dbus` are installed.
2.  **Copies Scripts:**
    *   `daemon.sh` is copied to `~/.local/bin/strict-pomodoro.sh`.
    *   `hosts-manager` is securely copied to `/usr/local/bin/strict-pomodoro-hosts-manager` with `root` ownership.
3.  **Sets Up Blocklist:** A default `blocklist.txt` is placed in `~/.local/share/strict-pomodoro/`.
4.  **Configures Sudoers:** A file is created at `/etc/sudoers.d/strict-pomodoro` to allow the daemon to run the `hosts-manager` script without a password.
5.  **Deploys Service:** The systemd user service file is copied to `~/.config/systemd/user/`.
6.  **Starts Service:** The systemd user daemon is reloaded, and the `strict-pomodoro` service is enabled and started.

---

## 🛡️ Security Model

Modifying `/etc/hosts` requires root privileges. To avoid running the entire daemon as root, Strict Pomodoro uses a more secure model:

1.  A minimal script, `hosts-manager`, is placed in `/usr/local/bin` and owned by `root`. Its sole purpose is to add or remove specific lines from `/etc/hosts`.
2.  The installer adds a rule to `/etc/sudoers.d/`. This rule allows your user to execute *only* the `hosts-manager` script with `sudo` without being prompted for a password.
3.  The main `daemon.sh` script, which runs with user privileges, can then call `sudo strict-pomodoro-hosts-manager` to safely perform the block/unblock actions.

This isolates the root-level operations, ensuring the daemon cannot perform any unauthorized actions.

---

## ⚙️ Configuration

### Edit Blocklist

The list of blocked websites is stored at:
`~/.local/share/strict-pomodoro/blocklist.txt`

You can add or remove any domain.

**Example:**
```
www.facebook.com
youtube.com
twitter.com
instagram.com
```

After editing the file, restart the service to apply changes:
```bash
systemctl --user restart strict-pomodoro.service
```

### Browser Integration (Tab Closing)

The automatic tab-closing feature uses the Chrome DevTools Protocol and requires a Chromium-based browser (Google Chrome, Chromium, Brave, etc.).

**Requirements:**
*   `jq` command-line JSON processor must be installed (`sudo apt install jq`).
*   Your browser must be launched with remote debugging enabled.

**How to Enable Remote Debugging:**

Launch your browser from the terminal with the remote debugging flag.

```bash
# For Google Chrome
google-chrome --remote-debugging-port=9222 &

# For Chromium
chromium-browser --remote-debugging-port=9222 &
```

To make this permanent, edit your browser's `.desktop` file (e.g., in `/usr/share/applications/`) and add the `--remote-debugging-port=9222` flag to the `Exec` line.

---

## 🛠️ Managing the Service

*   **Check Status:**
    ```bash
    systemctl --user status strict-pomodoro.service
    ```

*   **View Live Logs:**
    ```bash
    journalctl --user -u strict-pomodoro.service -f
    ```

*   **Start GNOME Pomodoro (Headless):**
    ```bash
    gnome-pomodoro --no-default-window
    ```

---

## 🗑️ Uninstall

To completely remove Strict Pomodoro and all its components:

```bash
./install.sh --uninstall
```

This will stop the service, remove all installed files (including the scripts, blocklist, service file, and sudoers rule), and restore your system to its previous state.