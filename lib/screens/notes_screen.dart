import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
    });
  }

  void _openNote({AppNote? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    bool hasReminder = existing?.hasReminder ?? false;
    DateTime? reminderDate = existing?.reminderDate;
    final author = 'Pengguna WalletScript';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.outline, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),

                // Title
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppTheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    hintText: 'Judul',
                    hintStyle: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 22, fontWeight: FontWeight.w800),
                    border: InputBorder.none, filled: false,
                  ),
                ),

                // Meta info
                Text(
                  existing != null
                      ? 'Dibuat: ${DateFormat('d MMM yyyy, HH:mm').format(existing.createdAt)}'
                      : 'Dibuat: ${DateFormat('d MMM yyyy, HH:mm').format(DateTime.now())}',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
                if (existing?.updatedAt != null)
                  Text('Diedit: ${DateFormat('d MMM yyyy, HH:mm').format(existing!.updatedAt!)}',
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                Text('Oleh: $author', style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                const Divider(height: 20),

                // Content
                TextField(
                  controller: contentCtrl,
                  maxLines: 8,
                  style: const TextStyle(color: AppTheme.onSurface, fontSize: 15, height: 1.6),
                  decoration: const InputDecoration(
                    hintText: 'Mulai menulis...',
                    border: InputBorder.none, filled: false,
                  ),
                ),
                const Divider(height: 20),

                // Reminder toggle
                GestureDetector(
                  onTap: () async {
                    if (!hasReminder) {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx, initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (time == null) return;
                      setModal(() {
                        hasReminder = true;
                        reminderDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    } else {
                      setModal(() { hasReminder = false; reminderDate = null; });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: hasReminder ? Colors.orange.withOpacity(0.1) : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: hasReminder ? Colors.orange.withOpacity(0.4) : Colors.transparent),
                    ),
                    child: Row(children: [
                      Icon(Icons.notifications_rounded,
                          color: hasReminder ? Colors.orange : AppTheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          hasReminder ? 'Reminder aktif' : 'Tambah ke Kalender sebagai Reminder',
                          style: TextStyle(
                            color: hasReminder ? Colors.orange : AppTheme.onSurface,
                            fontWeight: FontWeight.w600, fontSize: 14,
                          ),
                        ),
                        if (hasReminder && reminderDate != null)
                          Text(DateFormat('d MMMM yyyy, HH:mm', 'id').format(reminderDate!),
                              style: const TextStyle(color: Colors.orange, fontSize: 12)),
                        if (!hasReminder)
                          const Text('Note akan muncul di kalender pada tanggal yang dipilih',
                              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                      ])),
                      Icon(hasReminder ? Icons.close_rounded : Icons.add_rounded,
                          color: hasReminder ? Colors.orange : AppTheme.onSurfaceVariant, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Save button
                Row(children: [
                  if (existing != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<NoteProvider>().deleteNote(existing.id!);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                        label: const Text('Hapus', style: TextStyle(color: AppTheme.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  if (existing != null) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (titleCtrl.text.isEmpty) return;
                        final now = DateTime.now();
                        if (existing != null) {
                          await context.read<NoteProvider>().updateNote(existing.copyWith(
                            title: titleCtrl.text,
                            content: contentCtrl.text,
                            updatedAt: now,
                            hasReminder: hasReminder,
                            reminderDate: reminderDate,
                          ));
                        } else {
                          await context.read<NoteProvider>().addNote(AppNote(
                            title: titleCtrl.text,
                            content: contentCtrl.text,
                            createdAt: now,
                            hasReminder: hasReminder,
                            reminderDate: reminderDate,
                          ));
                        }
                        Navigator.pop(ctx);
                        if (hasReminder && reminderDate != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('? Reminder diset: ${DateFormat('d MMM, HH:mm').format(reminderDate!)}'),
                            backgroundColor: Colors.orange,
                          ));
                        }
                      },
                      child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>().notes;
    final pinned = notes.where((n) => n.isPinned).toList();
    final others = notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Catatan', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 28),
            onPressed: () => _openNote(),
          ),
        ],
      ),
      body: notes.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.sticky_note_2_outlined, size: 64, color: AppTheme.onSurfaceVariant),
              const SizedBox(height: 16),
              const Text('Belum ada catatan', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Tap + untuk membuat catatan baru', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pinned.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('DISEMATKAN',
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    ),
                    _notesGrid(pinned),
                    const SizedBox(height: 16),
                  ],
                  if (others.isNotEmpty) ...[
                    if (pinned.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('CATATAN LAIN',
                            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11,
                                fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      ),
                    _notesGrid(others),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _notesGrid(List<AppNote> notes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (ctx, i) {
        final note = notes[i];
        return GestureDetector(
          onTap: () => _openNote(existing: note),
          onLongPress: () async {
            await context.read<NoteProvider>().updateNote(note.copyWith(isPinned: !note.isPinned));
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: note.hasReminder ? Colors.orange.withOpacity(0.4) : AppTheme.outline),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + pin
                Row(children: [
                  Expanded(child: Text(note.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15))),
                  if (note.isPinned)
                    const Icon(Icons.push_pin_rounded, color: AppTheme.primary, size: 16),
                  if (note.hasReminder)
                    const Icon(Icons.notifications_rounded, color: Colors.orange, size: 16),
                ]),
                const SizedBox(height: 6),
                // Content preview
                Expanded(
                  child: Text(note.content,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, height: 1.5)),
                ),
                const SizedBox(height: 8),
                // Footer
                if (note.hasReminder && note.reminderDate != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(DateFormat('d MMM, HH:mm').format(note.reminderDate!),
                        style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                Text(
                  DateFormat('d MMM yyyy').format(note.updatedAt ?? note.createdAt),
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
