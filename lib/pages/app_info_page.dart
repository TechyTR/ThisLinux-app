import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/app_version.dart';
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

  final Future<void> Function(AppThemeColor) onThemeChanged;
  final Future<void> Function(AppThemeStyle) onStyleChanged;

  const AppInfoPage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
    required this.onThemeChanged,
    required this.onStyleChanged,
  });

  bool _isGlass(BuildContext context) {
    return selectedStyle != AppThemeStyle.normal;
  }

  bool _isLightGlass(BuildContext context) {
    return selectedStyle == AppThemeStyle.liquidGlassLight;
  }

  Color _borderColor(BuildContext context) {
    return _isLightGlass(context)
        ? Colors.white.withOpacity(0.62)
        : Colors.white.withOpacity(0.18);
  }

  Color _fillColor(BuildContext context) {
    return _isLightGlass(context)
        ? Colors.white.withOpacity(0.32)
        : Colors.white.withOpacity(0.065);
  }

  Color _highlightColor(BuildContext context) {
    return _isLightGlass(context)
        ? Colors.white.withOpacity(0.76)
        : Colors.white.withOpacity(0.13);
  }

  Widget _glassCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
    BorderRadiusGeometry radius =
        const BorderRadius.all(Radius.circular(24)),
  }) {
    if (!_isGlass(context)) {
      return Card(
        margin: margin,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              _isLightGlass(context) ? 0.07 : 0.28,
            ),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 26,
            sigmaY: 26,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _fillColor(context),
              borderRadius: radius,
              border: Border.all(
                color: _borderColor(context),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _highlightColor(context),
                  Colors.transparent,
                  _isLightGlass(context)
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white.withOpacity(0.025),
                ],
                stops: const [
                  0.0,
                  0.42,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: _isLightGlass(context)
                            ? Colors.white.withOpacity(0.92)
                            : Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backgroundGlow(BuildContext context) {
    if (!_isGlass(context)) {
      return const SizedBox.shrink();
    }

    final color = AppTheme.colorOf(selectedTheme);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -70,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 70,
                sigmaY: 70,
              ),
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(
                    _isLightGlass(context) ? 0.14 : 0.11,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -110,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 80,
                sigmaY: 80,
              ),
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(
                    _isLightGlass(context) ? 0.07 : 0.065,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeButton(
    BuildContext context,
    AppThemeColor theme,
  ) {
    final selected = selectedTheme == theme;
    final color = AppTheme.colorOf(theme);

    if (!_isGlass(context)) {
      final textColor =
          ThemeData.estimateBrightnessForColor(color) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black;

      return GestureDetector(
        onTap: () {
          onThemeChanged(theme);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(
            right: 10,
            bottom: 10,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            border: Border.all(
              color: color,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.30),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Text(
            AppTheme.labelOf(theme),
            style: TextStyle(
              color: selected ? textColor : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        onThemeChanged(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(
          right: 10,
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(
                  _isLightGlass(context) ? 0.20 : 0.14,
                )
              : Colors.white.withOpacity(
                  _isLightGlass(context) ? 0.10 : 0.035,
                ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.65)
                : _borderColor(context),
            width: selected ? 1.3 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.22),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.45),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Text(
              AppTheme.labelOf(theme),
              style: TextStyle(
                color: selected
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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
    final selected = selectedStyle == style;
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      context,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            onStyleChanged(style);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? scheme.primary.withOpacity(
                            _isGlass(context) ? 0.16 : 0.12,
                          )
                        : Colors.white.withOpacity(
                            _isGlass(context)
                                ? (_isLightGlass(context)
                                    ? 0.14
                                    : 0.045)
                                : 0.06,
                          ),
                    border: _isGlass(context)
                        ? Border.all(
                            color: selected
                                ? scheme.primary.withOpacity(0.42)
                                : _borderColor(context),
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('selected'),
                          color: scheme.primary,
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          key: const ValueKey('not-selected'),
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
      context,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withOpacity(
                      _isGlass(context)
                          ? (_isLightGlass(context)
                              ? 0.12
                              : 0.08)
                          : 0.10,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final themeColor = AppTheme.colorOf(selectedTheme);

    return _glassCard(
      context,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: 14),
      radius: BorderRadius.circular(30),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 205,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeColor.withOpacity(
                _isLightGlass(context) ? 0.20 : 0.16,
              ),
              Colors.white.withOpacity(
                _isLightGlass(context) ? 0.13 : 0.025,
              ),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -35,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 25,
                  sigmaY: 25,
                ),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeColor.withOpacity(0.18),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      _isLightGlass(context) ? 0.22 : 0.07,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        _isLightGlass(context) ? 0.55 : 0.16,
                      ),
                    ),
                  ),
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Icon(
                        Icons.auto_awesome_rounded,
                        color: themeColor,
                        size: 42,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Stellar Center',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Linux sistem yardımcı merkezi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(
                      _isLightGlass(context) ? 0.14 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: themeColor.withOpacity(0.30),
                    ),
                  ),
                  child: Text(
                    'v${AppVersion.current}',
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: _isGlass(context),
      appBar: AppBar(
        title: const Text(
          'Stellar Center',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            _isGlass(context) ? Colors.transparent : null,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _backgroundGlow(context),
          ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              _hero(context),

              Text(
                'Tema',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
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

              const SizedBox(height: 8),

              Text(
                'Görünüm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
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
                AppThemeStyle.liquidGlassLight,
                Icons.light_mode_rounded,
                'Liquid Glass Light',
              ),

              _styleButton(
                context,
                AppThemeStyle.liquidGlassDark,
                Icons.dark_mode_rounded,
                'Liquid Glass Dark',
              ),

              const SizedBox(height: 8),

              Text(
                'Araçlar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              _toolButton(
                context,
                icon: Icons.speed_rounded,
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
                context,
                icon: Icons.storage_rounded,
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
                context,
                icon: Icons.sensors_rounded,
                title: 'SensorLab',
                subtitle: 'Sensörleri incele',
                onTap: () {
                  _openPage(
                    context,
                    const SensorLabPage(),
                  );
                },
              ),

              _toolButton(
                context,
                icon: Icons.network_check_rounded,
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
                context,
                icon: Icons.battery_full_rounded,
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

              const SizedBox(height: 8),

              Text(
                'Güncelleme',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              _glassCard(
                context,
                child: const UpdateButton(
                  currentVersion:
                      AppVersion.current,
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Stellar Center',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Linux • v${AppVersion.current}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

