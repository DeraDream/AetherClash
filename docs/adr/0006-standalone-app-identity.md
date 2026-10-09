# 0006. po0-clash 作为独立应用发布

- 状态：已采纳
- 日期：2026-09-28

## 背景

`v0.8.98-po0.1` ～ `po0.6` 沿用了 FlClash 的全部身份：Android 包名 `com.follow.clash`、macOS bundle id、
Windows Inno Setup `AppId`、进程 / 服务名、IPC socket 与数据目录都与官方版相同。结果是：

- Windows 安装包直接覆盖官方 FlClash；Android 因签名不同必须先卸载官方版；同一台设备无法同时保留两者。
- 两个应用若同时存在（例如 macOS 上改了 `.app` 名），会争用同一个 helper 服务、socket、锁文件和数据目录。
- 版本号挂在上游版本上（`0.8.98-po0.N`），需要额外的 `forkRevision` 和自定义比较规则，并且与上游发版节奏耦合。
- Android 签名密钥只存在于构建 VPS，发版需要人工在 VPS 构建 APK 再上传，VPS 成了单点。

## 决定

po0-clash 成为全新的独立应用，与官方 FlClash（以及旧的 FlClash-po0 构建）在同一设备上并存、互不冲突。

| 项目 | 取值 |
|---|---|
| 显示名 | `AetherClash` |
| macOS 安装包 / 可执行文件 | `AetherClash.app` / `AetherClash` |
| Windows 安装包 / 可执行文件 | `AetherClash-<version>-windows-amd64-setup.exe` / `po0-clash.exe` |
| 应用 ID（Android applicationId、macOS bundle id、Linux APPLICATION_ID） | `io.github.yuuukicreation.po0clash` |
| Windows Inno Setup `AppId` | `67A8CFA2-EC79-4DD3-AB44-75CDD5C3B591` |
| 内核 / helper（兼 Windows 服务名） | `Po0ClashCore` / `Po0ClashHelperService` |
| Linux helper | systemd `po0clash-helper`，socket `/run/po0clash/helper.sock` |
| IPC | `/tmp/Po0ClashSocket_*`、`\\.\pipe\Po0ClashCore_*` |
| 锁文件 / TUN 设备 | `po0-clash.lock` / `Po0Clash` |
| 应用专属 URL scheme | `po0clash://`（`clash://`、`clashmeta://` 保留，用于一键导入订阅） |
| 发布者 | yuuuki-creation，<https://github.com/yuuuki-creation/po0-clash> |
| 产物 | `po0-clash-<ver>-<platform>-<arch>.<ext>` |

- **版本**：独立语义化版本，从 `1.0.0` 开始；`pubspec.yaml` 的 `version` 是唯一来源，标签为 `v<X.Y.Z>`。
  `forkRevision` 与 `-po0.N` 后缀废弃。
- **内部命名不改**：Dart 包名 `fl_clash`、Kotlin 包与 Gradle `namespace` `com.follow.clash*`、由其派生的
  MethodChannel 名、`FlClash*` 类名。它们对操作系统不可见，改名只会放大与上游的差异；凡是需要「本应用 ID」
  的地方一律在运行时读取真实的 `packageName`。
- **签名文件入库**：Android 发版 keystore `android/app/keystore.jks` 与 `android/signing.properties` 提交到仓库，
  Gradle 直接读取，CI 无需 secret。仓库所有者明确接受这把密钥公开：po0-clash 不上架应用商店，签名只用于
  保证同一应用可以覆盖升级。除这两个文件外，其他密钥与凭据仍不得入库。
- **构建**：Android 与 Windows / macOS 一起在 GitHub Actions（`release.yaml`）上构建，只在推送版本标签或手动运行时
  触发；构建 VPS 只负责 format / analyze / test。取代 [ADR 0002](0002-build-infrastructure.md) 中 Android 构建与
  签名的部分。
- **移除 Firebase / Crashlytics**：应用不再集成 Firebase，也不再需要 `google-services.json`。

## 后果

- 官方 FlClash 与 po0-clash 可以同时安装；同时开启系统代理或 TUN 仍会互相抢占，需要用户只在一个应用里开启。
- 旧 FlClash-po0 用户不能原地升级：需要单独安装 po0-clash，用「备份与恢复」导出的本地文件导入配置
  （或重新填写 po0 token），再自行卸载旧版。WebDAV 备份目录随应用名变为 `/po0-clash`，读不到旧版的 WebDAV 备份。
- 任何人都能用公开的 keystore 签出「看起来是 po0-clash」的 APK 并覆盖安装；用户应只从本仓库的 Release 下载。
  keystore 一旦更换，所有 Android 用户必须卸载重装，因此不要更换。
- 合并上游时，身份相关文件成为新的冲突热点，`pubspec.yaml` 的版本号冲突一律保留本分支的值
  （见 [upstream-sync.md](../development/upstream-sync.md)）。
- 发版不再依赖 VPS，Actions 每次发版多消耗一个 Linux 任务。
