import 'package:flutter/material.dart';

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

    if (!mounted) {
      return;
    }

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

    final isNewer =
        UpdateService.isNewerVersion(
      widget.currentVersion,
      update.latestVersion,
    );

    if (!isNewer) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'ThisLinux v${widget.currentVersion} güncel.',
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
            'Güncelleme mevcut',
          ),
          content: Text(
            'Yeni sürüm: v${update.latestVersion}\n\n'
            'Mevcut sürüm: v${widget.currentVersion}\n\n'
            'Yeni APK indirilecek ve Android kurulum ekranı açılacak.',
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
    if (_installing) {
      return;
    }

    setState(() {
      _installing = true;
    });

    try {

      await UpdateService.downloadAndInstall(
        update.downloadUrl,
      );

    } on Exception catch (error) {

      if (!mounted) {
        return;
      }

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

    return Card(
      margin:
          const EdgeInsets.only(
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
                  : 'Mevcut sürüm: v${widget.currentVersion}',
        ),

        trailing:
            _checking || _installing
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
            _checking || _installing
                ? null
                : _checkForUpdate,
      ),
    );
  }
}
