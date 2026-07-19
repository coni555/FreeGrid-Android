# FreeGrid Android · HANDOFF

> 最后更新：2026-07-14。iOS 1.2 功能对标第四轮 P1-P5 与 13 项最终验收已全部完成。

## 当前状态

已完成基础环境与项目骨架：

- 安装 Flutter 3.44.5 / Dart 3.12.2。
- 安装 Android command line tools，并把 Flutter 的 Android SDK 指向 `/Users/coni/Library/Android/sdk`。
- 安装 Homebrew `openjdk@21`，并配置 Flutter 使用它，避开 JDK 26 与 Gradle 的兼容风险。
- Android licenses 已接受。
- 新建工程：`/Users/coni/Desktop/FreeGrid-Android`。
- 只生成 Android 平台，包名 `cn.conilab.freegrid`。
- 已建立最小 App 壳、主题、核心模型、`FreedomMath`、`BackupCodec` 和测试。
- 占位启动页已替换为 FreeGrid Dashboard shell。
- 2026-07-10 重新以 iOS 主仓 `freegrid-public` 的当前代码为准对照：Android 默认外观改为 iOS 同款冷白 Silverline；Dashboard 保留当前 iOS 的左右 Hero、12 周趋势、Freedom Grid、三联统计、收支操作与标准四 Tab 导航，移除了之前不对标的深色悬浮胶囊导航。
- Dashboard 已从写死 demo 改为读取本地 `BackupData` 快照：用 `shared_preferences` 保存 iOS 兼容 JSON；记支出会扣现金、记收入会加现金，Freedom Days / Grid / Today / 12 周趋势即时重算；“模拟一笔”只预览影响，不写数据。
- Assets 已继续向 iOS 当前 IA 靠齐：净值、双桶编辑、被动收入新增/编辑/删除、资产与现金调拨、净值说明均可用并本地持久化。
- History 已从占位页替换为可用页面：全部/支出/收入筛选、支出分类汇总、逐笔撤销确认，撤销会反向更新现金；右上角月度汇总已接入月度收支和分类明细。
- 旧 Check Tab 已更名为 Settings；Settings 内是 iOS 1.2 同结构的财富自由自检入口，8 项规则直接按当前资产、日均、被动收入和自由天数计算。
- 2026-07-10 完成第二轮 UI / 交互重做：Silverline 浅色与 Vault 深色不再写死，主题选择会持久化；Dashboard 顶栏主题与 Hero 布局按钮均可用，布局选择也会持久化。
- 底部导航重做为 Android 安全区内的浮动 Silverline dock，切 Tab 有触觉反馈；Android 返回键在非首页 Tab 会先回 Dashboard。
- Dashboard 新增记账后 5 秒撤销 Snackbar、空网格提示、完整 Today / Avg 对比文案；Hero 支持左右与居中两种布局。
- Assets 重新梳理为净值 Hero、资产/现金双桶、被动覆盖、调拨和解释层级；空资产有明确引导，被动收入删除增加二次确认，调拨完成有反馈。
- History 筛选器、分类 chip、金额层级已重做；逐笔撤销改为 Android 原生感的左滑确认；月度卡支持展开/收起分类明细。
- 记支出/收入 Sheet 重做为全宽底部面板：金额即时校验、分类快捷选择、可改日期、可选备注、键盘避让和禁用态保存均已接入。
- 模拟决策 Sheet 已补齐 KILL 1 净值 / KILL 2 日均 / KILL 3 自由天数传导，以及前后 Freedom Grid 对照；仍然只预览、不写账本。
- Android 应用名修正为 `FreeGrid`，并加入 FreeGrid F 网格自适应图标、圆形图标和 Android 13 monochrome 图标。
- Dashboard Hero 数字不再依赖 Android 默认 Roboto，也不使用手工 Canvas 轮廓：根据 iOS `DesignSystem.swift` 中“原始目标是 Geist 100”的注释，APK 内置 OFL 授权的 Geist Thin 100，只用于自由天数大数字；左右与居中 Hero 布局共用，使用 tabular figures 并保持离线。
- 2026-07-10 完成 iOS parity 第三轮 P1：旧 `_LifeGrid` 已从 `dashboard_shell.dart` 迁到 `features/dashboard/widgets/life_grid.dart`；日/月/年分别使用 9/12/16dp 固定方格与 2.5/3/3.5dp 间距，列数随可用宽度计算，当前格用独立 2 秒余弦动画实现亮暗不同峰值的双层呼吸 glow。`core/` 未改动。
- 2026-07-10 完成 iOS parity 第三轮 P2：Geist 字族补齐 Thin 100 / Light 300 / Regular 400，并由 `FreeGridThemeContext.numberStyle` 统一管理。Hero、趋势端点、Grid 数量、Dashboard stats、Today/Avg、Assets 净值/资金桶/被动金额、History 日期/净额/逐笔及月度金额、金额输入与模拟结果均改用 Geist + tabular figures；中文正文继续系统字体，`core/` 未改动。
- 2026-07-10 完成 iOS parity 第三轮 P3：Dashboard Hero 新增仅暗色显示的原生 Flutter 流星层，按 iOS 当前源码的 4 组宽度、位置、延迟、周期和渐隐参数实现；四颗流星共用单个 `AnimationController` 与 `CustomPainter`，动画不重建 Hero 内容。离开 Dashboard、切到浅色或系统要求减少动态效果时均停止/移除动画，`core/` 未改动。
- 2026-07-11 完成 iOS parity 第三轮 P4：Dashboard 顶栏从两个 32dp 可见圆框降级为 22dp 品牌靶心与 18dp 无边框布局图标，同时保留两侧 48dp Android 点击热区；Hero sparkline 独立到 `widgets/dashboard_sparkline.dart`，统一使用主题 `skyDeep`、1.2dp 圆角折线与 5dp 终点。顶栏也迁到 `widgets/dashboard_top_bar.dart`，`core/` 未改动。
- 2026-07-14 完成 iOS parity 第四轮 P1：新增纯逻辑 `core/data/data_io.dart`，CSV 与 iOS 对齐 UTF-8 BOM、表头、日期排序、RFC4180 转义和 0~2 位金额，JSON 直接复用 schema v1 `BackupCodec`；Assets 页新增紧凑 DATA 卡，CSV/JSON 通过 Android 系统分享面板导出。清空全部数据有 destructive 二次确认，持久化空 schema 后 Dashboard/Assets/History 回到空态且重启仍为空；同时修复了空账本因数学 `∞` 被误显示为“已财富自由”的渲染问题。新增 `share_plus`，release APK 继续零 INTERNET 权限。
- 2026-07-14 完成 iOS parity 第四轮 P2：`ExpenseCategory` 独立为 `core/domain/expense_category.dart`，手工记账和导入共用 iOS 同款 9 个 canonical 分类；新增纯逻辑 `core/data/data_importer.dart`，支持合法 UUID 精确去重、旧文件自然日内容指纹、分类归一及原标签留痕、schema v1 双桶/旧 Web 单桶识别，以及 replace / addToCash / skipAssets 三种策略。Assets DATA 卡新增系统 JSON 文件选择，导入审核 Sheet 先展示新增/重复统计，再处理非标准分类和资产策略，默认只导交易。Android `file_selector` 返回内存字节时 `XFile.readAsString()` 会按 code unit 产生中文乱码，因此入口固定改为原始字节显式 UTF-8 解码并加回归测试；分类归一后的旧文件再次导入会利用 `原分类·xxx` 留痕重建原始指纹，保证幂等。
- 2026-07-14 完成 iOS parity 第四轮 P3：新增 `widgets/bookkeeping_impact_preview.dart`，`BookkeepingImpact` 统一复用 `FreedomMath.dailyBurn/freedomDays` 计算下一步净值、日均与自由天数；记支出金额有效时内联显示 KILL 1 净值 / KILL 2 日均 / KILL 3 自由天数，记收入显示 GAIN 1 净值 / GAIN 2 自由天数，无效金额不挂载预览。独立“模拟一笔”也改读同一结果模型，消除两套公式与显示口径漂移；`core/` 未改动。
- 2026-07-14 完成 iOS parity 第四轮 P4：新增 `widgets/simulation_grid_demo.dart`，模拟决策从静态双网格升级为单 `AnimationController` + 单 `CustomPainter` 的三态推演（演示/推演中/重播）；支出按末格向前级联熄灭，收入按新增顺序点亮且使用更慢的 0.72 秒单格 envelope，级联 span 分别 cap 1.6/3 秒。当前 Grid 单位在整段推演中锁定，避免跨日/月阈值时格数语义跳变；系统“移除动画”时不挂载 painter 和播放按钮，降级为静态前后对照。`core/` 未改动。
- 2026-07-14 完成 iOS parity 第四轮 P5：Settings 的平铺版本/本地隐私弹窗改为单一「关于」push 子页；Android MethodChannel 读取真实版本 `1.0.0 (1)`，隐私政策通过系统浏览器打开与 iOS 相同的公开 `PRIVACY.md`。页面明确“本机存储 / 离线可用 / 无需账号”，不加入 ICP 与商店评价；隐私行同时暴露 TalkBack button + tap action。
- 第四轮最终跨端审计发现并修复两处旧验收未覆盖的问题：显式 `first_record_date=2024-09-08` 曾被更早的收入日期 `2024-09-01` 覆盖，导致 Android 多算 7 个 track day；现在显式起算日优先、旧文件缺字段才从交易推断，补录更早日期仍会前移。Dashboard 原先 `extendBody=true` 使“模拟一笔”可见区域落进底栏 History 点击层；现在 body 截止在浮动导航上方，Pixel 7 验证两者点击 bounds 不再重叠。
- 2026-07-14 修复 History 支出分类横向筛选栏的 8px 底部溢出：分类栏高度从 62 调整为 72，chip 内容按最小高度布局；红色 `BOTTOM OVERFLOWED` 仅会出现在 debug，但本次同时消除了正式版会被静默裁切的真实布局问题，并补 Pixel 7 尺寸回归测试。

