// lib/screens/notes_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';

const Color _navy = Color(0xFF0D1B3E);
const Color _yellow = Color(0xFFF5C842);
const Color _white = Colors.white;
const Color _navySub = Color(0x800D1B3E);
const Color _navyHint = Color(0x400D1B3E);
const Color _greyLine = Color(0xFFECECEC);
const Color _greyFill = Color(0xFFF4F5F7);
const Color _yellowBg = Color(0x18F5C842);

TextStyle _n({
  double size = 14,
  FontWeight weight = FontWeight.w400,
  Color color = _navy,
  double height = 1.5,
  double letterSpacing = 0,
}) =>
    GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(
      () => setState(() => _searchFocused = _searchFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _greyFill,
      body: Column(
        children: [
          // ── Navy header — curved bottom, NO search bar ─────────
          Container(
            decoration: const BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: topPadding + 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: _white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Notes',
                          style: _n(
                              size: 22,
                              weight: FontWeight.w800,
                              color: _white)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => NoteEditorScreen())),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _yellow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: _navy, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar di bawah header, background greyFill ────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 48,
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchFocused ? _yellow : _greyLine,
                  width: _searchFocused ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _searchFocused
                        ? _yellow.withOpacity(0.18)
                        : _navy.withOpacity(0.06),
                    blurRadius: _searchFocused ? 12 : 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                style: _n(color: _navy, size: 14),
                cursorColor: _navy,
                decoration: InputDecoration(
                  hintText: 'Search notes…',
                  hintStyle: _n(color: _navy.withOpacity(0.30), size: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _searchFocused ? _navy : _navy.withOpacity(0.35),
                    size: 20,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(Icons.close_rounded,
                              color: _navy.withOpacity(0.4), size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Notes list ─────────────────────────────────────────
          Expanded(
            child: Consumer<NoteProvider>(
              builder: (context, provider, _) {
                final notes = provider.notes
                    .where((n) =>
                        _query.isEmpty ||
                        n.title.toLowerCase().contains(_query) ||
                        n.content.toLowerCase().contains(_query))
                    .toList();

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _navy.withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.sticky_note_2_outlined,
                              size: 36, color: _navy.withOpacity(0.2)),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _query.isEmpty
                              ? 'No notes yet'
                              : 'No results for "$_query"',
                          style: _n(
                              size: 16,
                              weight: FontWeight.w700,
                              color: _navySub),
                        ),
                        if (_query.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Tap + to create your first note',
                              style: _n(size: 13, color: _navyHint)),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _NoteCard(note: notes[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => NoteEditorScreen())),
        backgroundColor: _navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: _yellow),
      ),
    );
  }
}

// ── Note card ──────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final AppNote note;
  const _NoteCard({required this.note});

  String _preview(String raw) {
    return raw
        .replaceAll(RegExp(r'^\[.\] ', multiLine: true), '')
        .replaceAll(RegExp(r'^• ', multiLine: true), '')
        .replaceAll(RegExp(r'^\d+\. ', multiLine: true), '')
        .replaceAll(RegExp(r'^  ', multiLine: true), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final hasReminder = note.hasReminder && note.reminderDate != null;
    final preview = _preview(note.content);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: note)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _greyLine, width: 1),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _n(size: 15, weight: FontWeight.w800)),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _n(size: 13, color: _navySub, height: 1.55)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _navy.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('d MMM yyyy').format(note.createdAt),
                    style: _n(
                        size: 11,
                        weight: FontWeight.w700,
                        color: _navySub,
                        letterSpacing: 0.1),
                  ),
                ),
                const Spacer(),
                if (hasReminder)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _yellowBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: _yellow, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM, HH:mm').format(note.reminderDate!),
                          style: _n(
                              size: 11,
                              weight: FontWeight.w700,
                              color: _yellow),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: _navyHint, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
