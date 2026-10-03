AetherClash v5.5.2：品牌升级与桌面在线升级自动重启修复。

## 本次更新

- 应用名称由 po0-clash 升级为 **AetherClash**
- 启用新的 AetherClash 极简猫咪轨道图标，并让 Release 构建自动生成 Windows / macOS / Android 原生图标
- 修复 Windows 在线升级安装完成后未自动启动新版本的问题
- 静默升级完成后由 Inno Setup 使用原桌面用户身份重新启动 AetherClash，避免继承 UAC 管理员权限
- PowerShell 升级器改为显式等待安装器退出，并在安装器未拉起应用时增加桌面 Shell 兜底启动
- 更新 GitHub 项目与 Release 品牌链接到 DeraDream/AetherClash，并保留旧仓库更新地址作为重命名过渡兼容
- 保留原有内部进程名、Helper、应用 ID 和数据目录，确保现有 5.5.1 用户可原地升级且配置不丢失

## 升级说明

- Windows 5.5.1 用户可直接在应用内检查更新并升级到 5.5.2
- 下载完成后确认 UAC，旧版本会退出；安装完成后应自动启动 5.5.2
- 新安装的桌面名称显示为 AetherClash；为保证在线升级兼容，本版本仍保留 po0-clash.exe / po0-clash.app 等内部文件名
- Windows 升级日志位于 %LOCALAPPDATA%\AetherClash\update.log
- 现有配置、订阅、po0 设置和桌面偏好均会保留

## 安装

- Windows：AetherClash-5.5.2-windows-amd64-setup.exe（安装包）或对应 .zip（免安装）
- macOS：使用 Release 中对应架构的 dmg，或运行仓库 scripts/install-macos.sh
- Android：安装 Release 中的 arm64-v8a APK（主流机型）

## 已知限制

- Android 首次开启自动加白后需重启一次 VPN，直连路由才会生效
- Android 从最近任务划掉 AetherClash 后停止检查，重新打开应用即恢复
- 同时在用的网段超过白名单容量时，各设备可能互相挤占
- 与其他代理客户端同时开启系统代理或 TUN 会互相抢占，请只在一个应用里开启
- macOS 版本未经 Apple 公证，首次启动时可能需要按系统提示允许运行
