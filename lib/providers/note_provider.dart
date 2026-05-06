import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class NoteProvider extends ChangeNotifier {
  List<AppNote> _notes = [];
  List<AppNote> get notes => _notes;

  Future<void> loadNotes() async {
    _notes = await DatabaseService.instance.getNotes();
    notifyListeners();
  }

  Future<void> addNote(AppNote note) async {
    final id = await DatabaseService.instance.insertNote(note);
    final saved = note.copyWith(id: id);
    if (saved.hasReminder &&
        saved.reminderDate != null &&
        saved.reminderDate!.isAfter(DateTime.now())) {
      try {
        await NotificationService().scheduleReminder(
          id: id,
          title: '📝 ${saved.title}',
          body: saved.content.length > 80
              ? '${saved.content.substring(0, 80)}...'
              : saved.content,
          scheduledDate: saved.reminderDate!,
        );
      } catch (e) {
        debugPrint('Notification error (ignored): $e');
      }
    }
    _notes.insert(0, saved);
    notifyListeners();
  }

  Future<void> updateNote(AppNote note) async {
    await DatabaseService.instance.updateNote(note);
    if (note.hasReminder &&
        note.reminderDate != null &&
        note.reminderDate!.isAfter(DateTime.now())) {
      try {
        await NotificationService().scheduleReminder(
          id: note.id!,
          title: '📝 ${note.title}',
          body: note.content.length > 80
              ? '${note.content.substring(0, 80)}...'
              : note.content,
          scheduledDate: note.reminderDate!,
        );
      } catch (e) {
        debugPrint('Notification error (ignored): $e');
      }
    } else if (note.id != null) {
      try {
        await NotificationService().cancelReminder(note.id!);
      } catch (e) {
        debugPrint('Cancel notification error (ignored): $e');
      }
    }
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) _notes[idx] = note;
    notifyListeners();
  }

  Future<void> deleteNote(int id) async {
    await DatabaseService.instance.deleteNote(id);
    try {
      await NotificationService().cancelReminder(id);
    } catch (e) {
      debugPrint('Cancel notification error (ignored): $e');
    }
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  List<AppNote> getRemindersForDate(DateTime date) {
    return _notes.where((n) {
      if (!n.hasReminder || n.reminderDate == null) return false;
      final r = n.reminderDate!;
      return r.year == date.year && r.month == date.month && r.day == date.day;
    }).toList();
  }
}
