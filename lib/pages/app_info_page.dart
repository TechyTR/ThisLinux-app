import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/update_button.dart';
import 'battery_lab_page.dart';
import 'benchmark_page.dart';
import 'network_lab_page.dart';
import 'sensor_lab_page.dart';
import 'storage_manager_page.dart';

class AppInfoPage extends StatelessWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  final Future<void> Function(
    AppThemeColor,
  ) onThemeChanged;

  final Future<void> Function(
    AppThemeStyle,
  ) onStyleChanged;

  const AppInfoPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  Widget _themeButton(
    BuildContext context,
    AppThemeColor theme,
  ) {
    final selected =
        selectedTheme == theme;

    final color =
        AppTheme.colorOf(theme);

    final textColor =
        ThemeData.estimateBrightnessForColor(
              color,
            ) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: () {
        onThemeChanged(theme);
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(
          right: 12,
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color
              : Colors.transparent,
          border: Border.all(
            color: color,
            width: 2,
          ),
          borderRadius:
              BorderRadius.circular(30),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color:
                        color.withOpacity(0.32),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          AppTheme.labelOf(theme),
          style: TextStyle(
            color: selected
                ? textColor
                : color,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _styleButton(
    BuildContext context,
    AppThemeStyle style,
    IconData icon,
    String title,
  ) {
    final selected =
        selectedStyle == style;

    return Card(
      margin:
          const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: selected
            ? const Icon(
                Icons.check_circle,
              )
            : null,
        onTap: () {
          onStyleChanged(style);
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

  void _openPage(
    BuildContext context,
    Widget page,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stellar Center',
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding:
            const EdgeInsets.all(20),
        children: [
          Container(
            padding:
                const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(0xFFE53935),
                  Color(0xFFFF9800),
                  Color(0xFFFFD740),
                  Color(0xFF43A047),
                  Color(0xFF1E88E5),
                  Color(0xFF8E24AA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/icon.png',
                  width: 58,
                  height: 58,
                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return const Icon(
                      Icons
                          .auto_awesome_rounded,
                      color: Colors.white,
                      size: 58,
                    );
                  },
                ),
                const SizedBox(height: 18),
                const Text(
                  'Stellar Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Linux',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Sistem yardımcı merkezi',
            style: TextStyle(
              color:
                  scheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Tema',
            style: TextStyle(
              fontWeight:
                  FontWeight.w600,
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
          ),

          const SizedBox(height: 12),

          Text(
            'Görünüm',
            style: TextStyle(
              fontWeight:
                  FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          _styleButton(
            context,
            AppThemeStyle.normal,
            Icons.palette_outlined,
            'Material Design',
          ),

          _styleButton(
            context,
            AppThemeStyle
                .liquidGlassLight,
            Icons.light_mode,
            'Liquid Glass Light',
          ),

          _styleButton(
            context,
            AppThemeStyle
                .liquidGlassDark,
            Icons.dark_mode,
            'Liquid Glass Dark',
          ),

          const SizedBox(height: 12),

          Text(
            'Araçlar',
            style: TextStyle(
              fontWeight:
                  FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          _toolButton(
            icon: Icons.speed,
            title: 'Benchmark',
            subtitle:
                'Cihaz performansını detaylı test et',
            onTap: () {
              _openPage(
                context,
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
                context,
                const StorageManagerPage(),
              );
            },
          ),

          _toolButton(
            icon: Icons.sensors,
            title: 'SensorLab',
            subtitle:
                'Sensörleri incele',
            onTap: () {
              _openPage(
                context,
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
                context,
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
                context,
                const BatteryLabPage(),
              );
            },
          ),

          const SizedBox(height: 12),

          Text(
            'Güncelleme',
            style: TextStyle(
              fontWeight:
                  FontWeight.w600,
              color:
                  scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 12),

          const UpdateButton(
            currentVersion: '2.5',
          ),

          const SizedBox(height: 18),

          Center(
            child: Column(
              children: [
                Text(
                  'Stellar Center',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600,
                    color:
                        scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Linux • v2.5',
                  style: TextStyle(
                    color:
                        scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
