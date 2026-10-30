# CachyOS workstation: `make`

This implements [the migration design](../cachyos-migration.md) as a separate
post-install workflow, **not an OS converter, custom ISO or verified lockfile**.
It requires an installed, supported CachyOS x86_64 base and Python 3.11+.
No third-party Python dependencies, AUR helper or unattended upgrades are used.
Do not run the CachyOS installer on Fedora/bootc, a live installer or an unreviewed production
host. Test on a separate installation first.
The design describes selectable modules; this implementation uses them as
internal review/test boundaries. Normal setup has one fixed workstation
selection, not a profile or feature menu.

## Normal installation: just `make`

Install the minimal CachyOS base with networking, Git, Make and a sudo-enabled
regular account, then run `make` from this clone **as that user**.
The default target runs `make setup` first and `make dotfiles` only after it
succeeds, including under parallel Make. `make help` lists the targets.
`scripts/setup.sh` bootstraps Python from signed repositories if necessary and
runs checks; setup installs the fixed workstation defaults, detects hardware
and preserves an existing UFW/power stack and NetworkManager Wi-Fi backend
where possible. It performs root read-only preflight, presents the plan,
then invokes the installer through sudo without a questionnaire or custom
confirmation phrase. Only sudo and pacman's normal prompts remain. After installing,
it validates again. Setup alone does not apply personal Stow/theme/shell
preferences; the full `make` workflow then links them and applies dark/orange
Adwaita, including Ghostty's bundled theme. `make dotfiles` can also be rerun
independently without installing packages or changing system services.

Keep external backups and a rescue boot option before starting: setup performs
a full system upgrade, including when Python needs bootstrapping. It does not
ask for backup locations, test dates, bootloader details or an `INSTALL` phrase.
Recovery evidence is optional and never fabricated; absent evidence is recorded
as unverified, not as passing tests. Nothing bypasses package signatures. Unsupported
hardware, conflicting services or complex existing configuration still stop
for review rather than being silently overwritten. A command cannot replace
physical hardware/backup tests or provision a missing bootable rescue path.
The prerequisite upgrade saves its own private pre-upgrade package/unit inventory
alongside the user's setup plan under
`$XDG_STATE_HOME/cachyos-desktop` (normally `~/.local/state/cachyos-desktop`).

There are no setup arguments or Make feature variables to pass. `make local`
runs static checks followed by the configuration-only workflow on every
distribution. On non-CachyOS systems, setup refuses without installing or
linking anything; use `make dotfiles` explicitly with that system's prerequisites.

## 1. Standard defaults and hardware detection

Plain `make setup` installs all of the following:

| Area | Included defaults |
| --- | --- |
| Desktop | GDM, minimal usable GNOME and Niri, Ghostty, Files, Settings, Software, Fuzzel, Waybar, Mako and lock/idle tools |
| Integration | Fonts/CLI tools, en_US.UTF-8 generation (no global language change), portals/keyring/polkit, PipeWire/WirePlumber, camera/phone/input support and hardware diagnostics |
| Host | Firmware/microcode/AMD or Intel userspace as detected, NetworkManager/OpenVPN, Bluetooth tools, one firewall/power stack, existing zram policy or a standard default |
| Flatpak | Flatpak and deferred per-user Flathub registration; no apps/system remote |
| Containers | Podman, Distrobox, rootless helpers and missing subordinate-ID mappings; ARM/AArch64 static emulation with only those binfmt registrations |
| Virtualization | x86 KVM/QEMU, modular sockets, local-active passwordless access for the invoking libvirt-group account, next-boot default NAT, virt-manager, UEFI/TPM, virtio GL/QXL/EGL/SPICE/PipeWire/USB, ARM32/AArch64 TCG and firmware |
| Other tools | Tailscale and U2F/Yubico tools; no automatic authentication, enrollment or PAM changes |
| Recovery | Inventories, optional operator-provided backup/recovery evidence and manual acceptance checks |

`make cachyos-plan` is a read-only preview of this same fixed module/package
selection. The final plan inside setup also incorporates the detected existing
firewall, power stack and Wi-Fi backend. Bluetooth tools are always available;
the Bluetooth service is enabled only when a controller is detected. No browser,
GNOME application suite, extensions, Flatpak apps, guest OS or container images
are preinstalled. The local libvirt compatibility proxy is not needed by the
standard direct modular connections; no TCP/TLS libvirt listeners are enabled.

