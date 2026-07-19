# FreeGrid Android

Flutter 真原生安卓版工程。目标不是把 iOS 的 SwiftUI 直接转换过来，而是复用 FreeGrid 已经验证过的产品规则、算法口径和 JSON 备份格式，在 Android 上重写一版原生体验。

## 当前状态

- Flutter SDK: 3.44.5
- Dart: 3.12.2
- Android SDK: `/Users/coni/Library/Android/sdk`
- JDK: Homebrew `openjdk@21`
- 包名: `cn.conilab.freegrid`
- 平台: Android only

已建立：

- 最小 Flutter App 壳
- FreeGrid 核心模型
- `FreedomMath` 纯 Dart 迁移
- iOS/Web 兼容的 `BackupJSON` codec
- 核心算法与备份格式测试
- 项目接力与迁移文档

## 常用命令

```bash
cd /Users/coni/Desktop/FreeGrid-Android
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

如果新终端找不到 Java，先加：

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="/opt/homebrew/opt/openjdk@21/bin:$HOME/Library/Android/sdk/platform-tools:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
```

## 文档入口

- [AGENTS.md](AGENTS.md): 项目协作规则
- [HANDOFF.md](HANDOFF.md): 当前进度和下一步
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): 工程架构
- [docs/DATA_CONTRACT.md](docs/DATA_CONTRACT.md): iOS/Web/Android 数据契约
- [docs/ANDROID_ENV.md](docs/ANDROID_ENV.md): 本机安卓环境
- [docs/MIGRATION_CHECKLIST.md](docs/MIGRATION_CHECKLIST.md): 从 iOS/Web 迁移到 Flutter 的验收清单
