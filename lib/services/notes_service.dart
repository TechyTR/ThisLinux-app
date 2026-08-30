import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_item.dart';

class NotesService {
  static const String _notesKey = 'notes_list';

  static Future<List<NoteItem>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_notesKey);

    if (saved == null) {
      return [];
    }

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;

      return decoded
          .map(
            (item) => NoteItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNotes(List<NoteItem> notes) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      notes.map((note) => note.toJson()).toList(),
    );

    await prefs.setString(_notesKey, encoded);
  }
}
