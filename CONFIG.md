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

### Install yay (AUR helper)

Arch's official repositories cover most software, but a lot of community packages — proprietary apps, dev tools, niche utilities — live in the [Arch User Repository (AUR)](https://aur.archlinux.org/). `yay` is a friendly `pacman`-like wrapper that automates downloading, building, and installing AUR packages. Bootstrap it once by building it from source:

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd .. && rm -rf yay   # the build directory is no longer needed
```

After this initial bootstrap, `yay` itself is a regular installed package and updates alongside the rest of the system via `yay -Syu`.

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

Once installed and configured, start the compositor from the TTY (text-mode login) with:

```bash
start-hyprland
```

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

### System-level utilities

A grab-bag of small tools I find myself reaching for constantly:

```bash
sudo pacman -S curl cmake os-prober trash-cli zip unzip \
               man-db imagemagick grim slurp rsync okular \
               gwenview fastfetch btop xorg-xrdb
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
- **`fastfetch`** — the most-liked system and hardware display tool. Print a nicely formatted summary of your distro, kernel, CPU, GPU, memory, etc. by simply running `fastfetch` (the modern successor to `neofetch`).
- **`btop`** — convenient system monitor in the terminal. Shows live CPU/memory/disk/network usage with mouse-clickable, color-coded panels — a modern replacement for `top`/`htop`.
- **`xorg-xrdb`** — the X resources database utility. Useful for managing legacy X11 apps (e.g. setting fonts, colors, and DPI via `~/.Xresources`) when running them under XWayland.

### NVIDIA drivers

If your machine has a recent NVIDIA GPU (Turing or newer), the open-source kernel modules are the recommended choice as of 2025:

```bash
sudo pacman -S nvidia-open nvidia-utils
sudo pacman -S vulkan-icd-loader
```

- **`nvidia-open`** — open-source NVIDIA kernel modules (replaces the legacy `nvidia` package on supported GPUs).
- **`nvidia-utils`** — the proprietary user-space libraries (OpenGL, CUDA stubs, `nvidia-smi`, etc.).
- **`vulkan-icd-loader`** — Vulkan loader, required by most modern games and GPU-accelerated apps.

The NVIDIA kernel modules are not loaded into the currently running kernel — a **reboot** is required before the driver actually takes effect. Without it, `nvidia-smi` will fail and Hyprland may refuse to start.

