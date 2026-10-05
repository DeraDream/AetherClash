AetherClash v5.5.14：补齐 Mihomo v1.19.32 对应的客户端 UI / 编辑器能力，并优化桌面端系统代理与虚拟网卡卡片交互。

## 智能配置编辑器

- 为现有 re_editor 增加 Mihomo YAML Schema / 自动补全能力
- 保持 AetherClash 原编辑器结构，不整体迁移新版 FlClash 编辑器 UI
- 支持按当前 YAML 层级给出对应字段提示
- 已存在的同级字段不会重复提示
- 支持从当前配置中识别策略组、代理、proxy provider、rule provider 等名称用于补全

## XHTTP

- VLESS 等支持的 network 字段可自动提示 xhttp
- xhttp-opts 自动提示：
  - path
  - host
  - mode
  - headers
- mode 自动提示：
  - auto
  - packet-up
  - stream-up
  - stream-one

## REALITY ML-KEM

- reality-opts 自动提示：
  - public-key
  - short-id
  - support-x25519mlkem768

## MIPS

- tun.stack Schema 增加 mips
- 网络设置中 MIPS 显示为“ MIPS（推荐）”
- 其他 stack 的原有显示保持不变

## EasyTier

- 编辑器识别 type: easytier
- 补充当前 Core 支持的 EasyTier 主要配置字段，包括：
  - network-name / network-secret
  - peers / listeners
  - exit-nodes / proxy-networks
  - encryption
  - KCP / QUIC
  - MTU / DNS
  - secure mode / key 等

## 系统代理 / 虚拟网卡卡片

桌面端侧栏两个卡片现在采用独立点击行为：

- 点击“系统代理”卡片本体：打开现有“网络”设置页面
- 点击“虚拟网卡”卡片本体：打开同一个现有“网络”设置页面
- 点击卡片内 Switch：继续只执行原来的开启/关闭逻辑
- 点击 Switch 不会触发页面跳转
- TUN 开启时原有二次确认逻辑保持不变
- “设置 → 进阶配置 → 网络”原入口保持不变

网络页直接复用现有 BaseScaffold + NetworkListView，不新增第二套设置页面。

## 验证

发布前已完成：

- Changed-file Dart Format：通过
- Flutter Analyze：通过
- XHTTP Schema 专项测试：通过
- REALITY ML-KEM Schema 专项测试：通过
- MIPS Schema 专项测试：通过
- EasyTier Schema 专项测试：通过
- 系统代理 / 虚拟网卡卡片导航专项测试：通过
- 完整 Flutter Tests：通过
- main 分支正式 Preflight：Format / Analyze / 全量 Tests 全部通过

## 发布目标

- Windows amd64 Setup EXE
- Windows amd64 ZIP
- macOS arm64 DMG

Android 与 macOS Intel 继续保持停用。
