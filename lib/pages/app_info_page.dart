import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../theme/app_theme.dart';

class AppInfoPage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;
  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const AppInfoPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String currentVersion = 'Yükleniyor...';
  bool isCheckingUpdate = false;

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

  Future<void> _checkForUpdate() async {
    if (isCheckingUpdate) return;

    setState(() {
      isCheckingUpdate = true;
    });

    final updateInfo =
        await UpdateService.checkForUpdate(currentVersion);

    if (!mounted) return;

    setState(() {
      isCheckingUpdate = false;
    });

    if (updateInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uygulamanız güncel.'),
        ),
      );
      return;
    }

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Güncelleme mevcut'),
          content: Text(
            'Yeni sürüm: ${updateInfo.latestVersion}\n\n'
            'Mevcut sürüm: $currentVersion',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Güncellemeyi Aç'),
            ),
          ],
        );
      },
    );

    if (shouldOpen != true) return;

    final uri = Uri.tryParse(updateInfo.downloadUrl);

    if (uri == null) return;

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Widget _themeButton(AppThemeColor theme) {
    final isSelected =
        widget.selectedTheme == theme;

    final color = AppTheme.colorOf(theme);

    return GestureDetector(
      onTap: () {
        widget.onThemeChanged(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(
          right: 10,
          bottom: 10,
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
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 220),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppTheme.labelOf(theme),
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : color,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w600,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check,
                size: 18,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _styleButton(AppThemeStyle style) {
    final isSelected =
        widget.selectedStyle == style;

    final isLight =
        style == AppThemeStyle.liquidGlassLight;

    final color =
        AppTheme.colorOf(widget.selectedTheme);

    return GestureDetector(
      onTap: () {
        widget.onStyleChanged(style);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(
                  isLight ? 0.18 : 0.28,
                )
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : Colors.transparent,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              style == AppThemeStyle.normal
                  ? Icons.palette_outlined
                  : Icons.blur_on,
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppTheme.styleLabelOf(style),
                style: TextStyle(
                  fontWeight: isSelected
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Hakkında'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'ThisLinux',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Sistem yardımcı uygulaması',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Renk Teması',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            children: AppThemeColor.values.map(
              (theme) {
                return _themeButton(theme);
              },
            ).toList(),
          ),

          const SizedBox(height: 24),

          Text(
            'Görünüm',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          _styleButton(
            AppThemeStyle.normal,
          ),

          _styleButton(
            AppThemeStyle.liquidGlassLight,
          ),

          _styleButton(
            AppThemeStyle.liquidGlassDark,
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: isCheckingUpdate
                  ? null
                  : _checkForUpdate,
              icon: isCheckingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.system_update,
                    ),
              label: Text(
                isCheckingUpdate
                    ? 'Kontrol ediliyor...'
                    : 'Güncellemeleri kontrol et',
              ),
            ),
          ),

          const SizedBox(height: 30),

          Center(
            child: Text(
              'Sürüm v$currentVersion',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
