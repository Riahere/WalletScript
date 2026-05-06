import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/note_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Set<String> _readIds = {};

  final List<_FinancialTip> _tips = [
    _FinancialTip(
        id: 't1',
        icon: Icons.account_balance_wallet_outlined,
        color: Color(0xFF10B981),
        title: 'Aturan 50/30/20',
        body:
            'Alokasikan 50% untuk kebutuhan, 30% keinginan, dan 20% tabungan setiap bulan. Aturan ini membantu menjaga keseimbangan keuangan jangka panjang.',
        time: '1 jam lalu'),
    _FinancialTip(
        id: 't2',
        icon: Icons.show_chart_rounded,
        color: Color(0xFF6C63FF),
        title: 'Insight Pasar',
        body:
            'IHSG naik 1.2% hari ini. Sektor teknologi dan perbankan memimpin penguatan. Investor asing mencatat net buy Rp 320 miliar.',
        time: '3 jam lalu'),
    _FinancialTip(
        id: 't3',
        icon: Icons.receipt_long_outlined,
        color: Color(0xFFF59E0B),
        title: 'Tips Keuangan',
        body:
            'Hindari impulse buying dengan menunggu 24 jam sebelum membeli barang non-esensial. Catat juga semua pengeluaran kecil — akumulasinya sering mengejutkan.',
        time: '5 jam lalu'),
    _FinancialTip(
        id: 't4',
        icon: Icons.currency_exchange_outlined,
        color: Color(0xFF3B82F6),
        title: 'Kurs Hari Ini',
        body:
            'USD/IDR: Rp 16.240\nEUR/IDR: Rp 17.580\nSGD/IDR: Rp 12.010\nJPY/IDR: Rp 108\n\nData diperbarui pukul 06.00 WIB.',
        time: '6 jam lalu'),
    _FinancialTip(
        id: 't5',
        icon: Icons.donut_large_outlined,
        color: Color(0xFFEF4444),
        title: 'Tips Investasi',
        body:
            'Diversifikasi portofolio adalah kunci manajemen risiko. Jangan taruh semua modal dalam satu instrumen — kombinasikan saham, obligasi, dan reksa dana sesuai profil risiko kamu.',
        time: 'Kemarin'),
    _FinancialTip(
        id: 't6',
        icon: Icons.corporate_fare_rounded,
        color: Color(0xFF0EA5E9),
        title: 'Info Reksa Dana',
        body:
            'Reksa dana pasar uang cocok untuk dana darurat karena likuid dan risikonya rendah. Return rata-rata 4–6% per tahun, lebih tinggi dari bunga tabungan biasa.',
        time: 'Kemarin'),
  ];

  void _markRead(String id) {
    setState(() => _readIds.add(id));
  }

  void _markAllRead(List<String> ids) {
    setState(() => _readIds.addAll(ids));
  }

  bool _isRead(String id) => _readIds.contains(id);

  void _showDetail(
    BuildContext context, {
    required String id,
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String time,
    Widget? extra,
  }) {
    _markRead(id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(time,
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 12)),
                  ])),
            ]),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.outline),
            const SizedBox(height: 16),
            Text(body,
                style: const TextStyle(
                    color: AppTheme.onSurface, fontSize: 14, height: 1.6)),
            if (extra != null) ...[const SizedBox(height: 16), extra],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteProvider>().loadNotes();
      context.read<TransactionProvider>().loadTransactions();
      context.read<BudgetProvider>().loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>().notes;
    final txProvider = context.watch<TransactionProvider>();
    final budgets = context.watch<BudgetProvider>().budgets;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();

    final reminders = notes
        .where((n) =>
            n.hasReminder &&
            n.reminderDate != null &&
            n.reminderDate!.isAfter(now.subtract(const Duration(days: 1))))
        .toList();

    final todayTx = txProvider.transactions
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .toList();

    final nearLimitBudgets = budgets
        .where((b) =>
            b.targetAmount > 0 && (b.currentAmount / b.targetAmount) >= 0.8)
        .toList();

    final spendRatio = txProvider.totalIncome > 0
        ? txProvider.totalExpense / txProvider.totalIncome
        : 0.0;

    // Kumpulin semua id buat "tandai semua"
    final allIds = [
      ...reminders.map((n) => 'r${n.id}'),
      'insight',
      ...todayTx.map((t) => 'tx${t.id}'),
      ...nearLimitBudgets.map((b) => 'b${b.id}'),
      ..._tips.map((t) => t.id),
    ];

    final unreadCount = allIds.where((id) => !_isRead(id)).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          const Text('Notifikasi',
              style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 20)),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(allIds),
            child: const Text('Tandai dibaca',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          if (reminders.isNotEmpty) ...[
            _sectionHeader(
                'Reminder', Icons.notifications_rounded, Colors.orange),
            ...reminders.map((n) => _reminderCard(n, formatter)),
            const SizedBox(height: 8),
          ],
          _sectionHeader(
              'Insight Keuangan', Icons.bar_chart_rounded, AppTheme.primary),
          _insightCard(spendRatio, txProvider.totalExpense,
              txProvider.totalIncome, formatter),
          const SizedBox(height: 8),
          if (todayTx.isNotEmpty) ...[
            _sectionHeader('Transaksi Hari Ini', Icons.swap_horiz_rounded,
                const Color(0xFF6C63FF)),
            ...todayTx.take(3).map((t) => _txCard(t, formatter)),
            const SizedBox(height: 8),
          ],
          if (nearLimitBudgets.isNotEmpty) ...[
            _sectionHeader(
                'Budget Alert', Icons.warning_amber_rounded, AppTheme.error),
            ...nearLimitBudgets.map((b) => _budgetCard(b, formatter)),
            const SizedBox(height: 8),
          ],
          _sectionHeader('Tips & Berita Keuangan', Icons.auto_awesome_outlined,
              const Color(0xFFF59E0B)),
          ..._tips.map((t) => _tipCard(t)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(children: [
        Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(title,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2)),
      ]),
    );
  }

  Widget _unreadDot() => Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.only(left: 6, top: 2),
        decoration: const BoxDecoration(
            color: AppTheme.primary, shape: BoxShape.circle),
      );

  Widget _reminderCard(AppNote note, NumberFormat formatter) {
    final id = 'r${note.id}';
    final read = _isRead(id);
    return GestureDetector(
      onTap: () => _showDetail(
        context,
        id: id,
        icon: Icons.notifications_active_outlined,
        color: Colors.orange,
        title: note.title,
        body: note.content,
        time: note.reminderDate != null
            ? DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id')
                .format(note.reminderDate!)
            : '',
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppTheme.surface : Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: read ? AppTheme.outline : Colors.orange.withOpacity(0.35)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(read ? 0.08 : 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.notifications_active_outlined,
                color: read ? AppTheme.onSurfaceVariant : Colors.orange,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(note.title,
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 14)),
                  if (!read) _unreadDot(),
                ]),
                Text(note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12)),
              ])),
          const SizedBox(width: 8),
          if (note.reminderDate != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(DateFormat('HH:mm').format(note.reminderDate!),
                  style: TextStyle(
                      color: read ? AppTheme.onSurfaceVariant : Colors.orange,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Text(DateFormat('d MMM').format(note.reminderDate!),
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 11)),
            ]),
        ]),
      ),
    );
  }

  Widget _insightCard(
      double ratio, double expense, double income, NumberFormat fmt) {
    final id = 'insight';
    final read = _isRead(id);
    final String message;
    final String detailBody;
    final Color color;
    final IconData icon;

    if (ratio >= 0.9) {
      message = 'Pengeluaran hampir melebihi pemasukan!';
      detailBody =
          'Pengeluaranmu sudah mencapai ${(ratio * 100).toStringAsFixed(0)}% dari total pemasukan. Ini sinyal bahaya — segera evaluasi pos pengeluaran non-esensial dan pertimbangkan untuk memotong langganan yang tidak dipakai.';
      color = AppTheme.error;
      icon = Icons.warning_amber_rounded;
    } else if (ratio >= 0.7) {
      message =
          'Pengeluaran ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan. Hati-hati!';
      detailBody =
          'Keuanganmu masih aman tapi sudah di zona waspada. Pengeluaranmu sudah ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan. Coba tinjau kembali pengeluaran minggu ini dan cari yang bisa dikurangi.';
      color = Colors.orange;
      icon = Icons.bar_chart_rounded;
    } else if (income == 0) {
      message = 'Belum ada transaksi tercatat.';
      detailBody =
          'Mulai catat pemasukan dan pengeluaranmu hari ini! Pencatatan rutin membantu kamu memahami pola keuangan dan membuat keputusan yang lebih baik.';
      color = AppTheme.primary;
      icon = Icons.bar_chart_rounded;
    } else {
      message =
          'Keuanganmu sehat! Pengeluaran ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan.';
      detailBody =
          'Bagus! Pengeluaranmu terkontrol dengan baik di angka ${(ratio * 100).toStringAsFixed(0)}% dari total pemasukan. Pertahankan kebiasaan ini dan pertimbangkan untuk menginvestasikan sisa ${(100 - ratio * 100).toStringAsFixed(0)}%-nya.';
      color = AppTheme.primary;
      icon = Icons.check_circle_outline_rounded;
    }

    return GestureDetector(
      onTap: () => _showDetail(
        context,
        id: id,
        icon: icon,
        color: color,
        title: 'Ringkasan Keuangan',
        body: detailBody,
        time: 'Diperbarui hari ini',
        extra: Row(children: [
          Expanded(
              child:
                  _statChip('Pemasukan', fmt.format(income), AppTheme.primary)),
          const SizedBox(width: 8),
          Expanded(
              child: _statChip(
                  'Pengeluaran', fmt.format(expense), AppTheme.error)),
        ]),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppTheme.surface : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: read ? AppTheme.outline : color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(read ? 0.06 : 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon,
                  color: read ? AppTheme.onSurfaceVariant : color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text('Ringkasan Keuangan',
                        style: TextStyle(
                            color: read ? AppTheme.onSurfaceVariant : color,
                            fontWeight:
                                read ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14)),
                    if (!read) _unreadDot(),
                  ]),
                  Text(message,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          height: 1.3)),
                ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _statChip(
                    'Pemasukan', fmt.format(income), AppTheme.primary)),
            const SizedBox(width: 8),
            Expanded(
                child: _statChip(
                    'Pengeluaran', fmt.format(expense), AppTheme.error)),
          ]),
        ]),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }

  Widget _txCard(AppTransaction t, NumberFormat formatter) {
    final id = 'tx${t.id}';
    final read = _isRead(id);
    final isIncome = t.type == 'income';
    final color = isIncome ? AppTheme.primary : AppTheme.error;
    return GestureDetector(
      onTap: () => _showDetail(
        context,
        id: id,
        icon: isIncome
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded,
        color: color,
        title: t.title,
        body:
            '${isIncome ? "Pemasukan" : "Pengeluaran"} sebesar ${formatter.format(t.amount)} tercatat pada kategori "${t.category}".'
            '${t.note != null && t.note!.isNotEmpty ? '\n\nCatatan: ${t.note}' : ''}',
        time: DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id').format(t.date),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppTheme.surface : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: read ? AppTheme.outline : color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(read ? 0.06 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: read ? AppTheme.onSurfaceVariant : color,
                size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(t.title,
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: read ? FontWeight.w500 : FontWeight.w600,
                          fontSize: 14)),
                  if (!read) _unreadDot(),
                ]),
                Text(t.category,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12)),
              ])),
          Text('${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
              style: TextStyle(
                  color: read ? AppTheme.onSurfaceVariant : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _budgetCard(AppBudget b, NumberFormat formatter) {
    final id = 'b${b.id}';
    final read = _isRead(id);
    final ratio = (b.currentAmount / b.targetAmount).clamp(0.0, 1.0);
    final color = ratio >= 1.0 ? AppTheme.error : Colors.orange;
    final sisa = b.targetAmount - b.currentAmount;
    return GestureDetector(
      onTap: () => _showDetail(
        context,
        id: id,
        icon: Icons.warning_amber_rounded,
        color: color,
        title: '${b.emoji} ${b.title}',
        body: ratio >= 1.0
            ? 'Budget "${b.title}" sudah habis! Total budget ${formatter.format(b.targetAmount)} sudah terpakai seluruhnya. Pertimbangkan untuk menambah budget atau menahan pengeluaran di kategori ini.'
            : 'Budget "${b.title}" sudah terpakai ${(ratio * 100).toStringAsFixed(0)}% dari ${formatter.format(b.targetAmount)}. Sisa budget yang tersedia: ${formatter.format(sisa)}. Pantau pengeluaran di kategori ini agar tidak melebihi batas.',
        time: 'Diperbarui hari ini',
        extra: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppTheme.surface : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: read ? AppTheme.outline : color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(read ? 0.06 : 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(b.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Text(b.title,
                        style: TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight:
                                read ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14)),
                    if (!read) _unreadDot(),
                  ]),
                  Text(
                      ratio >= 1.0
                          ? 'Budget habis!'
                          : 'Sudah ${(ratio * 100).toStringAsFixed(0)}% terpakai',
                      style: TextStyle(
                          color: read ? AppTheme.onSurfaceVariant : color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ])),
            Text(
                sisa > 0
                    ? 'Sisa ${formatter.format(sisa)}'
                    : 'Melebihi budget!',
                style: TextStyle(
                    color: read ? AppTheme.onSurfaceVariant : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tipCard(_FinancialTip tip) {
    final read = _isRead(tip.id);
    return GestureDetector(
      onTap: () => _showDetail(
        context,
        id: tip.id,
        icon: tip.icon,
        color: tip.color,
        title: tip.title,
        body: tip.body,
        time: tip.time,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppTheme.surface : tip.color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: read ? AppTheme.outline : tip.color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: tip.color.withOpacity(read ? 0.06 : 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(tip.icon,
                color: read ? AppTheme.onSurfaceVariant : tip.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(tip.title,
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 14)),
                  if (!read) _unreadDot(),
                ]),
                const SizedBox(height: 2),
                Text(tip.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 4),
                Text(tip.time,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 11)),
              ])),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant, size: 18),
        ]),
      ),
    );
  }
}

class _FinancialTip {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  const _FinancialTip(
      {required this.id,
      required this.icon,
      required this.color,
      required this.title,
      required this.body,
      required this.time});
}
