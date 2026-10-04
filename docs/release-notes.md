AetherClash v5.5.8：修复 Speedtest 测速节点列表无法加载的问题，并保留 v5.5.7 的测速、延迟与静默升级改进。

## 本次更新

- 修复 Speedtest 测速节点列表解析失败
  - 修复 `FormatException: Unexpected extension byte (at offset 1)`
  - Speedtest.net 的服务器列表可能返回 gzip 压缩 JSON
  - 现在会显式识别 gzip 响应并先解压，再进行 UTF-8 / JSON 解析
  - 新增普通 JSON 与 gzip JSON 两种解析测试，防止该问题再次回归

- Speedtest 测速继续保持
  - 右上角选择的是 Speedtest 测速服务器，而不是代理节点
  - 测速默认经当前最终实际代理节点
  - 支持嵌套策略组解析到真实节点
  - 节点 / 配置 / Provider 变化后自动刷新测速服务器列表
  - 下载约 15 秒、上传约 15 秒，多连接并发
  - 实时显示 Mbps 与 MB/s
  - 最终显示下载 / 上传 Mbps 与 MB/s
  - 使用隐藏测速策略组，不修改用户真实代理组

- 网络延迟继续使用 mihomo 节点 delay 探测
  - 结果明确经当前最终代理节点
  - 当前代理变化后自动刷新
  - Google / Cloudflare / GitHub 使用轻量探测地址

- Windows 在线升级继续使用隐藏后台流程
  - 通过 wscript.exe 启动隐藏 PowerShell
  - 保留自动退出旧进程、静默安装和自动启动新版

## 发布目标

- Windows amd64
- macOS arm64

Android 与 macOS Intel 继续暂时停用，相关构建代码仍保留。
