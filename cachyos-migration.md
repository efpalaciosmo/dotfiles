# Minimal CachyOS desktop: Niri and GNOME

A standalone specification for packages, services, kernel modules, drivers and
modular installation. This is a design reference, **not a tested installer or a
verified package lockfile**. Verify package availability and hardware support
against the CachyOS repositories and kernel used for installation.

**Implemented entry-point contract:** plain `make` performs CachyOS system
setup followed by personal GNU Stow synchronization. `make setup` installs
packages, prepares the system and enables services for the next boot without
linking personal preferences; `make dotfiles` only validates/links those
preferences and applies Adwaita dark/orange, including the bundled Ghostty theme.
Setup is CachyOS-only, retains review/recovery confirmations and never reboots.
It also additively generates `en_US.UTF-8` and fills missing rootless subordinate
ID mappings after conflict checking. These are approved implementation updates
to the original design below; see [the current installation guide](docs/cachyos-install.md).

## 1. Goal and non-negotiable behavior

Build a personal, minimal **CachyOS desktop with Niri and GNOME selectable in
GDM**, with working hardware integration and user-controlled configuration.

- Niri is the intended initial session; GDM remembers subsequent user choices.
- GNOME is a complete usable session, **not the complete GNOME application suite**.
- Keep Ghostty, a small launcher inventory, working hardware integration, and
  optional containers/VMs. No preinstalled browser, GNOME extensions, or Flatpak apps.
- Offer Flathub per user, not a preconfigured system-wide app collection.
- User dotfiles take precedence over system fallbacks. System setup never links
  personal preferences; the separate dotfiles stage explicitly opts into the
  repository's Ghostty/Adwaita/shell preferences. Do not change the login shell.
- Install explicit package selections and enable only services required by the
  selected modules. Do not silently install every desktop or virtualization backend.
- Preserve package-signature verification, a working firewall, and deliberate
  administrative authorization. Never fix permissions with world-writable devices.
- No automatic reboot. Recovery and backups must be tested, not assumed.

The complete desktop profile includes both sessions. Containers, virtualization,
ARM emulation, Tailscale and security-key tooling are independently selectable.

## 2. Platform and installation model

| Area | Requirement |
| --- | --- |
| Base | Supported CachyOS x86_64 installation, rolling updates and signed repositories |
| Kernel | Supported CachyOS kernel, such as `linux-cachyos`; verify the selected variant and retain a tested fallback boot option |
| Boot | Preserve the chosen bootloader and supported initramfs tooling; test kernel/initramfs regeneration and Secure Boot separately |
| Installation | Start with modular post-install configuration; a custom ISO is optional future work |
| Desktop | Explicit session components rather than full desktop application groups |
| Security | Signed packages, one host firewall, deliberate polkit authorization, no automatic PAM changes |
| Configuration | Managed system defaults with user-owned dotfiles taking precedence |
| Inventories | Record requested modules, explicit packages, all installed package versions, launcher IDs, managed files and enabled units |
| Recovery | External backups and a tested rescue path; optional Btrfs snapshots are not backups |

Kernel headers are required when building out-of-tree/DKMS modules, not merely
to use in-tree drivers. Match headers to each selected kernel. Do not install
custom drivers or replace the boot stack unless the hardware requires it.

## 3. Minimal GNOME: absent applications versus hidden launchers

**Keep the application menu clean primarily by not installing the full GNOME
application suite, rather than installing everything and hiding it afterward.**

Maintain an explicit launcher allowlist. Inspect installed `.desktop` files,
including `NoDisplay`, `Hidden`, `OnlyShowIn`, and `NotShowIn`; report unexpected
or missing launchers rather than silently hiding them.

The intended host launcher set is:

| Application | Desktop file |
| --- | --- |
| btop | `btop.desktop` |
| Ghostty | `com.mitchellh.ghostty.desktop` |
| nvtop | `nvtop.desktop` |
| Files | `org.gnome.Nautilus.desktop` |
| Settings | `org.gnome.Settings.desktop` |
| Software | `org.gnome.Software.desktop` |
| Zathura | `org.pwmt.zathura.desktop` |
| Virtual Machine Manager | `virt-manager.desktop` |

Some installed tools are CLI-only, background components, or already marked as
non-launcher desktop entries by their packages. They remain installed and usable.
This is a host-software baseline, not a restriction on applications users install.

For CachyOS:

