import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/note_provider.dart';
import '../models/transaction_model.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<NoteProvider>().loadNotes();
    });
  }

  List<DateTime> _daysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final startWeekday = first.weekday % 7;
    return [
      ...List.generate(startWeekday, (i) => first.subtract(Duration(days: startWeekday - i))),
      ...List.generate(last.day, (i) => DateTime(month.year, month.month, i + 1)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final today = DateTime.now();
    final days = _daysInMonth(_focusedMonth);

    final selectedTx = txProvider.transactions.where((t) =>
      t.date.year == _selectedDay.year &&
      t.date.month == _selectedDay.month &&
      t.date.day == _selectedDay.day).toList();

    final selectedReminders = noteProvider.getRemindersForDate(_selectedDay);

    final monthNames = ['Januari','Februari','Maret','April','Mei','Juni',
                        'Juli','Agustus','September','Oktober','November','Desember'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // -- DARK HEADER --
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    // Nav row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                          onPressed: () => setState(() {
                            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                          }),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                          onPressed: () => setState(() {
                            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                          }),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Day labels
                    Row(
                      children: ['Min','Sen','Sel','Rab','Kam','Jum','Sab'].map((d) =>
                        Expanded(child: Center(
                          child: Text(d, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
                        ))
                      ).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Calendar grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4,
                      ),
                      itemCount: days.length,
                      itemBuilder: (ctx, i) {
                        final day = days[i];
                        final isCurrentMonth = day.month == _focusedMonth.month;
                        final isSelected = day.year == _selectedDay.year &&
                            day.month == _selectedDay.month && day.day == _selectedDay.day;
                        final isToday = day.year == today.year &&
                            day.month == today.month && day.day == today.day;
                        final hasTx = txProvider.transactions.any((t) =>
                            t.date.year == day.year && t.date.month == day.month && t.date.day == day.day);
                        final hasReminder = noteProvider.notes.any((n) =>
                            n.hasReminder && n.reminderDate != null &&
                            n.reminderDate!.year == day.year &&
                            n.reminderDate!.month == day.month &&
                            n.reminderDate!.day == day.day);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDay = day),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${day.day}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white
                                          : !isCurrentMonth ? Colors.white12
                                          : isToday ? AppTheme.primary
                                          : Colors.white,
                                      fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                                      fontSize: 13,
                                    )),
                                if ((hasTx || hasReminder) && isCurrentMonth)
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    if (hasTx) Container(width: 4, height: 4,
                                        margin: const EdgeInsets.only(top: 2, right: 1),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : AppTheme.primary,
                                          shape: BoxShape.circle)),
                                    if (hasReminder) Container(width: 4, height: 4,
                                        margin: const EdgeInsets.only(top: 2),
                                        decoration: const BoxDecoration(
                                          color: Colors.orange, shape: BoxShape.circle)),
                                  ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Set Reminder button
                    GestureDetector(
                      onTap: () => _showSetReminderSheet(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Center(
                          child: Text('+ Set Reminder',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -- CONTENT --
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'id').format(_selectedDay),
                    style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  if (selectedReminders.isNotEmpty) ...[
                    const Text('REMINDER',
                        style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    ...selectedReminders.map((n) => _reminderCard(n)),
                    const SizedBox(height: 16),
                  ],

                  const Text('TRANSAKSI',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  if (selectedTx.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: const Column(children: [
                        Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.onSurfaceVariant),
                        SizedBox(height: 8),
                        Text('Tidak ada transaksi', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      ]),
                    )
                  else
                    ...selectedTx.map((t) => _txCard(t, formatter)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(AppNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note.title, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
          Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ])),
        if (note.reminderDate != null)
          Text(DateFormat('HH:mm').format(note.reminderDate!),
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }

  Widget _txCard(AppTransaction t, NumberFormat formatter) {
    final isIncome = t.type == 'income';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: isIncome ? AppTheme.primary.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIncome ? AppTheme.primary : AppTheme.error, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
          Text('${t.category} • ${DateFormat('HH:mm').format(t.date)}',
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ])),
        Text('${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
            style: TextStyle(color: isIncome ? AppTheme.primary : AppTheme.error,
                fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
    );
  }

  void _showSetReminderSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    DateTime reminderDate = _selectedDay.copyWith(hour: 9, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set Reminder', style: TextStyle(color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(controller: titleCtrl,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(hintText: 'Judul reminder', filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              TextField(controller: contentCtrl, maxLines: 3,
                style: const TextStyle(color: AppTheme.onSurface),
                decoration: InputDecoration(hintText: 'Isi catatan...', filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(reminderDate));
                  if (time != null) setModalState(() {
                    reminderDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, time.hour, time.minute);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Text('Jam: ${DateFormat('HH:mm').format(reminderDate)}',
                        style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, color: AppTheme.onSurfaceVariant, size: 16),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty) return;
                    await context.read<NoteProvider>().addNote(AppNote(
                      title: titleCtrl.text, content: contentCtrl.text,
                      createdAt: DateTime.now(), reminderDate: reminderDate, hasReminder: true,
                    ));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Reminder diset: ${DateFormat('d MMM, HH:mm').format(reminderDate)}')));
                  },
                  child: const Text('Simpan Reminder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
