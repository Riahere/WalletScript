// lib/screens/note_editor_screen.dart
// Redesign: Nunito font (Gotham-style), iOS Notes feel, curved layout, accessible toolbar

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../providers/note_provider.dart';

// ─── Color palette ────────────────────────────────────────────────
const Color _navy = Color(0xFF0D1B3E);
const Color _yellow = Color(0xFFF5C842);
const Color _green = Color(0xFF1DB87A);
const Color _white = Colors.white;
const Color _navySub = Color(0x800D1B3E);
const Color _navyHint = Color(0x400D1B3E);
const Color _greyLine = Color(0xFFECECEC);
const Color _greyFill = Color(0xFFF8F8FA);
const Color _surface = Color(0xFFF2F2F7); // iOS-like surface

// ─── Font helper — Nunito (Gotham-style: geometric, warm, readable) ──
TextStyle _n({
  double size = 15,
  FontWeight weight = FontWeight.w400,
  Color color = _navy,
  double height = 1.55,
  TextDecoration? decoration,
}) =>
    GoogleFonts.nunito(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      decoration: decoration,
    );

// ─── Line types ───────────────────────────────────────────────────
enum _LineType { plain, bullet, numbered, checklist }

class _Line {
  _LineType type;
  String text;
  bool checked;
  _Line({required this.type, required this.text, this.checked = false});

  _Line copyWith({_LineType? type, String? text, bool? checked}) => _Line(
        type: type ?? this.type,
        text: text ?? this.text,
        checked: checked ?? this.checked,
      );
}

// ─── Screen ───────────────────────────────────────────────────────
class NoteEditorScreen extends StatefulWidget {
  final AppNote? existing;
  const NoteEditorScreen({super.key, this.existing});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleCtrl;

  late List<_Line> _lines;
  final List<TextEditingController> _ctrls = [];
  final List<FocusNode> _focusNodes = [];

  bool _hasReminder = false;
  DateTime? _reminderDate;
  bool _isSaving = false;
  int _activeLine = 0;

  bool get _isEdit => widget.existing != null;

  // ── Parse / serialize ────────────────────────────────────────────
  List<_Line> _parse(String raw) {
    if (raw.isEmpty) return [_Line(type: _LineType.plain, text: '')];
    return raw.split('\n').map((l) {
      if (l.startsWith('[x] '))
        return _Line(
            type: _LineType.checklist, text: l.substring(4), checked: true);
      if (l.startsWith('[ ] '))
        return _Line(
            type: _LineType.checklist, text: l.substring(4), checked: false);
      if (l.startsWith('• '))
        return _Line(type: _LineType.bullet, text: l.substring(2));
      if (RegExp(r'^\d+\. ').hasMatch(l))
        return _Line(
            type: _LineType.numbered,
            text: l.replaceFirst(RegExp(r'^\d+\. '), ''));
      return _Line(
          type: _LineType.plain, text: l.startsWith('  ') ? l.substring(2) : l);
    }).toList();
  }

  String _serialize() {
    int n = 1;
    return _lines.map((line) {
      switch (line.type) {
        case _LineType.plain:
          return '  ${line.text}';
        case _LineType.bullet:
          return '• ${line.text}';
        case _LineType.numbered:
          return '${n++}. ${line.text}';
        case _LineType.checklist:
          return '${line.checked ? '[x]' : '[ ]'} ${line.text}';
      }
    }).join('\n');
  }

  // ── Controllers ──────────────────────────────────────────────────
  void _buildControllers() {
    for (final c in _ctrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _ctrls.clear();
    _focusNodes.clear();
    for (int i = 0; i < _lines.length; i++) {
      _ctrls.add(TextEditingController(text: _lines[i].text));
      _focusNodes.add(FocusNode()..addListener(() => _onFocusChange(i)));
    }
  }

  void _onFocusChange(int i) {
    if (_focusNodes[i].hasFocus) setState(() => _activeLine = i);
  }

  @override
  void initState() {
    super.initState();
    final note = widget.existing;
    _titleCtrl = TextEditingController(text: note?.title ?? '');
    _hasReminder = note?.hasReminder ?? false;
    _reminderDate = note?.reminderDate;
    _lines = _parse(note?.content ?? '');
    _buildControllers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final c in _ctrls) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _syncTexts() {
    for (int i = 0; i < _lines.length; i++) {
      _lines[i] = _lines[i].copyWith(text: _ctrls[i].text);
    }
  }

  void _insertLine(int after) {
    _syncTexts();
    final prevType = _lines[after].type;
    _lines.insert(after + 1, _Line(type: prevType, text: ''));
    final fn = FocusNode();
    _ctrls.insert(after + 1, TextEditingController());
    _focusNodes.insert(after + 1, fn);
    for (int i = 0; i < _focusNodes.length; i++) {
      final idx = i;
      _focusNodes[i].addListener(() => _onFocusChange(idx));
    }
    setState(() => _activeLine = after + 1);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[after + 1].requestFocus());
  }