Review `cachyos/modules.json`: each module declares explicit packages,
dependencies, managed file sources, system/user units, acceptance checks and
removal limitations. Change candidate providers there only after repository and
content inspection; unavailable packages fail instead of invoking AUR or
substituting an entire desktop/backend suite.

The ARM module uses `edk2-aarch64` and `qemu-system-arm-firmware`: current Arch
package indexes split the design's candidate `edk2-armvirt` capability between
these providers. Both architectures' firmware code/variable files are checked
on target. This upstream metadata review is not a CachyOS package lock or a
guest-boot test.

CPU microcode, graphics and split firmware are hardware-detected, not a menu
of features. Detection uses known PCI/USB vendor IDs with a sysfs fallback and
is advisory, not hardware certification. Unsupported NVIDIA or ambiguous
hardware stops for review rather than installing a universal driver stack.
Setup keeps existing Intel VA-API providers without asking for a GPU generation
or selecting an unverified replacement. If none is installed, generation-specific
video decoding needs separate provisioning; Intel Vulkan is still selected.
SOF firmware and UCM are explicit.

Setup preserves an existing reviewed UFW setup or otherwise uses firewalld,
and preserves an existing power implementation or defaults to TuneD/tuned-ppd.
Competing managers stop for review. Setup preserves any existing zram policy
without adding an override or asking a question. If no policy exists, it installs
the standard zram0 configuration in
`/etc/systemd/zram-generator.conf.d/99-cachyos-desktop.conf`:
`min(ram,8192)` MiB, priority 100, `zstd(level=1)`, no disk writeback.
Existing files remain untouched. Maintenance-time `--reviewed-zram` layering
still checks for additional devices, advanced/non-swap settings and later
competing drop-ins; setup does not automatically approve that layering.

Kernel selection, fallback kernel installation, matching headers for actual
DKMS users, Secure Boot, firmware settings, OpenCL/ROCm, multilib/NVIDIA,
Steam/OpenRGB/Solaar rules and optional snapshots remain deliberate,
hardware/filesystem-specific operations. No universal driver list is loaded.
The tool never replaces the bootloader, initramfs stack, `/etc`, `/usr`, PAM,
login shell or personal dotfiles.

## 2. Verify the target and recovery before mutation

1. Back up external data with ownership, symlinks, ACLs and xattrs where needed.
   Include dotfiles, Flatpak data, container volumes/definitions and secrets
   outside this repository. Shut down guests before copying disks/backing
   chains, XML, NVRAM, TPM state, snapshots and custom storage pools.
   Inventory Flatpak apps/remotes as the actual user (`flatpak list --user`,
   `flatpak remotes --user`, and the corresponding `--system` queries), rootless
   containers/volumes (`podman ps -a`, `podman volume ls`), and both libvirt
   connections' definitions, networks and pools. Keep exports outside Git and
   preserve their connection/UID/GID context; emulator/firmware paths must be
   reviewed before importing on a different distribution.
2. Test a restore, rescue-medium boot, fallback kernel boot and the target's
   kernel/initramfs regeneration. Keep the tested boot option. Btrfs snapshots
   alone do not meet the external backup requirement; account separately for
   `/boot`/ESP and package-database consistency.
3. No recovery questionnaire or record is required to install. If using the
   maintenance CLI, `--recovery-record PATH` optionally attaches an existing
   operator attestation, validated against `cachyos/recovery.example.json`.
   Previous records are not silently reused. Do not record passing results
   until you have actually performed those tests; installation does not certify
   that your backups or recovery procedures work.
4. Setup's automatic root read-only preflight checks CachyOS/keyring and the
   effective required/trusted package-signature
   policy for every configured repository, `pacman -Si` availability, repository
   servers, foreign packages and read-only dependency/upgrade transactions.
   It **does not refresh sync databases**. Stale databases may require a
   deliberate supported full upgrade before planning again, never `pacman -Sy`
   followed by selective installs. Repository metadata is not a package lock.
   Protected configuration is inspected through sudo automatically; no system
   configuration is written by that preflight. An empty repository `SigLevel`
   from `pacman-conf --repo cachyos-znver4 SigLevel` normally means inheritance
   from `[options]`, not disabled verification. Both the Python installer and
   its shell bootstrap validate that inherited global policy; no repository
   override needs to be added. Plans record raw and effective policies.
