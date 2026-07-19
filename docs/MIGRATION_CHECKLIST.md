# Migration Checklist

## Engine

- [x] Port `FreedomMath.trackDays`
- [x] Port `dailyBurn`
- [x] Port `dailyPassive`
- [x] Port `passiveRatio`
- [x] Port `freedomDays`
- [x] Port `freedomDaysDisplay`
- [x] Port `gridState`
- [x] Port `freedomDaysHistory`
- [x] Cover floor rounding, `∞`, natural-day history, and dual-bucket grid tests

## Data

- [x] Define domain models
- [x] Decode iOS/Web snake_case backup JSON
- [x] Encode Android backup JSON with schema v1
- [x] Add local JSON store layer
- [x] Persist local state on Android
- [ ] Add SQLite persistence
- [ ] Add import preview and UUID/content dedup
- [ ] Add export/share flow

## UI

- [x] Replace Flutter counter demo with FreeGrid app shell
- [x] Add initial Silverline color theme
- [x] Dashboard shell aligned to current iOS Silverline first screen
- [x] Dashboard with persisted local data
- [x] Assets summary
- [x] Asset/cash edit sheets
- [x] Passive income add sheet
- [x] History: 全部/支出/收入筛选、支出分类汇总、逐笔撤销确认
- [x] History 月度汇总与月内分类明细
- [x] Settings: 从旧 Check Tab 升级为 iOS 1.2 的 Settings 信息架构，并保留 8 项财富自由自检入口
- [x] Add expense/income sheets wired from Dashboard buttons
- [x] Simulate decision sheet wired from Dashboard
- [x] History empty state
- [x] Assets empty-state 引导
- [x] Silverline 浅色 / Vault 深色动态主题与持久化
- [x] Dashboard 左右 / 居中 Hero 布局切换与持久化
- [x] 记账后 5 秒撤销、左滑撤销交易、删除被动收入确认
- [x] 记账日期选择、分类快捷选择与输入即时校验
- [x] 模拟决策 KILL 1/2/3 与前后网格对照

## Android Release

- [x] Debug APK builds locally
- [x] App runs on Android emulator
- [x] App icon
- [x] Android adaptive icon + Android 13 monochrome icon
- [x] Manifest privacy check: release APK 无网络权限
- [ ] Release signing config
- [ ] AAB build
