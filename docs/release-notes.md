AetherClash v5.5.19：完善 macOS 应用身份、网络信息与系统代理体验。

## 更新

- macOS 应用统一显示为 `AetherClash.app`，更新器、安装脚本、README 与发布说明同步调整。
- macOS 安装脚本会移除隔离属性并执行临时签名，降低 Gatekeeper 首次打开失败概率。
- 开启系统代理后立即重新检测出口 IP，避免底部 IP 状态滞后。
- 网络信息 IP 来源移除 myip、ipapi、ipinfo、ident，加入 IPPure；可按当前选择的来源直接打开浏览器检测 IP。
- 网络延迟默认新增 YouTube 和 Netflix。
- 系统代理页新增环境变量复制项，支持 PowerShell、macOS 与 Linux 格式。
- 优化延迟检测目标弹窗和连接页面活动计数的视觉样式。

## 验证

- 相关 Flutter 测试 35 项通过。
- macOS x86_64 Release 构建通过。
- CI 全量测试改为串行执行，避免共享状态并发导致预检失败。

## 发布目标

- Windows amd64 Setup EXE / ZIP
- macOS arm64 DMG
