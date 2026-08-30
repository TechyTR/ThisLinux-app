import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller =
      TextEditingController();

  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs =
        await SharedPreferences.getInstance();

    final notes =
        prefs.getStringList('notes') ?? [];

    if (!mounted) return;

    setState(() {
      _notes = notes;
    });
  }

  Future<void> _saveNotes() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setStringList(
      'notes',
      _notes,
    );
  }

  Future<void> _addNote() async {
    final text =
        _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _notes.insert(0, text);
      _controller.clear();
    });

    await _saveNotes();
  }

  Future<void> _deleteNote(int index) async {
    final deletedNote = _notes[index];

    setState(() {
      _notes.removeAt(index);
    });

    await _saveNotes();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Not silindi.',
        ),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () async {
            setState(() {
              _notes.insert(
                index.clamp(0, _notes.length),
                deletedNote,
              );
            });

            await _saveNotes();
          },
        ),
      ),
    );
  }

  Future<void> _showAddNoteDialog() async {
    _controller.clear();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Yeni Not',
          ),
          content: TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Notunuzu yazın...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'İptal',
              ),
            ),
            FilledButton(
              onPressed: () async {
                await _addNote();

                if (!context.mounted) return;

                Navigator.pop(context);
              },
              child: const Text(
                'Kaydet',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme =
        Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notlar',
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(
          Icons.add,
        ),
      ),
      body: _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 64,
                    color:
                        scheme.onSurfaceVariant,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    'Henüz not yok.',
                    style: TextStyle(
                      fontSize: 18,
                      color:
                          scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              itemCount: _notes.length,
              itemBuilder:
                  (context, index) {
                final note =
                    _notes[index];

                return Dismissible(
                  key: ValueKey(
                    '$note-$index',
                  ),
                  direction:
                      DismissDirection.endToStart,
                  background: Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    alignment:
                        Alignment.centerRight,
                    padding:
                        const EdgeInsets.only(
                      right: 24,
                    ),
                    decoration:
                        BoxDecoration(
                      color: scheme.error,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
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
                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: ListTile(
                      contentPadding:
                         
