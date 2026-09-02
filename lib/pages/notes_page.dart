import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({
    super.key,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _contentController =
      TextEditingController();

  List<String> _notes = [];

  bool get _isGlass {
    final brightness = Theme.of(context).brightness;
    final cardTheme = Theme.of(context).cardTheme;

    return cardTheme.shape is RoundedRectangleBorder &&
        (brightness == Brightness.light ||
            brightness == Brightness.dark);
  }

  bool get _isLightGlass {
    return Theme.of(context).brightness == Brightness.light;
  }

  Color get _glassBorder {
    return _isLightGlass
        ? Colors.white.withOpacity(0.62)
        : Colors.white.withOpacity(0.18);
  }

  Color get _glassFill {
    return _isLightGlass
        ? Colors.white.withOpacity(0.34)
        : Colors.white.withOpacity(0.065);
  }

  Color get _glassHighlight {
    return _isLightGlass
        ? Colors.white.withOpacity(0.72)
        : Colors.white.withOpacity(0.12);
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();

    final notes = prefs.getStringList('notes') ?? [];

    if (!mounted) return;

    setState(() {
      _notes = notes;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'notes',
      _notes,
    );
  }

  Future<void> _addNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      return;
    }

    final note = '$title\n$content';

    setState(() {
      _notes.insert(0, note);
      _titleController.clear();
      _contentController.clear();
    });

    await _saveNotes();
  }

  Future<void> _deleteNote(int index) async {
    if (index < 0 || index >= _notes.length) {
      return;
    }

    setState(() {
      _notes.removeAt(index);
    });

    await _saveNotes();
  }

  Future<void> _showAddNoteDialog() async {
    _titleController.clear();
    _contentController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;

        return AlertDialog(
          backgroundColor: _isGlass
              ? (_isLightGlass
                  ? Colors.white.withOpacity(0.72)
                  : const Color(0xFF181A20).withOpacity(0.86))
              : null,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: _isGlass
                ? BorderSide(
                    color: _glassBorder,
                    width: 1,
                  )
                : BorderSide.none,
          ),
          title: const Text('Yeni Not'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Not başlığı',
                    filled: _isGlass,
                    fillColor: _isGlass
                        ? Colors.white.withOpacity(
                            _isLightGlass ? 0.24 : 0.055,
                          )
                        : null,
                    border: _isGlass
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _glassBorder,
                            ),
                          )
                        : null,
                    enabledBorder: _isGlass
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _glassBorder,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'İçerik',
                    hintText: 'Not içeriği',
                    filled: _isGlass,
                    fillColor: _isGlass
                        ? Colors.white.withOpacity(
                            _isLightGlass ? 0.24 : 0.055,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    enabledBorder: _isGlass
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _glassBorder,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                await _addNote();

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(dialogContext);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  List<String> _parseNote(String note) {
    final lines = note.split('\n');

    if (lines.isEmpty) {
      return ['', ''];
    }

    final title = lines.first;

    final content = lines.length > 1
        ? lines.sublist(1).join('\n')
        : '';

    return [
      title,
      content,
    ];
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.all(18),
    EdgeInsetsGeometry margin =
        const EdgeInsets.only(bottom: 14),
    BorderRadiusGeometry radius =
        const BorderRadius.all(Radius.circular(24)),
  }) {
    if (!_isGlass) {
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
              _isLightGlass ? 0.08 : 0.28,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: _glassFill,
              borderRadius: radius,
              border: Border.all(
                color: _glassBorder,
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _glassHighlight,
                  Colors.transparent,
                  _isLightGlass
                      ? Colors.white.withOpacity(0.16)
                      : Colors.white.withOpacity(0.025),
                ],
                stops: const [
                  0.0,
                  0.38,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: _isLightGlass
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.20),
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

  Widget _backgroundGlow() {
    if (!_isGlass) {
      return const SizedBox.shrink();
    }

    final themeColor =
        Theme.of(context).colorScheme.primary;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 65,
                sigmaY: 65,
              ),
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withOpacity(
                    _isLightGlass ? 0.14 : 0.12,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: 70,
                sigmaY: 70,
              ),
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withOpacity(
                    _isLightGlass ? 0.08 : 0.08,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: _glassCard(
        margin: const EdgeInsets.symmetric(
          horizontal: 28,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_outlined,
              size: 58,
              color: scheme.primary.withOpacity(0.85),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz not yok.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Yeni bir not oluşturmak için + düğmesine dokun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteCard({
    required int index,
    required String title,
    required String content,
  }) {
    final scheme = Theme.of(context).colorScheme;

    final note = _notes[index];

    return Dismissible(
      key: ValueKey('$note-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 26),
        decoration: BoxDecoration(
          color: scheme.error.withOpacity(
            _isGlass ? 0.55 : 1,
          ),
          borderRadius: BorderRadius.circular(24),
          border: _isGlass
              ? Border.all(
                  color: Colors.white.withOpacity(0.20),
                )
              : null,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 27,
        ),
      ),
      onDismissed: (_) {
        _deleteNote(index);
      },
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title.isEmpty
                        ? 'Başlıksız Not'
                        : title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (_isGlass)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(
                      top: 7,
                      left: 10,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withOpacity(
                        0.75,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary
                              .withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.outlineVariant.withOpacity(
                      _isGlass ? 0.65 : 1,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              content.isEmpty
                  ? 'Boş not'
                  : content,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: content.isEmpty
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _isGlass,
      appBar: AppBar(
        title: const Text(
          'Notlar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            _isGlass ? Colors.transparent : null,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        elevation: _isGlass ? 0 : 6,
        backgroundColor: _isGlass
            ? Colors.white.withOpacity(
                _isLightGlass ? 0.32 : 0.10,
              )
            : null,
        foregroundColor:
            Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: _isGlass
              ? BorderSide(
                  color: _glassBorder,
                )
              : BorderSide.none,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: Stack(
        children: [
          _backgroundGlow(),
          if (_notes.isEmpty)
            _emptyState()
          else
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                110,
              ),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final parsed =
                    _parseNote(_notes[index]);

                return _noteCard(
                  index: index,
                  title: parsed[0],
                  content: parsed[1],
                );
              },
            ),
        ],
      ),
    );
  }
}