1. Select GNOME session packages individually; avoid selecting all of `gnome` or
   `gnome-extra`, or an unreviewed desktop preset that adds unwanted applications.
2. Keep Files, Settings and Software intentionally; “minimal” does not mean zero
   graphical applications. Check GNOME Software's Flatpak integration separately.
3. Verify actual desktop-file IDs supplied by the selected packages.
4. Generate the expected launcher set from selected modules: omitting virtualization
   must also omit the expectation for `virt-manager.desktop`.
5. If an essential dependency adds an unwanted launcher, document why. Prefer a
   managed XDG override with `NoDisplay=true` rather than deleting or editing
   pacman-owned files. Record this exception in the module configuration.
6. Do not overwrite user overrides in `~/.local/share/applications/`; test both
   GNOME's application grid and Fuzzel, including applications installed by users.

Hiding a launcher neither uninstalls the application nor disables its services.

## 4. Package selection by capability

These are candidate Arch/CachyOS package selections, **not one command to install
everything**. Select the relevant modules and hardware-specific alternatives.
Confirm names, providers, dependencies and contents with `pacman -Si PACKAGE`,
`pacman -Ss PATTERN`, and package file-list queries. Prefer signed repository
packages; do not add AUR builds silently when something is unavailable.

### Core tools, shell and fonts

`btop`, `curl`, `fastfetch`, `fontconfig`, `git`, `kmod`, `make`, `pciutils`,
`python`, `stow`, `usbutils`,
`tar`, `traceroute`, `unzip`, `vim`, `xz`, `zsh`, `starship`,
`zsh-completions`, `ttf-jetbrains-mono-nerd`.

Add `vi` if a separate implementation is wanted. Configure required locales using
`/etc/locale.gen` and `locale-gen`. Keep the terminal font styles Regular, Bold,
Italic and Bold Italic available. Shell/prompt setup remains user-controlled.

### GNOME and shared desktop integration

`adwaita-icon-theme`, `adwaita-fonts`, `dbus`, `gdm`, `gnome-backgrounds`,
`gnome-control-center`, `gnome-keyring`, `gnome-session`,
`gnome-settings-daemon`, `gnome-shell`, `gnome-software`, `nautilus`,
`gvfs`, `gvfs-afc`, `gvfs-mtp`, `gvfs-smb`, `polkit`,
`xdg-desktop-portal`, `xdg-desktop-portal-gnome`, `xdg-desktop-portal-gtk`,
`xdg-user-dirs`, `xdg-utils`.

Verify GDM/keyring PAM integration, GNOME Software's Flatpak support and portal
routing in both desktop sessions. Install session components individually, not
the entire `gnome`/`gnome-extra` application selection.

### Niri and desktop tools

`brightnessctl`, `fuzzel`, `ghostty`, `libnotify`, `mako`,
`network-manager-applet`, `niri`, `playerctl`, `swaybg`, `swayidle`,
`swaylock`, `util-linux`, `waybar`, `wl-clipboard`, `xwayland-satellite`,
`zathura`, `zathura-djvu`, `zathura-pdf-mupdf`.

Select a lightweight polkit agent. If using `/usr/bin/lxpolkit`, verify its package
provider (commonly `lxsession`); otherwise update session startup to the chosen
agent. Installing the network applet or wallpaper tool does not autostart it.

### Audio, multimedia and device integration

`alsa-ucm-conf`, `alsa-utils`, `sof-firmware`, `pipewire`, `pipewire-alsa`,
`pipewire-pulse`, `libpulse`, `wireplumber`, `libheif`, `libxcrypt-compat`,
`libcamera-tools`, `gst-plugin-libcamera`, `libimobiledevice`, `libinput`,
`libwacom`, `libratbag`.

Review optional GStreamer codec support, including `gst-plugins-bad`/`openh264`,
against actual application needs. Verify Bluetooth audio codecs, camera pipelines
and phone access rather than assuming the presence of tools guarantees support.

### Networking, power and firmware

`networkmanager`, `networkmanager-openvpn`, `bluez`, `bluez-utils`, `fwupd`,
`linux-firmware`, `lm_sensors`, `nvtop`, `zram-generator`.

- Include the Wi-Fi backend required by the NetworkManager configuration.
- Use the required split firmware packages and `sof-firmware` for the hardware.
- Select `amd-ucode` or `intel-ucode` for the installed CPU.
- Choose one firewall: the intended stack is `firewalld`, but preserve or
  deliberately migrate an existing UFW setup rather than enabling both.
