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
      builder: (context) {
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
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'İçerik',
                    hintText: 'Not içeriği',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () async {
                await _addNote();

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context);
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
      body: _notes.isEmpty
          ? Center(
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
                    'Henüz not yok.',
                    style: TextStyle(
                      fontSize: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final parsed = _parseNote(note);

                final title = parsed[0];
                final content = parsed[1];

                return Dismissible(
                  key: ValueKey('$note-$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(
                      right: 24,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.error,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) {
                    _deleteNote(index);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty
                                ? 'Başlıksız Not'
                                : title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            color: scheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            content,
                            style: const TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

