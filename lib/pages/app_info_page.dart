import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/benchmark_page.dart';
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

    final updateInfo =
        await UpdateService.checkForUpdate(
      currentVersion,
    );

    if (!mounted) return;

    setState(() {
      isCheckingUpdate = false;
    });

    if (updateInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uygulamanız güncel.',
          ),
        ),
      );

      return;
    }

    final shouldUpdate =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Güncelleme mevcut',
          ),
          content: Text(
            'Yeni sürüm: '
            '${updateInfo.latestVersion}\n\n'
            'Mevcut sürüm: '
            '$currentVersion',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'APK\'yı Aç',
              ),
            ),
          ],
        );
      },
    );

    if (shouldUpdate != true) {
      return;
    }

    final uri =
        Uri.tryParse(
      updateInfo.downloadUrl,
    );

    if (uri == null) {
      _showUpdateError();
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showUpdateError();
      }
    } catch (_) {
      _showUpdateError();
    }
  }

  void _showUpdateError() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Güncelleme dosyası açılamadı.',
        ),
      ),
    );
  }

  Widget _themeButton(
    AppThemeColor theme,
  ) {
    final isSelected =
        widget.selectedTheme == theme;

    final color =
        AppTheme.colorOf(theme);

    return GestureDetector(
      onTap: () {
        widget.onThemeChanged(theme);
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 200,
        ),
        margin:
            const EdgeInsets.only(
          right: 12,
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration:
            BoxDecoration(
          color: isSelected
              ? color
              : Colors.transparent,
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius:
              BorderRadius.circular(
            30,
          ),
        ),
        child: Text(
          AppTheme.labelOf(theme),
          style: TextStyle(
            color: isSelected
                ? Colors.black
                : color,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _sectionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 6,
        ),
        leading: Icon(
          icon,
          color: scheme.primary,
        ),
        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Uygulama'),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          const Text(
            'ThisLinux',
            style: TextStyle(
              fontSize: 32,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Sistem yardımcı uygulaması',
            style: TextStyle(
              fontSize: 15,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          Text(
            'Tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Wrap(
            children:
                AppThemeColor.values
                    .map(
                      (theme) =>
                          _themeButton(
                        theme,
                      ),
                    )
                    .toList(),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            'Araçlar',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _sectionButton(
            icon: Icons.speed,
            title: 'Benchmark',
            subtitle:
                'Cihaz performansını test et',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const BenchmarkPage(),
                ),
              );
            },
          ),

          _sectionButton(
            icon: Icons.storage,
            title:
                'Storage Manager',
            subtitle:
                'Depolama kullanımını incele',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Storage Manager yakında.',
                  ),
                ),
              );
            },
          ),

          _sectionButton(
            icon: Icons.sensors,
            title: 'SensorLab',
            subtitle:
                'Sensör bilgilerini görüntüle',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'SensorLab yakında.',
                  ),
                ),
              );
            },
          ),

          _sectionButton(
            icon: Icons.network_check,
            title: 'Network Lab',
            subtitle:
                'Ağ bağlantısını incele',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Network Lab yakında.',
                  ),
                ),
              );
            },
          ),

          _sectionButton(
            icon: Icons.battery_full,
            title: 'Battery Lab',
            subtitle:
                'Pil durumunu incele',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Battery Lab yakında.',
                  ),
                ),
              );
            },
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            height: 52,
            child:
                FilledButton.icon(
              onPressed:
                  isCheckingUpdate
                      ? null
                      : _checkForUpdate,
              icon: isCheckingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
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

          const SizedBox(
            height: 24,
          ),

          Center(
            child: Text(
              'ThisLinux v$currentVersion',
              style: TextStyle(
                color:
                    scheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}