- Choose one power-profile stack: `tuned` plus `tuned-ppd` where supported,
  or the existing CachyOS alternative. Do not run competing power managers.
- Review OpenRGB, Solaar and Steam Input udev-rule providers separately from their
  GUIs. Do not install full applications solely to obtain device rules without
  making that dependency visible in the installation plan.

### Graphics and acceleration

| Capability | Candidate packages / selection |
| --- | --- |
| OpenGL/EGL/GLES/GBM | `mesa`, `libglvnd` |
| AMD Vulkan | `vulkan-radeon` |
| Intel Vulkan | `vulkan-intel` |
| Intel VA-API | `intel-media-driver` for supported generations; choose a generation-appropriate alternative for older hardware |
| GPU diagnostics | `mesa-utils`, `vulkan-tools`, `libva-utils`, `nvtop` |
| OpenCL | GPU-appropriate ICD, such as `opencl-mesa` where supported; optional, not a universal driver |
| AMD metrics | Optional supported AMD SMI provider; no automatic full ROCm installation |

NVIDIA, 32-bit/multilib graphics, gaming applications and GPU passthrough are
separate hardware/feature modules, not part of the AMD/Intel baseline.

### Applications, containers and security keys

- `flatpak`: Flathub per user, no preinstalled applications or system remotes.
- `podman`, `distrobox`: optional rootless containers; verify subordinate UID/GID
  mappings and networking helpers. Do not create or download containers at install.
- `tailscale`: optional client/daemon, no automatic authentication.
- `pam-u2f`, `yubico-pam`: optional security-key tools; verify `pamu2fcfg` is
  included. Do not change PAM rules or enroll keys automatically.

### Modular virtualization packages

| Module | Candidate packages / required capabilities |
| --- | --- |
| VM core | `qemu-system-x86`, `qemu-img`, `libvirt`, `virt-install`, `virt-manager`, `dnsmasq` |
| UEFI and TPM | `edk2-ovmf`, `swtpm`; verify included TPM tooling |
| 3D, display and audio | `virglrenderer` plus selected `qemu-hw-*`, `qemu-ui-*`, `qemu-audio-*`, `qemu-chardev-*` backends for virtio GL, QXL, EGL/OpenGL, SPICE, PipeWire and USB redirection |
| ARM guests | Optional `qemu-system-aarch64`, `qemu-system-arm`, and suitable firmware such as `edk2-armvirt`, after verifying package contents |
| ARM containers | Optional user-mode emulation/binfmt providers, such as `qemu-user-static` and `qemu-user-static-binfmt`; inspect which architectures they register |
| Guest console | Optional `virt-viewer` |

Do not default to `qemu-full` or install every foreign-architecture emulator,
remote storage backend, Ceph, Gluster or iSCSI integration. Request the optional
dependencies needed by each selected capability explicitly.

For any upstream download that cannot be supplied by a trusted package, record
its source/version, verify its checksum/signature and retain its license. Bundle
a verified Flathub descriptor/key if offline-friendly user registration is needed.

## 5. Package migration rules

When adapting a package list from another distribution, translate capabilities,
not names alone. Useful examples for RPM-based source lists:

| Source package naming | Arch/CachyOS equivalent or action |
| --- | --- |
| `python3`, `vim-enhanced`, `vim-minimal` | `python`, `vim`; optionally `vi` |
| `glibc-langpack-*` | Configure locales through `glibc`, `locale.gen` and `locale-gen` |
| `gnome-session-wayland-session`, `gnome-keyring-pam` | `gnome-session`; verify keyring PAM integration separately |
| `adwaita-sans-fonts`, `adwaita-mono-fonts` | Check `adwaita-fonts` |
| `dbus-tools` | `dbus`; verify required commands |
| `pipewire-pulseaudio`, `pulseaudio-utils` | `pipewire-pulse`, `libpulse` |
| `alsa-ucm`, `alsa-sof-firmware` | `alsa-ucm-conf`, `sof-firmware` |
| `NetworkManager-openvpn*` | `networkmanager-openvpn` |
| `microcode_ctl`, `amd-ucode-firmware` | CPU-appropriate `intel-ucode` or `amd-ucode` |
| `kernel-modules`, `kernel-modules-extra` | Modules supplied by the selected kernel, not separate packages with these names |
| Split Mesa driver/library packages | Hardware-specific selections from the graphics table above |
| Split libvirt driver/client packages | `libvirt`; review supplied units and optional dependencies |
| `qemu-system-*-core`, `qemu-device-*` | Appropriate `qemu-system-*` and explicit Arch backend packages; verify device support |
| `edk2-aarch64`, `swtpm-tools` | Check ARM firmware provider and tools included in `swtpm` |
| `pam_yubico`, separate `pamu2fcfg` | `yubico-pam`, tools supplied by `pam-u2f` |
| `zram-generator-defaults` | `zram-generator` plus explicit configuration |

