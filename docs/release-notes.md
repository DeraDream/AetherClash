AetherClash v5.5.3：新增网络信息页并继续优化桌面交互。

## 本次更新

- 新增「网络信息」页面，从桌面侧栏底部公网 IP 入口进入
- 当前 IP 支持来源选择与手动刷新
  - 自动（多源抢最快成功结果）
  - IP.SB
  - ipwho.is
  - ipapi.co
  - ipinfo.io
  - ident.me
  - myip.com
  - ip-api.com
- 新增网络拓扑：本机 → AetherClash / mihomo → 当前代理或 DIRECT → 公网出口
- 新增网络延迟检测，默认检测 Google / Cloudflare / GitHub
- 延迟页面显示单项延迟、颜色状态、进度条和平均延迟，并支持手动刷新
- 「活动 → 请求」自动跟随控制从页面中央移到右上角，并改为暂停 / 恢复图标
- 优化桌面语言选择弹窗与代理页面右侧设置面板样式
- Release 暂停 Android 与 macOS Intel 构建，目前只发布 Windows amd64 与 macOS arm64
- 保留 v5.5.2 的 Windows 在线升级完成后自动重启修复

## 桌面在线升级

Windows 用户可从应用内直接检查更新。下载并安装完成后，AetherClash 会自动重新启动。

## 发布目标

- Windows amd64
- macOS arm64

Android 与 macOS Intel 仅暂时从 Release 构建矩阵中注释，代码没有删除。
