# PLAN · iOS 视觉对齐(第三轮)

> 2026-07-10 建立。背景:前两轮 parity 搬对了色板/数据契约/信息架构,但产品的视觉招牌走样。
> 本轮只修"脸"和"灵魂",不动数据层(FreedomMath / BackupCodec 已有测试兜底,不要碰)。
> 诊断结论:差距 80% 集中在 P1;P1 做完先上模拟器对照截图,再决定 P2/P3 力度。

## 差距诊断(已核对两端源码,非猜测)

| # | 问题 | iOS 现场 | Android 现场 |
|---|------|---------|-------------|
| P1 | Freedom Grid 是稀疏圆点不是密铺网格;当前格呼吸动画缺失 | `Item.swift:313` GridUnit 日 9pt/月 12pt/年 16pt,间距 2.5/3/3.5(格:距≈3.6:1),圆角 11%,列数自适应;`ContentView.swift:57` LifeGrid 当前格 2s 余弦呼吸(scale+双层 glow),注释原话"产品记忆点永远保留" | `dashboard_shell.dart:1059` `_LifeGrid`:写死 30 列、gap 5.0,Pixel 7 上实际 cell≈5dp(格:距=1:1),圆角 2(占比 40%);当前格静态 ink 色块+固定 boxShadow |
| P2 | 数字字感不统一 | 全部数字(hero/三联 stats/金额)SF Pro Rounded thin + monospacedDigit | 只有 hero 用 Geist Thin(`freegrid_hero_number.dart`),stats/金额全是 Roboto w200 |
| P3 | 暗色模式动效层缺失 | `ContentView.swift:146` MeteorLayer 流星层(TimelineView 余弦相位驱动) | 无,暗色全静态 |
| P4 | 细节杂项 | 顶栏 logo 是小圆点;sparkline skyDeep 1.2pt | 顶栏左右两个 44dp 大圆按钮过重;sparkline 用浅 sky、偏粗 |

## P1 重做 Freedom Grid(最高优先,单独一个对话做)

**输入**:`lib/features/dashboard/dashboard_shell.dart` 的 `_LifeGrid`(1059-1108)与 `_FreedomGridCard`(984 起);对照 `/Users/coni/Desktop/FreeGrid/FreeGrid/ContentView.swift:46-143`、`Item.swift:310-350`。

**改动**:

1. 新建 `lib/features/dashboard/widgets/life_grid.dart`,把 `_LifeGrid` 迁出重写(顺带开始拆 4479 行大文件,新组件一律进 `widgets/`)。
2. 尺寸参数照抄 iOS,挂到已有的 `GridUnit` 上(`freedom_math.dart:7` 已移植枚举,渲染层没用):
   - cellSize:day 9 / month 12 / year 16(dp)
   - spacing:day 2.5 / month 3 / year 3.5
   - 圆角 = cellSize × 0.11(当前格 × 0.17)
   - 列数不写死:`maxWidth ~/ (cellSize + spacing)` 自适应,格子保持固定尺寸、行数随内容涨
3. 当前格呼吸动画,照抄 iOS 的免状态方案:单个 `AnimationController`(2s repeat)或 `TimelineView` 等价物,余弦相位 `breath = 0.5 - 0.5*cos(phase*2π)`,驱动 scale 1.1→1.35(暗色 1.6)+ 双层 glow(参数见 `ContentView.swift:97-134`,亮/暗色各一套)。只有当前格一个元素动,不会有性能问题;`count` 最大 365,`Wrap` 可留可换,别引入新依赖。
4. 当前格颜色改 iOS 同款高亮色(亮色:蓝格 #3380C7 系 / 金格 #B89433 系;暗色:提亮),不再用 ink 黑点。

**验收**:
- 模拟器亮/暗色各截一张,与 `/Users/coni/Desktop/FreeGrid/app展示图/appstore-ready/1-自由天数.png` 并排对照:格子必须读作"密铺方格墙",93 天与 279 天两种数据量都要看;
- 当前格呼吸肉眼可见且不掉帧;
- `flutter analyze && flutter test && flutter build apk --debug` 全绿。

## P2 统一数字字体(可与 P1 同对话,改动小)

**输入**:`pubspec.yaml:62`(已内置 Geist Thin w100,family `GeistHero`)、`freegrid_theme.dart`、`dashboard_shell.dart` 中 `_StatCard`(1147)及各金额 Text。

**改动**:
1. 补 Geist Regular/Light 字重资产(assets/fonts/ 下,OFL 授权随附),family 改名 `Geist` 统一注册;
2. theme 里加一个 `numberStyle(size, weight)` helper(或 TextTheme 扩展),所有数字位(三联 stats、净值、金额、sparkline 端点数字)统一走 Geist + `FontFeature.tabularFigures()`;
3. 中文和正文不动,继续系统字体。

**验收**:Dashboard/Assets/History 三页截图里不再出现 Roboto 数字(和 hero 数字字形一致);analyze/test 全绿。

## P3 暗色流星层(便宜的记忆点,P1/P2 验收后再做)

**输入**:`ContentView.swift:146` MeteorLayer(4 颗流星、LinearGradient 拖尾、余弦相位)。
**改动**:`CustomPainter` + 单 controller 移植,仅暗色主题挂载,置于 Dashboard 背景层。
**验收**:暗色模式可见流星划过,亮色无此层,滚动列表不掉帧。

## P4 细节收尾(跟 P3 一批)

- 顶栏两个圆按钮从 44dp 圆圈降级为 iOS 同款视觉重量(小 logo 点 + 无边框 icon,对照 `1-自由天数.png` 顶部);
- sparkline stroke 改 `skyDeep`、1.2 宽;
- 每项改完对照 iOS 截图确认,不确定就并排贴图让用户裁决。

## 红线(沿用 HANDOFF)

- 不碰 `core/`(FreedomMath/BackupCodec/models/store),改渲染层不改口径;
- 不迁 iOS 私有分支的云同步/token/私有端点;
- 每步收尾必跑:`flutter analyze && flutter test && flutter build apk --debug`;
- 新组件写进 `lib/features/dashboard/widgets/`,不再往 dashboard_shell.dart 里加代码;只搬不重构,大文件整体拆分另开任务。

## 执行方式

一个对话做一个 P。每个 P 结束更新 HANDOFF.md「当前状态」+ 模拟器截图存 `_local/`,命名 `freegrid-parity3-<p>-<light|dark>.png`。
