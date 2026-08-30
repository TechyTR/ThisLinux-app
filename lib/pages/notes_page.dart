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
    final loadedNotes = await NotesService.loadNotes();

    if (!mounted) return;

    setState(() {
      notes = loadedNotes;
      isLoading = false;
    });
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
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
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
                if (contentController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  NoteItem(
                    title: titleController.text.trim().isEmpty
                        ? 'Not'
                        : titleController.text.trim(),
                    content: contentController.text.trim(),
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
    setState(() {
      notes.removeAt(index);
    });

    await _saveNotes();
  }

  void _showNote(NoteItem note) {
    showDialog(
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
                        '${note.createdAt.microsecondsSinceEpoch}_$index',
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
