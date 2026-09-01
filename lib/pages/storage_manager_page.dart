import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class StorageManagerPage extends StatefulWidget {
  const StorageManagerPage({super.key});

  @override
  State<StorageManagerPage> createState() =>
      _StorageManagerPageState();
}

class _StorageManagerPageState
    extends State<StorageManagerPage> {
  bool _loading = true;

  final Map<String, double> _categories = {
    'Görseller': 0,
    'Videolar': 0,
    'Ses': 0,
    'Belgeler': 0,
    'Diğer': 0,
  };

  double _totalMb = 0;

  @override
  void initState() {
    super.initState();
    _scanStorage();
  }

  Future<void> _scanStorage() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final result = <String, double>{
      'Görseller': 0,
      'Videolar': 0,
      'Ses': 0,
      'Belgeler': 0,
      'Diğer': 0,
    };

    double total = 0;

    try {
      final root =
          Directory('/storage/emulated/0');

      if (await root.exists()) {
        await _scanDirectory(
          root,
          result,
          (size) {
            total += size;
          },
        );
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _categories
        ..clear()
        ..addAll(result);

      _totalMb =
          total / 1024 / 1024;

      _loading = false;
    });
  }

  Future<void> _scanDirectory(
    Directory directory,
    Map<String, double> result,
    void Function(double) addSize,
  ) async {
    List<FileSystemEntity> entities;

    try {
      entities = await directory
          .list(
            followLinks: false,
          )
          .toList();
    } catch (_) {
      return;
    }

    for (final entity in entities) {
      try {
        if (entity is File) {
          final size =
              await entity.length();

          addSize(size);

          final category =
              _categoryFor(entity.path);

          result[category] =
              (result[category] ?? 0) +
                  size;
        } else if (entity is Directory) {
          final name =
              entity.path
                  .split('/')
                  .last;

          if (_shouldSkipDirectory(
            entity.path,
            name,
          )) {
            continue;
          }

          await _scanDirectory(
            entity,
            result,
            addSize,
          );
        }
      } catch (_) {}
    }
  }

  bool _shouldSkipDirectory(
    String path,
    String name,
  ) {
    final lower =
        name.toLowerCase();

    if (lower == 'android') {
      return true;
    }

    if (lower == 'android' ||
        lower == '.thumbnails' ||
        lower == '.trash') {
      return true;
    }

    return path
        .toLowerCase()
        .contains('/android/');
  }

  String _categoryFor(String path) {
    final extension =
        path.toLowerCase();

    if (RegExp(
      r'\.(jpg|jpeg|png|webp|gif|heic|heif|bmp)$',
    ).hasMatch(extension)) {
      return 'Görseller';
    }

    if (RegExp(
      r'\.(mp4|mkv|avi|mov|webm|3gp|m4v)$',
    ).hasMatch(extension)) {
      return 'Videolar';
    }

    if (RegExp(
      r'\.(mp3|wav|ogg|flac|m4a|aac|opus)$',
    ).hasMatch(extension)) {
      return 'Ses';
    }

    if (RegExp(
      r'\.(pdf|doc|docx|txt|xls|xlsx|ppt|pptx|csv|zip|rar|7z)$',
    ).hasMatch(extension)) {
      return 'Belgeler';
    }

    return 'Diğer';
  }

  String _formatSize(double mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }

    if (mb < 1) {
      return '${(mb * 1024).toStringAsFixed(1)} KB';
    }

    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final totalBytes =
        _categories.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final values =
        _categories.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Storage Manager',
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _scanStorage,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(20),
                children: [
                  SizedBox(
                    height: 240,
                    child: CustomPaint(
                      painter:
                          _StorageChartPainter(
                        values: values,
                        backgroundColor:
                            Theme.of(context)
                                .colorScheme
                                .surface,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              _formatSize(
                                _totalMb,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 26,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Taranan alan',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  ..._categories.entries.map(
                    (entry) {
                      final percentage =
                          totalBytes <= 0
                              ? 0
                              : entry.value /
                                  totalBytes *
                                  100;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: ListTile(
                          leading: Icon(
                            _categoryIcon(
                              entry.key,
                            ),
                          ),
                          title:
                              Text(entry.key),
                          subtitle: Text(
                            _formatSize(
                              entry.value /
                                  1024 /
                                  1024,
                            ),
                          ),
                          trailing:
                              Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Android sistem klasörleri '
                    'güvenlik nedeniyle taramaya '
                    'dahil edilmez.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _categoryIcon(
    String category,
  ) {
    switch (category) {
      case 'Görseller':
        return Icons.image_outlined;

      case 'Videolar':
        return Icons.video_library_outlined;

      case 'Ses':
        return Icons.audiotrack_outlined;

      case 'Belgeler':
        return Icons.description_outlined;

      default:
        return Icons.folder_outlined;
    }
  }
}

class _StorageChartPainter
    extends CustomPainter {
  final List<double> values;
  final Color backgroundColor;

  _StorageChartPainter({
    required this.values,
    required this.backgroundColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final total =
        values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        min(
          size.width,
          size.height,
        ) /
            2 -
            10;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.butt
      ..color = backgroundColor;

    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    if (total <= 0) {
      return;
    }

    const colors = [
      Color(0xFF7E57C2),
      Color(0xFF42A5F5),
      Color(0xFF66BB6A),
      Color(0xFFFFA726),
      Color(0xFF78909C),
    ];

    double startAngle = -pi / 2;

    for (var i = 0;
        i < values.length;
        i++) {
      final sweep =
          values[i] /
              total *
              2 *
              pi;

      if (sweep <= 0) {
        continue;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32
        ..strokeCap = StrokeCap.butt
        ..color =
            colors[i % colors.length];

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant _StorageChartPainter oldDelegate,
  ) {
    return oldDelegate.values != values ||
        oldDelegate.backgroundColor !=
            backgroundColor;
  }
}

