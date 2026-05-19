## Personal Configuration Guide

*By Xuda Ye — [ye481@purdue.edu](mailto:ye481@purdue.edu)*

This document picks up where [INSTALL.md](INSTALL.md) leaves off. The base system from the installation guide is intentionally minimal — enough to boot, log in, and reach the network, but nothing more. The sections below cover the additional packages I install on every fresh Arch machine to turn it into a daily-driver workstation: a friendlier shell, a tiling Wayland compositor, working audio and video, common command-line utilities, GPU drivers, an AUR helper, and a handful of GUI applications.

Feel free to cherry-pick. Each section is self-contained, so you can run only the ones that apply to your setup.

### Install zsh and Oh My Zsh

`zsh` is an interactive shell with significantly better completion, history, and theming than `bash`. [Oh My Zsh](https://ohmyz.sh/) is a community framework that bundles hundreds of plugins and themes on top of `zsh`, and is by far the easiest way to get a polished prompt out of the box.

Install both `zsh` and `git` — the latter is needed by Oh My Zsh's installer, which clones its repo:

```bash
sudo pacman -S zsh git
```

Then install Oh My Zsh — the official one-line installer pulls the framework into `~/.oh-my-zsh` and offers to switch your default login shell to `zsh`:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

After it finishes, log out and back in so the shell change takes effect. Theme and plugin configuration is then done via `~/.zshrc`.

### Install Hyprland

[Hyprland](https://hypr.land/) is a modern, GPU-accelerated tiling Wayland compositor. The package list below installs Hyprland itself together with the supporting pieces I rely on day-to-day:

```bash
sudo pacman -S kitty dolphin dunst waybar qt5-wayland qt6-wayland \
               hyprland hyprlauncher hyprpaper hyprpolkitagent \
               xdg-desktop-portal-hyprland
```

What each package does:

- **`hyprland`** — the compositor (the window manager itself).
- **`kitty`** — a fast, GPU-accelerated terminal emulator. My preferred terminal under Hyprland.
- **`dolphin`** — KDE's graphical file manager.
- **`dunst`** — a lightweight notification daemon (Wayland-compatible).
- **`waybar`** — the top/bottom status bar (clock, workspaces, system tray, etc.).
- **`hyprlauncher`** — an application launcher for Hyprland.
- **`hyprpaper`** — the wallpaper daemon.
- **`hyprpolkitagent`** — the polkit authentication agent (lets GUI apps prompt for your password when they need root).
- **`xdg-desktop-portal-hyprland`** — implements XDG desktop portals on Hyprland (needed for screen sharing, file pickers in flatpak apps, etc.).
- **`qt5-wayland`** / **`qt6-wayland`** — Qt platform plugins so Qt apps render natively on Wayland instead of falling back to XWayland.

The matching configuration files I use live under [.config/hypr/](.config/hypr/) and [.config/kitty/](.config/kitty/) in this repo — copy them into `~/.config/` after installation.

### Audio and video playback

Modern Arch uses [PipeWire](https://wiki.archlinux.org/title/PipeWire) as the unified audio/video server, with WirePlumber as its session manager. This combination replaces the older PulseAudio + JACK stack and works out of the box for both desktop apps and pro-audio workflows.

```bash
sudo pacman -S usbutils pipewire pipewire-alsa pipewire-pulse \
               alsa-utils wireplumber mpv
```

- **`pipewire`** — the core audio/video server.
- **`pipewire-alsa`** / **`pipewire-pulse`** — drop-in compatibility layers so existing ALSA and PulseAudio applications transparently route through PipeWire.
- **`wireplumber`** — PipeWire's session and policy manager.
- **`alsa-utils`** — provides `alsamixer` and other low-level tooling for inspecting/debugging sound cards.
- **`usbutils`** — `lsusb` and friends, useful when diagnosing USB audio devices.
- **`mpv`** — a minimal, scriptable media player. Good default for both local video files and streamed URLs.

After installation, the user-level PipeWire services should auto-start on next login. Test playback with `mpv <some-file>` or `speaker-test -c 2`.

### Command-line utilities

A grab-bag of small tools I find myself reaching for constantly:

```bash
sudo pacman -S curl cmake os-prober trash-cli zip unzip \
               man-db imagemagick grim slurp rsync okular gwenview
```

- **`curl`**, **`cmake`** — fundamental dev tooling (`git` was already installed earlier alongside Oh My Zsh).
- **`os-prober`** — detects other operating systems on the disk (useful if you ever dual-boot and want GRUB to list both).
- **`trash-cli`** — `rm`'s safer cousin: `trash <file>` moves to the freedesktop trash instead of permanently deleting.
- **`zip`** / **`unzip`** — classic archive tools (Arch installs `tar` and `gzip` by default but not these).
- **`man-db`** — populates the `man` database so manual pages are searchable.
- **`imagemagick`** — `convert`, `mogrify`, etc., for command-line image manipulation.
- **`grim`** + **`slurp`** — Wayland-native screenshot tools. `slurp` lets you select a region; `grim` captures it.
- **`rsync`** — incremental file copy/sync, indispensable for backups.
- **`okular`** — KDE's PDF viewer (good annotation support).
- **`gwenview`** — KDE's image viewer.

### NVIDIA drivers

If your machine has a recent NVIDIA GPU (Turing or newer), the open-source kernel modules are the recommended choice as of 2025:

```bash
sudo pacman -S nvidia-open nvidia-utils vulkan-icd-loader
```

- **`nvidia-open`** — open-source NVIDIA kernel modules (replaces the legacy `nvidia` package on supported GPUs).
- **`nvidia-utils`** — the proprietary user-space libraries (OpenGL, CUDA stubs, `nvidia-smi`, etc.).
- **`vulkan-icd-loader`** — Vulkan loader, required by most modern games and GPU-accelerated apps.

The NVIDIA kernel modules are not loaded into the currently running kernel — a **reboot** is required before the driver actually takes effect. Without it, `nvidia-smi` will fail and Hyprland may refuse to start.

> ⚠️ **Important:** NVIDIA + Wayland still has rough edges. After installing the drivers, reboot, then verify with `nvidia-smi` that the kernel module loaded correctly. If you see flickering or black screens under Hyprland, consult the [Hyprland NVIDIA page](https://wiki.hyprland.org/Nvidia/) for the current set of environment variables and `modprobe` tweaks.

If your card is older than Turing or you encounter issues with the open modules, fall back to the proprietary blob with `sudo pacman -S nvidia nvidia-utils` instead.

### Install yay (AUR helper)

Arch's official repositories cover most software, but a lot of community packages — proprietary apps, dev tools, niche utilities — live in the [Arch User Repository (AUR)](https://aur.archlinux.org/). `yay` is a friendly `pacman`-like wrapper that automates downloading, building, and installing AUR packages. Bootstrap it once by building it from source:

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd .. && rm -rf yay   # the build directory is no longer needed
```

After this initial bootstrap, `yay` itself is a regular installed package and updates alongside the rest of the system via `yay -Syu`.

### Useful third-party applications

A short list of applications I always install. Some live in the AUR (installed via `yay`), others are already in the official Arch repositories:

```bash
yay -S google-chrome
yay -S visual-studio-code-bin
sudo pacman -S github-cli
```

- **`google-chrome`** — Google's official Chrome browser (the open-source upstream is `chromium`, also in the main repos).
- **`visual-studio-code-bin`** — Microsoft's official VS Code binary (the `-bin` suffix indicates a prebuilt package; building from source is also possible via the `code` package but takes much longer).
- **`github-cli`** — GitHub's official command-line tool (`gh`). Great for cloning repos, opening pull requests, and authenticating `git push`/`pull` without juggling personal access tokens. Run `gh auth login` once after installation to link the CLI to your GitHub account.

Add anything else here that you find yourself installing repeatedly — `yay -Ss <keyword>` is a quick way to search both the official repos and the AUR at once.
