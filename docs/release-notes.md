AetherClash v5.5.17：修复规则页面进入后出现 profileDisabledRuleIdsProvider disposed during loading 的错误。

## 修复

- 规则页不再通过 autoDispose 的 profileDisabledRuleIdsProvider 读取持久化禁用状态
- 规则页刷新直接从 RulesDao 查询当前配置的禁用规则覆盖
- 规则开关写入直接使用 RulesDao
- 开关写入失败时保持原有回滚逻辑
- 写入后仅失效相关缓存 Provider，不再依赖其异步加载结果
- 配置加载时的规则覆盖恢复同样直接读取数据库，页面路径和 Core 重载路径保持一致

## 验证

- Flutter Analyze 通过
- 完整 Flutter Tests 通过
- 规则开关 Mihomo RuleWrapper 专项验证继续通过
- 配置重载后的规则覆盖恢复逻辑继续保留
- Rule Provider / Geo 资源更新逻辑保持 v5.5.16 的专项验证结果

## 发布目标

- Windows amd64 Setup EXE / ZIP
- macOS arm64 DMG