Do not carry over another distribution's repository definitions, release-specific
backgrounds, PAM files, firmware package splits or package-manager services.
Arch optional dependencies must be requested explicitly when a feature needs them.

## 6. Proposed modular installation

Use a small, reviewable post-install tool on a supported CachyOS base before
considering a custom ISO. The following are proposed logical modules:

| Module | Contents and dependencies | Complete profile |
| --- | --- | --- |
| `base` | Core CLI tools, locale/fonts, package provenance and inventories | Required |
| `desktop-common` | GDM, keyring, polkit, portals, PipeWire/WirePlumber, Files, Settings, Software | Required for desktop profile |
| `gnome-minimal` | Selected GNOME session components; no full app suite | Yes |
| `niri` | Niri, Ghostty, Waybar/Fuzzel/Mako, lock/idle helpers and fallback config | Yes |
| `hardware` | Detected firmware, CPU microcode, graphics, audio, input, camera and diagnostics | Yes; hardware-aware selections |
| `network` | NetworkManager, Bluetooth as applicable, OpenVPN and chosen firewall | Yes |
| `power-memory` | One power-profile implementation and explicit zram configuration | Yes |
| `flatpak-user` | Per-user Flathub registration, no application installation | Yes |
| `containers` | Rootless Podman/Distrobox, no precreated containers/images | Yes, but independently optional |
| `virtualization-core` | x86 KVM/QEMU, libvirt, virt-manager, NAT, UEFI and virtual TPM | Yes, but independently optional |
| `virtualization-3d` | Selected virtio GL/EGL/SPICE/PipeWire backends; requires VM core | Optional |
| `virtualization-arm` | ARM32/AArch64 TCG guests and firmware; requires VM core | Optional |
| `containers-arm` | Reviewed ARM binfmt/user-mode emulation; requires containers | Optional |
| `tailscale` | Client/daemon only; no automatic authentication | Yes, but independently optional |
| `security-keys` | U2F/Yubico tools only; no PAM changes | Yes, but independently optional |
| `recovery` | Backups, optional Btrfs snapshot integration, tested boot recovery | Required recovery plan; filesystem-specific implementation |

Each module should declare packages, dependencies, managed configuration files,
system/user units, checks, and rollback/removal limitations. A dry run must show
those changes before applying them. Reapplying must not duplicate configuration,
users, remotes or polkit rules. Omitting a module must not remove existing user
packages, VM disks, containers or dotfiles.

Suggested execution order:

1. Detect CachyOS, architecture, hardware, installed packages and existing services.
2. Select the profile and optional modules; resolve dependencies and conflicts.
3. Review signed repository sources, package availability, the plan and backups.
4. Complete a supported full system upgrade; install explicit selections. Never
   use `pacman -Sy` followed by selective installs as a partial-upgrade shortcut.
5. Apply only managed system configuration; preserve existing files or stop for
   review instead of overwriting them.
6. Enable selected system units on the installed target; do not start GDM or
   replace networking in the middle of an active live session.
7. Register user-session setup without running user Flatpak commands as root.
8. Run static/inventory checks, then reboot deliberately and test both sessions.

Do not replace the existing `/etc`, `/usr`, `os-release`, package presets or boot
configuration with files copied wholesale from another installation.

## 7. System services and session startup

### System units, enabled only with their selected modules

```text
gdm.service
NetworkManager.service
bluetooth.service
firewalld.service
tailscaled.service
tuned.service
tuned-ppd.service
virtqemud.socket
virtnetworkd.socket
virtnodedevd.socket
virtnwfilterd.socket
virtsecretd.socket
virtstoraged.socket
virtproxyd.socket
virtlogd.socket
virtlockd.socket
```

The default target is `graphical.target`. With modular libvirt, leave
`libvirtd.service`, `libvirtd.socket`, `libvirtd-ro.socket`, `libvirtd-admin.socket`,
`libvirtd-tcp.socket`, `libvirtd-tls.socket`, `virtproxyd-tcp.socket`,
`virtproxyd-tls.socket` disabled. Leave `sshd.service` disabled unless remote login
is explicitly requested. Review package/vendor presets for any additional units.

