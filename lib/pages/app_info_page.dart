import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_theme.dart';
import 'battery_lab_page.dart';
import 'benchmark_page.dart';
import 'network_lab_page.dart';
import 'sensor_lab_page.dart';
import 'storage_manager_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

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
            const Duration(milliseconds: 200),
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
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : Colors.transparent,
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius:
              BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        color.withOpacity(0.30),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
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

  Widget _styleButton(
    AppThemeStyle style,
    IconData icon,
    String title,
  ) {
    final isSelected =
        widget.selectedStyle == style;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: isSelected
            ? const Icon(Icons.check_circle)
            : null,
        onTap: () {
          widget.onStyleChanged(style);
        },
      ),
    );
  }

  Widget _toolButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing:
            const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama'),
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sistem yardımcı uygulaması',
            style: TextStyle(
              color:
                  scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Tema',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            children:
                AppThemeColor.values
                    .map(
                      (theme) =>
                          _themeButton(
                        context,
                        theme,
                      ),
                    )
                    .toList(),
          ),          const SizedBox(height: 12),
          Text(
            'Görünüm',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _styleButton(
            AppThemeStyle.normal,
            Icons.palette_outlined,
            'Material Design',
          ),
          _styleButton(
            AppThemeStyle.liquidGlassLight,
            Icons.light_mode,
            'Liquid Glass Light',
          ),
          _styleButton(
            AppThemeStyle.liquidGlassDark,
            Icons.dark_mode,
            'Liquid Glass Dark',
          ),
          const SizedBox(height: 12),
          Text(
            'Araçlar',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _toolButton(
            icon: Icons.speed,
            title: 'Benchmark',
            subtitle:
                'Cihaz performansını test et',
            onTap: () {
              _openPage(
                const BenchmarkPage(),
              );
            },
          ),
          _toolButton(
            icon: Icons.storage,
            title: 'Storage Manager',
            subtitle:
                'Depolama kullanımını incele',
            onTap: () {
              _openPage(
                const StorageManagerPage(),
              );
            },
          ),
          _toolButton(
            icon: Icons.sensors,
            title: 'SensorLab',
            subtitle:
                'Sensör bilgilerini incele',
            onTap: () {
              _openPage(
                const SensorLabPage(),
              );
            },
          ),
          _toolButton(
            icon: Icons.network_check,
            title: 'Network Lab',
            subtitle:
                'Ağ bağlantısını incele',
            onTap: () {
              _openPage(
                const NetworkLabPage(),
              );
            },
          ),
          _toolButton(
            icon: Icons.battery_full,
            title: 'Battery Lab',
            subtitle:
                'Pil durumunu incele',
            onTap: () {
              _openPage(
                const BatteryLabPage(),
              );
            },
          ),
          const SizedBox(height: 24),
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
        ],
      ),
    );
  }
}
