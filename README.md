# FreeGrid Android

> **自由天数记账**——把每一笔收支翻译成「±N 天自由」。纯本地、零联网、无账号。

FreeGrid 的 **Flutter 真原生安卓版**。不是 iOS SwiftUI 的机器翻译，而是复用 FreeGrid 已验证的产品规则、算法口径和 JSON 备份格式，在 Android 上重写的原生体验。

## 📥 下载

**[⬇️ FreeGrid-Android-1.0.0.apk](https://github.com/coni555/FreeGrid-Freedom/releases/tag/android-v1.0.0)**（发布在主仓 FreeGrid-Freedom 的 Releases，附 SHA-256 校验和与安装说明）

## ✨ 与 iOS 版同源对标

- **自由天数**：净值 ÷（日均消费 − 日均被动收入），首页一个大数字
- **Freedom Grid**：自由天数点亮成格子，日/月/年三档
- **模拟决策**：下单前预演这笔支出对自由天数的冲击
- **资产双桶 / 被动收入 / 历史账本 / 财富自由自检**
- **数据互通**：备份 JSON 与 [iOS / macOS 版](https://github.com/coni555/FreeGrid-Freedom)、[网页 / Windows 版](https://github.com/coni555/FreeGrid-Web) 完全互通，CSV 可导出

## 🔒 隐私

APK **不含 `android.permission.INTERNET`**——不是"承诺不联网"，是系统层面**没有联网能力**。数据只存在你的手机里，本仓库源码可自行验证与构建。

## 🌍 其他平台

| 平台 | 仓库 |
|---|---|
| 🍎 iOS / macOS（SwiftUI 原生，主仓） | [FreeGrid-Freedom](https://github.com/coni555/FreeGrid-Freedom) |
| 🌐 网页 / 🪟 Windows（Svelte + Tauri） | [FreeGrid-Web](https://github.com/coni555/FreeGrid-Web) |
| 🤖 Android（Flutter，本仓） | 就是这里 |

## 🛠 开发

```bash
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

- Flutter 3.44 / Dart 3.12，包名 `cn.conilab.freegrid`
- release 构建强制正式 keystore 签名（`android/key.properties`，不入库）；缺失时构建直接失败，绝不回退 debug 签名
- 文档：[HANDOFF.md](HANDOFF.md)（进度）· [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)（架构）· [docs/DATA_CONTRACT.md](docs/DATA_CONTRACT.md)（跨端数据契约）· [docs/MIGRATION_CHECKLIST.md](docs/MIGRATION_CHECKLIST.md)（迁移验收清单）

## 许可

**MIT License + [Commons Clause](https://commonsclause.com/)**——与主仓一致：源码公开，允许自由使用、修改、学习、非商业分发，但**不得出售本软件**。
