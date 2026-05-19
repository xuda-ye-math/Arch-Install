## Arch Linux Installation Guide

*By Xuda Ye — [ye481@purdue.edu](mailto:ye481@purdue.edu)*

Arch Linux is a rolling-release distribution that emphasizes simplicity, minimalism, and full user control over the system. It is well suited to users who prefer to build their environment from the ground up rather than rely on opinionated defaults. Its package manager is `pacman`, complemented by AUR helpers such as `yay` and `paru` for community-maintained packages.

Because Arch tracks upstream closely, it ships the latest releases of toolchains like Python, C/C++, and Rust, which makes it a strong choice for performance-sensitive workloads such as running `llama.cpp`. The trade-off is reduced support for certain proprietary software (for example, MATLAB) and a higher maintenance burden than fixed-release distributions. Users who depend on such software, or who simply want a stable, low-effort system, are likely better served by a different distribution.

Several popular Arch-based downstream distributions, such as [CachyOS](https://cachyos.org/), [Manjaro](https://manjaro.org/), and [EndeavourOS](https://endeavouros.com/), ship with a graphical installer and sensible defaults out of the box. If you mainly want to try out the Arch ecosystem without going through a manual installation, any of these is a reasonable starting point. Alternatively, if you are on Windows and only need access to Arch's userland and package ecosystem, you can run Arch inside [WSL (Windows Subsystem for Linux)](https://learn.microsoft.com/en-us/windows/wsl/) — for example via the [ArchWSL](https://github.com/yuk7/ArchWSL) project — which avoids touching your existing OS or disk layout.

This guide is based on the [official installation guide](https://wiki.archlinux.org/title/Installation_guide), with additional notes aimed at beginners. It assumes an `x86_64` system, a Wi-Fi internet connection, `en_US.UTF-8` as the default system locale, and a clean install that erases a single NVMe M.2 SSD. If you instead want to install Arch onto a specific partition of an existing disk, refer to the official wiki or seek more experienced guidance.

### What you need to prepare (physically)

You will need a USB drive (at least 4 GB, ideally 8 GB or more) and the latest Arch installation ISO, which you can obtain from the official [download page](https://archlinux.org/download/). Once you have the ISO, flash it onto the USB drive using a tool appropriate for your current operating system:

- On **Windows**, use [Rufus](https://rufus.ie/en/).
- On **macOS or Linux**, use [balenaEtcher](https://etcher.balena.io/), or run `dd` directly from the terminal if you are comfortable with command-line tools.

Note that this process will erase any existing data on the USB drive, so make sure to back it up first. Once flashing has completed, the drive should appear similar to the screenshot below:

<p align="center">
  <img src="ISO.png" alt="Flashed Arch installation USB" width="800">
</p>

Plug the USB drive into the target machine and enter the BIOS/UEFI settings (usually by pressing `F2`, `Del`, `F10`, or `Esc` during power-on — the exact key varies by manufacturer). Disable **Secure Boot** and **Fast Boot**, then move the USB drive to the top of the boot order. Save the changes and reboot; the system will load the Arch live environment from the USB into RAM and drop you into a root shell, from which the rest of the installation proceeds.

During the first boot from the USB, you may hear a short beep from your computer — this is just the normal POST (power-on self-test) signal and can be safely ignored. Once the live environment has finished loading, you should be presented with a shell prompt that looks like:

<pre><code><span style="color: red;">root</span>@archiso ~ #
</code></pre>

The `root@archiso` prefix indicates that you are logged in as the `root` user inside the Arch live ISO environment, with full administrative privileges. All commands in the rest of this guide are run from this prompt unless stated otherwise.

**Tip:** press the up arrow at any time to recall previously entered commands from the shell history. This is especially handy for fixing a typo without retyping the entire line — just press up, edit the mistake, and hit Enter. If you are ever unsure what a command does, run `man <command>` to open its manual page.

### Connect to the internet

Before installing any packages, you need a working internet connection. Since this guide assumes a Wi-Fi setup, we will use `iwctl` — the interactive front-end for **iNet Wireless Daemon (iwd)**, the default wireless backend on the Arch live ISO. Launch it from the root shell with:

```bash
iwctl
```

You should then be dropped into the `iwd` interactive prompt:

<pre><code><span style="color: green;">[iwd]</span>#
</code></pre>

From here, all subsequent wireless commands (listing devices, scanning networks, connecting, etc.) are run inside this prompt rather than from the regular shell.

First, list the available wireless interfaces with:

```
device list
```

You should see one or more wireless adapters; in most laptops this is simply `wlan0`. If your interface has a different name, substitute it for `wlan0` in the commands below.

Next, scan for nearby networks. The scan itself runs silently and produces no output:

```
station wlan0 scan
```

Once the scan finishes (typically within a couple of seconds), list the discovered networks:

```
station wlan0 get-networks
```

Locate the SSID you want to join in the resulting table — we will call it `<network-name>` — and connect to it with:

```
station wlan0 connect <network-name>
```

You will then be prompted for the network's passphrase. If the SSID contains spaces or special characters, wrap it in double quotes. For example, to connect to a hotspot called `Carol's iPhone`:

```
station wlan0 connect "Carol's iPhone"
```

After connecting successfully, you can exit `iwctl` with `exit` (or `Ctrl+D`) and verify connectivity from the regular shell with `ping 8.8.8.8`.

### Identify and partition the target disk

Before doing anything destructive, you need to identify exactly which block device you intend to install Arch onto. Use `lsblk` to list all attached disks together with their sizes and existing partitions, and `lsblk -f` to additionally show filesystem types and labels:

```
lsblk
lsblk -f
```

NVMe SSDs typically appear as `nvme0n1`, `nvme1n1`, and so on — the first number is the controller index, and the trailing `n1` is the namespace (almost always `n1` on consumer drives). If the machine has multiple NVMe SSDs, you will see several `nvmeXn1` entries.

> ⚠️ **Important:** these controller numbers are assigned by the kernel at boot time and do **not** necessarily match the physical M.2 slot order on your motherboard. They can also shift between reboots if you add, remove, or rearrange drives. Always confirm the target device against the size and existing partition layout shown by `lsblk` before running any of the commands that follow — every step below is destructive and will permanently erase the selected disk.

For the rest of this guide, we will assume the target SSD is `/dev/nvme0n1`. If your device has a different name, substitute it accordingly in every command.

Begin by wiping any existing filesystem signatures, partition tables, and bootloader remnants from the disk:

```bash
wipefs -af /dev/nvme0n1
```

Then open the interactive GPT partitioning tool:

```bash
gdisk /dev/nvme0n1
```

`gdisk` is driven entirely by single-letter commands entered at its prompt. The handful you will use here are:

```bash
o   # create a new empty GPT partition table
n   # create a new partition
d   # delete an existing partition
p   # print the current partition status
w   # write changes to disk and exit
q   # quit without saving any changes
```

We recommend skimming `man gdisk` once before proceeding, so you know what each command does. If at any point you are unsure about what to do next, you can always press `q` to abort safely — no changes are written to disk until you explicitly invoke `w`.

Once inside `gdisk`, type `p` to print the current disk summary and sanity-check that you are operating on the right device. On my machine the output looks like:

```
Disk /dev/nvme0n1: 2000409264 sectors, 953.9 GiB
Model: SKHynix_HFS001TEJ9X115N
Sector size (logical/physical): 512/512 bytes
Disk identifier (GUID): ...
```

Below that, `gdisk` returns you to its main prompt:

```
Command (? for help):
```

This is where every subsequent step is entered. Now proceed as follows.

**Step 1 — Create a fresh GPT.** Press `o` and then `Enter`. `gdisk` will warn:

```
This option deletes all partitions and creates a new protective MBR.
Proceed? (Y/N):
```

Press `Y` to confirm. Despite the wording, this does *not* convert the disk to MBR — the "protective MBR" is a small legacy header that GPT places at the start of the disk to prevent older, non-GPT-aware tools from mistakenly treating the drive as empty. The actual partition scheme is still GPT.

**Step 2 — Create the EFI System Partition (ESP).** Press `n` to start creating a new partition. `gdisk` will ask for a partition number:

```
Partition number (1-128, default 1):
```

Just press `Enter` to accept the default of `1`, which makes this the first partition on the disk — its block device name will be `/dev/nvme0n1p1`. Next, `gdisk` asks for the starting sector:

```
First sector (34-2000409230, default = 2048) or {+-}size{KMGTP}:
```

Press `Enter` again to start the partition at the first aligned free sector (`2048`). You will then be asked for the ending sector:

```
Last sector (2048-2000409230, default = 2000408575) or {+-}size{KMGTP}:
```

Type `+1G` (note the leading **`+`** — it tells `gdisk` to interpret the value as a *size* rather than an absolute sector number) to reserve 1 GiB of space for the boot partition. Finally, `gdisk` prompts for the partition type:

```
Hex code or GUID (L to show codes, Enter = 8300):
```

Type `EF00` and press `Enter`. This is the type code for an EFI System Partition, which the firmware looks for at boot time. `gdisk` will confirm:

```
Changed type of partition to 'EFI system partition'
```

You can now run `p` to verify that the new partition appears correctly in the layout with the expected size (~1 GiB) and type (`EFI system partition`).

**Step 3 — Create the swap partition.** Swap is disk space that the kernel uses as an overflow for physical RAM: when memory pressure is high, less-active pages can be evicted to swap to free up space. It is also what enables suspend-to-disk (hibernation), where the entire contents of RAM are written to swap before powering off. A common rule of thumb is to allocate **8–32 GiB**, depending on workload and RAM size. If your machine has 64 GiB of RAM or more (typical for heavy compute or ML workloads) and you do not plan to hibernate, you may safely skip the swap partition altogether.

Press `n` and `Enter`, then follow the same flow as Step 2 to create partition 2 (the defaults for partition number and starting sector are again what you want). When you reach the last-sector prompt:

```
Last sector (2099200-2000409230, default = 2000408575) or {+-}size{KMGTP}:
```

type `+32G` to reserve 32 GiB for swap (adjust the number to match what you decided above). At the partition-type prompt, enter `8200` — the GUID code for Linux swap. `gdisk` will confirm:

```
Changed type of partition to 'Linux swap'
```

**Step 4 — Create the root partition.** The remaining free space on the disk will host the Linux root filesystem (`/`), which contains the kernel, system libraries, applications, user data, and everything else not on the ESP. Press `n` and simply hit `Enter` at every subsequent prompt — the defaults (partition number `3`, starting at the first free sector, ending at the last sector of the disk, type `8300` for *Linux filesystem*) are exactly what you want.

Once the partition is created, type `p` to print the final layout. It should look similar to:

```
Number Start (sector)   End (sector)    Size        Code   Name
1      2048             2099199         1024.0 MiB  EF00   EFI system partition
2      2099200          69208063        32.0 GiB    8200   Linux swap
3      69208064         2000408575      920.9 GiB   8300   Linux filesystem
```

Up to this point, nothing has actually been written to the disk yet — everything lives in `gdisk`'s in-memory copy of the partition table. Take a moment to double-check the sizes and types, and then commit the changes with `w`:

```
Command (? for help): w

Do you want to proceed? (Y/N): Y
```

`gdisk` will write the new GPT to disk and exit back to the shell. After this point the partitions exist physically on the SSD as `/dev/nvme0n1p1`, `/dev/nvme0n1p2`, and `/dev/nvme0n1p3`.

### Format the partitions and mount

At this point the three partitions exist on the disk but contain no filesystems — running `lsblk -f` will show empty `FSTYPE` columns for `nvme0n1p1`, `nvme0n1p2`, and `nvme0n1p3`. We now format each partition for its intended role:

```bash
mkfs.fat -F32 /dev/nvme0n1p1         # FAT32 for the EFI System Partition
mkswap /dev/nvme0n1p2                # initialize swap signature
mkfs.btrfs -L System /dev/nvme0n1p3  # Btrfs for the root filesystem
```

A few notes on each command:

- **`mkfs.fat -F32`** is required for the ESP. UEFI firmware can only read FAT (typically FAT32), so this choice is not optional — it is dictated by the boot specification.
- **`mkswap`** does not create a filesystem in the usual sense; it just writes a small swap header so the kernel can recognize the partition as swap space.
- **`mkfs.btrfs -L System`** formats the root partition as [Btrfs](https://wiki.archlinux.org/title/Btrfs), a modern copy-on-write filesystem that supports snapshots, transparent compression, and subvolumes — features that are very convenient for system rollback and backups. The `-L System` flag sets a human-readable label; you can change it to `Root`, `Arch`, `C`, or anything else you like. Labels show up in `lsblk -f` and file managers, and can be referenced by `LABEL=...` in `/etc/fstab`, but they do not affect the way the filesystem works. If you omit `-L`, the filesystem simply has no label (and `lsblk` shows the generic type name instead).

If you prefer a simpler, more conservative choice, you can format the root partition as **ext4** instead:

```bash
mkfs.ext4 -L System /dev/nvme0n1p3
```

ext4 is the default filesystem in most Linux distributions, extremely stable, and well-understood — at the cost of lacking the snapshot and compression features that Btrfs provides. Either choice is a reasonable default; the rest of this guide works the same way regardless.

Run `lsblk -f` once more to confirm that each partition now reports the expected filesystem type (`vfat`, `swap`, and `btrfs`/`ext4`). With the filesystems in place, we mount them under `/mnt` so that the live ISO can install the new system *into* the target disk. Conceptually, `/mnt` will become the new system's `/` once you reboot into it.

```bash
mount /dev/nvme0n1p3 /mnt               # mount root at /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot  # create /mnt/boot and mount the ESP there
swapon /dev/nvme0n1p2                   # activate swap
```

A few details worth noting:

- The order matters: the root partition must be mounted **first**, because `/mnt/boot` only exists as a directory once the root filesystem sits under `/mnt`.
- The `--mkdir` flag on the second `mount` tells `mount` to create the target directory if it does not already exist, saving you from a separate `mkdir /mnt/boot` step.
- `swapon` does not format anything (that was already done by `mkswap`); it simply activates the swap partition so the kernel can start using it immediately.

After these commands, `/mnt` should contain exactly one directory — `boot` — and `lsblk` should show all three partitions as mounted/active.

### Install the base system

With the partitions mounted, we can now use `pacstrap` — Arch's bootstrap installer — to download and install a minimal Arch system into `/mnt`. The `-K` flag initializes a fresh pacman keyring inside the target system (important on a clean install, otherwise package signature verification can fail later).

```bash
pacstrap -K /mnt base linux linux-firmware base-devel networkmanager grub efibootmgr micro sudo
```

A short note on what each package is for:

- **`base`** — the minimal core utilities and `pacman` itself.
- **`linux`** — the Linux kernel (use `linux-lts` if you want the long-term-support variant instead).
- **`linux-firmware`** — proprietary firmware blobs for Wi-Fi, GPUs, and other hardware. Skipping it can leave you with a system that boots but can't talk to your network card.
- **`base-devel`** — a meta-package of common build tools (`make`, `gcc`, `pkgconf`, …), required for building AUR packages later.
- **`networkmanager`** — the post-install networking daemon. Once you reboot out of the live ISO, `iwctl` is gone, and `NetworkManager` is the simplest replacement.
- **`grub`** + **`efibootmgr`** — the bootloader and the tool that registers it with the UEFI firmware.
- **`micro`** — a small, modeless terminal editor with familiar Ctrl-S / Ctrl-C / Ctrl-Z bindings. I strongly recommend it over `vim` or `nano` if you are coming from Windows or macOS; it has none of the modal-editing learning curve and behaves the way you would expect a text editor to behave.
- **`sudo`** — lets a regular user run commands as root, which we will configure shortly.

Next, generate the new system's `/etc/fstab` so that the kernel knows which filesystems to mount on boot, then change root into the installed system:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

`genfstab -U` writes one line per currently mounted filesystem, identifying each by UUID (which is stable across reboots and disk renumbering — unlike `/dev/nvmeXn1pY` paths). `arch-chroot` then treats `/mnt` as the new root: every command you run from this point until you `exit` is executed as if you had already booted into the freshly installed system.

After `arch-chroot`, the prompt changes to something like:

```
[root@archiso /]#
```

The hostname still reads `archiso` (we will set a proper hostname shortly), but running `pwd` now returns `/`, confirming that you are operating inside the new root filesystem. Everything you install or configure from here is persisted on the SSD.

Running `date` inside the chroot will show the current time in UTC, since the new system has no timezone configured yet. To pick yours, browse the available zone files under `/usr/share/zoneinfo`:

```bash
ls /usr/share/zoneinfo/Asia      # cities in Asia
ls /usr/share/zoneinfo/America   # cities in the Americas
ls /usr/share/zoneinfo/Europe    # cities in Europe
```

Each subdirectory contains a file per representative city. Once you have found the right one, link it to `/etc/localtime`, then write the current time back to the hardware clock so the kernel and the BIOS agree:

```bash
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime   # example: US Eastern
hwclock --systohc
```

For a user in mainland China, the corresponding command would be:

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
hwclock --systohc
```

The `ln -sf` flag combination creates (or replaces) the symlink in one step. `hwclock --systohc` then synchronizes the hardware (RTC) clock from the now-correct system time, assuming the RTC is set to UTC — which is the standard convention on Linux. Run `date` once more to verify that the displayed time matches your local clock.

Next, configure the system locale. `/etc/locale.gen` lists every locale Arch *could* generate, all commented out by default; we enable the one we want and then run `locale-gen` to build the corresponding locale data:

```bash
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
```

You should see output similar to:

```
Generating locales...
  en_US.UTF-8... done
Generation complete.
```

Then write `/etc/locale.conf` so that the new system actually *uses* this locale on boot:

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

Now set the machine's hostname. This is the short name your computer announces itself by — both locally (it appears in your shell prompt) and on the network (for SSH, mDNS, etc.):

```bash
echo "archbox" > /etc/hostname
```

You can pick anything you like — a hardware nickname (e.g. `rog`, `thinkpad`) or a descriptive label (e.g. `archbox`, `dev-laptop`). Once the system is booted and `sshd` is running, you would log in from another machine with:

```bash
ssh <user>@<hostname>     # if your LAN resolves it via mDNS / DNS
ssh <user>@<ip-address>   # otherwise, use the box's IP directly
```

Set the root password (you will be prompted to type it twice, with no on-screen feedback):

```bash
passwd
```

Finally, create your first regular user. The `-m` flag creates a home directory under `/home/<user>`, and `-G wheel` adds the user to the `wheel` group — Arch's convention for users who are allowed to use `sudo`:

```bash
useradd -mG wheel <user>
passwd <user>
```

Replace `<user>` with your preferred username (lowercase, no spaces). The `wheel` membership alone does not yet grant `sudo` rights — you also need to edit `/etc/sudoers`. Open it with:

```bash
EDITOR=micro visudo
```

`visudo` opens the file in `micro` (or whichever editor `EDITOR` points to) and validates the syntax before saving, which prevents you from accidentally locking yourself out with a malformed `sudoers` file. Around line 125, uncomment the following line (remove the leading `#`):

```
%wheel ALL=(ALL:ALL) ALL
```

Then press **Ctrl+S** to save and **Ctrl+Q** to quit `micro`. After this, the new user can use `sudo` as expected.

### Install the bootloader and enable networking

GRUB (the GRand Unified Bootloader) is the most widely used boot manager on Linux. It is the small program that runs immediately after the UEFI firmware hands off control, locates the Linux kernel, and loads it into memory. Without a bootloader installed, the firmware has no entry point for the new system and the machine simply will not boot into Arch.

Install GRUB onto the ESP and then generate its configuration:

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Arch Linux"
grub-mkconfig -o /boot/grub/grub.cfg
```

A quick breakdown of the flags:

- **`--target=x86_64-efi`** — build a 64-bit EFI bootloader (matches our assumed `x86_64` UEFI system).
- **`--efi-directory=/boot`** — where the ESP is mounted inside the chroot (we mounted `/dev/nvme0n1p1` to `/mnt/boot` earlier, which is `/boot` from within the chroot's perspective).
- **`--bootloader-id="Arch Linux"`** — the label that will show up in the firmware's boot menu. You can change it to whatever you prefer (e.g. `"Arch"`, `"My Linux"`).

`grub-mkconfig` then scans the system, detects the installed kernel(s), and writes out `/boot/grub/grub.cfg` — the file GRUB actually reads at boot.

Next, enable `NetworkManager` so the new system has working internet on its very first boot (remember: `iwctl` lives only on the live ISO and will be gone after reboot):

```bash
systemctl enable NetworkManager
```

At this point the installation is complete. Leave the chroot to return to the live ISO's shell:

```bash
exit
```

Then unmount every filesystem under `/mnt` and shut the machine down:

```bash
umount -R /mnt
shutdown now
```

The `-R` flag unmounts recursively, so `/mnt/boot` is dismounted before `/mnt` itself. This guarantees that all pending writes are flushed to disk before power is cut. Note that the command is `umount` (no second `n`) — a very common first-time typo.

Once the machine has powered off, unplug the USB drive. On the next boot, the UEFI firmware will find your newly installed Arch system and load GRUB from the ESP. Take a moment to relax — the heavy lifting is done. The next time you see a prompt, it will be the freshly installed Arch greeting you with a `login:` line, where you can sign in as the regular user you created earlier..

### Post-installation

After the first boot you will land at a plain text login prompt. Sign in as the regular user you created during the install. The following steps cover the bare minimum to make the new system usable day-to-day.

#### Reconnect to the network

`NetworkManager` is enabled but does not yet know about any Wi-Fi networks — the credentials you entered via `iwctl` only lived inside the live ISO. Launch the text-mode UI:

```bash
nmtui
```

Pick **Activate a connection**, choose your SSID from the list of nearby networks, enter the passphrase, and confirm. From now on `NetworkManager` will remember this network and auto-connect on every boot.

If you prefer a one-liner, the same thing can be done from the shell with:

```bash
nmcli device wifi connect "<SSID>" password "<passphrase>"
```

#### Update the system

A fresh Arch install is already a few days behind upstream by the time you boot it. Bring everything up to date:

```bash
sudo pacman -Syu
```

`-S` invokes the sync operation, `-y` refreshes the package database from the mirrors, and `-u` upgrades every installed package to its latest version. On Arch this is also how you do "the update" in general — there is no separate concept of major releases.

#### Install a desktop environment (optional)

If you want a graphical environment, pick one of the popular options and install it via `pacman`. Some common choices:

- **[GNOME](https://wiki.archlinux.org/title/GNOME)** — clean, opinionated, touch-friendly; closest to the macOS experience.
- **[KDE Plasma](https://wiki.archlinux.org/title/KDE)** — highly configurable, Windows-like layout by default.
- **[Cinnamon](https://wiki.archlinux.org/title/Cinnamon)** — traditional desktop metaphor, lightweight, great for users coming from Linux Mint.
- **[Hyprland](https://wiki.archlinux.org/title/Hyprland)** — modern tiling Wayland compositor for keyboard-centric workflows.

You can also stay in pure-CLI mode indefinitely — this is a perfectly valid choice for servers, dev boxes, or minimalist setups. The Arch Wiki has an excellent [overview of available desktop environments](https://wiki.archlinux.org/title/Desktop_environment) with installation commands and screenshots.

This guide stops here, since everything beyond this point depends on personal preference. Enjoy your new Arch system.