### User units

```text
pipewire.socket
pipewire-pulse.socket
wireplumber.service
```

Provide a separate, explicitly managed user oneshot for Flathub registration.
It should run after graphical-session startup, retry failures, and use a bundled
verified descriptor so login does not block on downloading it. The unit creates
only the user remote, not apps or a system remote; it is not supplied automatically
by installing Flatpak. Its registration command is:

```sh
flatpak remote-add --user --if-not-exists flathub /path/to/verified/flathub.flatpakrepo
```

The descriptor path must be supplied by the installer; do not run this as root
on behalf of a desktop user.

### CachyOS service policy

- Enable GDM for the desktop profile, NetworkManager for network management, and
  Bluetooth only when selected/needed. Keep `graphical.target` for graphical hosts.
- Keep `NetworkManager-wait-online.service` only if a real boot dependency needs it.
- Choose **one** host firewall. If selecting firewalld, inspect any existing
  CachyOS UFW configuration before replacing it. Never enable both blindly.
- Enable Tailscale and the chosen power stack only with their modules. Enabling
  `tailscaled` does not authenticate it; `tailscale up` remains deliberate.
- Use the VM sockets above only when the installed libvirt package supplies them
  and the virtualization module is selected; see the migration notes below.
- Keep PipeWire sockets/WirePlumber in the **user** manager. Do not replace them
  with a root-run audio service.
- Do not enable a global `dnsmasq.service` merely for libvirt NAT; libvirt manages
  its own instance. Podman also does not require a permanently running daemon.
- Leave SSH and remote libvirt listeners off unless requested; do not enable
  unattended upgrade timers by default.

Enablement is not the same as an always-running process: sockets activate daemons
on demand, and some services use D-Bus or other activation rather than `enable`.
Inspect existing units and vendor presets instead of running blanket `preset-all`
on an already personalized CachyOS machine.

### Niri startup is separate from system service enablement

Provide a system fallback at `/etc/niri/config.kdl` that starts Waybar, Mako,
the chosen polkit agent and swayidle in the Niri session. Do not also autostart
duplicate copies through user units. Start `swaybg` or the network applet only
if desired; package installation alone does not start them.

The fallback should provide touchpad tap, 12-pixel gaps, half-width columns,
screenshot and media/brightness keys, and these essential shortcuts:

| Shortcut | Action |
| --- | --- |
| `Super+Enter` | Ghostty in the home directory |
| `Super+D` | Fuzzel |
| `Super+E` | Files |
| `Super+Alt+L` | Lock |
| `Super+Shift+/` | Shortcut overlay |
| `Super+H/J/K/L` | Navigate windows/columns/workspaces |
| `Super+Shift+E` | Leave Niri |

Idle policy: lock after five minutes, blank monitors after ten, lock before
suspend and restore monitors after resume. Keep the fallback in English and
validate with `niri validate --config /etc/niri/config.kdl`. User configuration
at `$XDG_CONFIG_HOME/niri/config.kdl` or `~/.config/niri/config.kdl` replaces the
fallback entirely, including its startup/locking behavior. Launch through the
packaged `niri-session` integration and test portals, keyring and polkit in both
sessions. Do not assume GNOME's session services automatically cover standalone Niri.

## 8. Virtualization: modular packages, modular daemons, optional instances

These are three independent choices: selecting optional VM capabilities,
splitting libvirt daemons by driver, and choosing system versus user-session VMs.

### Required behavior

- x86_64 guests use KVM; ARM32/AArch64 guests use TCG emulation on the x86 host.
- VM features include UEFI, emulated TPM, NAT, directory/filesystem storage,
  virtio 3D, local SPICE/OpenGL, PipeWire audio, and USB redirection.
- Prefer **modular, socket-activated libvirt**, not monolithic libvirtd.
- Package installation must not grant passwordless system-libvirt access. Require
  administrator authentication by default; optionally authorize one explicitly
  selected local account through reviewed polkit/socket policy.
- If single-account passwordless access is enabled, replacing the selected account
  must replace the previous grant. Review broader group/socket access as well;
  require a full logout/login after group changes.
- System-libvirt write access is powerful host administration, not merely access
  to `/dev/kvm`.