  void _removeLine(int at) {
    if (_lines.length <= 1) return;
    _syncTexts();
    _ctrls[at].dispose();
    _focusNodes[at].dispose();
    _lines.removeAt(at);
    _ctrls.removeAt(at);
    _focusNodes.removeAt(at);
    final prev = (at - 1).clamp(0, _lines.length - 1);
    setState(() => _activeLine = prev);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNodes[prev].requestFocus());
  }

  void _applyFormat(_LineType type) {
    _syncTexts();
    setState(() {
      _lines[_activeLine] = _lines[_activeLine].copyWith(type: type);
    });
    _focusNodes[_activeLine].requestFocus();
  }

  void _toggleCheck(int i) {
    _syncTexts();
    setState(() {
      _lines[i] = _lines[i].copyWith(checked: !_lines[i].checked);
    });
  }

  // ── Reminder ─────────────────────────────────────────────────────
  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _reminderDate ?? now.add(const Duration(hours: 1))),
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (time == null || !mounted) return;
    setState(() {
      _reminderDate =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _hasReminder = true;
    });
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _navy,
            onPrimary: _white,
            secondary: _yellow,
            onSecondary: _navy,
          ),
        ),
        child: child!,
      );

  // ── Save ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    _syncTexts();
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Title cannot be empty', style: _n(color: _white)),
        backgroundColor: _navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
      return;
    }
    setState(() => _isSaving = true);
    final content = _serialize();
    final provider = context.read<NoteProvider>();
    try {
      if (_isEdit) {
        await provider.updateNote(widget.existing!.copyWith(
          title: title,
          content: content,
          updatedAt: DateTime.now(),
          hasReminder: _hasReminder,
          reminderDate: _hasReminder ? _reminderDate : null,
        ));
      } else {
        await provider.addNote(AppNote(
          title: title,
          content: content,
          createdAt: DateTime.now(),
          hasReminder: _hasReminder,
          reminderDate: _hasReminder ? _reminderDate : null,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e', style: _n(color: _white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────
  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text('Delete Note', style: _n(size: 18, weight: FontWeight.w800)),
        content: Text('This note will be permanently deleted.',
            style: _n(size: 14, color: _navySub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: _n(color: _navySub, weight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: _n(color: Colors.red, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<NoteProvider>().deleteNote(widget.existing!.id!);
    if (mounted) Navigator.pop(context);
  }

  // ── Build a single content line ───────────────────────────────────
  Widget _buildLine(int i) {
    final line = _lines[i];

    Widget leading;
    switch (line.type) {
      case _LineType.plain:
        leading = const SizedBox(width: 4);
        break;

      case _LineType.bullet:
        leading = Padding(
          padding: const EdgeInsets.only(top: 11, right: 10, left: 4),
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
          ),
        );
        break;

      case _LineType.numbered:
        final numIdx = _lines
            .sublist(0, i + 1)
            .where((l) => l.type == _LineType.numbered)
            .length;
        leading = Padding(
          padding: const EdgeInsets.only(top: 2, right: 8, left: 2),
          child: SizedBox(
            width: 22,
            child: Text(
              '$numIdx.',
              style: _n(
                  size: 15,
                  weight: FontWeight.w700,
                  color: _navy.withOpacity(0.45)),
              textAlign: TextAlign.right,
            ),
          ),
        );
        break;

      case _LineType.checklist:
        leading = GestureDetector(
          onTap: () => _toggleCheck(i),
          child: Padding(
            padding: const EdgeInsets.only(top: 3, right: 10, left: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: line.checked ? _green : _white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: line.checked ? _green : _navySub,
                  width: 1.8,
                ),
              ),
              child: line.checked
                  ? const Icon(Icons.check_rounded, color: _white, size: 14)
                  : null,
            ),
          ),
        );
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          Expanded(
            child: TextField(
              controller: _ctrls[i],
              focusNode: _focusNodes[i],
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: _n(
                size: 15,
                height: 1.7,
                color: line.type == _LineType.checklist && line.checked
                    ? _navyHint
                    : _navy,
                decoration: line.type == _LineType.checklist && line.checked
                    ? TextDecoration.lineThrough
                    : null,
              ),
              decoration: InputDecoration(
                hintText: i == 0 ? 'Start writing…' : '',
                hintStyle: _n(size: 15, color: _navyHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(top: 2),
              ),
              onSubmitted: (_) => _insertLine(i),
              onChanged: (val) => _lines[i] = _lines[i].copyWith(text: val),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formatting toolbar ── iOS Notes style ─────────────────────────
  Widget _buildToolbar() {
    final active = _activeLine < _lines.length
        ? _lines[_activeLine].type
        : _LineType.plain;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _greyLine, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              const SizedBox(width: 4),

              // Bold
              _toolbarChip(
                icon: Icons.format_bold_rounded,
                label: 'Bold',
                isActive: false,
                onTap: () {},
              ),

              // Italic
              _toolbarChip(
                icon: Icons.format_italic_rounded,
                label: 'Italic',
                isActive: false,
                onTap: () {},
              ),

              const SizedBox(width: 6),
              Container(width: 1, height: 22, color: _greyLine),
              const SizedBox(width: 6),

              // Bullet
              _toolbarChip(
                icon: Icons.format_list_bulleted_rounded,
                label: 'List',
                isActive: active == _LineType.bullet,
                onTap: () => _applyFormat(active == _LineType.bullet
                    ? _LineType.plain
                    : _LineType.bullet),
              ),

              // Numbered
              _toolbarChip(
                icon: Icons.format_list_numbered_rounded,
                label: '1 2 3',
                isActive: active == _LineType.numbered,
                onTap: () => _applyFormat(active == _LineType.numbered
                    ? _LineType.plain
                    : _LineType.numbered),
              ),

              // Checklist
              _toolbarChip(
                icon: Icons.checklist_rounded,
                label: 'To-do',
                isActive: active == _LineType.checklist,
                onTap: () => _applyFormat(active == _LineType.checklist
                    ? _LineType.plain
                    : _LineType.checklist),
              ),

              const Spacer(),

              // Dismiss keyboard
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.keyboard_hide_rounded,
                      color: _navySub, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: isActive ? _navy : _surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: isActive ? _yellow : _navySub),
            const SizedBox(width: 5),
            Text(label,
                style: _n(
                  size: 12,
                  weight: FontWeight.w700,
                  color: isActive ? _yellow : _navySub,
                )),
          ],
        ),
      ),
    );
  }

  // ── Main build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _white,
      body: Column(
        children: [
          // ── Header ── navy, curved bottom ──────────────────────
          Container(
            decoration: const BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(top: topPadding),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                children: [
                  // Back button
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
                  Text(
                    _isEdit ? 'Edit Note' : 'New Note',
                    style: _n(size: 19, weight: FontWeight.w800, color: _white),
                  ),
                  const Spacer(),
                  if (_isEdit) ...[
                    GestureDetector(
                      onTap: _delete,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Colors.redAccent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Save button
                  GestureDetector(
                    onTap: _isSaving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: _isSaving ? _yellow.withOpacity(0.6) : _yellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: _navy, strokeWidth: 2.5))
                          : Text('Save',
                              style: _n(
                                  size: 14,
                                  weight: FontWeight.w800,
                                  color: _navy)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title field ─────────────────────────────────
                  TextField(
                    controller: _titleCtrl,
                    maxLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: _n(size: 24, weight: FontWeight.w800, height: 1.3),
                    decoration: InputDecoration(
                      hintText: 'Note title…',
                      hintStyle: _n(
                          size: 24,
                          weight: FontWeight.w800,
                          color: _navyHint,
                          height: 1.3),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Meta date (edit mode) ───────────────────────
                  if (_isEdit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        DateFormat('d MMM yyyy · HH:mm').format(
                            widget.existing!.updatedAt ??
                                widget.existing!.createdAt),
                        style: _n(size: 12, color: _navyHint),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // ── Curved writing card ─────────────────────────
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 220),
                    decoration: BoxDecoration(
                      color: _greyFill,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _greyLine, width: 1),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _lines.length,
                      itemBuilder: (_, i) => _buildLine(i),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Reminder section ────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: _greyFill,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _greyLine),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _yellow.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: _yellow,
                                    size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text('Reminder',
                                  style: _n(size: 15, weight: FontWeight.w700)),
                              const Spacer(),
                              Switch.adaptive(
                                value: _hasReminder,
                                onChanged: (v) async {
                                  if (v) {
                                    await _pickReminder();
                                  } else {
                                    setState(() {
                                      _hasReminder = false;
                                      _reminderDate = null;
                                    });
                                  }
                                },
                                activeColor: _green,
                              ),
                            ],
                          ),
                        ),
                        if (_hasReminder && _reminderDate != null) ...[
                          Divider(height: 1, color: _greyLine),
                          GestureDetector(
                            onTap: _pickReminder,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      color: _yellow, size: 15),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat('EEE, d MMM yyyy · HH:mm')
                                        .format(_reminderDate!),
                                    style: _n(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: _navy),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.edit_rounded,
                                      color: _navyHint, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Meta footer (edit mode) ─────────────────────
                  if (_isEdit) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      Icon(Icons.access_time_rounded,
                          color: _navyHint, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Created ${DateFormat('d MMM yyyy, HH:mm').format(widget.existing!.createdAt)}',
                        style: _n(size: 12, color: _navyHint),
                      ),
                    ]),
                    if (widget.existing!.updatedAt != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.edit_calendar_rounded,
                            color: _navyHint, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'Last edited ${DateFormat('d MMM yyyy, HH:mm').format(widget.existing!.updatedAt!)}',
                          style: _n(size: 12, color: _navyHint),
                        ),
                      ]),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // ── Formatting toolbar ───────────────────────────────────
          _buildToolbar(),
        ],
      ),
    );
  }
}
