po0-clash v5.4.0：新增 Windows / macOS 应用内在线升级，下载、校验、安装和重启可在客户端内完成。

## 本次更新

- Windows / macOS 的“检查更新”改为应用内在线升级，不再只跳转 GitHub Release 下载页
- 发现新版本后弹出更新确认窗口，确认后显示实时下载进度、百分比和已下载 / 总大小
- Windows 自动选择对应版本的 amd64 setup.exe；macOS 自动识别 Apple Silicon / Intel 并选择对应 dmg
- 下载完成后校验 Release 文件大小，并在 GitHub 提供 SHA-256 digest 时进一步校验完整性
- 更新安装前通过现有退出流程保存设置、关闭托盘、系统代理 / DNS 和 Core；超时仍会由独立更新进程强制结束主进程
- Windows 使用独立 PowerShell 更新器提权静默覆盖安装，完成后自动重新启动 po0-clash，并清理临时更新目录
- macOS 使用独立更新脚本挂载 dmg、覆盖当前 app；必要时请求管理员权限，强退兜底同时清理残留 Po0ClashCore，完成后自动重新打开
- 更新源和安装脚本仓库地址统一修正为 DeraDream/po0-clash
- Android 和其他非桌面平台保持原有 Release 页面下载方式

## 升级说明

- 5.3.0 及更早版本尚未包含新的在线升级器，本次 5.4.0 需要先手动覆盖安装一次
- 从 5.4.0 开始，后续 Windows / macOS 版本可直接在应用内完成在线升级
- 覆盖升级会保留现有配置、订阅、po0 设置和桌面偏好
- Windows 在线升级过程中如安装目录需要管理员权限，会弹出 UAC 确认
- macOS 版本仍未经 Apple 公证，升级时如目标目录需要管理员权限会出现系统授权提示

## 安装

- Windows：po0-clash-5.4.0-windows-amd64-setup.exe（安装包）或 .zip（免安装）
- macOS：使用 Release 中对应架构的 dmg，或运行仓库 scripts/install-macos.sh
- Android：po0-clash-5.4.0-android-arm64-v8a.apk（主流机型），可与官方 FlClash 共存

## 已知限制

- Android 首次开启自动加白后需重启一次 VPN，直连路由才会生效
- Android 从最近任务划掉 po0-clash 后停止检查，重新打开应用即恢复
- 同时在用的网段超过白名单容量（5 条，服务端已有的固定记录也占名额）时，各设备会互相挤占
- 与其他代理客户端同时开启系统代理或 TUN 会互相抢占，请只在一个应用里开启
- macOS 版本未经 Apple 公证，首次启动时可能需要按系统提示允许运行
