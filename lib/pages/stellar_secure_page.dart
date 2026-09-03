import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/app_version.dart';
import '../services/security_service.dart';
import '../theme/app_theme.dart';

class StellarSecurePage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  const StellarSecurePage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
  });

  @override
  State<StellarSecurePage> createState() => _StellarSecurePageState();
}

class _StellarSecurePageState extends State<StellarSecurePage>
    with SingleTickerProviderStateMixin {
  SecurityStatus _status = SecurityStatus.scanRequired;
  bool _protectionEnabled = true;
  bool _scanning = false;
  List<String> _scannedApps = [];
  List<String> _suspiciousApps = [];

  late final AnimationController _scanController;

  bool get _isGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle == AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Color _statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (_status) {
      case SecurityStatus.safe:
        return Colors.green;
      case SecurityStatus.scanRequired:
        return Colors.orange;
      case SecurityStatus.malwareDetected:
        return scheme.error;
    }
  }

  String get _statusText {
    switch (_status) {
      case SecurityStatus.safe:
        return 'Telefonunuz güvende';
      case SecurityStatus.scanRequired:
        return 'Telefonunuzun taranması gerekiyor';
      case SecurityStatus.malwareDetected:
        return 'Kötü amaçlı yazılım göstergesi tespit edildi';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case SecurityStatus.safe:
        return Icons.verified_user_rounded;
      case SecurityStatus.scanRequired:
        return Icons.warning_rounded;
      case SecurityStatus.malwareDetected:
        return Icons.gpp_bad_rounded;
    }
  }

  Future<void> _scan() async {
    if (_scanning) return;

    setState(() {
      _scanning = true;
      _scannedApps = [];
      _suspiciousApps = [];
    });
    _scanController.repeat();

    final result = await SecurityService.scanDevice(
      onAppScanned: (app) {
        if (!mounted || !_scanning) return;
        // Only show a lightweight rolling progress list during the scan.
        setState(() {
          if (_scannedApps.length < 12) {
            _scannedApps = [..._scannedApps, app];
          }
        });
      },
    );

    if (!mounted) return;

    _scanController.stop();
    setState(() {
      _status = result.status;
      _scannedApps = result.scannedApps;
      _suspiciousApps = result.suspiciousApps;
      _scanning = false;
    });
  }

  Widget _glassCard({required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: _isGlass
            ? Colors.white.withOpacity(_isLightGlass ? 0.15 : 0.065)
            : scheme.surfaceContainerHighest,
        border: _isGlass
            ? Border.all(
                color: Colors.white.withOpacity(_isLightGlass ? 0.52 : 0.18),
              )
            : null,
      ),
      child: child,
    );

    if (!_isGlass) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: content,
      ),
    );
  }

  Widget _scanButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primary;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: _isGlass
            ? LinearGradient(
                colors: [
                  accent.withOpacity(_isLightGlass ? 0.30 : 0.22),
                  Colors.white.withOpacity(_isLightGlass ? 0.20 : 0.07),
                ],
              )
            : null,
        color: _isGlass ? null : accent,
        border: _isGlass
            ? Border.all(
                color: Colors.white.withOpacity(_isLightGlass ? 0.50 : 0.18),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(_scanning ? 0.28 : 0.12),
            blurRadius: _scanning ? 18 : 10,
            spreadRadius: _scanning ? 1 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _scanning ? null : _scan,
          splashColor: Colors.white.withOpacity(0.20),
          highlightColor: Colors.white.withOpacity(0.10),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Row(
                key: ValueKey(_scanning),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_scanning)
                    RotationTransition(
                      turns: _scanController,
                      child: const Icon(
                        Icons.radar_rounded,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(Icons.radar_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    _scanning ? 'Telefonunuz taranıyor' : 'Telefonu Tara',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!_isGlass) return button;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: button,
      ),
    );
  }

  Widget _animatedStatus(BuildContext context) {
    final color = _statusColor(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Column(
        key: ValueKey(_status),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.72, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: Icon(_statusIcon, size: 58, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stellar Secure'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          if (_isGlass)
            Positioned(
              top: -100,
              right: -80,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          if (_isGlass)
            Positioned(
              bottom: 80,
              left: -120,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withOpacity(0.055),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _glassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary.withOpacity(0.12),
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          size: 34,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stellar Secure',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v${AppVersion.current}',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Column(
                    children: [
                      _animatedStatus(context),
                      const SizedBox(height: 18),
                      _scanButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: _protectionEnabled ? Colors.green : scheme.error,
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Virüs koruması',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: _protectionEnabled,
                        activeColor: Colors.green,
                        onChanged: (value) => setState(() {
                          _protectionEnabled = value;
                        }),
                      ),
                    ],
                  ),
                ),
                if (_scanning || _scannedApps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.apps_rounded),
                            const SizedBox(width: 10),
                            const Text(
                              'Taranan uygulamalar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Text('${_scannedApps.length}'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_scannedApps.isEmpty)
                          const Text('Uygulamalar hazırlanıyor...')
                        else
                          ..._scannedApps.take(40).map(
                                (app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          app,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
                if (_suspiciousApps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şüpheli uygulamalar',
                          style: TextStyle(
                            color: scheme.error,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._suspiciousApps.map((app) => Text('• $app')),
                      ],
                    ),
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
