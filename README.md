# KStats

KStats is a **KDE Plasma 6** panel widget inspired by [exelban/stats](https://github.com/exelban/stats).

It displays a compact, menu-bar-style status strip directly in the Plasma panel.
Clicking the strip opens a dropdown popup with more detailed readings.

All sensor data is sourced from KDE's **KSysGuard sensor API**
(`org.kde.ksysguard.sensors`), which is part of
[plasma-systemmonitor](https://invent.kde.org/plasma/plasma-systemmonitor).

## Features

- **CPU** – aggregate usage percentage, updated every 2 s
- **Memory** – used physical RAM (strip) + used / total with a progress bar (popup)
- **Disk I/O** – aggregate read and write rates for all block devices
- **Network I/O** – aggregate download and upload rates across all interfaces
- Human-readable byte formatting (B / K / M / G / T) with `/s` suffix for rates

## Requirements

| Dependency | Version |
|---|---|
| KDE Plasma | 6.0+ |
| KDE Frameworks (ECM, KF6::Package) | 6.0+ |
| plasma-systemmonitor (KSysGuard sensors) | any Plasma 6–era build |
| CMake | 3.16+ |

## Installation

### Build from source

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
cmake --install build   # may require sudo
```

After installation, restart Plasma or run:

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

Then right-click your panel → **Add Widgets** → search for **KStats**.

### Install directly (no build step)

The plasmoid is a pure-QML package, so you can also install it without CMake:

```bash
kpackagetool6 --install package --type Plasma/Applet
```

To upgrade after pulling new changes:

```bash
kpackagetool6 --upgrade package --type Plasma/Applet
```

To remove:

```bash
kpackagetool6 --remove org.kde.kstats --type Plasma/Applet
```

## Project layout

```
package/
├── metadata.json          # Plasma 6 applet manifest
└── contents/
    └── ui/
        └── main.qml      # PlasmoidItem – sensors, compact strip, popup
CMakeLists.txt             # ECM/KDE CMake build definition
```

## License

[MIT](LICENSE) © 2026 Jun Ouyang