- Bridges are deliberate; a Wi-Fi station is not normally a conventional Ethernet
  bridge uplink. No VM, container, or guest OS is automatically created.

### Proposed CachyOS implementation

Check the units provided by the installed `libvirt` package before enabling the
modular-daemon architecture. Package modularity and daemon modularity are separate
concerns; a single package can supply several driver daemons.

For a fresh system-libvirt profile, enable the required `virtqemud`, network,
storage, secret, device/filter, logging and locking sockets listed above. Retain
`virtproxyd.socket` only for the selected compatibility/connection requirements.
Do not enable monolithic libvirtd alongside the modular drivers. For an existing
libvirtd installation, first back up definitions/state, shut down guests, and
follow the upstream daemon migration procedure; merely enabling new sockets is
not a safe conversion. Never stop virtlogd/virtlockd underneath running guests.

Socket-only activation is suitable for on-demand use. If guests must start at
host boot without a client connection, explicitly configure and test the relevant
daemon services/object autostart rather than assuming enabled sockets guarantee it.

Offer two clearly distinguished connections:

| Connection | Intended use | Important limitations |
| --- | --- | --- |
| `qemu:///system` | Centrally managed guests, libvirt NAT, host-boot autostart where configured | Administrative authorization required; storage/device permissions must be managed correctly |
| `qemu:///session` | Optional per-user instance with user-owned VM state | Not the same VM inventory; networking and host-boot autostart differ, and privileged host-device/network operations are restricted |

Do not silently move definitions between them or call session mode inherently
faster. Validate 3D permissions for either mode; system mode does not inherently
forbid render-node access. Keep libvirt TCP/TLS listeners disabled by default.

Configure authorization separately from package installation. Review socket
ownership, group grants and polkit rule order before relying on single-user
authorization semantics. Do not bypass authentication or change device permissions
globally to make virt-manager connect.

For NAT, confirm the default network exists before starting/autostarting it;
do not overwrite an existing definition. Check guest DHCP, DNS and HTTPS through
`virbr0` with the host firewall enabled. Do not solve failures by disabling the
firewall, globally forcing an old backend, or permitting all routed traffic.

Keep the 3D and ARM modules separate. Package/content checks must confirm the
selected QEMU build actually has the promised virtio GL/QXL/USB devices,
EGL/SPICE displays, audio backends, KVM accelerator and ARM firmware. A working
`virt-manager` executable alone proves none of that.

## 9. Kernel modules, firmware and hardware configuration

### Kernel modules and drivers

Drivers normally come from the selected kernel and are loaded automatically for
detected devices. This is a **hardware-dependent verification list**, not a list
to force-load on every machine. Modules may be built in or have platform-specific
variants; use kernel configuration and actual driver bindings when appropriate.

| Area | Modules/drivers to verify | Selection notes |
| --- | --- | --- |
| Virtualization | `kvm`, `kvm_amd` or `kvm_intel` | CPU virtualization must be enabled in firmware; verify `/dev/kvm` and QEMU KVM support |
| VM networking | `tun`, `bridge`, `vhost_net` where used | Verify TAP/bridge support and the selected accelerated virtio networking path |
| Firewall/NAT | `nf_tables`, connection-tracking/NAT support required by the selected firewall backend | Let the firewall/libvirt load dependencies; do not force a competing backend |
| AMD graphics | `amdgpu` | Pair with matching firmware, Mesa and AMD Vulkan userspace |
| Intel graphics | `i915` or `xe` | Use the driver supported for the GPU/kernel; do not force a driver switch globally |
| Intel Wi-Fi | `iwlwifi` and device-appropriate companion modules | Matching Intel wireless firmware required |
| Realtek Wi-Fi | Device-specific `rtw89_*`/`rtw88_*`, for example `rtw89_8852ce` | Match the exact PCI/USB ID; do not assume all Realtek adapters use one driver |
| Other Wi-Fi | Hardware-appropriate `ath*`, `brcmfmac`, `mt76*` or other driver | Select firmware by actual adapter, not by vendor name alone |
| USB Bluetooth | `btusb`; vendor support such as `btrtl` where applicable | Verify controller firmware and reconnection |
| HDA audio | `snd_hda_intel` | Driver name also applies to supported non-Intel HDA controllers |
| USB audio | `snd_usb_audio` | Test playback and microphone paths |
| SOF audio | `snd_sof` plus platform-specific modules | Requires appropriate SOF firmware and ALSA UCM profiles |
| Tablets/input | `wacom`, appropriate HID drivers | Test pressure, mapping and buttons with libinput/libwacom |
| Virtual input | `uinput` | Needed for selected virtual-input/Steam Input workflows; access remains controlled by udev |
| Compressed swap | `zram` | Verify the kernel supports the selected compression algorithm |
| USB cameras | `uvcvideo` where applicable | Other camera types may need different kernel/libcamera support |