`flutter doctor -v` 当前 Android toolchain 通过。CocoaPods 未安装提示只影响 iOS/macOS，本工程暂不处理。

## 已验证

```bash
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

结果：

- Android toolchain 为通过状态。
- `flutter analyze` 无问题。
- `flutter test` 全部通过。
- debug APK 构建成功：`build/app/outputs/flutter-apk/app-debug.apk`。
- Android 模拟器已创建并跑通过：`FreeGrid_Pixel_7_API_36`。
- 已在模拟器 `emulator-5554` 上安装并启动 `cn.conilab.freegrid`，截图见 `_local/freegrid-android-emulator.png`。
- Dashboard shell 已安装到模拟器验证，截图见 `_local/freegrid-dashboard-shell.png`。
- 最新 Silverline Dashboard 已安装到模拟器验证，截图见 `_local/freegrid-latest-dashboard-android.png`。
- 已在模拟器实际保存一笔 10 元支出，Freedom Days 从 93 变 92，Grid 从 93 变 92；强停重启后仍为 92，确认本地持久化生效。截图见 `_local/freegrid-after-expense-save.png`、`_local/freegrid-after-restart-persisted.png`。
- Assets tab 已在模拟器打开验证，截图见 `_local/freegrid-assets-tab.png`；被动收入添加面板截图见 `_local/freegrid-passive-income-sheet.png`。
- 2026-07-10 新版已在模拟器验证：Dashboard `_local/freegrid-ios-parity-dashboard.png`、Assets `_local/freegrid-ios-parity-assets-stable.png`、History `_local/freegrid-ios-parity-history-stable.png`、Settings `_local/freegrid-ios-parity-settings-stable.png`。
- 第二轮重做已在 `FreeGrid_Pixel_7_API_36` 实机模拟器验证：浅色 Dashboard `_local/freegrid-redesign-dashboard-light.png`、Assets `_local/freegrid-redesign-assets-light.png`、History `_local/freegrid-redesign-history-light.png`、Settings `_local/freegrid-redesign-settings-light.png`。
- 深色 Dashboard 与主题持久化已验证，截图 `_local/freegrid-redesign-final-dashboard.png`；Hero 布局切换后强停重启仍保留。
- Geist Hero 数字已在深色主题的左右、居中两种布局中安装验证，截图 `_local/freegrid-geist-hero-final-top.png`、`_local/freegrid-geist-hero-final-centered.png`；两种布局均无溢出或错位。字体 A/B 过程截图为 `_local/freegrid-font-ab.png`，最终未保留 Nunito 资产。
- Parity3 P1 Freedom Grid 已用 Pixel 7 API 36 验证：暗色 93 天 `_local/freegrid-parity3-p1-dark.png`，浅色 279 天 `_local/freegrid-parity3-p1-light.png`，iOS/Android 并排图 `_local/freegrid-parity3-p1-ios-android.png`；呼吸动画录屏 `_local/freegrid-parity3-p1-breath.mp4`，逐帧拼图 `_local/freegrid-parity3-p1-breath-contact.png`。新增 3 项 widget 测试覆盖自适应换行、三档尺寸和暗色 1.6 峰值。
- Parity3 P2 数字字体已用 Pixel 7 API 36 浅色主题验证：Dashboard `_local/freegrid-parity3-p2-dashboard-light.png`、Assets `_local/freegrid-parity3-p2-assets-light.png`、History `_local/freegrid-parity3-p2-history-light.png`；大额 `¥19,900`、资金桶、三联 stats、日期和负金额均无溢出或字体回退。新增主题测试锁定 `Geist` 与 `tnum` 特性。
- Parity3 P3 流星层已用 Pixel 7 API 36 验证：浅色无流星 `_local/freegrid-parity3-p3-light.png`，暗色流星 `_local/freegrid-parity3-p3-dark.png`，10 秒运动录屏 `_local/freegrid-parity3-p3-dark.mp4`，逐帧拼图 `_local/freegrid-parity3-p3-dark-contact.png`。新增 3 项 widget 测试，锁定浅色不挂载、暗色仅挂载单层且固定 4 颗、非活动 Dashboard 不挂载。滚动期间的 SurfaceFlinger 图层统计已保存到 `_local/freegrid-parity3-p3-framestats.txt`：Flutter SurfaceView 共 1668 帧，`droppedFrames = 0`、`jankyFrames = 0`；该无界面模拟器的软件渲染平均帧率约 20 FPS，因此只以图层零掉帧/零卡顿计数作为本轮回归证据，不外推为真机性能结论。
- Parity3 P4 细节收尾已用 Pixel 7 API 36 验证：浅色 `_local/freegrid-parity3-p4-light.png`、暗色 `_local/freegrid-parity3-p4-dark.png`、居中 Hero `_local/freegrid-parity3-p4-light-vertical.png`、iOS/Android 并排 `_local/freegrid-parity3-p4-ios-android.png`。模拟器点击两侧控件后主题与 Hero 布局均正常切换；新增 2 项 widget 测试锁定 22dp/18dp 可见尺寸、48dp 点击热区，以及 sparkline 的主题颜色、1.2dp 线宽和 5dp 终点。
- Parity4 P1 已用 Pixel 7 API 36 验证：数据卡 `_local/freegrid-parity4-p1-data-card.png`、CSV 分享 `_local/freegrid-parity4-p1-share-sheet.png`、JSON 分享 `_local/freegrid-parity4-p1-share-json.png`、清空确认 `_local/freegrid-parity4-p1-clear-confirm.png`、重启空态 `_local/freegrid-parity4-p1-cleared-restart.png`。从 App 缓存实际拉出的 `_local/freegrid-parity4-p1-export.csv` 前三字节为 `EF BB BF`，JSON 保留 schema v1 双桶；全量 26 项测试通过，debug/release APK 构建成功，release 权限记录 `_local/freegrid-parity4-p1-release-permissions.txt` 不含 INTERNET。
- Parity4 P2 已用 Pixel 7 API 36 和仓内真实 iOS `freegrid-import.json` 验证：DATA 导入入口 `_local/freegrid-parity4-p2-data-card.png`、文件选择器 `_local/freegrid-parity4-p2-file-picker.png`、真实预览 `_local/freegrid-parity4-p2-review-top.png`、导入后 Dashboard `_local/freegrid-parity4-p2-imported-dashboard.png`、History `_local/freegrid-parity4-p2-imported-history.png`、强停重启 `_local/freegrid-parity4-p2-restart.png`、二次导入 `_local/freegrid-parity4-p2-second-import.png`。首次完整保留 1883 支出 + 20 收入并按 replace 还原资产 ¥3500 / 现金 ¥749.7；二次导入及删除全部 id 后导入均为 0 新增、1903 项跳过。Android 实际回导文件 `_local/freegrid-parity4-p2-android-roundtrip.json` 保留原记录数、双桶、起算日和 9 个 canonical 分类，摘要见 `_local/freegrid-parity4-p2-roundtrip-summary.json`；全量 44 项测试通过，`flutter analyze` 无问题，debug APK 构建成功。
- Parity4 P3 已用 Pixel 7 API 36 和 P2 导入的真实 iOS 数据验证：支出 Sheet 输入 ¥100 得到净值 `¥4,249.7 → ¥4,149.7`、日均 `¥69.5 → ¥69.67`、自由天数 `61 → 59（−2 天）`，截图 `_local/freegrid-parity4-p3-expense-preview.png`；收入为净值 `¥4,249.7 → ¥4,349.7`、自由天数 `61 → 62（+1 天）`，截图 `_local/freegrid-parity4-p3-income-preview.png`；“模拟一笔”的同额支出 XML 数值逐项相同，截图 `_local/freegrid-parity4-p3-simulate-parity.png`。新增 5 项计算/组件测试，全量 49 项测试通过，`flutter analyze` 无问题，debug APK 构建并覆盖安装成功。
- Parity4 P4 已用 Pixel 7 API 36 验证：¥1000 支出把 `61 → 45 天` 转为末端 16 格级联熄灭，静止截图 `_local/freegrid-parity4-p4-expense-idle.png`、录屏 `_local/freegrid-parity4-p4-expense.mp4`、逐帧拼图 `_local/freegrid-parity4-p4-expense-contact.png`；同额收入把 `61 → 75 天` 转为 14 格顺向慢速点亮，录屏 `_local/freegrid-parity4-p4-income.mp4`、逐帧拼图 `_local/freegrid-parity4-p4-income-contact.png`。系统动画缩放设为 0 后实机回退静态双网格，截图 `_local/freegrid-parity4-p4-reduce-motion.png`，验证后已恢复缩放为 1。SurfaceFlinger 图层统计 `_local/freegrid-parity4-p4-framestats.txt` / `...-income-framestats.txt` 中 Flutter SurfaceView 分别 `47/38` 帧、`droppedFrames=0`、`jankyFrames=0`；SwiftShader 软件模拟器叠加录屏仅约 7.5/5.3 FPS，因此只把图层零掉帧/零 jank 作为回归证据，不外推真机流畅度。新增 6 项时间/方向/降级测试，全量 55 项测试通过，`flutter analyze` 无问题，debug APK 构建并覆盖安装成功。
- Parity4 P5 已用最新 debug APK 在 Pixel 7 API 36 验证：Settings 入口 `_local/freegrid-parity4-p5-settings-final.png`、关于页 `_local/freegrid-parity4-p5-about-final.png`、系统 Chrome 外跳 `_local/freegrid-parity4-p5-privacy-external-final.png`。UI Automator 树 `_local/freegrid-parity4-p5-about-final.xml` 显示版本语义为 `版本，1.0.0 (1)`，隐私政策语义为可点击按钮；未出现 ICP/商店评价。
- Parity4 最终 A1/A2 双端口径不是只做 schema 推断：`_local/ios_roundtrip_verifier.swift` 直接与 iOS 主仓当前 `Item.swift + ContentView.swift + DesignSystem.swift + Platform.swift` 一起编译，实际调用 iOS 生产 `DataIO.previewJSON/commitImport/exportJSON` 导入 Android 实际导出 `_local/freegrid-parity4-p2-android-roundtrip.json`。iOS 首次导入 1883 支出 + 20 收入，双桶 ¥3500 / ¥749.7；iOS 再导出仍为 schema v1 与相同记录数，第二次导入 0 新增、1903 跳过，结果见 `_local/freegrid-parity4-final-ios-roundtrip.json`。
- 同一真实 JSON 在 2026-07-14 的 Android/iOS 生产算法逐项比较全部通过：净值 `4249.7`、track days `675`、日均 `70.2433629629…`、被动日均 `0`、自由天数 `60.4996660288…`，8 项自检结果均为 `[✓, ✓, ✓, ×, ×, ×, ×, ×]`（3/8）。机器可读结果 `_local/freegrid-parity4-final-android-real-data.json` / `...-ios-roundtrip.json`，断言记录 `_local/freegrid-parity4-final-cross-platform-comparison.txt`；Pixel 7 UI 截图 `_local/freegrid-parity4-final-cross-platform-dashboard.png` 显示 `60 / 70.2 / 675`。
- Parity4 最终 C7 已把 Android 实际 CSV 在 macOS Numbers 真正打开，不只检查 BOM：Numbers 识别为 2 行 × 5 列，中文表头 `日期 / 类型 / 类别/来源 / 金额 / 备注` 与中文记录均正常，截图 `_local/freegrid-parity4-final-csv-numbers.png`；原 CSV `_local/freegrid-parity4-p1-export.csv` 首三字节仍为 `EF BB BF`。
- Parity4 最终 D9 用恢复前备份的真实账本完成三点闭环。¥100 支出在记账 Sheet 与模拟 Sheet 都是净值 `4249.7→4149.7`、日均 `70.2→70.39`、自由天数 `60→58`，实际保存后 Dashboard 为 `58 / 70.4 / 675`；¥100 收入两处预览均为净值 `4249.7→4349.7`、自由天数 `60→61`，实际保存后 Dashboard 为 `61 / 70.2 / 675`。截图以 `_local/freegrid-parity4-final-expense-*` / `...income-*` / `...simulate-*` 命名；两次验收后均以私有偏好文件字节级恢复，最终设备回到 `60 / 70.2 / 675`。
- Parity4 最终 13 项验收均有当前证据：A3 UUID/no-id 二次导入均 0 新增（P2 截图 + `data_importer_test`）；A4 旧 Web 单桶与 B6 三资产策略由对应纯逻辑/widget 测试覆盖。B5 另用真实文件把 `food / ¥12,345` 在审核页手动改为“晚餐”后 commit，History 支出分类汇总显示 `晚餐 ¥16,586` 且首条记录保留 `原分类·food`，截图 `_local/freegrid-parity4-final-category-review-edited.png` / `...category-history-summary.png`；验收后账本字节级恢复。C8 清空确认/三页空态/重启、D10 双向动画/减少动态/零 dropped+jank 均有 P1/P4 运行证据；P1-P5 截图均在 `_local/`。
- 最终工程闸门重新从当前源码执行：`flutter analyze` 无问题，61 项测试全绿，debug/release APK 均成功（release 51.9MB）；`aapt dump permissions` 仅有包内 `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`，无 `android.permission.INTERNET`。日志 `_local/freegrid-parity4-final-{analyze,tests,debug-build,release-build,release-permissions}.txt`，SHA-256 见 `_local/freegrid-parity4-final-apk-sha256.txt`。
- 新版记支出 Sheet 已验证金额即时启用、分类、日期选择和备注布局，截图 `_local/freegrid-redesign-expense-sheet.png`、`_local/freegrid-redesign-expense-filled.png`。
- 新版模拟决策 Sheet 已验证：¥100 支出预览得到净值 `¥6,631 → ¥6,531`、日均 `¥71.3 → ¥71.5`、自由天数 `93 → 91`，截图 `_local/freegrid-redesign-simulate.png`。
- `flutter build apk --release` 成功：`build/app/outputs/flutter-apk/app-release.apk`（50.3 MB）。release APK 清单已用 `aapt dump permissions` 核验，不含 `android.permission.INTERNET`；debug/profile 的 INTERNET 仅供 Flutter 调试工具使用。
- 本轮第一次安装时 `flutter install` 误先卸载旧模拟器包再寻找不存在的 release APK，因此旧的模拟器演示数据被重置；工程源码和本地数据契约未受影响，随后已改用 `adb install -r` 覆盖安装。

后续每次改核心代码需要跑：

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## 分发决策（2026-07-12 已确认）

- **APK 直发，不上国内应用商店、不走商店合规（软著/逐商店审核）**。理由：商店上架的成本是持续性的（每次更新重审 + targetSdk 年度合规），与"没有心力维护安卓"不匹配；本 app 零 INTERNET 纯本地，商店合规收益接近零；小白用户已由 PWA 网页版接住。
- 分发渠道：FreeGrid-Freedom 公开仓 GitHub Releases 挂 APK + 校验和，进双仓库统一下载表交叉链接；下载页附国产 ROM"未知来源/风险应用"警告的安装引导两行。
- 此决策不可逆性低：将来有量再补软著/备案上商店即可。iOS 侧已有 ICP 备案号，届时 App 备案加 Android 平台可能是增量操作（未核实，用时现查）。

## 下一步建议

1. 第四轮功能 parity 已完成，不再继续改 R4；下一阶段优先用真实小屏 Android、字体放大和 TalkBack 做无障碍 / 响应式验收（当前完成 Pixel 7 API 36 + 关键 TalkBack 语义树）。
2. 公开发 APK 前生成正式 release keystore 并做多处备份；当前 release 构建与零 INTERNET 已验收，但签名连续性仍是分发阶段任务。
3. 后续若要更强查询和历史筛选，再把当前本地 JSON store 迁到 Drift + SQLite。

## 关键红线

- 不能把 iOS 私人 `main` 分支里的云同步、token、私有端点迁进 Android。
- 不要把 Web/PWA 当最终安卓版；本项目目标是真 Flutter 原生。
- 不要先大规模画 UI 而跳过数据契约和算法测试。
- **release 签名 keystore 一次定终身**：生成后必须多处备份、绝不进 git；换签名用户无法覆盖升级只能卸载重装，而数据纯本地、卸载即全丢，keystore 连续性是数据安全问题。
- **公开发 APK 前必须先落地 P1 的 JSON 导出**：数据纯本地，没有备份出口就公开分发，第一个换手机的用户就是数据事故。
