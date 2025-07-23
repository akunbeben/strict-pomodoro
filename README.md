# 🕒 Strict Pomodoro

**Strict Pomodoro** is a lightweight Linux daemon that blocks distracting websites during Pomodoro work sessions and automatically unblocks them during breaks. Seamlessly integrated with [**GNOME Pomodoro**](https://github.com/gnome-pomodoro/gnome-pomodoro) for a distraction-free focus workflow.

---

## 🚀 Features

* 🔒 **Blocks distracting websites** (Facebook, YouTube, Twitter, etc.) during Pomodoro focus sessions.
* 🔓 **Automatically unblocks** sites during short breaks or long breaks.
* 📡 Real-time monitoring of GNOME Pomodoro states via D-Bus.
* 📝 Simple, editable blocklist (`blocklist.txt`) to customize blocked sites.
* ⚡ Quick installer for fast setup on new devices.
* 🗑️ Built-in uninstaller for clean removal.

---

## 📦 Installation

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

## 📖 How It Works

1. When GNOME Pomodoro enters the `pomodoro` state, Strict Pomodoro:
   * Adds entries to `/etc/hosts` to redirect distracting websites to `127.0.0.1`.

2. When GNOME Pomodoro switches to `short-break`, `long-break`, or becomes idle:
   * Removes the blocking entries from `/etc/hosts`.