Persistently load `uinput` through a small `/etc/modules-load.d/` entry only if
the selected input module needs it. Do not add every driver above to modules-load
or the initramfs; follow hardware detection and the selected boot tooling.
Avoid driver blacklists and custom module parameters without a documented need.

Useful read-only checks:

```sh
uname -r
lspci -k
lsusb
lsmod
modinfo amdgpu
modinfo kvm_amd
journalctl -k -b
```

Choose `modinfo` targets for the actual hardware. A module present on disk is not
proof that it is loaded, bound to the device, or functioning correctly. Install
`pciutils` and `usbutils` if those diagnostic commands are not already available.

### Firmware and userspace drivers

- Cover the installed GPU, Wi-Fi, Bluetooth and audio devices through the selected
  `linux-firmware` providers, including split AMD, Intel, Realtek, MediaTek,
  Qualcomm/Atheros, Broadcom or Cirrus packages where required.
- Check kernel logs for missing firmware; do not fetch arbitrary blobs or install
  every vendor driver as a workaround. Firmware paths and compression may change
  between package versions.
- CPU microcode, GPU firmware, a kernel driver, Mesa/Vulkan/VA-API userspace and
  application codecs are separate layers; installing one does not replace the others.
- Verify runtime `libEGL.so.1`, `libGLESv2.so.2`, `libGL.so.1` and `libgbm.so.1`
  loading. Niri/Ghostty may load these dynamically, so executable presence alone
  does not prove graphics support.

### Runtime policies

- **Graphics:** AMD/Intel kernel drivers and Mesa; no forced global graphics
  environment variables, relaxed `/dev/dri` permissions or full ROCm requirement.
  Verify EGL/GLES/GL runtime loading, Vulkan and GPU-appropriate VA-API/OpenCL.
- **Audio:** PipeWire/WirePlumber, ALSA UCM/SOF firmware, Bluetooth audio plugins
  and microphone switching. Installed tools do not prove physical codec support.
- **Networking:** NetworkManager Wi-Fi and GNOME OpenVPN import; no provisioned
  VPN credentials or automatically established tunnel.
- **Peripherals:** firmware, libinput/Wacom, camera and phone integration, and
  selected udev rules without unnecessary GUIs. Proprietary Xbox adapters may
  need separate drivers; installed rules do not guarantee physical device support.
- **Power:** Integrate one supported power-profile implementation with GNOME.
- **Zram:** Intended policy: `min(ram, 8192)` MiB, priority 100,
  `zstd(level=1)`, no disk writeback or hibernation setup. Specify size, priority
  and compression explicitly in zram-generator configuration. Inspect existing
  CachyOS zram configuration first to avoid duplicate devices or conflicting rules.
- **Shell:** Zsh, Starship and completions are available but not automatically
  configured. Stow is available for user-reviewed dotfiles; do not rewrite home
  paths or import another system's shell initialization automatically.

| Area | Runtime checks |
| --- | --- |
| Graphics | `glxinfo -B`, `eglinfo`, `vulkaninfo --summary`, `vainfo`, `nvtop` |
| Audio | `wpctl status`, `pactl list short sinks`, `pactl list short sources`, `aplay -l`, `arecord -l` |
| Network | `nmcli device status`, `nmcli connection show --active` |
| Bluetooth | `bluetoothctl show`, `rfkill list`, relevant journals |
| Power | GNOME profile switching and the chosen daemon's status; `tuned-adm active` if using TuneD |
| Memory | `zramctl`, `swapon --show`, `/sys/block/zram0/comp_algorithm` |

Graphics checks require a suitable running session/device, and hardware-specific
tools may be absent when their optional module is not selected.

## 10. Updates, recovery and migration of existing data

- Use supported full `pacman -Syu` upgrades from trusted signed repositories;
  handle repository/AUR packages separately and review upstream notices.
- Default to user-initiated upgrades; an optional notification/check schedule
  must not silently become an unattended full-system upgrade or reboot.
