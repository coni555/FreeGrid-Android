import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/platform/freegrid_platform.dart';
import '../../../app/theme/freegrid_theme.dart';

typedef VersionLoader = Future<String> Function();
typedef ExternalUrlOpener = Future<bool> Function(Uri url);

class AboutPage extends StatefulWidget {
  const AboutPage({
    this.loadVersion = FreeGridPlatform.appVersion,
    this.openExternalUrl = FreeGridPlatform.openExternalUrl,
    super.key,
  });

  static final privacyUrl = Uri.parse(
    'https://github.com/coni555/FreeGrid-Freedom/blob/main/PRIVACY.md',
  );
  static const privacyRowKey = ValueKey('about-privacy-policy');

  final VersionLoader loadVersion;
  final ExternalUrlOpener openExternalUrl;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  var _version = '读取中…';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final value = await widget.loadVersion();
      if (mounted) setState(() => _version = value);
    } on PlatformException {
      if (mounted) setState(() => _version = '—');
    }
  }

  Future<void> _openPrivacyPolicy() async {
    HapticFeedback.selectionClick();
    final opened = await widget.openExternalUrl(AboutPage.privacyUrl);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('未找到可打开网页的应用')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fg.paper,
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _BrandCard(),
          const SizedBox(height: 14),
          _AboutCard(
            child: Column(
              children: [
                _AboutRow(
                  icon: Icons.info_outline_rounded,
                  title: '版本',
                  trailing: _version,
                ),
                Divider(height: 1, color: context.fg.hairlineSoft),
                _AboutRow(
                  key: AboutPage.privacyRowKey,
                  icon: Icons.privacy_tip_outlined,
                  title: '隐私政策',
                  trailingIcon: Icons.open_in_new_rounded,
                  onTap: _openPrivacyPolicy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _PrivacyPromiseCard(),
        ],
      ),
    );
  }
}

class _BrandCard extends StatelessWidget {
  const _BrandCard();

  @override
  Widget build(BuildContext context) {
    return _AboutCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.fg.inkMuted, width: 1.2),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.fg.sky,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'FreeGrid',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: context.fg.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '通往财富自由之路',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.fg.inkFaint),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _PromiseChip('本机存储'),
                _PromiseChip('离线可用'),
                _PromiseChip('无需账号'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromiseChip extends StatelessWidget {
  const _PromiseChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: context.fg.skyFaint,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.fg.skySoft.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: context.fg.skyDeep,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PrivacyPromiseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.fg.skyFaint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.fg.skySoft.withValues(alpha: 0.65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: context.fg.skyDeep, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '数据只留在你的设备上',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.fg.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'FreeGrid Android 不需要账号，不上传财务数据，也没有广告或行为埋点。删除 App 前，请先导出 JSON 备份。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.fg.inkMuted,
                    height: 1.55,
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

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.fg.mist,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.fg.hairline),
      ),
      child: child,
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    this.trailing,
    this.trailingIcon,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: context.fg.inkMuted, size: 20),
            const SizedBox(width: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.fg.ink),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing!,
                style: context.numberStyle(
                  13,
                  color: context.fg.inkFaint,
                  weight: FontWeight.w400,
                ),
              ),
            if (trailingIcon != null)
              Icon(trailingIcon, color: context.fg.inkGhost, size: 17),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: onTap == null ? '$title，${trailing ?? ''}' : '$title，在浏览器中打开',
      child: ExcludeSemantics(child: row),
    );
  }
}
