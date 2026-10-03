# AetherClash

[**English**](README.md)

AetherClash 是基于 [FlClash](https://github.com/chen08209/FlClash) 与 ClashMeta（mihomo）的多平台代理客户端，
内置 po0 防火墙自动加白，并统一使用 Material 3 风格界面。

本仓库以 **AetherClash** 作为独立发行项目维护；同时继续保留上游署名与 GPL-3.0 许可要求。

<p align="center">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="docs/features/images/ui_po0_dark.png">
        <img alt="AetherClash 的 po0 加白页面" src="docs/features/images/ui_po0_light.png" width="90%">
    </picture>
</p>

## 功能

- **po0 自动加白**：为每台 po0 机器添加 `pgnfw_` token，AetherClash 打开期间按刷新间隔检查白名单，
  本机出口不在名单时立即加白；请求强制直连，因此加入的是真实出口而不是代理 IP。
- **统一 Material 3 界面**：Android、Windows、macOS 使用一致的设计、导航与动效，支持动态取色。
- **桌面在线升级**：Windows / macOS 可在应用内检查 GitHub Release、下载并安装兼容的新版本。
- 保留本发行版使用到的 FlClash 功能：ClashMeta 内核、订阅导入、WebDAV 同步、深色模式等。

## 安装

从 [Releases](https://github.com/DeraDream/AetherClash/releases) 下载对应平台产物。

| 平台 | 安装方式 |
|---|---|
| Windows | 运行 `AetherClash-<版本>-windows-amd64-setup.exe`；也可使用对应 `.zip` 免安装版本 |
| macOS | 在「终端」执行下方命令，自动识别 Apple Silicon / Intel |
| Android | 安装对应的 `AetherClash-<版本>-android-*.apk` |
| Linux / iOS | 当前独立 Release 工作流暂不发布 |

```bash
curl -fsSL https://raw.githubusercontent.com/DeraDream/AetherClash/main/scripts/install-macos.sh | bash
```

macOS 可使用 `AETHERCLASH_VERSION`、`AETHERCLASH_DMG`、`AETHERCLASH_REPO` 指定版本、DMG 或仓库；
为兼容旧版升级，原来的 `PO0CLASH_*` 变量仍然可用。

**v5.5.2 会优先原地升级已有 po0-clash 安装。** 为了不丢失配置并确保 5.5.1 能直接在线升级，
这一版仍保留部分内部可执行文件名、Helper、Bundle ID 与数据目录标识；用户界面与新安装品牌统一显示为 AetherClash。

同一时间只在一个代理客户端里开启系统代理或 TUN，否则会互相抢占。

## 开发

项目文档见 [docs/](docs/README.md)，代码规范见 [AGENTS.md](AGENTS.md)。

## 致谢与许可

- [chen08209/FlClash](https://github.com/chen08209/FlClash)：上游客户端
- [w0ven/po0fw](https://github.com/w0ven/po0fw)：po0 防火墙加白逻辑

与上游相同，以 [GPL-3.0](LICENSE) 许可发布。
