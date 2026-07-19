# FreeGrid Android · Agent Rules

## 先读现场

每次进项目先读：

1. `AGENTS.md`
2. `HANDOFF.md`
3. 本次要改的相关源码文件

## 项目边界

- 这是 Flutter 真原生安卓版，不是 PWA/TWA/WebView 壳。
- iOS 主仓在 `/Users/coni/Desktop/FreeGrid`，Web/PWA 在 `/Users/coni/Desktop/FreeGrid-Web`。本工程只在需要对齐算法、数据格式和视觉语言时读取它们，不直接改它们。
- 包名固定为 `cn.conilab.freegrid`。
- 隐私承诺默认与公开版一致：无账号、无云、无埋点，财务数据只存在本机。

## 技术规则

- 核心算法必须在 `lib/core/domain/freedom_math.dart` 里先有测试再改。
- JSON 备份格式必须兼容 iOS 的 `BackupJSON`：`schema_version`、`locked_assets`、`cash`、`passive_sources`、`first_record_date` 等 snake_case 字段不能随意改名。
- 日期口径统一走自然日：不要裸用 `DateTime.difference` 算用户账本天数。
- UI 先做 Android 体验，再保留 Silverline 视觉语言；不要机械照搬 iOS 控件。
- 不引入网络权限，除非用户明确决定要做云同步或更新检查。

## 验收

每次核心改动至少跑：

```bash
flutter analyze
flutter test
```

涉及 Android 壳或依赖时再跑：

```bash
flutter build apk --debug
```
