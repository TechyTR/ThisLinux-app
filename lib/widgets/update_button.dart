import 'package:flutter/material.dart';

import '../services/app_version.dart';
import '../services/update_service.dart';

class UpdateButton extends StatefulWidget {
  final String currentVersion;

  const UpdateButton({
    super.key,
    required this.currentVersion,
  });

  @override
  State<UpdateButton> createState() =>
      _UpdateButtonState();
}

class _UpdateButtonState
    extends State<UpdateButton> {
  bool _checking = false;
  bool _installing = false;

  Future<void> _checkForUpdate() async {
    if (_checking || _installing) {
      return;
    }

    setState(() {
      _checking = true;
    });

    final update =
        await UpdateService.checkForUpdate();

    if (!mounted) return;

    setState(() {
      _checking = false;
    });

    if (update == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Güncelleme kontrolü başarısız.',
          ),
        ),
      );

      return;
    }

    final newer =
        UpdateService.isNewerVersion(
      AppVersion.current,
      update.latestVersion,
    );

    if (!newer) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Stellar Center v${AppVersion.current} güncel.',
          ),
        ),
      );

      return;
    }

    _showUpdateDialog(update);
  }

  void _showUpdateDialog(
    UpdateInfo update,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Yeni Stellar sürümü',
          ),
          content: Text(
            'Yeni sürüm: '
            'v${update.latestVersion}\n\n'
            'Mevcut sürüm: '
            'v${AppVersion.current}\n\n'
            'APK indirilecek ve Android '
            'kurulum ekranı açılacak.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _installUpdate(update);
              },
              child: const Text(
                'Güncelle',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _installUpdate(
    UpdateInfo update,
  ) async {
    if (_installing) return;

    setState(() {
      _installing = true;
    });

    try {
      await UpdateService.downloadAndInstall(
        update.downloadUrl,
      );
    } on Exception catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Güncelleme başlatılamadı: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _installing = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final scheme =
        Theme.of(context).colorScheme;

    final busy =
        _checking || _installing;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: Icon(
          Icons.system_update_outlined,
          color: scheme.primary,
        ),
        title: const Text(
          'Güncellemeleri kontrol et',
        ),
        subtitle: Text(
          _installing
              ? 'APK indiriliyor...'
              : _checking
                  ? 'Güncellemeler kontrol ediliyor...'
                  : 'Stellar Center v${AppVersion.current}',
        ),
        trailing: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.chevron_right,
              ),
        onTap:
            busy
                ? null
                : _checkForUpdate,
      ),
    );
  }
}
