# PLAN · iOS 对齐（第四轮 · 功能面）

> 2026-07-12 建立。对标基线：iOS 主仓 `freegrid-public` 分支最新提交 `fc11f0e`（1.2 Settings 重构）。
> 1.3 决策透镜包在 iOS 侧未提交、状态 parked，不进本轮对标范围。
> 第三轮（视觉 P1-P4）已全部完成并验证。本轮差距集中在**数据功能**，不再是视觉。

## 差距诊断（已核对两端源码，非猜测）

| # | 差距 | iOS 现场 | Android 现状 | 量级 |
|---|------|---------|-------------|------|
| G1 | 数据导出缺失 | `ContentView.swift:1485` Assets 页「导出 CSV / 导出 JSON」按钮 → `DataIO.exportCSV/exportJSON`(2114-2190)：CSV 带 UTF-8 BOM、表头`日期,类型,类别/来源,金额,备注`；JSON 走 schema v1 snake_case，与导入完全对称可回导。临时文件 → 系统分享面板 | 完全没有。`BackupCodec.encodeMap` 已能产出 schema v1 JSON（有测试兜底），但无 UI、无分享通道 | 中 |
| G2 | JSON 导入缺失 | `fileImporter` → `DataImporter.previewJSON`(2195) → `ImportReviewSheet`(3780)：导入统计预览、非 canonical 分类对齐建议（按总额降序、可手动改）、资产策略三选一（replace/addToCash/skipAssets）、去重（带 id 按 UUID 精确；旧文件退回 date\|amount\|category\|note 内容指纹）→ commit 保留原 UUID | 完全没有。`BackupCodec.decodeMap` 已能解析（含 `schema_version`/`locked_assets`/`id`），缺 DataImporter 业务层、文件选择和整个预览 UI | 大 |
| G3 | 清空数据缺失 | `ContentView.swift:1506` Assets 数据区末尾弱化的危险操作 → destructive alert → `DataPurger`(2417) 清空含 UserAssets 单例 | 无入口 | 小 |
| G4 | 记账 Sheet 内联预览缺失 | AddExpenseSheet 内嵌「戴维斯三杀预览」(3509)：输入金额即时显示 KILL 1 净值 / KILL 2 日均 / KILL 3 自由天数传导；AddIncomeSheet 内嵌「自由增长预览」(3682) | `_ExpenseSheet/_IncomeSheet` 只有表单（金额校验/分类/日期/备注），传导预览只存在于独立的模拟 Sheet | 中 |
| G5 | 模拟推演是静态对照，不是级联动画 | `SimDemoGrid`(3960-4380)：格子级联熄灭（支出，利落）/ 点亮（收入，刻意放慢 0.72s/格），TimelineView 余弦 envelope，产品核心体感「这笔花出去，自由的格子熄灭几格」 | 模拟 Sheet 是静态 before→after 双 `_MiniGrid` + 箭头 | 中 |
| G6 | Settings 关于面弱一档 | 「关于」push 子页：版本 / 隐私政策外链(GitHub PRIVACY.md) / ICP 备案号点击复制；顶层另有「评价与反馈」跳 App Store | 平铺两行：版本 + 本地隐私 dialog。ICP 与 App Store 评价是 iOS 发布合规项，Android 未上架暂不适用 | 小 |

不算差距、刻意不做：SwiftData/云端（红线）、macOS 相关（Platform.swift）、iOS 1.3 parked 功能。

## 执行顺序（沿用惯例：一个对话做一个 P，每步收尾更新 HANDOFF + 截图进 `_local/`）

### P1 · 数据导出 + 清空（G1 + G3，先做——为 P2 双端比对提供工具；**同时是公开发 APK 的前置条件**：数据纯本地，导出是用户唯一的备份出口）

**输入**：`lib/core/data/backup_codec.dart`（已有 encode）、Assets 页（`dashboard_shell.dart`）；对照 iOS `ContentView.swift:1485-1560, 2114-2190`。

**改动**：
1. 新增 `core/data/data_io.dart`：`exportCsv()` 逐字段对齐 iOS（UTF-8 BOM、同表头、同金额格式 0~2 位小数）；`exportJson()` 直接走 `BackupCodec.encodeMap`。
2. 引入 `share_plus`（写临时文件 → 系统分享面板）。这是本轮唯一新增的两个依赖之一，属平台通道必需；release APK 仍必须不含 INTERNET 权限。
3. Assets 页尾部按 iOS 层级加数据区：导出 CSV / 导出 JSON 并排紧凑按钮 + 说明文案；分隔线下弱化的「清空所有数据」→ Material destructive 确认对话框 → 清空全部（含资产单例），回到空态引导。

### P2 · JSON 导入：预览 + 分类对齐 + 去重（G2，最大件，单独一个对话）

**输入**：`core/data/backup_codec.dart`（已有 decode）；对照 iOS `ContentView.swift:1562-1626, 2017-2460, 3780-3960`。

**改动**：
1. 新增 `core/domain/expense_category.dart`：canonical 分类权威列表与 iOS 单一来源逐项一致；记账 Sheet 的分类快捷选择改引用它（手动记账只能选 canonical，导入是唯一混入外来分类的口子）。
2. 新增 `core/data/data_importer.dart`（纯逻辑，可测试）：
   - `previewJson`：解析统计 + 去重（带 id 按 UUID 精确，无 id 退回 date|amount|category|note 内容指纹）+ 非 canonical 分类对齐建议（按总额降序）+ 双桶策略识别（schema v1 有 locked_assets/旧文件只有 total）。
   - `commitImport`：按用户在预览里改过的分类映射与资产策略（replace / addToCash / skipAssets）写入，**保留原 UUID**（否则再导同一文件去重失效）。