5. The reviewed preparation plan enables `en_US.UTF-8` in the existing
   `/etc/locale.gen` and runs `locale-gen` when needed, preserving other enabled
   locales. It does not change `/etc/locale.conf` or the global language. The
   personal dotfiles use this locale for messages and Waybar's calendar.

Plan output contains requested/resolved modules, packages, full managed file
contents/hashes, system and global-user enablement, target/session policy,
launcher allowlist, conflicts, checks and rollback limitations. Resolve blockers
before apply. Do not post inventories publicly without reviewing host metadata.

## 3. Installation is part of `make setup`

After showing the plan, setup performs the upgrade/installation itself through
sudo. It does not ask for recovery evidence, a backup path or an `INSTALL` phrase.
Pacman still asks you to confirm its actual transactions; Ctrl+C cancels.
There is no separate apply command to run. Review the repository's code before
executing it as root. Root executes only argument arrays, not package/configuration
text as shell commands. The underlying planner retains module subsets for
maintenance/testing, but the setup entry point accepts no feature selectors.

Apply performs a supported **full `pacman -Syu`**, rechecks signatures and
availability, then `pacman -S --needed` for explicit selections. Both package
transactions retain interactive prompts: review dependency/provider additions,
replacements and removals. Installation scripts/hooks from trusted packages are
still the package manager's responsibility; this tool does not suppress them.

It verifies required installed units, packaged sessions, the polkit agent, GNOME Software
Flatpak plugin, keyring PAM integration, graphics libraries and selected QEMU
capabilities before enabling anything. Missing support stops for review; PAM,
permissions and drivers are not patched as workarounds.
KVM must already be available before installation: enable AMD SVM/Intel VT-x in
firmware and verify `/dev/kvm`. The preflight refuses an unavailable KVM path
before upgrading packages. GDM's PAM integration is checked under `/etc/pam.d`
or, on stateless PAM packages, `/usr/lib/pam.d`, respecting `/etc` overrides.
The GL selection includes the required non-GL virtio GPU/PCI/VGA modules as well
as their GL variants; installing GL shared objects alone is insufficient.

Managed file handling is intentionally strict:

- Absent files are created; byte-identical files are left alone on reapply.
- Different files, directories and symlinked managed paths stop for review,
  even if a previous installer version wrote the differing file. There is no
  force-overwrite option. Preserve and review existing data before manually
  reconciling a desired change; do not remove distribution-owned files blindly.
- Only `/etc` and `/usr/local` defaults are managed. User overrides are untouched.
- Setup does not uninstall applications or discard existing data as cleanup.
- Locale/subordinate-ID preparation is additive rather than a replacement of
  entire configuration files. The plan shows before/after content, records it
  privately in the run inventory and refuses symlinks or changes since review.
- Setup pins the reviewed system plan and preparation hash before invoking
  apply. Changed package/file/unit/account declarations or preparation between
  review and apply stop before the transaction instead of applying an unseen
  plan. File contents are checked again before preparation writes.
- A failure is **not** rolled back automatically. Packages may already have
  upgraded; inspect the saved before/after inventory and pacman log. Never
  blindly downgrade rolling-system libraries to simulate rollback.

Only system units required by the standard workstation are enabled, without
`--now`. GDM is not started,
networking is not restarted, swap/binfmt is not reconfigured live, and no reboot
is requested. The workstation sets `graphical.target`. Audio sockets and
WirePlumber are enabled **globally in the user manager**, not run as root audio
services. Existing user masks/overrides still take precedence. No blanket
presets, global dnsmasq, SSH enablement, remote libvirt, Podman daemon or automatic
upgrade timer is requested. Review vendor presets/other existing units in the
inventory; this is not a cleanup tool for a previously customized host.
Before reporting success, the installer verifies persistent enablement for every
selected system/global-user unit and verifies `graphical.target`; a merely
running but disabled service does not pass.

Setup uses the invoking regular account automatically. AccountsService
sets initial `Session=niri`/`SessionType=wayland` **only if Session, legacy
XSession and SessionType are all empty**. Otherwise it preserves the saved
choice, including GNOME. Subsequent GDM choices remain user-controlled. No GDM
autologin is configured. An unsupported AccountsService API stops for review.

