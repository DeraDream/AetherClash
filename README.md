# AetherClash

[**简体中文**](README_zh_CN.md)

AetherClash is a multi-platform proxy client based on [FlClash](https://github.com/chen08209/FlClash) and ClashMeta (mihomo),
with a built-in po0 firewall auto-whitelist and a unified Material 3 desktop/mobile experience.

This repository is maintained as an independent AetherClash distribution. Upstream attribution and the GPL-3.0 license are
preserved.

<p align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="docs/features/images/ui_po0_dark.png">
        <img alt="AetherClash po0 page" src="docs/features/images/ui_po0_light.png" width="90%">
    </picture>
</p>

## Features

- **po0 auto-whitelist**: add a `pgnfw_` token for each po0 machine. While AetherClash is open it checks the whitelist at
  the configured interval and adds the real exit IP as soon as it is missing.
- **Material 3 across platforms**: a consistent Android, Windows and macOS interface with dynamic color.
- **Desktop self-update**: Windows and macOS can download and install a compatible GitHub Release from inside the app.
- Everything inherited from FlClash that remains in this distribution: ClashMeta core, subscriptions, WebDAV sync, dark mode and more.

## Install

Download the build for your platform from [Releases](https://github.com/DeraDream/AetherClash/releases).

| Platform | How |
|---|---|
| Windows | Run `AetherClash-<version>-windows-amd64-setup.exe`, or use the matching portable `.zip` |
| macOS | Run the command below; it chooses Apple Silicon or Intel automatically |
| Android | Install the matching `AetherClash-<version>-android-*.apk` |
| Linux / iOS | Not currently published by the standalone release workflow |

```bash
curl -fsSL https://raw.githubusercontent.com/DeraDream/AetherClash/main/scripts/install-macos.sh | bash
```

For macOS, `AETHERCLASH_VERSION`, `AETHERCLASH_DMG` and `AETHERCLASH_REPO` select a specific build or repository.
The legacy `PO0CLASH_*` variable names are still accepted for upgrade compatibility.

Current macOS releases install as `/Applications/AetherClash.app`. If Gatekeeper blocks first launch, run:

```bash
xattr -dr com.apple.quarantine "/Applications/AetherClash.app"
codesign --force --deep --sign - "/Applications/AetherClash.app"
open "/Applications/AetherClash.app"
```

For an older installed bundle, replace `AetherClash.app` with `po0-clash.app` in all three commands.

Only enable the system proxy or TUN in one proxy client at a time.

## Development

Project documentation lives in [docs/](docs/README.md); coding rules are in [AGENTS.md](AGENTS.md).

## Credits and license

- [chen08209/FlClash](https://github.com/chen08209/FlClash): upstream client
- [w0ven/po0fw](https://github.com/w0ven/po0fw): po0 firewall whitelist logic

Released under [GPL-3.0](LICENSE), like upstream.