3. 引入 `file_selector`（或 file_picker）选文件。
4. 新增 `features/.../import_review_sheet.dart`：预览统计、分类对齐可编辑列表、资产策略三选一、确认导入、结果反馈（✓ 导入完成 N 笔 / 跳过 M 笔重复）。
5. `core/` 新增文件必须带单元测试：去重两分支、三种资产策略、旧 Web 版无 schema_version 文件、分类归一。**不改 `FreedomMath` / `BackupCodec` 已有代码。**

### P3 · 记账 Sheet 内联预览（G4，渲染层，改动小）

**输入**：`_ExpenseSheet/_IncomeSheet`；对照 iOS `impactPreview`(3509) / `gainPreview`(3682)。

**改动**：金额输入有效时，Sheet 内即时渲染三杀行（支出：KILL 1 净值 / KILL 2 日均 / KILL 3 自由天数，前→后）或自由增长行（收入：净值、自由天数增量）。全部复用 `FreedomMath` 现有函数与模拟 Sheet 同一套口径，不新写算法。

### P4 · 模拟推演级联动画（G5，产品记忆点）

**输入**：模拟 Sheet 的静态 `_MiniGrid` 对照；对照 iOS `SimDemoGrid`(3960-4380) 与其注释里的三态设计（idle/playing/done 单一渲染路径）。

**改动**：静态双网格换成单网格级联推演：支出逐格熄灭（利落）、收入逐格点亮（放慢 ~0.72s/格）、span 随 delta 拉长且 cap ≈3s；单 `AnimationController` + `CustomPainter`（与流星层同套路），纯函数按 elapsed 分类每格状态。系统「减少动态效果」时降级为现在的静态 before→after 对照。

### P5 · Settings 关于收尾（G6，可与 P4 同对话）

- 「关于」改为 push 子页：版本 / 隐私政策外链（暂用 FreeGrid-Freedom 仓 PRIVACY.md，同 iOS）。
- ICP 备案行与商店评价行**确定不做**（分发决策已定 APK 直发，不上商店）。

## 分发决策（2026-07-12 已确认，详见 HANDOFF.md）

- APK 直发（GitHub Releases + 统一下载表），不上国内商店、不办软著；小白用户由 PWA 承接。
- 发布前置：P1 导出功能落地 + release keystore 生成并多处备份（换签名 = 用户卸载重装 = 本地数据全丢）。
- P5 的 ICP 备案行与商店评价行因此确定不做（不是暂缓）。

## 红线（沿用前几轮）

- 不迁 iOS 私有分支的云同步 / token / 私有端点；release APK 保持零 INTERNET 权限。
- release keystore 绝不进 git，生成后立即多处备份。
- `FreedomMath` / `BackupCodec` 已测试兜底的代码不动；本轮 `core/` 只**新增**文件（data_io / data_importer / expense_category），新增必须带测试。
- 新 UI 组件进 `features/**/widgets/`，不再往 `dashboard_shell.dart` 里堆代码。
- 每个 P 收尾必跑：`flutter analyze && flutter test && flutter build apk --debug`。

## 最终验收标准（整轮完成的定义）

**A. 双端口径比对（核心验收，用真实数据）**
1. 用真实 iOS 导出的 JSON（如仓内 `freegrid-import.json` 或现导一份）导入 Android：自由天数、净值、日均消费、被动收入、8 项自检结果与 iOS 端**逐项一致**。
2. 反向 round-trip：Android 导出 JSON → iOS 导入，同样逐项一致；Android 自导自回后数据无变化。
3. 同一文件连续导入两次：第二次统计为 0 新增、全部跳过（UUID 去重生效）；删除 JSON 里的 id 字段再导，内容指纹去重同样 0 新增。
4. 旧 Web 版格式（无 schema_version、单桶 total）文件可导入：replace 策略下 lockedAssets=0、cash=total。

**B. 导入预览与分类对齐**
5. 含非 canonical 分类的文件，预览列出对齐建议（按总额降序）、可手动改，commit 后 History 分类汇总按改后分类展示。
6. 资产策略三选一各自行为正确（整体替换 / 只加现金 / 完全不动两桶）。

**C. 导出与清空**
7. 导出 CSV 在 Excel/Numbers/腾讯文档打开：中文不乱码（BOM）、列与 iOS 导出文件一致。
8. 清空数据需二次确认；清空后 Dashboard/Assets/History 回到空态引导，重启仍为空。

**D. 预览与动画**
9. 记支出 Sheet 输入金额即出三杀预览，数值与「模拟一笔」及实际入账后的 Dashboard 一致（同口径）；记收入同理。
10. 模拟推演动画：支出可见逐格熄灭、收入可见放慢点亮；开启「减少动态效果」时为静态对照；动画期间零掉帧计数（沿用 P3 轮 SurfaceFlinger 图层统计法）。

**E. 常规工程门槛**
11. `flutter analyze` 无问题、`flutter test` 全绿（含 data_importer/data_io 新增单测）、`flutter build apk --debug` 与 `--release` 成功。
12. release APK `aapt dump permissions` 仍无 `android.permission.INTERNET`。
13. 每个 P 有模拟器截图存 `_local/`（命名 `freegrid-parity4-<p>-*.png`），HANDOFF.md「当前状态」同步更新。