Every run records private root-owned JSON under
`/var/lib/cachyos-desktop/runs/TIMESTAMP/`: before/after package versions and
explicit packages, hardware/kernel, enabled system/global-user units, requested
plan, managed file hashes, launcher flags, repository provenance, optional
recovery-record hash (or an explicit unverified status) and completion/failure status. A successful selection is also saved in
`current.json`. No credentials, guest disks or container volumes are copied.

## 4. Sessions, launchers and Flathub

The unthemed fallback `/etc/niri/config.kdl` starts Waybar, Mako, polkit-gnome and
one swayidle instance. It supplies touchpad tap, 12px gaps, half-width columns,
Ghostty in home, Fuzzel, Files, locking, help, H/J/K/L navigation, exit,
screenshots, audio/media and brightness keys. Locking is synchronous before
sleep; test it physically. No wallpaper, network applet, shell initialization
or personal theme is autostarted. The packaged `niri-session` is required.
Niri's fallback `TERMINAL` and the system XDG terminal defaults select Ghostty so `Terminal=true`
launchers such as btop/nvtop do not require Foot or GNOME Terminal. This adds
the explicit `xdg-terminal-exec` integration package, not another terminal GUI;
explicit user Fuzzel and XDG terminal preferences retain priority. The packaged
Fuzzel configuration is not edited. Test these launchers
from both menus, not just their visibility.

**User Niri configuration replaces this fallback entirely**, including startup
and idle/locking policy. The `make dotfiles` stage of plain `make` configures
Ghostty, appearance and shell/prompt preferences through GNU Stow. Its user XDG
terminal list, Fuzzel, Niri bindings and Waybar actions all select Ghostty.
Both the terminal configuration and `Adwaita Dark Orange` theme are in the
`ghostty` Stow package. Old Kitty links owned by this clone are retired only
after Ghostty is linked; independent Kitty files and packages remain untouched.
Do not expect its existing personal configuration to become the system fallback.

Run launcher inspection as the actual desktop user after logging into each
session (not under sudo):

```sh
python3 scripts/cachyos.py launchers
```

This reads the installed generated module-aware allowlist, respects XDG
directory precedence and desktop IDs/subdirectories, and reports `Hidden`,
`NoDisplay`, `OnlyShowIn`, `NotShowIn`, `TryExec`, missing and unexpected entries
for GNOME and Niri. VM Manager is part of the standard launcher set. Nothing is hidden
or deleted automatically. User-installed applications are allowed. GNOME's
actual grid and Fuzzel may filter differently; inspect them manually, including
Flatpak exports in your `XDG_DATA_DIRS`. Distribution changes to launcher IDs or
desktop-specific visibility must be reviewed, not declared passing by fiat.

If an essential dependency adds an unwanted launcher, document it in the
module-keyed `launcher_exceptions` map in `cachyos/modules.json`, for example:

```json
{"niri": {"dependency-tool.desktop": {
  "source": "config/applications/dependency-tool.desktop",
  "reason": "Reviewed essential dependency; its standalone GUI is not needed"
}}}
```

Supply a reviewed copy of that upstream desktop entry under the indicated
source with `NoDisplay=true`. The tool installs it in
`/usr/local/share/applications/`, never edits pacman-owned entries or
`~/.local/share/applications/`, records the reason and refuses to hide an
allowlisted application. There are no default hiding exceptions.

Flathub registration uses a bundled, SHA-256-pinned official descriptor and key
(see `cachyos/vendor/README.md`). A user timer defers registration until after
graphical startup; its oneshot retries failures once a minute with a bounded
timeout. Login does not download the descriptor or wait for network completion.
It runs `flatpak remote-add --user --if-not-exists`, never root's Flatpak setup,
never a system remote, and installs no apps. An existing user's Flathub remote
is preserved, not replaced. Test offline startup and later retry. For a session
with no graphical-session target, explicitly run as the user when ready:

```sh
flatpak remote-add --user --if-not-exists flathub \
  /usr/local/share/cachyos-desktop/flathub.flatpakrepo
```

## 5. Included tools do not automatically create workloads or credentials

