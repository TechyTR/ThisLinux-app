import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StorageManagerPage extends StatefulWidget {
  const StorageManagerPage({super.key});

  @override
  State<StorageManagerPage> createState() => _StorageManagerPageState();
}

class _StorageManagerPageState extends State<StorageManagerPage>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('org.test.thislinux/native');

  bool _loading = true;
  bool _hasAccess = false;
  int _fileCount = 0;
  int _errors = 0;
  double _totalBytes = 0;

  final Map<String, double> _sizes = {
    'Görseller': 0,
    'Videolar': 0,
    'Ses': 0,
    'Belgeler': 0,
    'APK': 0,
    'Arşivler': 0,
    'Diğer': 0,
  };

  final Map<String, int> _counts = {
    'Görseller': 0,
    'Videolar': 0,
    'Ses': 0,
    'Belgeler': 0,
    'APK': 0,
    'Arşivler': 0,
    'Diğer': 0,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAccess();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final access = await _channel.invokeMethod<bool>('hasStorageAccess') ?? false;
      if (!mounted) return;
      setState(() => _hasAccess = access);
      if (access) {
        await _scanStorage();
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasAccess = false;
        _loading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    try {
      await _channel.invokeMethod('openStorageAccessSettings');
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) await _checkAccess();
  }

  Future<void> _scanStorage() async {
    if (!_hasAccess || _loading) return;
    setState(() {
      _loading = true;
      _fileCount = 0;
      _errors = 0;
      _totalBytes = 0;
      for (final key in _sizes.keys) _sizes[key] = 0;
      for (final key in _counts.keys) _counts[key] = 0;
    });

    final sizes = {for (final key in _sizes.keys) key: 0.0};
    final counts = {for (final key in _counts.keys) key: 0};
    var bytes = 0.0;
    var files = 0;
    var errors = 0;
    var visited = 0;

    Future<void> walk(Directory dir) async {
      try {
        await for (final entity in dir.list(followLinks: false)) {
          try {
            if (entity is File) {
              final size = (await entity.length()).toDouble();
              final category = _categoryFor(entity.path);
              sizes[category] = (sizes[category] ?? 0) + size;
              counts[category] = (counts[category] ?? 0) + 1;
              bytes += size;
              files++;
              visited++;
              if (visited % 80 == 0) {
                await Future<void>.delayed(Duration.zero);
              }
            } else if (entity is Directory) {
              // Do not skip Android/ or other large user-data directories.
              // Inaccessible entries are handled individually and counted as errors.
              await walk(entity);
            }
          } catch (_) {
            errors++;
          }
        }
      } catch (_) {
        errors++;
      }
    }

    try {
      final root = Directory('/storage/emulated/0');
      if (await root.exists()) await walk(root);
    } catch (_) {
      errors++;
    }

    if (!mounted) return;
    setState(() {
      _sizes
        ..clear()
        ..addAll(sizes);
      _counts
        ..clear()
        ..addAll(counts);
      _totalBytes = bytes;
      _fileCount = files;
      _errors = errors;
      _loading = false;
    });
  }

  String _categoryFor(String path) {
    final p = path.toLowerCase();
    if (RegExp(r'\.(jpg|jpeg|png|webp|gif|heic|heif|bmp|tiff|svg)$').hasMatch(p)) return 'Görseller';
    if (RegExp(r'\.(mp4|mkv|avi|mov|webm|3gp|m4v|ts)$').hasMatch(p)) return 'Videolar';
    if (RegExp(r'\.(mp3|wav|ogg|flac|m4a|aac|opus|amr)$').hasMatch(p)) return 'Ses';
    if (p.endsWith('.apk')) return 'APK';
    if (RegExp(r'\.(zip|rar|7z|tar|gz|bz2|xz|iso|img)$').hasMatch(p)) return 'Arşivler';
    if (RegExp(r'\.(pdf|doc|docx|txt|xls|xlsx|ppt|pptx|csv|rtf|odt|ods|odp)$').hasMatch(p)) return 'Belgeler';
    return 'Diğer';
  }

  String _size(double bytes) {
    if (bytes >= 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${bytes.toStringAsFixed(0)} B';
  }

  IconData _icon(String key) => switch (key) {
        'Görseller' => Icons.image_outlined,
        'Videolar' => Icons.video_library_outlined,
        'Ses' => Icons.audiotrack_outlined,
        'Belgeler' => Icons.description_outlined,
        'APK' => Icons.android_outlined,
        'Arşivler' => Icons.archive_outlined,
        _ => Icons.folder_outlined,
      };

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Storage Manager'), centerTitle: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 20),
                const Text('Depolama erişimi gerekli', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Depolamadaki kullanıcı dosyalarının tamamını analiz edebilmek için erişim gerekir.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(onPressed: _openSettings, icon: const Icon(Icons.lock_open), label: const Text('Depolama erişimi ver')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Manager'),
        centerTitle: true,
        actions: [IconButton(onPressed: _loading ? null : _scanStorage, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _scanStorage,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(_size(_totalBytes), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          const Text('Taranan kullanıcı depolaması'),
                          const SizedBox(height: 5),
                          Text('$_fileCount dosya${_errors > 0 ? ' • $_errors erişim atlandı' : ''}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._sizes.entries.map((entry) {
                    final percentage = _totalBytes <= 0 ? 0.0 : entry.value / _totalBytes;
                    final color = Theme.of(context).colorScheme.primary;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: color.withOpacity(0.13), child: Icon(_icon(entry.key), color: color)),
                        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w650)),
                        subtitle: Text('${_counts[entry.key] ?? 0} dosya • ${_size(entry.value)}'),
                        trailing: Text('${(percentage * 100).toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  const Text('Taranabilen tüm kullanıcı depolama klasörleri dahil edilir. Erişilemeyen Android korumalı alanları ayrıca hata sayısında gösterilir.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
    );
  }
}
