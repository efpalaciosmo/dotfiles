# CachyOS acceptance record — NOT YET VALIDATED

Keep the completed record outside this repository; redact private host data.

- Date/tester:
- Target hardware (PCI/USB IDs as applicable):
- Kernel/firmware, bootloader, initramfs tooling and Secure Boot state:
- Full invocation: `make` (system setup then Stow links; no feature arguments)
- Separate stages: `make setup` (system only), `make dotfiles` (links/appearance only)
- Automatically resolved hardware/packages/units from the saved plan:
- `/var/lib/cachyos-desktop/runs/` record / package-version inventory:
- External backup and recovery-record location:

Use PASS / FAIL / PENDING / N/A with evidence, not an unchecked assumption.

| Test | Result | Evidence / limitations |
| --- | --- | --- |
| Fresh apply and identical reapply; package/file/unit inventories | PENDING | |
| Plain make runs setup then Stow; individual targets remain isolated | PENDING | |
| en_US.UTF-8 generated; global language and other locales preserved | PENDING | |
| All standard tools included without feature selection; no workload images or user data created | PENDING | |
| Both GDM sessions, remembered choice, initial Niri and offline login | PENDING | |
| System fallback versus XDG/user Niri precedence | PENDING | |
| GNOME grid and Fuzzel allowlist; user-added applications remain visible | PENDING | |
| No browser/extensions/Flatpak apps installed by this profile | PENDING | |
| Ghostty window and Regular/Bold/Italic/Bold Italic fonts | PENDING | |
| Ghostty defaults in bindings/Fuzzel/Waybar/XDG; config and orange Adwaita theme linked by Stow | PENDING | |
| Portals: chooser, screen sharing, screenshots in both sessions | PENDING | |
| Keyring unlock, polkit authentication, Software Flatpak plugin | PENDING | |
| User-only Flathub, empty fresh system remotes, offline retry | PENDING | |
| Playback, microphone/switching and Bluetooth audio codecs | PENDING | |
| Wi-Fi reconnect, Bluetooth reconnect and OpenVPN import | PENDING | |
| EGL/GLES/GL library loading, Vulkan and GPU-appropriate VA-API | PENDING | |
| Camera, phone, tablets/input, brightness and power profiles | PENDING | |
| Lock before suspend, no unlocked resume frame; 5/10 minute idle policy | PENDING | |
| Zram size/priority/zstd level; no duplicate/conflicting policy | PENDING | |
| Actual driver bindings and firmware; kernel logs after upgrade | PENDING | |
| Rootless containers/subordinate mappings/networking, no precreated images | PENDING | |
| Only ARM/AArch64 binfmt registered; test a user-supplied image | PENDING | |
| System libvirt requires admin; session VM inventory stays separate | PENDING | |
| x86 KVM, UEFI, TPM, directory storage and NAT DHCP/DNS/HTTPS | PENDING | |
| Included virtio GL/QXL/EGL/SPICE/audio/USB and ARM TCG paths | PENDING | |
| One firewall/power stack; SSH and remote libvirt disabled by default | PENDING | |
| System/user failed units and journals; no unexpected vendor enablement | PENDING | |
| Secure Boot, kernel/initramfs update and accessible fallback boot | PENDING | |
| Failed-upgrade recovery, rescue boot and external backup restore | PENDING | |
