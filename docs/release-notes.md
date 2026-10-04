AetherClash v5.5.7：重做网络信息测速与延迟探测，并进一步修复 Windows 在线升级的前台 PowerShell 窗口。

## 本次更新

- Windows 在线升级进一步静默化
  - 不再直接提权启动 powershell.exe
  - 改由无控制台窗口的 Windows Script Host（wscript.exe）作为升级启动器
  - PowerShell 继续使用 -WindowStyle Hidden / -NonInteractive 在后台执行
  - 保留完整的「下载 → 退出旧进程 → 静默安装 → 自动启动新版」流程
  - Windows UAC 系统授权框仍可能正常出现，但授权后不再显示管理员 PowerShell 控制台窗口

- 网络信息测速重做为 Speedtest 风格
  - 右上角下拉框现在选择 Speedtest 测速服务器，而不是代理节点
  - 测速服务器通过当前代理出口获取，并自动按测速服务器延迟排序
  - 默认通过当前实际代理节点进行测速
  - 支持嵌套策略组，自动递归解析到最终实际代理节点
  - Selector 尚未写入本地 selectedMap 时，会回退到 mihomo 当前真实 group.now
  - 当前代理节点、配置或节点列表变化后，会自动刷新测速服务器列表
  - 使用独立隐藏测速策略组和仅监听 127.0.0.1 的内部 listener，不修改用户真实代理组
  - 隐藏测速策略组不会显示在 Global 模式的代理列表中
  - 下载约 15 秒、上传约 15 秒，多连接并发测试
  - 测速过程中实时显示 Mbps 与 MB/s
  - 支持手动停止测速
  - 最终分别显示：
    - 下载 Mbps
    - 下载 MB/s
    - 上传 Mbps
    - 上传 MB/s

- 网络延迟探测修正
  - 不再把完整 DNS/TLS/HTTP 请求耗时直接当作节点延迟
  - 改用 mihomo 的代理节点 delay 探测，并明确指定当前最终代理节点
  - 每个目标进行两次探测并取较低有效值，降低首次建连带来的偏差
  - 当前代理变化后自动重新测试
  - 网络延迟区域会显示当前结果实际经过的代理节点
  - 默认目标调整为轻量地址：
    - Google：gstatic generate_204
    - Cloudflare：generate_204
    - GitHub：robots.txt

- CI / 发布流程
  - 普通 main 提交现在都会执行 Format/Parse、Analyze 与完整 Tests
  - 普通开发提交不会启动 Windows/macOS 原生打包
  - 仅 release tag、手动发布或 [release-build] 提交进入正式打包
  - 发布前新增的代理解析与隐藏组逻辑已通过完整测试

## 发布目标

- Windows amd64
- macOS arm64

Android 与 macOS Intel 继续暂时停用，相关构建代码仍保留。
