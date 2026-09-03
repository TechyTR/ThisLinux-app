import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/security_service.dart';
import '../theme/app_theme.dart';
import '../services/app_version.dart';

class StellarSecurePage extends StatefulWidget {
  final AppThemeColor selectedTheme;
  final AppThemeStyle selectedStyle;

  const StellarSecurePage({
    super.key,
    required this.selectedTheme,
    required this.selectedStyle,
  });

  @override
  State<StellarSecurePage> createState() =>
      _StellarSecurePageState();
}

class _StellarSecurePageState
    extends State<StellarSecurePage> {
  SecurityStatus _status =
      SecurityStatus.scanRequired;

  bool _protectionEnabled = true;
  bool _scanning = false;

  List<String> _scannedApps = [];
  List<String> _suspiciousApps = [];

  bool get _isGlass =>
      widget.selectedStyle ==
          AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle ==
          AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle ==
      AppThemeStyle.liquidGlassLight;

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
        return 'Telefonda Kötü Amaçlı Yazılım Tespit Edildi';
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case SecurityStatus.safe:
        return Icons.check_circle_rounded;

      case SecurityStatus.scanRequired:
        return Icons.warning_rounded;

      case SecurityStatus.malwareDetected:
        return Icons.dangerous_rounded;
    }
  }

  Future<void> _scan() async {
    if (_scanning) return;

    setState(() {
      _scanning = true;
      _status = SecurityStatus.scanRequired;
      _scannedApps = [];
      _suspiciousApps = [];
    });

    final result =
        await SecurityService.scanDevice(
      onAppScanned: (app) {
        if (!mounted) return;

        setState(() {
          _scannedApps.add(app);
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _status = result.status;
      _scannedApps = result.scannedApps;
      _suspiciousApps = result.suspiciousApps;
      _scanning = false;
    });
  }

  Widget _glassCard({
    required Widget child,
  }) {
    final scheme = Theme.of(context).colorScheme;

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: _isGlass
            ? Colors.white.withOpacity(
                _isLightGlass ? 0.15 : 0.065,
              )
            : scheme.surfaceContainerHighest,
        border: _isGlass
            ? Border.all(
                color: Colors.white.withOpacity(
                  _isLightGlass ? 0.52 : 0.18,
                ),
              )
            : null,
      ),
      child: child,
    );

    if (_isGlass) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 25,
            sigmaY: 25,
          ),
          child: content,
        ),
      );
    }

    return content;
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
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.10),
                ),
              ),
            ),
          if (_isGlass)
            Positioned(
              bottom: 80,
              left: -120,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withOpacity(0.07),
                ),
              ),
            ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                30,
              ),
              children: [
                _glassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              scheme.primary.withOpacity(0.12),
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                              style: TextStyle(
                                color:
                                    scheme.onSurfaceVariant,
                              ),
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
                      Icon(
                        _statusIcon,
                        size: 54,
                        color: statusColor,
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
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _scanning ? null : _scan,
                          icon: _scanning
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.radar_rounded,
                                ),
                          label: Text(
                            _scanning
                                ? 'Telefonunuz taranıyor'
                                : 'Telefonu Tara',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: _protectionEnabled
                            ? Colors.green
                            : scheme.error,
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
                        onChanged: (value) {
                          setState(() {
                            _protectionEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (_scanning || _scannedApps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _glassCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.apps_rounded,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Taranan uygulamalar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_scannedApps.length}',
                              style: TextStyle(
                                color:
                                    scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_scannedApps.isEmpty)
                          const Text(
                            'Uygulamalar hazırlanıyor...',
                          )
                        else
                          ..._scannedApps
                              .take(40)
                              .map(
                                (app) => Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 9,
                                  ),
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
                                          overflow:
                                              TextOverflow.ellipsis,
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                        ..._suspiciousApps.map(
                          (app) => Text('• $app'),
                        ),
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