- **Containers:** setup validates `/etc/subuid` and `/etc/subgid` and preserves
  existing valid mappings by account name or UID. Missing mappings get a free
  65536-ID range, excluding existing ranges and real account/group IDs. Malformed,
  overlapping or undersized mappings stop for manual review rather than rewriting
  them. No accounts, group memberships or existing mappings are replaced. After
  login, test `podman info` rootlessly; actual networking still needs testing.
  Do not copy Podman's entire storage across distributions. No containers,
  images, networks or volumes are created. ARM installs the signed repository's
  static interpreter package, which may contain other architectures, but manages
  only explicit ARM/AArch64 binfmt entries and rejects other existing QEMU
  registrations. It never installs the all-architecture binfmt preset package.
- **Libvirt:** the invoking regular account is appended to `libvirt`, preserving
  its other groups. The early managed polkit rule grants that exact account
  passwordless management only when local, active and in the group; other
  accounts receive `AUTH_ADMIN` before the vendor's blanket group rule. This is
  deliberate root-equivalent access. Other existing members, local grants,
  earlier rules, custom socket policy and monolithic/remote units stop for review.
  Fully log out/reboot after membership changes. `make doctor` checks the current
  session's membership, noninteractive polkit authorization and a non-mutating
  query through a read/write system connection. Never chmod devices 666.
- Existing monolithic libvirt needs the [upstream daemon migration procedure](https://libvirt.org/daemons.html),
  shut-down guests and state backups **before** using this fresh modular profile.
  Never stop virtlogd/virtlockd underneath guests. Modular sockets are verified
  from the installed package and enabled by the standard installation.
- `qemu:///system` and `qemu:///session` are different inventories. Session mode
  has networking/device/boot-autostart limitations, not inherently better speed.
  No VM XML or storage is moved between them. Bridges are a separate decision;
  a Wi-Fi station is not an ordinary Ethernet bridge uplink.
- The enabled `cachyos-libvirt-network.service` runs **on the next boot**, after
  the firewall and required sockets. It starts/autostarts the existing default
  NAT without changing its XML. If none exists, it chooses a free private /24
  and defines it through libvirt. Non-NAT definitions, conflicting host/VPN
  routes or an unowned `virbr0` stop with an actionable journal error. No live
  network service is started by setup. Both nftables and the nft iptables
  frontend (current package `iptables`, providing `iptables-nft`) are supplied;
  the installed frontend is verified and no backend is globally forced. Test guest
  DHCP/DNS/HTTPS with the chosen firewall enabled. No firewall bypass is used.
  Boot-autostart guests need explicit daemon/object-autostart testing, not just
  enabled sockets. x86 uses KVM; ARM guests on this host use TCG.
- UEFI/TPM and the included 3D/ARM package contents are checked, but real guest boot,
  render-node permissions, local SPICE/OpenGL, USB redirection, PipeWire audio
  and ARM firmware compatibility remain acceptance tests. No guest console GUI
  is added unless separately requested/provisioned.
- Tailscale is installed and its daemon enabled by default; authentication remains `tailscale up`
  by deliberate user action. Security-key modules supply tools including
  `pamu2fcfg` but never enroll keys or alter PAM.

## 6. Deliberate reboot and acceptance

```sh
sudo python3 scripts/cachyos.py inventory
make system-check
make doctor
```

These commands use the last successful plan. `check` verifies managed files,
packages, selected enablement, installed capability checks, conflicts and default
target. `make system-check` also requires the selected system services/sockets
to be active after reboot, including GDM, the firewall and the NAT oneshot.
They are not runtime certification; root inventory cannot substitute
for the actual user's launcher and session checks. Run those separately.

After a deliberate reboot, complete **all** applicable checks in specification
section 11. Copy `cachyos/acceptance.example.md` outside the repository and record
exact versions/hardware, commands/results and pending/failed tests. Include both
GDM sessions, offline/online behavior, application windows/fonts/portals/keyring/
polkit, audio/microphone, Wi-Fi/OpenVPN/Bluetooth, GPU/video/camera/input,
brightness/power, physical suspend/locking, zram, kernel/firmware logs, included
containers/VM paths, authorization/firewall/remote listeners and failed units in
both system and user managers. Secure Boot, an update, a failed-upgrade recovery
and a real backup restore need their own physical-target test records.

Do not claim success based on static checks, a nested compositor, VM-only tests
or executable presence. Reapply to verify idempotence; setup must not remove
user packages, images, guests, overrides or data. Removal and changes
to previously managed content require a reviewed manual plan; automatic teardown
or rollback would risk destroying exactly that state.
