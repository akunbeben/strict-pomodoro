# 🕒 Strict Pomodoro

**Strict Pomodoro** is a Linux daemon script that blocks distracting websites during Pomodoro work sessions and automatically unblocks them during breaks. Seamlessly integrated with [**GNOME Pomodoro**](https://github.com/gnome-pomodoro/gnome-pomodoro) for a distraction-free focus workflow.

---

## 📖 How It Works

1. When GNOME Pomodoro enters the `pomodoro` state, Strict Pomodoro:
   * Adds entries to `/etc/hosts` to redirect distracting websites to `127.0.0.1`.
   * Closes any open browser tabs that match the blocklist.

2. When GNOME Pomodoro switches to `short-break`, `long-break`, or becomes idle:
   * Removes the blocking entries from `/etc/hosts`.

---

## 🚀 Features

* 🔒 **Blocks distracting websites** (Facebook, YouTube, Twitter, etc.) during Pomodoro focus sessions.
* 탭 **Closes distracting tabs** to prevent you from getting sidetracked by already-open sites.
* 🔓 **Automatically unblocks** sites during short breaks or long breaks.
* 📡 Real-time monitoring of GNOME Pomodoro states via D-Bus.
* 📝 Simple, editable blocklist (`blocklist.txt`) to customize blocked sites.
* ⚡ Quick installer for fast setup on new devices.

---

## 📦 Installation

> **Note:** The tab-closing feature requires Google Chrome or a Chromium-based browser with remote debugging enabled. See the **Browser Integration** section for details.

1️⃣ Clone the repository:

```bash
git clone https://github.com/akunbeben/strict-pomodoro.git
cd strict-pomodoro
```

2️⃣ Run the installer:

```bash
chmod +x install.sh
./install.sh
```

The installer will:

* Install dependencies (`gnome-shell-pomodoro`, `dbus`)
* Copy the daemon script to `~/.local/bin`
* Set up a systemd user service
* Enable and start the service

---

## 📝 Edit Blocklist

The list of blocked websites is stored in:

```bash
~/.local/share/strict-pomodoro/blocklist.txt
```

Example:

```
www.facebook.com
youtube.com
twitter.com
instagram.com
```

To apply changes:

```bash
systemctl --user restart strict-pomodoro.service
```

---

## 🗑️ Uninstall

To completely remove Strict Pomodoro:

```bash
./install.sh --uninstall
```

---

## 🔥 Pro Tips

* Check service status:
  ```bash
  systemctl --user status strict-pomodoro.service
  ```

* View live logs:
  ```bash
  journalctl --user -u strict-pomodoro.service -f
  ```

* Start GNOME Pomodoro in background:
  ```bash
  gnome-pomodoro --no-default-window
  ```

---

## 🌐 Browser Integration

The automatic tab-closing feature uses the Chrome DevTools Protocol to communicate with your browser.

**Requirements:**
* Google Chrome, Chromium, or another Chromium-based browser.
* Remote debugging must be enabled.

**How to Enable Remote Debugging:**

1.  **Find your browser's executable.**
2.  **Launch it with the remote debugging flag:**
    ```bash
    google-chrome --remote-debugging-port=9222 &
    ```
    or for other browsers:
    ```bash
    chromium-browser --remote-debugging-port=9222 &
    ```
3.  To make this permanent, you can:
    *   Edit your browser's `.desktop` file (e.g., `/usr/share/applications/google-chrome.desktop`) and add the flag to the `Exec` line.
    *   If you use a keyboard shortcut to launch your browser, update the shortcut command to include the `--remote-debugging-port=9222` flag.


