import 'package:flutter/material.dart';

import '../models/note_item.dart';
import '../services/notes_service.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<NoteItem> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final loadedNotes = await NotesService.loadNotes();

      if (!mounted) return;

      setState(() {
        notes = loadedNotes;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        notes = [];
        isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    await NotesService.saveNotes(notes);
  }

  Future<void> _addNote() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<NoteItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Not'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Not',
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
              onPressed: () {
                final content = contentController.text.trim();

                if (content.isEmpty) {
                  return;
                }

                final title = titleController.text.trim();

                Navigator.pop(
                  context,
                  NoteItem(
                    title: title.isEmpty ? 'Not' : title,
                    content: content,
                    createdAt: DateTime.now(),
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    contentController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      notes.insert(0, result);
    });

    await _saveNotes();
  }

  Future<void> _deleteNote(int index) async {
    if (index < 0 || index >= notes.length) {
      return;
    }

    final deletedNote = notes[index];

    setState(() {
      notes.removeAt(index);
    });

    try {
      await _saveNotes();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        notes.insert(index, deletedNote);
      });
    }
  }

  void _showNote(NoteItem note) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(note.title),
          content: SingleChildScrollView(
            child: Text(note.content),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notlar'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : notes.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz not yok.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];

                    return Dismissible(
                      key: ValueKey(
                        note.createdAt.microsecondsSinceEpoch,
                      ),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                      onDismissed: (_) => _deleteNote(index),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _showNote(note),
                          leading: const Icon(Icons.note_outlined),
                          title: Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