> ⚠️ **Important:** NVIDIA + Wayland still has rough edges. After installing the drivers, reboot, then verify with `nvidia-smi` that the kernel module loaded correctly. If you see flickering or black screens under Hyprland, consult the [Hyprland NVIDIA page](https://wiki.hyprland.org/Nvidia/) for the current set of environment variables and `modprobe` tweaks.

If your card is older than Turing or you encounter issues with the open modules, fall back to the proprietary blob with `sudo pacman -S nvidia nvidia-utils` instead.

### Install fonts

A working Arch install needs a sensible set of system fonts before any terminal, browser, or document viewer looks right — Latin text, CJK characters, and emoji all live in separate font files. The following bundle covers everything used by my Hyprland / kitty setup and by the fontconfig defaults in [config/fontconfig/fonts.conf](config/fontconfig/fonts.conf):

```bash
yay -S ttf-dejavu ttf-liberation noto-fonts \
        noto-fonts-cjk noto-fonts-emoji consolas-font
```

- **`ttf-dejavu`** — the long-standing default sans/serif/mono family on most Linux distros; widely assumed as a fallback by other software.
- **`ttf-liberation`** — metric-compatible replacements for Arial / Times New Roman / Courier New, so documents authored on Windows render with the right line breaks.
- **`noto-fonts`** + **`noto-fonts-cjk`** + **`noto-fonts-emoji`** — Google's "no tofu" family. Covers virtually every Unicode script plus full-color emoji. The `-cjk` package is what makes Chinese/Japanese/Korean text display correctly.
- **`consolas-font`** (AUR) — Microsoft's Consolas, packaged for Arch by the community. Used as the regular (non-Nerd) Consolas family on this system.

#### Install Consolas Nerd Font

The patched **Consolas Nerd Font** (used by the kitty config in this repo) is not available in any package repository — it has to be installed manually from the `.ttf` files. This repo ships them under [fonts/](fonts/); copy them into your per-user font directory and refresh the font cache:

```bash
mkdir -p ~/.local/share/fonts
cp fonts/ConsolasNerdFont_*.ttf ~/.local/share/fonts/
fc-cache -fv
```

After this, `fc-list | grep -i "consolas nerd"` should list both the Regular and Italic variants, and kitty will pick them up automatically on next launch.

### Chinese input method

[Fcitx5](https://fcitx-im.org/) is the most widely used input method framework on modern Linux desktops. For typing Chinese (and other CJK languages), install the framework plus the Chinese add-on bundle and the graphical configuration tool:

```bash
yay -S fcitx5 fcitx5-chinese-addons
yay -S fcitx5-configtool
```

- **`fcitx5`** — the core input method framework.
- **`fcitx5-chinese-addons`** — bundles Pinyin, Shuangpin, Wubi, and Cangjie engines.
- **`fcitx5-configtool`** — a GUI for adding/reordering input methods and tweaking key bindings.

Two helper commands you will use regularly:

- **`fcitx5-remote`** — activates (starts) the Fcitx5 service. Run it once after login if Fcitx5 is not already autostarted by your session; my `hyprland.conf` calls it via `exec-once` so it launches with the desktop.
- **`fcitx5-configtool`** — opens the configuration GUI, where you add **Pinyin** (or whichever engine you prefer) to the active input method list and tweak key bindings.

The default toggle to switch between Chinese and English is **Ctrl+Space**.

### Install TeX Live

Install the TeX Live components from the official Arch repositories with `pacman`:

```bash
sudo pacman -S texlive-basic texlive-bin texlive-binextra texlive-latex \
  texlive-latexextra texlive-latexrecommended texlive-luatex texlive-xetex \
  texlive-fontsrecommended texlive-mathscience texlive-pictures \
  texlive-langchinese texlive-langcjk
```

This is roughly the set I rely on: the core engines (`texlive-bin`, `texlive-latex`, `texlive-luatex`, `texlive-xetex`), recommended/extra LaTeX packages, math and science macros, graphics support, and Chinese/CJK language data.

> ⚠️ **Be cautious with the AUR `texlive-full` meta-package.** During the build it sometimes fetches a newer release straight from the upstream TeX Live website that is ahead of the version currently in the AUR, leaving you with a mix of versions that no longer line up with the official Arch `texlive-*` packages and can break compilations until things resync. The individual `texlive-*` packages above stay in lockstep via `pacman -Syu`, which I find more predictable.

### Useful third-party applications

A short list of applications I always install. Some live in the AUR (installed via `yay`), others are already in the official Arch repositories:

```bash
yay -S google-chrome
yay -S visual-studio-code-bin
yay -S github-cli
```

- **`google-chrome`** — Google's official Chrome browser (the open-source upstream is `chromium`, also in the main repos).
- **`visual-studio-code-bin`** — Microsoft's official VS Code binary (the `-bin` suffix indicates a prebuilt package; building from source is also possible via the `code` package but takes much longer).
- **`github-cli`** — GitHub's official command-line tool (`gh`). Great for cloning repos, opening pull requests, and authenticating `git push`/`pull` without juggling personal access tokens. Run `gh auth login` once after installation to link the CLI to your GitHub account.

Add anything else here that you find yourself installing repeatedly — `yay -Ss <keyword>` is a quick way to search both the official repos and the AUR at once.

### Btrfs snapshots with btrbk

If your root filesystem is Btrfs, [btrbk](https://digint.ch/btrbk/) gives you on-demand snapshots with retention in a single command — no daemon, no systemd timer. I use it for quick safety snapshots before risky updates or experiments.

```bash
sudo pacman -S btrbk
```

Install the config shipped in this repo and create the snapshot directory:

```bash
sudo install -Dm644 config/btrbk/btrbk.conf /etc/btrbk/btrbk.conf
sudo mkdir -p /.snapshots
```

The config (see [config/btrbk/btrbk.conf](config/btrbk/btrbk.conf)) snapshots the root subvolume into `/.snapshots/`, keeps 7 daily + 4 weekly versions, and never prunes anything less than 2 days old. Trigger it manually whenever you want — each run takes a fresh snapshot and prunes anything past its retention window:

```bash
sudo btrbk -n run   # dry-run — preview the actions; touches nothing on disk
sudo btrbk run      # actually create snapshot + prune
sudo btrbk list snapshots
```

The `-n` (dry-run) flag is worth getting in the habit of: btrbk prints exactly which subvolumes it *would* snapshot and which old ones it *would* delete, but skips every actual btrfs call. Treat it as a preview of what the real `btrbk run` will do — useful for sanity-checking a config change before letting it touch your filesystem.

Restore a file by copying it back out of `/.snapshots/<timestamp>/`, or roll the whole subvolume back with `btrfs subvolume snapshot` in the other direction. If you ever want this to run on a schedule, enable the `btrbk.timer` unit shipped by the package.

### Copy my settings of Hyprland, kitty, micro and VS Code

From the root of this cloned repository, drop my dotfiles into `~/.config/` and install the Consolas Nerd Font that the kitty config depends on (the font block is repeated from the [Install fonts](#install-fonts) section above — running it twice is harmless):

```bash
mkdir -p ~/.config ~/.config/Code/User ~/.local/share/fonts
cp -r config/{hypr,kitty,micro} ~/.config/
cp config/Code/{settings.json,keybindings.json} ~/.config/Code/User/
cp fonts/ConsolasNerdFont_*.ttf ~/.local/share/fonts/
fc-cache -fv
```

This populates `~/.config/hypr/`, `~/.config/kitty/`, and `~/.config/micro/` in one shot, drops my VS Code `settings.json` and `keybindings.json` into `~/.config/Code/User/`, plus registers the Nerd Font with fontconfig. If any of those directories already exist with your own settings, back them up first (e.g. `mv ~/.config/hypr ~/.config/hypr.bak`) — `cp -r` overwrites individual files but does not merge them intelligently.

### Install the `open` helper script

`config/local-bin/open` is a small bash dispatcher I keep on `PATH` so that typing `open <file>` (or `open <url>`) in any shell launches the right app — Chrome for URLs, Dolphin for directories, gwenview for images, mpv for audio/video, okular for PDFs, `xdg-open` for office/archive files, and `micro` (in the current terminal) for everything else. It mirrors the convenience of macOS's `open` command.

```bash
mkdir -p ~/.local/bin
# Heads up: if ~/.local/bin/open already exists, this will overwrite it.
cp config/local-bin/open ~/.local/bin
chmod +x ~/.local/bin/open

# Make sure ~/.local/bin is on $PATH. Append this to ~/.zshrc (or ~/.bashrc):
#   export PATH="$HOME/.local/bin:$PATH"
# Then reopen the shell or `source ~/.zshrc` to pick up the change.
```

The script assumes `gwenview`, `mpv`, `okular`, `micro`, `dolphin`, and `google-chrome-stable` are installed — adjust the `case` block at the top of the file if you prefer different defaults.

> Side note: `~/.local/bin` is also where Claude Code's own installer drops the `claude` binary when you install it from the terminal, so adding the directory to `$PATH` once benefits both this `open` script and any future per-user CLI tools you install there.

### Enable your G6 Sound Blaster (external DAC)

Most Linux distributions ship with rough out-of-the-box support for external USB DACs — playback usually works, but the microphone input is what tends to misbehave (wrong sample rate, no input level, the device appearing in `pavucontrol` but producing silence, etc.). If you happen to be using the [Creative Sound BlasterX G6](https://us.creative.com/p/refurbished/sound-blasterx-g6-b-stock) like I am, see [`SOUND-BLASTERX-G6.md`](SOUND-BLASTERX-G6.md) for the steps that finally got both the headphone output and the microphone working reliably on Arch + PipeWire. _(That file is currently empty — I'll fill it in once I've cleaned up my notes.)_

### A note on my preferences

A few places where this config differs from typical Arch / Hyprland setups:

- **Light background.** The kitty theme uses a near-white background (`#f7f7f7`), suited to my 4K ROG panel. For a more conventional dark look, swap `config/kitty/current-theme.conf` for any theme under `/usr/share/kitty/themes/`.
- **Consolas as system monospace.** My fontconfig pins `Consolas Nerd Font` as the default `monospace` family. Switch to JetBrains Mono, FiraCode, or MesloLGS by editing `config/fontconfig/fonts.conf`.
- **VS Code terminal copy/paste.** My `keybindings.json` rebinds `Ctrl+C` so it copies when there is a selection and sends `SIGINT` (the usual terminal interrupt) when there isn't, and `Ctrl+V` always pastes. This matches the rest of the desktop — selection-aware copy on `Ctrl+C` — at the cost of losing the default "send `Ctrl+C` literally" behavior on an empty selection.
- **Super+letter app launchers.** Hyprland is rebound so the most common apps open with a single Super-key chord:

  | Binding | Action |
  |---|---|
  | `Super+T` | Terminal (`kitty`) |
  | `Super+G` | Google Chrome |
  | `Super+C` | VS Code |
  | `Super+D` | Dolphin (file manager) |
  | `Super+R` | Run / launcher |
  | `Super+Q` | Quit active window |
  | `Super+F` | Fullscreen |
  | `Super+V` | Toggle floating |
  | `Super+M` | Exit Hyprland |
  | `Super+1` … `Super+0` | Workspace 1 … 10 |
  | `Super+Left` / `Super+Right` | Lower / raise system volume (5% step) |
  | `Super+Z` | Screenshot of a slurp-selected region → `$HOME/YYMMDD_HH-MM-SS.png` |
  | `Super+X` | Full-screen screenshot → `$HOME/YYMMDD_HH-MM-SS.png` |

  The screenshot bindings need `grim` and `slurp` (`sudo pacman -S grim slurp`). Neither prints an on-screen confirmation when triggered from the keybind — check `$HOME` for the new file, or run the same command in a terminal to see any error output.

- **Brightness control is opt-in.** The `Super+Up` / `Super+Down` brightness bindings are shipped commented out in `config/hypr/hyprland.conf` because the right command depends on the hardware:
  - **Laptops** (built-in panel): `sudo pacman -S brightnessctl`, then uncomment the `brightnessctl` lines.
  - **Desktops with external monitors** (DDC/CI): `sudo pacman -S ddcutil`, then uncomment the `ddcutil` lines. The `--bus N` argument is monitor-specific — run `ddcutil detect` to find the right bus number (or paste its output to an AI and let it pick). Both paths are tested on my desktop and laptop respectively.
  - **NVIDIA GPU output**: skip the keybindings entirely and install `nvidia-settings` — adjusting brightness/gamma in its GUI is the most convenient route when the display is driven by the NVIDIA driver.

### What it ends up looking like

Once everything above is installed and the dotfiles are in place, the desktop on my ROG machine looks like this:

<p align="center">
  <img src="screenshot.png" alt="My configured Hyprland desktop" width="900">
</p>
