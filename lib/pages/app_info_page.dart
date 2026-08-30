import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_theme.dart';

class AppInfoPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final Future<void> Function(AppThemeColor) onThemeChanged;

  const AppInfoPage({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String currentVersion = 'Yükleniyor...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      if (!mounted) return;

      setState(() {
        currentVersion = packageInfo.version;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        currentVersion = 'Bilinmiyor';
      });
    }
  }

  Widget _themeButton(
    BuildContext context,
    AppThemeColor theme,
  ) {
    final isSelected = widget.selectedTheme == theme;
    final color = AppTheme.colorOf(theme);

    return GestureDetector(
      onTap: () => widget.onThemeChanged(theme),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(
          right: 12,
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : Colors.transparent,
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          AppTheme.labelOf(theme),
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Uygulama',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Tema',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          children: AppThemeColor.values
              .map(
                (theme) => _themeButton(
                  context,
                  theme,
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: scheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Sürüm v$currentVersion',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
