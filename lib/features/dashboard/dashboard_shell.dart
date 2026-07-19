import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/freegrid_theme.dart';
import '../../app/widgets/freegrid_hero_number.dart';
import '../../core/data/backup_codec.dart';
import '../../core/data/data_importer.dart';
import '../../core/data/data_io.dart';
import '../../core/data/local_freegrid_store.dart';
import '../../core/domain/expense_category.dart';
import '../../core/domain/freedom_math.dart';
import '../../core/domain/models.dart';
import 'first_record_date_resolver.dart';
import 'widgets/about_page.dart';
import 'widgets/bookkeeping_impact_preview.dart';
import 'widgets/dashboard_sparkline.dart';
import 'widgets/dashboard_top_bar.dart';
import 'widgets/data_management_card.dart';
import 'widgets/freedom_hero_presentation.dart';
import 'widgets/history_category_strip.dart';
import 'widgets/import_review_sheet.dart';
import 'widgets/life_grid.dart';
import 'widgets/meteor_layer.dart';
import 'widgets/simulation_grid_demo.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    required this.isDarkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  static const extendsBehindNavigation = false;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  static const _heroLayoutKey = 'freegrid.dashboard.hero.vertical';

  final _store = LocalFreeGridStore();
  final _preferences = SharedPreferencesAsync();

  var _index = 0;
  var _heroVertical = false;
  BackupData? _data;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAppearance();
  }

  Future<void> _loadAppearance() async {
    final vertical = await _preferences.getBool(_heroLayoutKey) ?? false;
    if (!mounted) return;
    setState(() => _heroVertical = vertical);
  }

  Future<void> _toggleHeroLayout() async {
    final next = !_heroVertical;
    setState(() => _heroVertical = next);
    await _preferences.setBool(_heroLayoutKey, next);
  }

  Future<void> _loadData() async {
    final data = await _store.load();
    if (!mounted) return;
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final pages = [
      data == null
          ? const _LoadingPage()
          : _DashboardView(
              data: data,
              onAddExpense: _addExpense,
              onAddIncome: _addIncome,
              isDarkMode: widget.isDarkMode,
              isActive: _index == 0,
              heroVertical: _heroVertical,
              onToggleTheme: () => widget.onDarkModeChanged(!widget.isDarkMode),
              onToggleHero: _toggleHeroLayout,
            ),
      data == null
          ? const _LoadingPage()
          : _AssetsView(
              data: data,
              onUpdateAssets: _updateAssets,
              onAddPassiveSource: _addPassiveSource,
              onUpdatePassiveSource: _updatePassiveSource,
              onDeletePassiveSource: _deletePassiveSource,
              onTransfer: _transfer,
              onImportJson: _importJson,
              onExportCsv: () => _shareExport(DataExportFormat.csv),
              onExportJson: () => _shareExport(DataExportFormat.json),
              onClearData: _clearAllData,
            ),
      data == null
          ? const _LoadingPage()
          : _HistoryView(data: data, onDelete: _deleteTransaction),
      data == null
          ? const _LoadingPage()
          : _SettingsView(
              data: data,
              isDarkMode: widget.isDarkMode,
              onDarkModeChanged: widget.onDarkModeChanged,
            ),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          HapticFeedback.selectionClick();
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        extendBody: DashboardShell.extendsBehindNavigation,
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: _BottomTabs(
            selectedIndex: _index,
            onSelected: (value) {
              if (_index == value) return;
              HapticFeedback.selectionClick();
              setState(() => _index = value);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _persist(BackupData next) async {
    setState(() => _data = next);
    await _store.save(next);
  }

  Future<void> _shareExport(DataExportFormat format) async {
    final data = _data;
    if (data == null) return;
    final bytes = switch (format) {
      DataExportFormat.csv => DataIO.exportCsv(data),
      DataExportFormat.json => DataIO.exportJson(data),
    };
    final fileName = DataIO.fileName(format);

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: format == DataExportFormat.csv
              ? '导出 FreeGrid 记账'
              : '备份 FreeGrid 数据',
          files: [XFile.fromData(bytes, mimeType: DataIO.mimeType(format))],
          fileNameOverrides: [fileName],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('无法打开系统分享，请稍后再试')));
    }
  }

  Future<void> _importJson() async {
    final current = _data;
    if (current == null) return;

    try {
      const jsonGroup = XTypeGroup(
        label: 'FreeGrid JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
      );
      final file = await openFile(
        acceptedTypeGroups: const [jsonGroup],
        confirmButtonText: '选择备份',
      );
      if (file == null) return;

      final preview = DataImporter.previewJsonBytes(
        bytes: await file.readAsBytes(),
        current: current,
      );
      if (!mounted) return;

      final decision = await showModalBottomSheet<ImportReviewDecision>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ImportReviewSheet(preview: preview),
      );
      if (decision == null || !mounted) return;

      final result = DataImporter.commitImport(
        preview: preview,
        current: current,
        strategy: decision.strategy,
        categoryMap: decision.categoryMap,
      );
      await _persist(result.data);
      if (!mounted) return;

      final transactionCount = result.expensesAdded + result.incomesAdded;
      final passiveLabel = result.passiveSourcesAdded > 0
          ? ' · ${result.passiveSourcesAdded} 个被动源'
          : '';
      final skippedLabel = result.duplicatesSkipped > 0
          ? ' · 跳过 ${result.duplicatesSkipped} 项重复'
          : '';
      final assetsLabel = switch (decision.strategy) {
        AssetsImportStrategy.replace => ' · 净值已替换',
        AssetsImportStrategy.addToCash => ' · 已加到现金',
        AssetsImportStrategy.skipAssets => '',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
            content: Text(
              '✓ 导入完成 $transactionCount 笔记录$passiveLabel$assetsLabel$skippedLabel',
            ),
          ),
        );
    } on FormatException {
      _showImportError('这不是有效的 FreeGrid JSON 备份');
    } catch (_) {
      _showImportError('无法读取这个文件，请确认文件完整后重试');
    }
  }

  void _showImportError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
          content: Text(message),
        ),
      );
  }

  Future<void> _clearAllData() {
    return _persist(const BackupData(schemaVersion: 1));
  }

  Future<void> _addExpense(_ExpenseDraft draft) async {
    final current = _data ?? LocalFreeGridStore.seedData(now: DateTime.now());
    final now = DateTime.now();
    final assets = current.assets ?? const UserAssets();
    final firstRecordDate = _firstRecordDate(current, draft.date);
    final nextCash = assets.cash - draft.amount;
    final nextAssets = UserAssets(
      total: assets.lockedAssets + nextCash,
      lockedAssets: assets.lockedAssets,
      cash: nextCash,
      updatedAt: now,
      firstRecordDate: firstRecordDate,
    );
    final category = ExpenseCategory.suggest(draft.category).canonical;
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: nextAssets,
      expenses: [
        ...current.expenses,
        Expense(
          id: LocalFreeGridStore.nextId('expense', now),
          amount: draft.amount,
          category: category,
          note: draft.note,
          date: draft.date,
          createdAt: now.toUtc(),
        ),
      ],
      incomes: current.incomes,
      devices: current.devices,
      passiveSources: current.passiveSources,
      firstRecordDate: firstRecordDate,
    );

    await _persist(next);
    if (!mounted) return;
    _showUndo(_Transaction.expense(next.expenses.last));
  }

  Future<void> _addIncome(_IncomeDraft draft) async {
    final current = _data ?? LocalFreeGridStore.seedData(now: DateTime.now());
    final now = DateTime.now();
    final assets = current.assets ?? const UserAssets();
    final firstRecordDate = _firstRecordDate(current, draft.date);
    final nextCash = assets.cash + draft.amount;
    final nextAssets = UserAssets(
      total: assets.lockedAssets + nextCash,
      lockedAssets: assets.lockedAssets,
      cash: nextCash,
      updatedAt: now,
      firstRecordDate: firstRecordDate,
    );
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: nextAssets,
      expenses: current.expenses,
      incomes: [
        ...current.incomes,
        Income(
          id: LocalFreeGridStore.nextId('income', now),
          amount: draft.amount,
          source: draft.source,
          note: draft.note,
          date: draft.date,
          createdAt: now.toUtc(),
        ),
      ],
      devices: current.devices,
      passiveSources: current.passiveSources,
      firstRecordDate: firstRecordDate,
    );

    await _persist(next);
    if (!mounted) return;
    _showUndo(_Transaction.income(next.incomes.last));
  }

  Future<void> _updateAssets(_AssetDraft draft) async {
    final current = _data ?? LocalFreeGridStore.seedData(now: DateTime.now());
    final now = DateTime.now();
    final firstRecordDate = _firstRecordDate(current, now);
    final nextAssets = UserAssets(
      total: draft.lockedAssets + draft.cash,
      lockedAssets: draft.lockedAssets,
      cash: draft.cash,
      updatedAt: now,
      firstRecordDate: firstRecordDate,
    );
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: nextAssets,
      expenses: current.expenses,
      incomes: current.incomes,
      devices: current.devices,
      passiveSources: current.passiveSources,
      firstRecordDate: firstRecordDate,
    );

    await _persist(next);
  }

  Future<void> _addPassiveSource(_PassiveDraft draft) async {
    final current = _data ?? LocalFreeGridStore.seedData(now: DateTime.now());
    final now = DateTime.now();
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: current.assets,
      expenses: current.expenses,
      incomes: current.incomes,
      devices: current.devices,
      passiveSources: [
        ...current.passiveSources,
        PassiveSource(
          id: LocalFreeGridStore.nextId('passive', now),
          name: draft.name,
          monthlyAmount: draft.monthlyAmount,
          createdAt: now.toUtc(),
        ),
      ],
      firstRecordDate: _firstRecordDate(current, now),
    );

    await _persist(next);
  }

  Future<void> _updatePassiveSource(_PassiveEdit draft) async {
    final current = _data;
    if (current == null) return;
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: current.assets,
      expenses: current.expenses,
      incomes: current.incomes,
      devices: current.devices,
      passiveSources: current.passiveSources
          .map(
            (source) => source.id == draft.id
                ? PassiveSource(
                    id: source.id,
                    name: draft.name,
                    monthlyAmount: draft.monthlyAmount,
                    createdAt: source.createdAt,
                  )
                : source,
          )
          .toList(),
      firstRecordDate: current.firstRecordDate,
    );
    await _persist(next);
  }

  Future<void> _deletePassiveSource(String? id) async {
    final current = _data;
    if (current == null || id == null) return;
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: current.assets,
      expenses: current.expenses,
      incomes: current.incomes,
      devices: current.devices,
      passiveSources: current.passiveSources
          .where((source) => source.id != id)
          .toList(),
      firstRecordDate: current.firstRecordDate,
    );
    await _persist(next);
  }

  Future<void> _transfer(_TransferDraft draft) async {
    final current = _data;
    if (current == null) return;
    final assets = current.assets ?? const UserAssets();
    final amount = draft.amount;
    if (amount <= 0 ||
        (draft.cashToAssets && amount > assets.cash) ||
        (!draft.cashToAssets && amount > assets.lockedAssets)) {
      return;
    }
    final locked = draft.cashToAssets
        ? assets.lockedAssets + amount
        : assets.lockedAssets - amount;
    final cash = draft.cashToAssets
        ? assets.cash - amount
        : assets.cash + amount;
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: UserAssets(
        total: locked + cash,
        lockedAssets: locked,
        cash: cash,
        updatedAt: DateTime.now(),
        firstRecordDate: assets.firstRecordDate ?? current.firstRecordDate,
      ),
      expenses: current.expenses,
      incomes: current.incomes,
      devices: current.devices,
      passiveSources: current.passiveSources,
      firstRecordDate: current.firstRecordDate,
    );
    await _persist(next);
  }

  Future<void> _deleteTransaction(_Transaction transaction) async {
    final current = _data;
    if (current == null) return;
    final assets = current.assets ?? const UserAssets();
    final cash = transaction.isExpense
        ? assets.cash + transaction.amount
        : assets.cash - transaction.amount;
    final next = BackupData(
      schemaVersion: current.schemaVersion ?? 1,
      assets: UserAssets(
        total: assets.lockedAssets + cash,
        lockedAssets: assets.lockedAssets,
        cash: cash,
        updatedAt: DateTime.now(),
        firstRecordDate: assets.firstRecordDate ?? current.firstRecordDate,
      ),
      expenses: transaction.isExpense
          ? current.expenses.where((item) => item.id != transaction.id).toList()
          : current.expenses,
      incomes: transaction.isExpense
          ? current.incomes
          : current.incomes.where((item) => item.id != transaction.id).toList(),
      devices: current.devices,
      passiveSources: current.passiveSources,
      firstRecordDate: current.firstRecordDate,
    );
    await _persist(next);
  }

  void _showUndo(_Transaction transaction) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
          content: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: transaction.isExpense
                      ? context.fg.flame
                      : context.fg.skyDeep,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '已记${transaction.isExpense ? '支出' : '收入'} '
                  '${transaction.signedAmount}',
                  style: context.numberStyle(14, color: context.fg.ink),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              HapticFeedback.mediumImpact();
              _deleteTransaction(transaction);
            },
          ),
        ),
      );
  }

  DateTime _firstRecordDate(BackupData data, DateTime fallback) {
    return resolveFirstRecordDateForMutation(data, fallback);
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.data,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.isDarkMode,
    required this.isActive,
    required this.heroVertical,
    required this.onToggleTheme,
    required this.onToggleHero,
  });

  final BackupData data;
  final ValueChanged<_ExpenseDraft> onAddExpense;
  final ValueChanged<_IncomeDraft> onAddIncome;
  final bool isDarkMode;
  final bool isActive;
  final bool heroVertical;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleHero;

  @override
  Widget build(BuildContext context) {
    final metrics = _DashboardMetrics.from(data);

    return ColoredBox(
      color: context.fg.paper,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardTopBar(
                isDarkMode: isDarkMode,
                heroVertical: heroVertical,
                onToggleTheme: onToggleTheme,
                onToggleHero: onToggleHero,
              ),
              const SizedBox(height: 22),
              _HeroCard(
                metrics: metrics,
                vertical: heroVertical,
                meteorEnabled: isActive,
              ),
              const SizedBox(height: 20),
              _FreedomGridCard(state: metrics.gridState),
              const SizedBox(height: 20),
              _StatsRow(metrics: metrics),
              const SizedBox(height: 20),
              _ActionRow(
                metrics: metrics,
                onAddExpense: onAddExpense,
                onAddIncome: onAddIncome,
              ),
              const SizedBox(height: 18),
              _SimulateButton(metrics: metrics),
              const SizedBox(height: 14),
              _TodayCompareCard(metrics: metrics),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetsView extends StatelessWidget {
  const _AssetsView({
    required this.data,
    required this.onUpdateAssets,
    required this.onAddPassiveSource,
    required this.onUpdatePassiveSource,
    required this.onDeletePassiveSource,
    required this.onTransfer,
    required this.onImportJson,
    required this.onExportCsv,
    required this.onExportJson,
    required this.onClearData,
  });

  final BackupData data;
  final ValueChanged<_AssetDraft> onUpdateAssets;
  final ValueChanged<_PassiveDraft> onAddPassiveSource;
  final ValueChanged<_PassiveEdit> onUpdatePassiveSource;
  final ValueChanged<String?> onDeletePassiveSource;
  final ValueChanged<_TransferDraft> onTransfer;
  final Future<void> Function() onImportJson;
  final Future<void> Function() onExportCsv;
  final Future<void> Function() onExportJson;
  final Future<void> Function() onClearData;

  @override
  Widget build(BuildContext context) {
    final assets = data.assets ?? const UserAssets();
    final dailyPassive = FreedomMath.dailyPassive(data.passiveSources);
    final monthlyPassive = data.passiveSources.fold(
      0.0,
      (sum, source) => sum + source.monthlyAmount,
    );

    return ColoredBox(
      color: context.fg.paper,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageTitle(title: 'Assets'),
              const SizedBox(height: 18),
              _SilverCard(
                background: context.fg.mist,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Kicker('NET WORTH · 净值'),
                    const SizedBox(height: 18),
                    Text(
                      '¥${_formatMoney(assets.netWorth)}',
                      style: context.numberStyle(
                        46,
                        color: context.fg.ink,
                        weight: FontWeight.w300,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      assets.netWorth == 0 ? '点击下方资金桶录入金额' : '净值由资产与现金自动相加',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.fg.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AssetBucketButton(
                      label: '资产',
                      value: assets.lockedAssets,
                      color: context.fg.incomeGold,
                      onTap: () => _showAssetSheet(
                        context,
                        initialLocked: assets.lockedAssets,
                        initialCash: assets.cash,
                        onSave: onUpdateAssets,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _AssetBucketButton(
                      label: '现金',
                      value: assets.cash,
                      color: context.fg.assetBlue,
                      onTap: () => _showAssetSheet(
                        context,
                        initialLocked: assets.lockedAssets,
                        initialCash: assets.cash,
                        onSave: onUpdateAssets,
                      ),
                    ),
                  ),
                ],
              ),
              if (assets.netWorth == 0) ...[
                const SizedBox(height: 14),
                _InlineHint(
                  icon: Icons.touch_app_outlined,
                  text: '点击上方资金桶录入金额，Freedom Days 会立即重算',
                ),
              ],
              const SizedBox(height: 14),
              _SilverCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _Kicker('PASSIVE · 被动收入'),
                        const Spacer(),
                        IconButton.outlined(
                          tooltip: '添加被动收入',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _showPassiveSheet(context, onAddPassiveSource);
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          color: context.fg.skyDeep,
                          style: IconButton.styleFrom(
                            side: BorderSide(color: context.fg.skyDeep),
                            minimumSize: const Size(42, 42),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${dailyPassive <= 0 ? 0 : (_DashboardMetrics.from(data).passiveRatio * 100).round()}',
                          style: context.numberStyle(
                            46,
                            color: context.fg.ink,
                            weight: FontWeight.w300,
                            height: 0.95,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3, left: 3),
                          child: Text(
                            '%',
                            style: context.numberStyle(
                              21,
                              color: context.fg.inkFaint,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '¥${_formatMoney(monthlyPassive)} / 月\n'
                            '¥${_formatDecimal(dailyPassive)} / 天',
                            textAlign: TextAlign.right,
                            style: context.numberStyle(
                              12,
                              color: context.fg.inkFaint,
                              weight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      data.passiveSources.isEmpty
                          ? '还没有被动收入源，点击右上角 + 添加'
                          : '${data.passiveSources.length} 个收入源正在覆盖日常消费',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.fg.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.passiveSources.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final source in data.passiveSources)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PassiveSourceRow(
                      source: source,
                      onEdit: () => _showPassiveSheet(
                        context,
                        onAddPassiveSource,
                        existing: source,
                        onEdit: onUpdatePassiveSource,
                      ),
                      onDelete: () => _confirmPassiveDelete(
                        context,
                        source,
                        () => onDeletePassiveSource(source.id),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 14),
              _TransferCard(assets: assets, onTransfer: onTransfer),
              const SizedBox(height: 14),
              const _ExplainCard(),
              const SizedBox(height: 14),
              DataManagementCard(
                onImportJson: onImportJson,
                onExportCsv: onExportCsv,
                onExportJson: onExportJson,
                onClearData: onClearData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.metrics,
    required this.vertical,
    required this.meteorEnabled,
  });

  final _DashboardMetrics metrics;
  final bool vertical;
  final bool meteorEnabled;

  @override
  Widget build(BuildContext context) {
    final display = metrics.heroPresentation.display;
    final delta = metrics.delta;

    return MeteorCardSurface(
      enabled: meteorEnabled,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Kicker(metrics.heroKicker),
              Spacer(),
              if (delta != null)
                _TrendBadge(
                  delta: delta.delta,
                  weeks: metrics.history.length - 1,
                ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: vertical
                ? _HeroVerticalBody(
                    key: const ValueKey('vertical'),
                    metrics: metrics,
                    display: display,
                  )
                : _HeroLeadingBody(
                    key: const ValueKey('leading'),
                    metrics: metrics,
                    display: display,
                  ),
          ),
          const SizedBox(height: 20),
          const _Hairline(),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${math.max(1, metrics.history.length - 1)} 周以来的自由天数',
                style: context.numberStyle(
                  14,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              Text(
                delta == null ? '等待趋势' : '${delta.start} → ${delta.end}',
                style: context.numberStyle(
                  14,
                  color: context.fg.ink,
                  weight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            width: double.infinity,
            child: DashboardSparkline(values: metrics.history),
          ),
        ],
      ),
    );
  }
}

class _HeroLeadingBody extends StatelessWidget {
  const _HeroLeadingBody({
    required this.metrics,
    required this.display,
    super.key,
  });

  final _DashboardMetrics metrics;
  final String display;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _HeroCopy(metrics: metrics)),
        const SizedBox(width: 10),
        SizedBox(
          width: 138,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.bottomRight,
            child: FreeGridHeroNumber(
              value: display,
              color: metrics.isCovered ? context.fg.mossGreen : context.fg.ink,
              height: 96,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroVerticalBody extends StatelessWidget {
  const _HeroVerticalBody({
    required this.metrics,
    required this.display,
    super.key,
  });

  final _DashboardMetrics metrics;
  final String display;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: FreeGridHeroNumber(
              value: display,
              color: metrics.isCovered ? context.fg.mossGreen : context.fg.ink,
              height: 104,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _HeroCopy(metrics: metrics, centered: true),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.metrics, this.centered = false});

  final _DashboardMetrics metrics;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final covered = metrics.isCovered;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          textAlign: centered ? TextAlign.center : TextAlign.start,
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.fg.ink,
              fontWeight: FontWeight.w300,
              height: 1.25,
            ),
            children: [
              TextSpan(text: covered ? '你已' : '你的'),
              TextSpan(
                text: covered ? '财富' : '自由',
                style: TextStyle(
                  color: covered ? context.fg.mossGreen : context.fg.skyDeep,
                ),
              ),
              if (covered) const TextSpan(text: '自由'),
            ],
          ),
        ),
        if (!covered)
          Text(
            '还能撑这么多${metrics.heroUnitLabel}',
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.fg.ink,
              fontWeight: FontWeight.w300,
              height: 1.25,
            ),
          ),
        const SizedBox(height: 7),
        Text(
          covered
              ? '按当前日均消费，被动已覆盖'
              : metrics.depleteDate == null
              ? '先记录支出，开始计算自由天数'
              : '约 ${_formatMonthDay(metrics.depleteDate!)} 见底',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: covered ? context.fg.mossGreen : context.fg.inkFaint,
          ),
        ),
      ],
    );
  }
}

class _FreedomGridCard extends StatelessWidget {
  const _FreedomGridCard({required this.state});

  final GridState state;

  @override
  Widget build(BuildContext context) {
    final assetCells = state.blueCells;
    return _SilverCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Kicker('FREEDOM GRID'),
              const Spacer(),
              Text(
                '${state.count} ${state.unit.label}',
                style: context.numberStyle(
                  14,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (state.count == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.grid_view_rounded,
                      color: context.fg.inkGhost,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '记录第一笔后，网格开始点亮',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.fg.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LifeGrid(
              unit: state.unit,
              count: state.count,
              assetCells: assetCells,
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              _LegendDot(color: context.fg.incomeGold, label: '资产'),
              const SizedBox(width: 22),
              _LegendDot(color: context.fg.assetBlue, label: '现金'),
              const Spacer(),
              Text(
                '每格 = 1 ${state.unit.label}自由',
                style: context.numberStyle(
                  12,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: _formatDecimal(metrics.dailyBurn),
            label: 'DAILY',
            unit: '元/天',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            value: '${(metrics.passiveRatio * 100).round()}%',
            label: 'PASSIVE',
            unit: '被动覆盖',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            value: '${metrics.trackDays}',
            label: 'TRACK',
            unit: '天追踪',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.unit,
  });

  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return _SilverCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: context.numberStyle(
                33,
                color: context.fg.ink,
                weight: FontWeight.w300,
                height: 0.94,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(width: 26, height: 1, color: context.fg.inkGhost),
          const SizedBox(height: 8),
          _Kicker(label),
          const SizedBox(height: 6),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.fg.inkFaint,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.metrics,
    required this.onAddExpense,
    required this.onAddIncome,
  });

  final _DashboardMetrics metrics;
  final ValueChanged<_ExpenseDraft> onAddExpense;
  final ValueChanged<_IncomeDraft> onAddIncome;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineActionButton(
            icon: Icons.remove_rounded,
            label: '记支出',
            color: context.fg.flame,
            onPressed: () => _showExpenseSheet(context, metrics, onAddExpense),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _OutlineActionButton(
            icon: Icons.add_rounded,
            label: '记收入',
            color: context.fg.skyDeep,
            onPressed: () => _showIncomeSheet(context, metrics, onAddIncome),
          ),
        ),
      ],
    );
  }
}

class _SimulateButton extends StatelessWidget {
  const _SimulateButton({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showSimulateSheet(context, metrics),
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text('模拟一笔 · 看决策影响'),
        style: TextButton.styleFrom(
          foregroundColor: context.fg.inkGhost,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class _TodayCompareCard extends StatelessWidget {
  const _TodayCompareCard({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final percent = metrics.dailyBurn <= 0
        ? 0.0
        : (metrics.todaySpending / metrics.dailyBurn).clamp(0.04, 1.0);
    final overAverage =
        metrics.dailyBurn > 0 && metrics.todaySpending > metrics.dailyBurn;

    return _SilverCard(
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¥${_formatDecimal(metrics.todaySpending)}',
                    style: context.numberStyle(
                      24,
                      color: context.fg.ink,
                      weight: FontWeight.w300,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _Kicker('TODAY'),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 3,
                    backgroundColor: context.fg.mist2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overAverage ? context.fg.flame : context.fg.assetBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥${_formatDecimal(metrics.dailyBurn)}',
                    style: context.numberStyle(
                      24,
                      color: context.fg.inkFaint,
                      weight: FontWeight.w300,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const _Kicker('AVG'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _todayComparison(metrics),
            textAlign: TextAlign.center,
            style: context.numberStyle(
              12,
              color: context.fg.inkMuted,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

String _todayComparison(_DashboardMetrics metrics) {
  if (metrics.dailyBurn <= 0) return '等待日均消费数据';
  if (metrics.todaySpending <= 0) return '今日尚未消费';
  final difference = metrics.todaySpending - metrics.dailyBurn;
  final percent = (difference.abs() / metrics.dailyBurn * 100).round();
  return difference > 0
      ? '高于日均 $percent% · 多花 ¥${_formatDecimal(difference)}'
      : '低于日均 $percent% · 节省 ¥${_formatDecimal(difference.abs())}';
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.2),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _TabSpec(icon: Icons.show_chart_rounded, label: 'Dashboard'),
      _TabSpec(icon: Icons.account_balance_wallet_outlined, label: 'Assets'),
      _TabSpec(icon: Icons.history_rounded, label: 'History'),
      _TabSpec(icon: Icons.settings_outlined, label: 'Settings'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.fg.nav,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: context.fg.hairline, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.34
                  : 0.10,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i += 1)
              Expanded(
                child: _BottomTab(
                  spec: tabs[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 58,
          decoration: BoxDecoration(
            color: selected ? context.fg.navSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                spec.icon,
                size: 23,
                color: selected ? context.fg.skyDeep : context.fg.inkMuted,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spec.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected ? context.fg.skyDeep : context.fg.inkMuted,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.fg.paper,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: context.fg.ink,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
        const Spacer(),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _TransferCard extends StatefulWidget {
  const _TransferCard({required this.assets, required this.onTransfer});

  final UserAssets assets;
  final ValueChanged<_TransferDraft> onTransfer;

  @override
  State<_TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<_TransferCard> {
  final _amount = TextEditingController();
  var _cashToAssets = true;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _parseAmount(_amount.text);
    final available = _cashToAssets
        ? widget.assets.cash
        : widget.assets.lockedAssets;
    final enabled = amount != null && amount <= available;
    return _SilverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Kicker('TRANSFER · 调拨'),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('现金 → 资产')),
              ButtonSegment(value: false, label: Text('资产 → 现金')),
            ],
            selected: {_cashToAssets},
            onSelectionChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _cashToAssets = value.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? context.fg.ink
                    : context.fg.inkMuted,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? context.fg.mist
                    : context.fg.mist2,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: context.fg.hairline),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: context.numberStyle(
              22,
              color: context.fg.ink,
              weight: FontWeight.w300,
            ),
            decoration: _inputDecoration(context, '0', prefix: '¥ '),
          ),
          const SizedBox(height: 12),
          Text(
            '可调拨 ¥${_formatMoney(available)}',
            style: context.numberStyle(
              13,
              color: context.fg.inkFaint,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          _SheetSaveButton(
            label: '确认调拨',
            color: context.fg.skyDeep,
            onPressed: enabled
                ? () {
                    HapticFeedback.mediumImpact();
                    widget.onTransfer(
                      _TransferDraft(
                        amount: amount,
                        cashToAssets: _cashToAssets,
                      ),
                    );
                    _amount.clear();
                    setState(() {});
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                          content: Text(
                            _cashToAssets ? '已从现金调入资产' : '已从资产调回现金',
                          ),
                        ),
                      );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ExplainCard extends StatelessWidget {
  const _ExplainCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.fg.skyFaint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '净值 = 资产 + 现金。资产是锁定的钱，例如定期、股票或基金；现金用于日常收支。两者之间可通过调拨移动。',
        style: TextStyle(
          color: context.fg.inkMuted,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

enum _HistoryFilter { all, expense, income }

class _HistoryView extends StatefulWidget {
  const _HistoryView({required this.data, required this.onDelete});

  final BackupData data;
  final ValueChanged<_Transaction> onDelete;

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  var _filter = _HistoryFilter.all;
  String? _category;

  @override
  Widget build(BuildContext context) {
    final transactions = _transactions;
    final categories = _categoryTotals;
    return ColoredBox(
      color: context.fg.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: _PageTitle(
                title: 'History',
                trailing: IconButton(
                  tooltip: '月度汇总',
                  onPressed: () => _showMonthlySummary(context, widget.data),
                  icon: const Icon(Icons.calendar_month_outlined),
                  color: context.fg.inkMuted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<_HistoryFilter>(
                segments: const [
                  ButtonSegment(value: _HistoryFilter.all, label: Text('全部')),
                  ButtonSegment(
                    value: _HistoryFilter.expense,
                    label: Text('支出'),
                  ),
                  ButtonSegment(
                    value: _HistoryFilter.income,
                    label: Text('收入'),
                  ),
                ],
                selected: {_filter},
                selectedIcon: Icon(
                  Icons.check_rounded,
                  color: context.fg.skyDeep,
                  size: 18,
                ),
                onSelectionChanged: (value) {
                  setState(() {
                    _filter = value.first;
                    if (_filter != _HistoryFilter.expense) _category = null;
                  });
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? context.fg.ink
                        : context.fg.inkMuted,
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? context.fg.mist
                        : context.fg.mist2,
                  ),
                  side: WidgetStatePropertyAll(
                    BorderSide(color: context.fg.hairline),
                  ),
                ),
              ),
            ),
            if (_filter == _HistoryFilter.expense && categories.isNotEmpty)
              HistoryCategoryStrip(
                categories: [
                  for (final item in categories)
                    HistoryCategoryItem(name: item.name, total: item.total),
                ],
                selectedCategory: _category,
                onSelected: (value) => setState(() => _category = value),
              ),
            Expanded(
              child: transactions.isEmpty
                  ? const _EmptyHistory()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 126),
                      itemCount: transactions.length + 1,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: context.fg.hairlineSoft),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _HistorySummary(transactions: transactions),
                          );
                        }
                        final tx = transactions[index - 1];
                        return Dismissible(
                          key: ValueKey(
                            '${tx.isExpense}-${tx.id ?? tx.date.microsecondsSinceEpoch}',
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(context, tx),
                          onDismissed: (_) {
                            HapticFeedback.mediumImpact();
                            widget.onDelete(tx);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: context.fg.flame.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.undo_rounded,
                              color: context.fg.flame,
                            ),
                          ),
                          child: _TransactionRow(transaction: tx),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_Transaction> get _transactions {
    final items = <_Transaction>[
      if (_filter != _HistoryFilter.income)
        for (final item in widget.data.expenses)
          if (_category == null || item.category == _category)
            _Transaction.expense(item),
      if (_filter != _HistoryFilter.expense)
        for (final item in widget.data.incomes) _Transaction.income(item),
    ];
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<_CategoryTotal> get _categoryTotals {
    final totals = <String, double>{};
    for (final item in widget.data.expenses) {
      totals[item.category] = (totals[item.category] ?? 0) + item.amount;
    }
    final items = totals.entries
        .map((entry) => _CategoryTotal(entry.key, entry.value))
        .toList();
    items.sort((a, b) => b.total.compareTo(a.total));
    return items;
  }

  Future<bool> _confirmDelete(BuildContext context, _Transaction tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('撤销这笔记录？'),
        content: Text(
          '${_formatDate(tx.date)} · ${tx.title}\n${tx.signedAmount}\n\n'
          '${tx.isExpense ? '现金会反向恢复' : '现金会反向减少'} ¥${_formatMoney(tx.amount)}',
          style: context.numberStyle(
            14,
            color: context.fg.ink,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.fg.flame),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.data,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  });

  final BackupData data;
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final summary = _CheckSummary.from(data);
    return ColoredBox(
      color: context.fg.paper,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 128),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: _PageTitle(title: 'Settings'),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _CheckPage(summary: summary),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: _SilverCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: summary.progress,
                              strokeWidth: 5,
                              strokeCap: StrokeCap.round,
                              backgroundColor: context.fg.mist2,
                              color: context.fg.skyDeep,
                            ),
                            Text(
                              '${summary.done}/8',
                              style: context.numberStyle(
                                14,
                                color: context.fg.ink,
                                weight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '财富自由自检',
                              style: TextStyle(
                                color: context.fg.ink,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary.next == null
                                  ? '已全部达成 🎉'
                                  : '下一站 · ${summary.next}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: context.fg.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.fg.inkGhost),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SettingsSectionLabel('外观'),
              const SizedBox(height: 8),
              _SilverCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Icon(
                      isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: context.fg.inkMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 14),
                    Text('主题', style: Theme.of(context).textTheme.bodyLarge),
                    const Spacer(),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('浅色')),
                        ButtonSegment(value: true, label: Text('深色')),
                      ],
                      selected: {isDarkMode},
                      onSelectionChanged: (value) {
                        HapticFeedback.selectionClick();
                        onDarkModeChanged(value.first);
                      },
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? context.fg.ink
                              : context.fg.inkFaint,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? context.fg.mist
                              : context.fg.mist2,
                        ),
                        side: WidgetStatePropertyAll(
                          BorderSide(color: context.fg.hairline),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 2),
              _SilverCard(
                padding: EdgeInsets.zero,
                child: _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  title: '关于',
                  trailing: '版本与隐私',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutPage()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '你的财务数据只存在这台设备上。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.fg.inkFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckPage extends StatelessWidget {
  const _CheckPage({required this.summary});

  final _CheckSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fg.paper,
      appBar: AppBar(
        title: const Text('财富自由自检'),
        backgroundColor: context.fg.paper,
        foregroundColor: context.fg.ink,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _SilverCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker('FREEDOM CHECKLIST'),
                const SizedBox(height: 12),
                Text(
                  '${summary.done} / 8',
                  style: context.numberStyle(
                    52,
                    color: context.fg.ink,
                    weight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: summary.progress,
                    minHeight: 4,
                    color: context.fg.skyDeep,
                    backgroundColor: context.fg.mist2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '达成项越多，离财富自由越近',
                  style: TextStyle(color: context.fg.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SilverCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var index = 0; index < summary.items.length; index++) ...[
                  _CheckRow(item: summary.items[index]),
                  if (index < summary.items.length - 1)
                    Divider(
                      height: 1,
                      indent: 54,
                      color: context.fg.hairlineSoft,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.item});

  final _CheckItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.done ? Icons.check_circle : Icons.circle_outlined,
            color: item.done ? context.fg.skyDeep : context.fg.inkFaint,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.index}. ${item.title}',
                  style: TextStyle(
                    color: item.done ? context.fg.inkFaint : context.fg.ink,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.done ? '已达成' : '怎么前进 · ${item.hint}',
                  style: TextStyle(
                    color: item.done ? context.fg.skyDeep : context.fg.inkFaint,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: context.fg.inkMuted, size: 20),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(color: context.fg.ink, fontSize: 16)),
            const Spacer(),
            Text(
              trailing,
              style: TextStyle(color: context.fg.inkFaint, fontSize: 13),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: context.fg.inkGhost,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.fg.inkFaint),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 42, color: context.fg.inkFaint),
          const SizedBox(height: 12),
          Text('还没有记录', style: TextStyle(color: context.fg.ink, fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            '回 Dashboard 添加第一笔支出或收入',
            style: TextStyle(color: context.fg.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.transactions});

  final List<_Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final net = transactions.fold<double>(
      0,
      (sum, tx) => sum + (tx.isExpense ? -tx.amount : tx.amount),
    );
    return Row(
      children: [
        Text(
          '共 ${transactions.length} 笔',
          style: context.numberStyle(
            13,
            color: context.fg.inkFaint,
            weight: FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          '净 ${net >= 0 ? '+' : '−'}¥${_formatMoney(net.abs())}',
          style: context.numberStyle(
            13,
            color: context.fg.ink,
            weight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final _Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isExpense ? context.fg.flame : context.fg.skyDeep;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(color: context.fg.ink, fontSize: 16),
                ),
                if (transaction.note.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    transaction.note,
                    style: TextStyle(color: context.fg.inkFaint, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.date),
                  style: context.numberStyle(
                    12,
                    color: context.fg.inkFaint,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.signedAmount,
            style: context.numberStyle(
              16,
              color: color,
              weight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_left_rounded,
            color: context.fg.inkGhost,
            size: 16,
          ),
        ],
      ),
    );
  }
}

void _showMonthlySummary(BuildContext context, BackupData data) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => _MonthlySummaryPage(data: data)));
}

class _MonthlySummaryPage extends StatelessWidget {
  const _MonthlySummaryPage({required this.data});

  final BackupData data;

  @override
  Widget build(BuildContext context) {
    final months = _months;
    return Scaffold(
      backgroundColor: context.fg.paper,
      appBar: AppBar(
        title: const Text('月度汇总'),
        backgroundColor: context.fg.paper,
        foregroundColor: context.fg.ink,
      ),
      body: months.isEmpty
          ? const _EmptyHistory()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: months.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _MonthCard(month: months[index]),
            ),
    );
  }

  List<_MonthSummary> get _months {
    final map = <String, _MonthAccumulator>{};
    for (final expense in data.expenses) {
      final key = _monthKey(expense.date);
      final item = map.putIfAbsent(key, () => _MonthAccumulator(key));
      item.expense += expense.amount;
      item.categories[expense.category] =
          (item.categories[expense.category] ?? 0) + expense.amount;
    }
    for (final income in data.incomes) {
      final key = _monthKey(income.date);
      map.putIfAbsent(key, () => _MonthAccumulator(key)).income +=
          income.amount;
    }
    final result = map.values.map((item) => item.finish()).toList();
    result.sort((a, b) => b.key.compareTo(a.key));
    return result;
  }
}

class _MonthCard extends StatefulWidget {
  const _MonthCard({required this.month});

  final _MonthSummary month;

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final month = widget.month;
    final net = month.income - month.expense;
    return _SilverCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: month.categories.isEmpty
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    setState(() => _expanded = !_expanded);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    month.label,
                    style: context.numberStyle(
                      19,
                      color: context.fg.ink,
                      weight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  '净 ${net >= 0 ? '+' : '−'}¥${_formatMoney(net.abs())}',
                  style: context.numberStyle(
                    14,
                    color: net >= 0 ? context.fg.mossGreen : context.fg.flame,
                    weight: FontWeight.w400,
                  ),
                ),
                if (month.categories.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.fg.inkFaint,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MonthStat(
                label: '支出',
                value: month.expense,
                color: context.fg.flame,
              ),
              const SizedBox(width: 20),
              _MonthStat(
                label: '收入',
                value: month.income,
                color: context.fg.skyDeep,
              ),
              const Spacer(),
              _MonthStat(label: '净', value: net, color: context.fg.ink),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: !_expanded
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 16),
                      Divider(height: 1, color: context.fg.hairlineSoft),
                      const SizedBox(height: 12),
                      for (final category in month.categories)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            children: [
                              Text(
                                category.name,
                                style: TextStyle(
                                  color: context.fg.inkMuted,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '¥${_formatMoney(category.total)}',
                                style: context.numberStyle(
                                  13,
                                  color: context.fg.ink,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.fg.inkFaint, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          '¥${_formatMoney(value)}',
          style: context.numberStyle(16, color: color, weight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _MonthAccumulator {
  _MonthAccumulator(this.key);

  final String key;
  var expense = 0.0;
  var income = 0.0;
  final categories = <String, double>{};

  _MonthSummary finish() {
    final rows =
        categories.entries
            .map((entry) => _CategoryTotal(entry.key, entry.value))
            .toList()
          ..sort((a, b) => b.total.compareTo(a.total));
    return _MonthSummary(key, expense, income, rows);
  }
}

class _MonthSummary {
  const _MonthSummary(this.key, this.expense, this.income, this.categories);

  final String key;
  final double expense;
  final double income;
  final List<_CategoryTotal> categories;

  String get label {
    final parts = key.split('-');
    return '${parts[0]} 年 ${int.parse(parts[1])} 月';
  }
}

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

Future<void> _showExpenseSheet(
  BuildContext context,
  _DashboardMetrics metrics,
  ValueChanged<_ExpenseDraft> onSave,
) async {
  final draft = await showModalBottomSheet<_ExpenseDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.fg.mist,
    builder: (context) => _ExpenseSheet(metrics: metrics),
  );
  if (draft != null) onSave(draft);
}

Future<void> _showIncomeSheet(
  BuildContext context,
  _DashboardMetrics metrics,
  ValueChanged<_IncomeDraft> onSave,
) async {
  final draft = await showModalBottomSheet<_IncomeDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.fg.mist,
    builder: (context) => _IncomeSheet(metrics: metrics),
  );
  if (draft != null) onSave(draft);
}

Future<void> _showSimulateSheet(
  BuildContext context,
  _DashboardMetrics metrics,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.fg.mist,
    builder: (context) => _SimulateSheet(metrics: metrics),
  );
}

Future<void> _showAssetSheet(
  BuildContext context, {
  required double initialLocked,
  required double initialCash,
  required ValueChanged<_AssetDraft> onSave,
}) async {
  final draft = await showModalBottomSheet<_AssetDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.fg.mist,
    builder: (context) =>
        _AssetSheet(initialLocked: initialLocked, initialCash: initialCash),
  );
  if (draft != null) onSave(draft);
}

Future<void> _showPassiveSheet(
  BuildContext context,
  ValueChanged<_PassiveDraft> onSave, {
  PassiveSource? existing,
  ValueChanged<_PassiveEdit>? onEdit,
}) async {
  final draft = await showModalBottomSheet<_PassiveResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.fg.mist,
    builder: (context) => _PassiveSheet(existing: existing),
  );
  if (draft == null) return;
  if (existing == null) {
    onSave(_PassiveDraft(name: draft.name, monthlyAmount: draft.monthlyAmount));
  } else if (onEdit != null) {
    onEdit(
      _PassiveEdit(
        id: existing.id,
        name: draft.name,
        monthlyAmount: draft.monthlyAmount,
      ),
    );
  }
}

Future<void> _confirmPassiveDelete(
  BuildContext context,
  PassiveSource source,
  VoidCallback onDelete,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除这个被动收入源？'),
      content: Text(
        '${source.name} · 月入 ¥${_formatMoney(source.monthlyAmount)}\n'
        '删除后，被动覆盖率会同步下降。',
        style: context.numberStyle(
          14,
          color: context.fg.ink,
          weight: FontWeight.w400,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: context.fg.flame),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    HapticFeedback.mediumImpact();
    onDelete();
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.fg.skyFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.fg.skySoft.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.fg.skyDeep, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.fg.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetBucketButton extends StatelessWidget {
  const _AssetBucketButton({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final double value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SilverCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  label == '资产' ? Icons.lock_rounded : Icons.payments_outlined,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Expanded(child: _Kicker(label)),
                Icon(Icons.edit_outlined, color: context.fg.inkFaint, size: 17),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '¥${_formatMoney(value)}',
                style: context.numberStyle(
                  24,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassiveSourceRow extends StatelessWidget {
  const _PassiveSourceRow({
    required this.source,
    required this.onEdit,
    required this.onDelete,
  });

  final PassiveSource source;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _SilverCard(
      padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: context.fg.mossGreen, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.name, style: TextStyle(color: context.fg.ink)),
                    Text(
                      '¥${_formatMoney(source.monthlyAmount)} / 月 · ¥${_formatDecimal(source.monthlyAmount / 30)} / 天',
                      style: context.numberStyle(
                        12,
                        color: context.fg.inkFaint,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '删除这个被动收入源',
            onPressed: onDelete,
            icon: const Icon(Icons.close),
            color: context.fg.inkFaint,
            iconSize: 16,
          ),
        ],
      ),
    );
  }
}

class _AssetSheet extends StatefulWidget {
  const _AssetSheet({required this.initialLocked, required this.initialCash});

  final double initialLocked;
  final double initialCash;

  @override
  State<_AssetSheet> createState() => _AssetSheetState();
}

class _AssetSheetState extends State<_AssetSheet> {
  late final TextEditingController _locked;
  late final TextEditingController _cash;

  @override
  void initState() {
    super.initState();
    _locked = TextEditingController(
      text: _formatPlainNumber(widget.initialLocked),
    );
    _cash = TextEditingController(text: _formatPlainNumber(widget.initialCash));
  }

  @override
  void dispose() {
    _locked.dispose();
    _cash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockedValue = _parseNonNegativeAmount(_locked.text);
    final cashValue = _parseNonNegativeAmount(_cash.text);
    final valid = lockedValue != null && cashValue != null;
    return _SheetFrame(
      title: '修正资产',
      accent: context.fg.incomeGold,
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _MoneyField(
            controller: _locked,
            accent: context.fg.incomeGold,
            hint: '0.00',
            label: '锁定资产（元）',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _MoneyField(
            controller: _cash,
            accent: context.fg.assetBlue,
            hint: '0.00',
            label: '现金（元）',
            autofocus: false,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _SheetSaveButton(
            label: '保存资产',
            color: context.fg.incomeGold,
            onPressed: valid
                ? () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(
                      _AssetDraft(lockedAssets: lockedValue, cash: cashValue),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _PassiveSheet extends StatefulWidget {
  const _PassiveSheet({this.existing});

  final PassiveSource? existing;

  @override
  State<_PassiveSheet> createState() => _PassiveSheetState();
}

class _PassiveSheetState extends State<_PassiveSheet> {
  late final TextEditingController _name;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '被动收入');
    _amount = TextEditingController(
      text: widget.existing == null
          ? ''
          : _formatPlainNumber(widget.existing!.monthlyAmount),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = _parseAmount(_amount.text);
    final valid = _name.text.trim().isNotEmpty && amountValue != null;
    return _SheetFrame(
      title: widget.existing == null ? '添加被动收入' : '编辑被动收入',
      accent: context.fg.skyDeep,
      icon: Icons.bolt_rounded,
      child: Column(
        children: [
          _NoteField(
            controller: _name,
            label: '名称',
            hint: '股息、房租…',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          _MoneyField(
            controller: _amount,
            accent: context.fg.skyDeep,
            label: '每月金额（元）',
            hint: '0.00',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _SheetSaveButton(
            label: '保存被动收入',
            color: context.fg.skyDeep,
            onPressed: valid
                ? () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(
                      _PassiveResult(
                        name: _name.text.trim(),
                        monthlyAmount: amountValue,
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  var _category = ExpenseCategory.canonical.first;
  var _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = _parseAmount(_amount.text);
    return _SheetFrame(
      title: '记支出',
      accent: context.fg.flame,
      icon: Icons.remove_rounded,
      child: Column(
        children: [
          _MoneyField(
            controller: _amount,
            accent: context.fg.flame,
            label: '金额（元）',
            hint: '0.00',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _CategoryPicker(
            value: _category,
            items: ExpenseCategory.canonical,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _category = value);
            },
          ),
          const SizedBox(height: 18),
          _DateField(
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 18),
          _NoteField(controller: _note, label: '备注（可选）', hint: '写点什么'),
          BookkeepingImpactSection(
            amount: amountValue,
            isExpense: true,
            netWorth: widget.metrics.netWorth,
            dailyBurn: widget.metrics.dailyBurn,
            dailyPassive: widget.metrics.dailyPassive,
            trackDays: widget.metrics.trackDays,
          ),
          const SizedBox(height: 22),
          _SheetSaveButton(
            label: '保存支出',
            color: context.fg.flame,
            onPressed: amountValue == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(
                      _ExpenseDraft(
                        amount: amountValue,
                        category: _category,
                        note: _note.text.trim(),
                        date: _date,
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}

class _IncomeSheet extends StatefulWidget {
  const _IncomeSheet({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  State<_IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<_IncomeSheet> {
  final _amount = TextEditingController();
  final _source = TextEditingController(text: '收入');
  final _note = TextEditingController();
  var _date = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _source.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amountValue = _parseAmount(_amount.text);
    final valid = amountValue != null && _source.text.trim().isNotEmpty;
    return _SheetFrame(
      title: '记收入',
      accent: context.fg.skyDeep,
      icon: Icons.add_rounded,
      child: Column(
        children: [
          _MoneyField(
            controller: _amount,
            accent: context.fg.skyDeep,
            label: '金额（元）',
            hint: '0.00',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _NoteField(
            controller: _source,
            label: '来源',
            hint: '工资、奖金…',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          _DateField(
            value: _date,
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 18),
          _NoteField(controller: _note, label: '备注（可选）', hint: '写点什么'),
          BookkeepingImpactSection(
            amount: amountValue,
            isExpense: false,
            netWorth: widget.metrics.netWorth,
            dailyBurn: widget.metrics.dailyBurn,
            dailyPassive: widget.metrics.dailyPassive,
            trackDays: widget.metrics.trackDays,
          ),
          const SizedBox(height: 22),
          _SheetSaveButton(
            label: '保存收入',
            color: context.fg.skyDeep,
            onPressed: valid
                ? () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(
                      _IncomeDraft(
                        amount: amountValue,
                        source: _source.text.trim(),
                        note: _note.text.trim(),
                        date: _date,
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _SimulateSheet extends StatefulWidget {
  const _SimulateSheet({required this.metrics});

  final _DashboardMetrics metrics;

  @override
  State<_SimulateSheet> createState() => _SimulateSheetState();
}

class _SimulateSheetState extends State<_SimulateSheet> {
  final _amount = TextEditingController(text: '100');
  var _isExpense = true;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = _parseAmount(_amount.text);
    final impact = amount == null
        ? null
        : BookkeepingImpact.calculate(
            isExpense: _isExpense,
            amount: amount,
            netWorth: widget.metrics.netWorth,
            dailyBurn: widget.metrics.dailyBurn,
            dailyPassive: widget.metrics.dailyPassive,
            trackDays: widget.metrics.trackDays,
          );
    final color = _isExpense ? context.fg.flame : context.fg.skyDeep;

    return _SheetFrame(
      title: '模拟一笔',
      accent: color,
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _InlineHint(
            icon: Icons.auto_awesome_rounded,
            text: '不会扣钱，不会写入账本，只预览这笔决策的传导影响',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ModePill(
                  selected: _isExpense,
                  label: '支出',
                  color: context.fg.flame,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isExpense = true);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModePill(
                  selected: !_isExpense,
                  label: '收入',
                  color: context.fg.skyDeep,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isExpense = false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MoneyField(
            controller: _amount,
            accent: color,
            label: _isExpense ? '假设花掉（元）' : '假设收入（元）',
            hint: '0.00',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          if (impact == null)
            const _InlineHint(
              icon: Icons.arrow_upward_rounded,
              text: '输入金额，实时看这笔决策会点亮或熄灭哪些自由格',
            )
          else ...[
            BookkeepingImpactPreview(impact: impact),
            const SizedBox(height: 14),
            SimulationGridDemo(
              before: SimulationGridSnapshot.fromFreedomDays(
                unit: widget.metrics.gridState.unit,
                freedomDays: impact.currentFreedomDays,
                lockedAssets: widget.metrics.lockedAssets,
                netWorth: impact.currentNetWorth,
              ),
              after: SimulationGridSnapshot.fromFreedomDays(
                unit: widget.metrics.gridState.unit,
                freedomDays: impact.nextFreedomDays,
                lockedAssets: widget.metrics.lockedAssets,
                netWorth: impact.nextNetWorth,
              ),
              isExpense: _isExpense,
            ),
          ],
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.accent,
    required this.icon,
    required this.child,
  });

  final String title;
  final Color accent;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.fg.hairline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.fg.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: context.fg.inkMuted),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.accent,
    this.hint = '金额',
    this.label,
    this.autofocus = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final Color accent;
  final String hint;
  final String? label;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        cursorColor: accent,
        style: context.numberStyle(
          32,
          color: context.fg.ink,
          weight: FontWeight.w300,
        ),
        decoration: _inputDecoration(context, hint, prefix: '¥ '),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.hint,
    this.label,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: context.fg.skyDeep,
        style: TextStyle(color: context.fg.ink),
        decoration: _inputDecoration(context, hint),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.child, this.label});

  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (label == null) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.fg.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '分类',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.fg.inkFaint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              ChoiceChip(
                label: Text(item),
                selected: value == item,
                showCheckmark: false,
                onSelected: (_) => onChanged(item),
                labelStyle: TextStyle(
                  color: value == item
                      ? context.fg.skyDeep
                      : context.fg.inkMuted,
                  fontWeight: value == item ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: value == item
                      ? context.fg.skyDeep
                      : context.fg.hairline,
                ),
                selectedColor: context.fg.skyFaint,
                backgroundColor: context.fg.paper,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: '日期',
      child: InkWell(
        onTap: () async {
          FocusScope.of(context).unfocus();
          final selected = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            helpText: '选择记账日期',
            cancelText: '取消',
            confirmText: '确定',
          );
          if (selected != null) {
            HapticFeedback.selectionClick();
            onChanged(selected);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: context.fg.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.fg.hairline),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: context.fg.inkMuted,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                _formatDate(value),
                style: context.numberStyle(
                  14,
                  color: context.fg.ink,
                  weight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: context.fg.inkGhost),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSaveButton extends StatelessWidget {
  const _SheetSaveButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.selected,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? color : context.fg.inkFaint,
        backgroundColor: selected ? color.withValues(alpha: 0.10) : null,
        side: BorderSide(color: selected ? color : context.fg.hairline),
        shape: const StadiumBorder(),
      ),
      child: Text(label),
    );
  }
}

class _SilverCard extends StatelessWidget {
  const _SilverCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.background,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? context.fg.mist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.fg.hairline, width: 1),
      ),
      child: child,
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          color: context.fg.inkFaint,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 3,
          height: 1.2,
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.delta, required this.weeks});

  final int delta;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final isUp = delta >= 0;
    final sign = isUp ? '+' : '';
    final icon = isUp
        ? Icons.arrow_drop_up_rounded
        : Icons.arrow_drop_down_rounded;
    final color = isUp ? context.fg.skyDeep : context.fg.flame;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 12, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          Text(
            '$sign$delta d · ${weeks}w',
            style: context.numberStyle(
              14,
              color: color,
              weight: FontWeight.w400,
              letterSpacing: 1.6,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.fg.hairline);
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.fg.inkMuted,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _DashboardMetrics {
  const _DashboardMetrics({
    required this.netWorth,
    required this.lockedAssets,
    required this.cash,
    required this.dailyBurn,
    required this.dailyPassive,
    required this.passiveRatio,
    required this.freedomDays,
    required this.gridState,
    required this.trackDays,
    required this.todaySpending,
    required this.history,
    required this.delta,
    required this.depleteDate,
  });

  final double netWorth;
  final double lockedAssets;
  final double cash;
  final double dailyBurn;
  final double dailyPassive;
  final double passiveRatio;
  final double freedomDays;
  final GridState gridState;
  final int trackDays;
  final double todaySpending;
  final List<double> history;
  final DeltaSummary? delta;
  final DateTime? depleteDate;

  String get heroKicker {
    return heroPresentation.kicker;
  }

  FreedomHeroPresentation get heroPresentation =>
      FreedomHeroPresentation.resolve(
        dailyBurn: dailyBurn,
        freedomDays: freedomDays,
      );

  bool get isCovered => heroPresentation.isCovered;

  String get heroUnitLabel {
    final unit = FreedomMath.freedomDaysUnit(freedomDays);
    return FreedomMath.freedomUnitLabel(unit);
  }

  factory _DashboardMetrics.from(BackupData data, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final assets = data.assets ?? const UserAssets();
    final firstRecordDate = resolveFirstRecordDate(data, today);
    final trackDays = FreedomMath.trackDays(
      firstRecordDate: firstRecordDate,
      now: today,
    );
    final totalExpenses = data.expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final dailyBurn = FreedomMath.dailyBurn(
      totalExpenses: totalExpenses,
      trackDays: trackDays,
    );
    final dailyPassive = FreedomMath.dailyPassive(data.passiveSources);
    final passiveRatio = FreedomMath.passiveRatio(
      dailyPassive: dailyPassive,
      dailyBurn: dailyBurn,
    );
    final freedomDays = FreedomMath.freedomDays(
      netWorth: assets.netWorth,
      dailyBurn: dailyBurn,
      dailyPassive: dailyPassive,
    );
    final gridState = FreedomMath.gridState(
      lockedAssets: assets.lockedAssets,
      cash: assets.cash,
      dailyBurn: dailyBurn,
      dailyPassive: dailyPassive,
    );
    final historyPoints = FreedomMath.freedomDaysHistory(
      expenses: data.expenses,
      incomes: data.incomes,
      currentNetWorth: assets.netWorth,
      firstRecordDate: firstRecordDate,
      dailyPassive: dailyPassive,
      now: today,
    );
    final todayStart = FreedomMath.startOfDay(today);
    final todaySpending = data.expenses
        .where((expense) => FreedomMath.startOfDay(expense.date) == todayStart)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    return _DashboardMetrics(
      netWorth: assets.netWorth,
      lockedAssets: assets.lockedAssets,
      cash: assets.cash,
      dailyBurn: dailyBurn,
      dailyPassive: dailyPassive,
      passiveRatio: passiveRatio,
      freedomDays: freedomDays,
      gridState: gridState,
      trackDays: trackDays,
      todaySpending: todaySpending,
      history: historyPoints.map((point) => point.freedomDays).toList(),
      delta: FreedomMath.deltaSummary(historyPoints),
      depleteDate: FreedomMath.depleteDate(
        freedomDays: freedomDays,
        now: today,
      ),
    );
  }
}

class _ExpenseDraft {
  const _ExpenseDraft({
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  final double amount;
  final String category;
  final String note;
  final DateTime date;
}

class _IncomeDraft {
  const _IncomeDraft({
    required this.amount,
    required this.source,
    required this.note,
    required this.date,
  });

  final double amount;
  final String source;
  final String note;
  final DateTime date;
}

class _AssetDraft {
  const _AssetDraft({required this.lockedAssets, required this.cash});

  final double lockedAssets;
  final double cash;
}

class _PassiveDraft {
  const _PassiveDraft({required this.name, required this.monthlyAmount});

  final String name;
  final double monthlyAmount;
}

class _PassiveEdit {
  const _PassiveEdit({
    required this.id,
    required this.name,
    required this.monthlyAmount,
  });

  final String? id;
  final String name;
  final double monthlyAmount;
}

class _PassiveResult {
  const _PassiveResult({required this.name, required this.monthlyAmount});

  final String name;
  final double monthlyAmount;
}

class _TransferDraft {
  const _TransferDraft({required this.amount, required this.cashToAssets});

  final double amount;
  final bool cashToAssets;
}

class _CategoryTotal {
  const _CategoryTotal(this.name, this.total);

  final String name;
  final double total;
}

class _Transaction {
  const _Transaction._({
    required this.id,
    required this.isExpense,
    required this.title,
    required this.note,
    required this.amount,
    required this.date,
  });

  factory _Transaction.expense(Expense expense) => _Transaction._(
    id: expense.id,
    isExpense: true,
    title: expense.category,
    note: expense.note,
    amount: expense.amount,
    date: expense.date,
  );

  factory _Transaction.income(Income income) => _Transaction._(
    id: income.id,
    isExpense: false,
    title: income.source,
    note: income.note,
    amount: income.amount,
    date: income.date,
  );

  final String? id;
  final bool isExpense;
  final String title;
  final String note;
  final double amount;
  final DateTime date;

  String get signedAmount => '${isExpense ? '−' : '+'}¥${_formatMoney(amount)}';
}

class _CheckItem {
  const _CheckItem({
    required this.index,
    required this.title,
    required this.done,
    required this.hint,
  });

  final int index;
  final String title;
  final bool done;
  final String hint;
}

class _CheckSummary {
  const _CheckSummary({
    required this.items,
    required this.done,
    required this.next,
  });

  final List<_CheckItem> items;
  final int done;
  final String? next;

  double get progress => done / items.length;

  factory _CheckSummary.from(BackupData data) {
    final metrics = _DashboardMetrics.from(data);
    final netWorth = data.assets?.netWorth ?? 0;
    final passiveRatio = metrics.passiveRatio;
    final freedom = metrics.freedomDays;
    final finiteDays = freedom.isFinite ? freedom.floor() : 999999;
    final items = [
      _CheckItem(
        index: 1,
        title: '记录天数超过 30 天',
        done: metrics.trackDays >= 30,
        hint: '继续每天记账',
      ),
      _CheckItem(
        index: 2,
        title: '了解自己的日均消费',
        done: metrics.trackDays >= 7 && metrics.dailyBurn > 0,
        hint: '记满 7 天且有支出记录',
      ),
      _CheckItem(
        index: 3,
        title: '记录了可变现资产',
        done: netWorth > 0,
        hint: '去 Assets 填入现金或资产',
      ),
      _CheckItem(
        index: 4,
        title: '自由天数超过 180 天',
        done: freedom >= 180,
        hint: '提高净值或降低日均消费',
      ),
      _CheckItem(
        index: 5,
        title: '自由天数超过 365 天',
        done: freedom >= 365,
        hint: '继续积累净值或被动收入',
      ),
      _CheckItem(
        index: 6,
        title: '有被动收入来源',
        done: data.passiveSources.isNotEmpty,
        hint: '在 Assets 添加被动收入',
      ),
      _CheckItem(
        index: 7,
        title: '被动覆盖率超过 50%',
        done: passiveRatio >= 0.5,
        hint: '提高被动收入或降低日均消费',
      ),
      _CheckItem(
        index: 8,
        title: '被动收入覆盖日常消费',
        done: passiveRatio >= 1,
        hint: '让被动收入覆盖全部日常消费',
      ),
    ];
    final next = finiteDays < 180
        ? '自由天数 180 天 · 还差 ${180 - finiteDays} 天'
        : finiteDays < 365
        ? '自由天数 365 天 · 还差 ${365 - finiteDays} 天'
        : items
              .where((item) => !item.done)
              .map((item) => item.title)
              .firstOrNull;
    return _CheckSummary(
      items: items,
      done: items.where((item) => item.done).length,
      next: next,
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context,
  String hint, {
  String? prefix,
}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefix,
    prefixStyle: TextStyle(color: context.fg.inkFaint),
    hintStyle: TextStyle(color: context.fg.inkGhost),
    filled: true,
    fillColor: context.fg.paper,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.fg.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: context.fg.skyDeep),
    ),
  );
}

double? _parseAmount(String source) {
  final normalized = source.trim().replaceAll(',', '');
  final value = double.tryParse(normalized);
  if (value == null || value <= 0) return null;
  return value;
}

double? _parseNonNegativeAmount(String source) {
  final normalized = source.trim().replaceAll(',', '');
  final value = double.tryParse(normalized);
  if (value == null || value < 0) return null;
  return value;
}

String _formatDecimal(double value) {
  return value.toStringAsFixed(1);
}

String _formatMoney(double value) {
  return value
      .toStringAsFixed(value.abs() >= 1000 ? 0 : 1)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
}

String _formatPlainNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}

String _formatMonthDay(DateTime value) {
  return '${value.month} 月 ${value.day} 日';
}

String _formatDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
