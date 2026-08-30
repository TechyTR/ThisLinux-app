import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
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

    final updateInfo = await UpdateService.checkForUpdate(
      currentVersion,
    );

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

    if (uri == null) {
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
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
          color: isSelected ? color : Colors.transparent,
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          AppTheme.labelOf(theme),
          style: TextStyle(
            color: isSelected ? Colors.black : color,
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

        const