- If using Btrfs snapshots, define what subvolumes they cover, how `/boot`/the
  ESP and package database remain consistent, and how to recover after a bad
  kernel. A snapshot is not an external backup or a guarantee of boot recovery.
- Keep a rescue medium and tested backups outside the installation being changed.

Before migrating an existing installation:

1. Inventory requested and effective packages, Flatpak apps/remotes, VM XML,
   networks/pools, containers and important service configuration. Translate
   functionality, not an `rpm -qa` list pasted into pacman.
2. Back up home/dotfiles and application data, including Flatpak user data and
   container volumes. Preserve ownership, ACLs, xattrs and symlinks as applicable;
   account for changed UID/GID mappings and distribution-specific security metadata.
3. Shut down VMs before copying disks; include backing chains, XML, UEFI NVRAM,
   TPM state, snapshots and custom pools. Review firmware/emulator paths before
   importing into the matching system or user-session connection.
4. Prefer reproducible container definitions and deliberate exports/backups to
   blindly copying the entire Podman storage directory between distributions.
5. Treat `/etc` and `/var/lib` selectively: they may contain secrets or
   distribution-specific state. Do not commit Tailscale/VPN credentials, private
   signing keys, VM secrets or personal data into the new project.
6. Install CachyOS on a separate/test target first, apply selected modules, restore
   data deliberately, and verify recovery before retiring the old installation.

## 11. Acceptance checklist

These are required tests, **not results already obtained for CachyOS**.

- [ ] Fresh and repeated modular installs produce the intended package/config/unit
  inventories; unselected modules do not create services, downloads or data.
- [ ] GDM offers both sessions, remembers the choice, and works offline; Niri uses
  the fallback only when user configuration is absent.
- [ ] GNOME/Fuzzel show the selected host launcher set. No browser, extensions or
  Flatpak apps were preinstalled, and user-added apps are not hidden.
- [ ] Ghostty maps a window; fonts, portals/file chooser/screen sharing, keyring,
  polkit and GNOME Software's Flatpak integration work in both sessions.
- [ ] Flathub is per user; fresh system remotes are empty. Offline login succeeds
  and later remote registration recovers without blocking the desktop.
- [ ] Audio/microphone, Wi-Fi, Bluetooth, OpenVPN import, graphics/video decode,
  camera, input devices, brightness and power profiles work on actual hardware.
- [ ] Locking precedes suspend and no unlocked desktop flashes on resume; zram
  uses the intended policy without conflicting with distribution configuration.
- [ ] Required kernel modules, firmware and userspace drivers match actual hardware;
  kernel logs show no unresolved device/firmware failures. Kernel updates retain
  working driver bindings and an accessible recovery boot path.
- [ ] Rootless Podman/Distrobox work without precreated containers; optional ARM
  binfmt registers only the intended supported architectures.
- [ ] System libvirt authorization matches policy; optional session VMs remain
  separate. x86 KVM, NAT DHCP/DNS/HTTPS, UEFI, TPM and selected 3D/ARM paths work.
- [ ] Only the selected firewall/power manager is active; SSH and libvirt network
  listeners remain off by default. Check system and user failed units/journals.
- [ ] Secure Boot, kernel updates, a failed-upgrade recovery and backup restoration
  are tested for the actual CachyOS boot/filesystem setup. No automatic reboot.

Static checks and nested/container desktop tests do not establish GDM login,
Secure Boot, suspend, firmware or hardware readiness. Record the exact package
versions, kernel, hardware and test results for each validated installation.

## 12. Sources for implementation

Upstream references (recheck against the installed versions):

- [CachyOS installation and package selection](https://wiki.cachyos.org/installation/installation_on_root/)
- [CachyOS QEMU/VMM setup](https://wiki.cachyos.org/virtualization/qemu_and_vmm_setup/)
- [CachyOS user-session connection](https://wiki.cachyos.org/virtualization/qemu_user_session/)
- [ArchWiki: Niri](https://wiki.archlinux.org/title/Niri)
- [ArchWiki: libvirt](https://wiki.archlinux.org/title/Libvirt)
- [Libvirt: modular daemons and migration](https://libvirt.org/daemons.html)
- [CachyOS Secure Boot](https://wiki.cachyos.org/configuration/secure_boot_setup/)

Some distribution guides demonstrate `qemu-full`, monolithic libvirtd or a
particular firewall backend. Those examples are not the minimal modular policy
specified here; inspect current package contents and use the upstream modular
daemon procedure when adapting them.
