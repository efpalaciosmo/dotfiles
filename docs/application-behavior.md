# Installed application behavior

Audited the installed native launchers and Flatpaks on 2026-11-07. Rules live in
`packages/niri/.config/niri/rules.kdl` and apply **only in Niri**. Both native
Wayland IDs and common Xwayland class names are matched where needed; Flatpak's
application ID is not always the window's ID.

## Floating utilities

Sizes below are **width × height in logical pixels**, chosen for the current
2560×1440 logical workspace (4K at 150%). These are starting sizes, not limits;
Niri constrains them to the available workspace and apps may enforce minimums.
New floating windows are centered unless noted. Reopen existing windows to apply
opening rules. `Super+V` still toggles any window between floating and tiled.

| Installed app | Starting size | Reason |
| --- | --- | --- |
| Thunar | 1000×720 | Quick file browsing/copying over the current task; enough space for two panes. Main windows only; dialogs keep natural sizing. |
| PeaZip, native Xarchiver | 1000×720 | Archive browsing and extraction. |
| Calculator | 440×600 | Compact keypad; resizable for advanced modes. |
| BudsLink | 480×640 | Earbud controls. Applies to either installed copy. |
| Blanket | 560×660 | Narrow ambient-sound controls. |
| Volume Control (Flatpak/native) | 760×560 | Mixer, device names and tabs. |
| Native Blueman and NetworkManager connection editor | 760×560 | Short-lived connection controls. |
| LocalSend | 760×600 | Device selection and transfer status. |
| Impression | 640×520 | Focused disk-image writing workflow. |
| ProtonPlus | 760×640 | Compatibility-tool management, not a game window. |
| Camera, Cine | 960×720 | Landscape preview/playback; fullscreen remains available. |
| GPU Screen Recorder | 900×700 | Recording setup without moving the task being recorded. |
| FurMark GUI | 900×700 | Benchmark configuration, not the benchmark renderer. |
| Flatseal, GNOME Settings launcher | 1000×760 | Settings with navigation sidebars. |
| Warehouse, Mission Center | 1100×760 | Utility tables/graphs need more horizontal space. |
| Zen/Firefox Picture-in-Picture | 480×270, bottom right | Passive video; does not take focus on opening. |

Parented dialogs, authentication prompts and fixed-size windows already float
automatically in Niri. There is no title-only rule that might float an unrelated
browser tab named “Settings” or “Calculator”. Native terminal monitors such as
Btop/Nvtop remain normal tiled terminals.

## Keep tiled

These use the existing half-width default (full available height), subject to
application minimum sizes. `Super+F` maximizes a column. No blanket
`open-floating false` rule is used, so their dialogs can still float normally.

| Installed apps | Reason |
| --- | --- |
| Zen, Brave | Primary browsing workspace; only browser PiP floats. |
| Ghostty, VS Code (Fedora container), Octave (Fedora container) | Terminal, coding and analysis workspaces. |
| Bruno, Obsidian, GNOME Text Editor | API development, notes and editing. |
| Bambu Studio, OrcaSlicer, Inkscape, Kdenlive | Large canvases, previews, timelines and tool panels. |
| OBS Studio | Persistent recording/streaming workspace, unlike the compact GPU recorder setup. |
| LibreOffice, Papers, Zathura | Documents benefit from persistent side-by-side space. |
| Pods, Boxes, virt-manager launcher | Container/VM management and consoles are sustained workspaces. |
| Bazaar | Browsing a software catalog benefits from a large tiled window. |
| Steam, PCSX2 | Libraries and games; preserve the app's own fullscreen behavior. |
| qBittorrent | Persistent transfer list. |
| ZapZap, Vesktop, Telegram | Persistent conversations beside other work. |

## Appearance

Thunar is already the default file manager: `xdg-mime query default inode/directory`
returns `thunar.desktop`. The doctor and recovery documentation use that same
association. File chooser dialogs still use the GTK portal, not Thunar; this is
independent of the folder-opening default.

Run `~/.local/bin/dotfiles-appearance` to reapply dark preferences. Native GTK 3
uses **Adwaita + prefer-dark**, avoiding the missing standalone `Adwaita-dark`
theme. Known installed GTK 3 Flatpaks get a per-app `GTK_THEME=Adwaita:dark`
override, without broad filesystem access; see [theme coverage](adwaita-theme.md).
The helper can be rerun after installing one of those apps. It does not install
software or reset unrelated Flatpak permissions.

GTK 4/libadwaita apps follow the existing dark portal preference. Apps with their
own rendering/theme setting can ignore it: select **System/Dark** inside Qt apps
(Kdenlive, qBittorrent, PCSX2, PeaZip, ZapZap), Electron apps (Bruno, Obsidian,
Vesktop), Telegram, LocalSend, the slicers and OBS when needed. Browser website
content and LibreOffice document pages are not controlled by the GTK chrome
theme. No global GTK/Qt override is imposed on those different toolkits.

To investigate a rule that does not match, use `niri msg pick-window` and compare
the actual app ID with the rule. Launcher/class aliases are fallbacks, not proof
that every installed app has been visually tested.
