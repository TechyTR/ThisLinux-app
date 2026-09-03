import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  List<String> _notes = [];

  bool get _isGlass {
    final style = Theme.of(context).brightness;
    return style == Brightness.dark ||
        Theme.of(context).cardTheme.shape != null;
  }

  bool get _isLightGlass {
    return Theme.of(context).brightness == Brightness.light;
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
    await prefs.setStringList('notes', _notes);
  }

  Future<void> _addNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) return;

    setState(() {
      _notes.insert(0, '$title\n$content');
    });

    _titleController.clear();
    _contentController.clear();

    await _saveNotes();
  }

  Future<void> _deleteNote(int index) async {
    if (index < 0 || index >= _notes.length) return;

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
        return AlertDialog(
          title: const Text('Yeni Not'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Not başlığı',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contentController,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    hintText: 'Not içeriği',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                await _addNote();

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
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

    return [
      lines.first,
      lines.length > 1 ? lines.sublist(1).join('\n') : '',
    ];
  }

  Widget _noteCard(
    BuildContext context,
    int index,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final parsed = _parseNote(_notes[index]);

    final title = parsed[0];
    final content = parsed[1];

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: _isGlass
            ? Colors.white.withOpacity(
                _isLightGlass ? 0.16 : 0.065,
              )
            : scheme.surfaceContainerHighest,
        border: _isGlass
            ? Border.all(
                color: Colors.white.withOpacity(
                  _isLightGlass ? 0.48 : 0.18,
                ),
              )
            : null,
        boxShadow: _isGlass
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    _isLightGlass ? 0.06 : 0.20,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? 'Başlıksız Not' : title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Divider(
              color: scheme.outlineVariant.withOpacity(0.45),
            ),
            const SizedBox(height: 8),
            Text(
              content.isEmpty ? 'Boş not' : content,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    if (_isGlass) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 22,
            sigmaY: 22,
          ),
          child: card,
        ),
      );
    }

    return Dismissible(
      key: ValueKey('${_notes[index]}-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => _deleteNote(index),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 82),
        child: FloatingActionButton(
          onPressed: _showAddNoteDialog,
          elevation: _isGlass ? 0 : 6,
          backgroundColor: _isGlass
              ? Colors.white.withOpacity(
                  _isLightGlass ? 0.32 : 0.12,
                )
              : null,
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: _isGlass
                ? BorderSide(
                    color: Colors.white.withOpacity(
                      _isLightGlass ? 0.55 : 0.22,
                    ),
                  )
                : BorderSide.none,
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 28,
          ),
        ),
      ),
      body: _notes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 64,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz not yok',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni bir not oluşturmak için + düğmesine dokun.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                110,
              ),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return _noteCard(context, index);
              },
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
