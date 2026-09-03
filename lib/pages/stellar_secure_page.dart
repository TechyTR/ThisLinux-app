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
  State<StellarSecurePage> createState() => _StellarSecurePageState();
}

class _StellarSecurePageState extends State<StellarSecurePage> {
  bool _protectionEnabled = true;
  bool _scanning = false;

  SecurityStatus _status = SecurityStatus.safe;

  List<String> _scannedApps = [];

  bool get _isGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight ||
      widget.selectedStyle == AppThemeStyle.liquidGlassDark;

  bool get _isLightGlass =>
      widget.selectedStyle == AppThemeStyle.liquidGlassLight;

  Color get _statusColor {
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

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 24,
  }) {
    if (!_isGlass) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 25,
          sigmaY: 25,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withOpacity(
              _isLightGlass ? 0.17 : 0.07,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(
                _isLightGlass ? 0.60 : 0.21,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  _isLightGlass ? 0.06 : 0.18,
                ),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: padding,
                child: child,
              ),
              Positioned(
                left: 16,
                right: 16,
                top: 0,
                height: 1.5,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(
                            _isLightGlass ? 0.80 : 0.38,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    return _glassCard(
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor.withOpacity(0.13),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withOpacity(0.22),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              _status == SecurityStatus.malwareDetected
                  ? Icons.close_rounded
                  : _status == SecurityStatus.scanRequired
                      ? Icons.priority_high_rounded
                      : Icons.check_rounded,
              color: _statusColor,
              size: 46,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Stellar Secure',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _protectionCard() {
    final scheme = Theme.of(context).colorScheme;

    return _glassCard(
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
    );
  }

  Future<void> _scan() async {
    if (_scanning) return;

    setState(() {
      _scanning = true;
      _scannedApps = [];
      _status = SecurityStatus.scanRequired;
    });

    final result = await SecurityService.scanDevice(
      onAppScanned: (app) {
        if (!mounted) return;

        setState(() {
          _scannedApps = [
            ..._scannedApps,
            app,
          ];
        });
      },
    );

    if (!mounted) return;

    setState(() {
      _scanning = false;
      _status = result.status;
    });
  }

  Widget _scanButton() {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _scanning ? null : _scan,
        icon: _scanning
            ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                ),
              )
            : const Icon(Icons.radar_rounded),
        label: Text(
          _scanning
              ? 'Telefonunuz taranıyor'
              : 'Telefonu Tara',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _appsCard() {
    if (!_scanning && _scannedApps.isEmpty) {
      return const SizedBox.shrink();
    }

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Taranan uygulamalar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (_scannedApps.isEmpty)
            const Text(
              'Uygulamalar hazırlanıyor...',
            )
          else
            ..._scannedApps.map(
              (app) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 9,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apps_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        app,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 19,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stellar Secure',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),
          children: [
            _glassCard(
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(
                        _isGlass ? 0.10 : 0.13,
                      ),
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: scheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stellar Secure',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Güvenlik merkezi • v${AppVersion.current}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _statusCard(),
            const SizedBox(height: 12),
            _protectionCard(),
            const SizedBox(height: 12),
            _scanButton(),
            const SizedBox(height: 12),
            _appsCard(),
          ],
        ),
      ),
    );
  }
}
