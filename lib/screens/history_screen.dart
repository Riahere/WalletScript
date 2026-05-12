import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'app_top_bar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CATATAN DEPENDENCIES:
// Pastikan pubspec.yaml sudah ada:
//   share_plus: ^10.0.0
//   path_provider: ^2.1.0
//
// Untuk PDF (opsional), tambahkan:
//   pdf: ^3.10.8
//   printing: ^5.12.0
// ─────────────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ── Filter state ──────────────────────────────────────────────────────────
  String _typeFilter = 'Semua'; // Semua / Income / Expense / Transfer
  String _categoryFilter = 'Semua'; // dinamis dari data
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchActive = false;

  // ── Category icon map ─────────────────────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _catMeta = {
    'Makanan': {'icon': Icons.restaurant_rounded, 'color': Color(0xFFD1FAE5)},
    'Transport': {
      'icon': Icons.directions_car_rounded,
      'color': Color(0xFFDBEAFE)
    },
    'Belanja': {'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFEDE9FE)},
    'Hiburan': {'icon': Icons.gamepad_rounded, 'color': Color(0xFFFEF3C7)},
    'Kesehatan': {
      'icon': Icons.health_and_safety_rounded,
      'color': Color(0xFFFFE4E6)
    },
    'Gaji': {
      'icon': Icons.account_balance_wallet_rounded,
      'color': Color(0xFFD1FAE5)
    },
    'Travel': {
      'icon': Icons.flight_takeoff_rounded,
      'color': Color(0xFFE0F2FE)
    },
    'Edu': {'icon': Icons.school_rounded, 'color': Color(0xFFE0F2FE)},
    'Transfer': {'icon': Icons.swap_horiz_rounded, 'color': Color(0xFFF3E8FF)},
    'Saldo Awal': {
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFFD1FAE5)
    },
    'Tagihan': {'icon': Icons.receipt_long_rounded, 'color': Color(0xFFFFE4E6)},
    'Investasi': {
      'icon': Icons.trending_up_rounded,
      'color': Color(0xFFD1FAE5)
    },
    'Hadiah': {'icon': Icons.card_giftcard_rounded, 'color': Color(0xFFFEF3C7)},
    'Lainnya': {'icon': Icons.more_horiz_rounded, 'color': Color(0xFFF1F5F9)},
  };

  static Map<String, dynamic> _catFor(String category) =>
      _catMeta[category] ??
      {'icon': Icons.receipt_rounded, 'color': AppTheme.surfaceContainer};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Daftar kategori unik dari data
  List<String> _uniqueCategories(List<AppTransaction> all) {
    final cats = all.map((t) => t.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<AppTransaction> _filtered(List<AppTransaction> all) {
    List<AppTransaction> result = all;

    // filter tipe
    if (_typeFilter == 'Income')
      result = result.where((t) => t.type == 'income').toList();
    else if (_typeFilter == 'Expense')
      result = result.where((t) => t.type == 'expense').toList();
    else if (_typeFilter == 'Transfer')
      result = result.where((t) => t.type == 'transfer').toList();

    // filter kategori
    if (_categoryFilter != 'Semua')
      result = result.where((t) => t.category == _categoryFilter).toList();

    // search
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Map<String, List<AppTransaction>> _groupByDate(List<AppTransaction> txs) {
    final map = <String, List<AppTransaction>>{};
    for (final t in txs) {
      final key = DateFormat('d MMMM yyyy', 'id').format(t.date);
      map[key] = [...(map[key] ?? []), t];
    }
    return map;
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays}h lalu';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TransactionProvider>();
    final ap = context.watch<AccountProvider>();
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final allTxs = tp.transactions;
    final filtered = _filtered(allTxs);
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList();
    final categories = _uniqueCategories(allTxs);

    final totalIncome = filtered
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = filtered
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── AppTopBar
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AppTopBar(),
            ),

            // ── Title + icons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                const Text('Flow History',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                _iconBtn(
                  icon: Icons.search_rounded,
                  active: _searchActive,
                  onTap: () {
                    setState(() => _searchActive = !_searchActive);
                    if (!_searchActive) {
                      _searchCtrl.clear();
                      _searchQuery = '';
                    }
                  },
                ),
                const SizedBox(width: 8),
                _iconBtn(
                  icon: Icons.tune_rounded,
                  active: _typeFilter != 'Semua' || _categoryFilter != 'Semua',
                  onTap: () => _showFilterSheet(context, categories),
                ),
              ]),
            ),

            // ── Search bar
            if (_searchActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style:
                      const TextStyle(color: AppTheme.onSurface, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    hintStyle:
                        const TextStyle(color: AppTheme.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppTheme.onSurfaceVariant, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () => setState(() {
                              _searchCtrl.clear();
                              _searchQuery = '';
                            }),
                            child: const Icon(Icons.close_rounded,
                                color: AppTheme.onSurfaceVariant, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),

            // ── Type filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in ['Semua', 'Income', 'Expense', 'Transfer'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _chip(f, _typeFilter == f,
                            () => setState(() => _typeFilter = f)),
                      ),
                  ],
                ),
              ),
            ),

            // ── Category filter chips (dinamis)
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _chip('Semua', _categoryFilter == 'Semua',
                            () => setState(() => _categoryFilter = 'Semua'),
                            small: true),
                      ),
                      for (final cat in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _chip(cat, _categoryFilter == cat,
                              () => setState(() => _categoryFilter = cat),
                              small: true,
                              icon: _catFor(cat)['icon'] as IconData),
                        ),
                    ],
                  ),
                ),
              ),

            // ── Summary chips
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  _summaryChip(
                      label: 'Pemasukan',
                      amount: fmt.format(totalIncome),
                      color: AppTheme.primary,
                      icon: Icons.arrow_downward_rounded),
                  const SizedBox(width: 10),
                  _summaryChip(
                      label: 'Pengeluaran',
                      amount: fmt.format(totalExpense),
                      color: AppTheme.error,
                      icon: Icons.arrow_upward_rounded),
                ]),
              ),

            const SizedBox(height: 10),

            // ── List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 56,
                              color:
                                  AppTheme.onSurfaceVariant.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text('Belum ada transaksi',
                              style: TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: dateKeys.length,
                      itemBuilder: (ctx, i) {
                        final dateLabel = dateKeys[i];
                        final txsForDate = grouped[dateLabel]!;
                        final dayTotal = txsForDate.fold(0.0, (s, t) {
                          if (t.type == 'income') return s + t.amount;
                          if (t.type == 'expense') return s - t.amount;
                          return s;
                        });
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8, top: 4),
                              child: Row(children: [
                                Text(dateLabel,
                                    style: const TextStyle(
                                        color: AppTheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text(
                                  '${dayTotal >= 0 ? '+' : ''}${fmt.format(dayTotal)}',
                                  style: TextStyle(
                                    color: dayTotal >= 0
                                        ? AppTheme.primary
                                        : AppTheme.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Column(
                                children: [
                                  for (int j = 0;
                                      j < txsForDate.length;
                                      j++) ...[
                                    if (j > 0)
                                      const Divider(
                                          height: 1,
                                          indent: 68,
                                          color: AppTheme.outline),
                                    _buildTxTile(txsForDate[j], fmt, ap, tp),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tile ──────────────────────────────────────────────────────────────────

  Widget _buildTxTile(AppTransaction t, NumberFormat fmt, AccountProvider ap,
      TransactionProvider tp) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final cat = _catFor(t.category);

    String accountName = '';
    if (ap.accounts.isNotEmpty) {
      final fromId = int.tryParse(t.accountId);
      final acc = fromId != null
          ? ap.accounts.where((a) => a.id == fromId).firstOrNull
          : null;
      accountName = acc?.name ?? '';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showDetailSheet(context, t, ap, tp),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: cat['color'] as Color,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(cat['icon'] as IconData,
                color: AppTheme.onSurface, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title,
                  style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Row(children: [
                Text(t.category.toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
                if (accountName.isNotEmpty) ...[
                  const Text(' · ',
                      style: TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 10)),
                  Text(accountName,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 10)),
                ],
                const Text(' · ',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 10)),
                Text(_timeAgo(t.date),
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 10)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              isTransfer
                  ? fmt.format(t.amount)
                  : '${isIncome ? '+' : '-'}${fmt.format(t.amount)}',
              style: TextStyle(
                color: isTransfer
                    ? AppTheme.onSurfaceVariant
                    : isIncome
                        ? AppTheme.primary
                        : AppTheme.error,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (t.note != null && t.note!.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.note_rounded,
                    size: 10, color: AppTheme.onSurfaceVariant),
              ),
          ]),
        ]),
      ),
    );
  }

  // ── Detail Sheet ──────────────────────────────────────────────────────────

  void _showDetailSheet(BuildContext context, AppTransaction t,
      AccountProvider ap, TransactionProvider tp) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final cat = _catFor(t.category);

    String accountName = '';
    String toAccountName = '';
    if (ap.accounts.isNotEmpty) {
      final fromId = int.tryParse(t.accountId);
      final acc = fromId != null
          ? ap.accounts.where((a) => a.id == fromId).firstOrNull
          : null;
      accountName = acc?.name ?? t.accountId;

      if (t.toAccountId != null) {
        final toId = int.tryParse(t.toAccountId!);
        final toAcc = toId != null
            ? ap.accounts.where((a) => a.id == toId).firstOrNull
            : null;
        toAccountName = toAcc?.name ?? t.toAccountId!;
      }
    }

    // RepaintBoundary key for screenshot
    final receiptKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.outline,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header amount
                      Center(
                        child: Column(children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                                color: cat['color'] as Color,
                                borderRadius: BorderRadius.circular(16)),
                            child: Icon(cat['icon'] as IconData,
                                color: AppTheme.onSurface, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isTransfer
                                ? fmt.format(t.amount)
                                : '${isIncome ? '+' : '-'}${fmt.format(t.amount)}',
                            style: TextStyle(
                              color: isTransfer
                                  ? AppTheme.onSurface
                                  : isIncome
                                      ? AppTheme.primary
                                      : AppTheme.error,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(t.title,
                              style: const TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isTransfer
                                      ? AppTheme.onSurfaceVariant
                                      : isIncome
                                          ? AppTheme.primary
                                          : AppTheme.error)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isTransfer
                                  ? 'Transfer'
                                  : isIncome
                                      ? 'Pemasukan'
                                      : 'Pengeluaran',
                              style: TextStyle(
                                color: isTransfer
                                    ? AppTheme.onSurfaceVariant
                                    : isIncome
                                        ? AppTheme.primary
                                        : AppTheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppTheme.outline),
                      const SizedBox(height: 16),

                      // ── Detail rows (wrapped in RepaintBoundary for screenshot)
                      RepaintBoundary(
                        key: receiptKey,
                        child: Container(
                          color: AppTheme.surface,
                          child: Column(
                            children: [
                              _detailRow(
                                  'Tanggal',
                                  DateFormat('EEEE, d MMMM yyyy', 'id')
                                      .format(t.date)),
                              _detailRow(
                                  'Waktu', DateFormat('HH:mm').format(t.date)),
                              _detailRow('Kategori', t.category),
                              _detailRow('Akun', accountName),
                              if (isTransfer && toAccountName.isNotEmpty)
                                _detailRow('Ke Akun', toAccountName),
                              _detailRow('Mata Uang', t.currency),
                              if (t.note != null && t.note!.isNotEmpty)
                                _detailRow('Catatan', t.note!),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Action buttons
                      Row(children: [
                        // Edit
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.edit_rounded,
                            label: 'Edit',
                            color: AppTheme.primary,
                            onTap: () {
                              Navigator.pop(ctx);
                              _showEditSheet(context, t, ap, tp);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Struk (image share)
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.share_rounded,
                            label: 'Struk',
                            color: const Color(0xFF6C63FF),
                            onTap: () => _shareReceiptAsImage(
                                context, receiptKey, t, fmt),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Hapus
                        Expanded(
                          child: _actionBtn(
                            icon: Icons.delete_rounded,
                            label: 'Hapus',
                            color: AppTheme.error,
                            onTap: () {
                              Navigator.pop(ctx);
                              _confirmDelete(context, t, tp, ap);
                            },
                          ),
                        ),
                      ]),

                      const SizedBox(height: 10),

                      // ── Share as text
                      SizedBox(
                        width: double.infinity,
                        child: _actionBtn(
                          icon: Icons.text_snippet_rounded,
                          label: 'Bagikan sebagai Teks',
                          color: AppTheme.onSurfaceVariant,
                          onTap: () => _shareReceiptAsText(t, fmt, accountName),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Sheet ────────────────────────────────────────────────────────────

  void _showEditSheet(BuildContext context, AppTransaction t,
      AccountProvider ap, TransactionProvider tp) {
    final titleCtrl = TextEditingController(text: t.title);
    final amountCtrl = TextEditingController(text: t.amount.toStringAsFixed(0));
    final noteCtrl = TextEditingController(text: t.note ?? '');
    String selectedCategory = t.category;
    final categories = _catMeta.keys.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
          child: StatefulBuilder(builder: (ctx2, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppTheme.outline,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Edit Transaksi',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 16),

                // Title
                _editField(titleCtrl, 'Judul', Icons.title_rounded),
                const SizedBox(height: 12),

                // Amount
                _editField(amountCtrl, 'Jumlah', Icons.attach_money_rounded,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),

                // Category picker
                const Text('Kategori',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setLocal(() => selectedCategory = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: selectedCategory == c
                                        ? AppTheme.primary
                                        : AppTheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(children: [
                                    Icon(
                                      _catFor(c)['icon'] as IconData,
                                      size: 13,
                                      color: selectedCategory == c
                                          ? Colors.white
                                          : AppTheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(c,
                                        style: TextStyle(
                                          color: selectedCategory == c
                                              ? Colors.white
                                              : AppTheme.onSurfaceVariant,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ]),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Note
                _editField(noteCtrl, 'Catatan (opsional)', Icons.note_rounded),
                const SizedBox(height: 20),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final newAmount = double.tryParse(amountCtrl.text
                              .replaceAll('.', '')
                              .replaceAll(',', '')) ??
                          t.amount;
                      final updated = AppTransaction(
                        id: t.id,
                        title: titleCtrl.text.trim().isEmpty
                            ? t.title
                            : titleCtrl.text.trim(),
                        amount: newAmount,
                        type: t.type,
                        category: selectedCategory,
                        currency: t.currency,
                        accountId: t.accountId,
                        toAccountId: t.toAccountId,
                        date: t.date,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                        attachmentPath: t.attachmentPath,
                      );
                      await tp.updateTransaction(updated);
                      if (ctx2.mounted) Navigator.pop(ctx2);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaksi diperbarui'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text('Simpan Perubahan',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Delete Confirm ────────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, AppTransaction t,
      TransactionProvider tp, AccountProvider ap) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Transaksi?',
            style: TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${t.title}\n${fmt.format(t.amount)}',
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tindakan ini tidak bisa dibatalkan.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await tp.deleteTransaction(t.id!, ap);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Transaksi dihapus'),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Hapus',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Share: image ──────────────────────────────────────────────────────────

  Future<void> _shareReceiptAsImage(BuildContext context, GlobalKey key,
      AppTransaction t, NumberFormat fmt) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/struk_${t.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Struk: ${t.title}',
        text: '${t.title} — ${fmt.format(t.amount)}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat struk: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Share: text ───────────────────────────────────────────────────────────

  void _shareReceiptAsText(
      AppTransaction t, NumberFormat fmt, String accountName) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final text = '''
━━━━━━━━━━━━━━━━━━━━
🧾 STRUK TRANSAKSI
━━━━━━━━━━━━━━━━━━━━
📌 ${t.title}
💰 ${isTransfer ? '' : isIncome ? '+' : '-'}${fmt.format(t.amount)}
🏷  Kategori : ${t.category}
🏦 Akun     : $accountName
📅 Tanggal  : ${DateFormat('d MMMM yyyy, HH:mm', 'id').format(t.date)}
${t.note != null && t.note!.isNotEmpty ? '📝 Catatan  : ${t.note}' : ''}
━━━━━━━━━━━━━━━━━━━━
Dibuat dengan WalletScript ✦
''';
    Share.share(text.trim(), subject: 'Struk: ${t.title}');
  }

  // ── Filter Sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext ctx, List<String> categories) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx2, setLocal) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
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
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(children: [
                const Text('Filter Transaksi',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const Spacer(),
                if (_typeFilter != 'Semua' || _categoryFilter != 'Semua')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _typeFilter = 'Semua';
                        _categoryFilter = 'Semua';
                      });
                      setLocal(() {});
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: AppTheme.error)),
                  ),
              ]),
              const SizedBox(height: 4),
              const Text('Tipe',
                  style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in ['Semua', 'Income', 'Expense', 'Transfer'])
                  GestureDetector(
                    onTap: () {
                      setState(() => _typeFilter = f);
                      setLocal(() {});
                    },
                    child: _chip(f, _typeFilter == f, () {}),
                  ),
              ]),
              const SizedBox(height: 16),
              const Text('Kategori',
                  style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _categoryFilter = 'Semua');
                    setLocal(() {});
                  },
                  child: _chip('Semua', _categoryFilter == 'Semua', () {},
                      small: true),
                ),
                for (final cat in categories)
                  GestureDetector(
                    onTap: () {
                      setState(() => _categoryFilter = cat);
                      setLocal(() {});
                    },
                    child: _chip(cat, _categoryFilter == cat, () {},
                        small: true, icon: _catFor(cat)['icon'] as IconData),
                  ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx2),
                  child: const Text('Terapkan',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      }),
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────────

  Widget _iconBtn(
      {required IconData icon,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withOpacity(0.1)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: active ? AppTheme.primary : Colors.transparent),
        ),
        child: Icon(icon,
            color: active ? AppTheme.primary : AppTheme.onSurfaceVariant,
            size: 19),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap,
      {bool small = false, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
            horizontal: small ? 10 : 14, vertical: small ? 5 : 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon,
                size: 11,
                color: selected ? Colors.white : AppTheme.onSurfaceVariant),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.onSurfaceVariant,
                fontSize: small ? 11 : 12,
                fontWeight: FontWeight.w600,
              )),
        ]),
      ),
    );
  }

  Widget _summaryChip(
      {required String label,
      required String amount,
      required Color color,
      required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
              Text(amount,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          const Text(' : ',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  TextField _editField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
        prefixIcon: Icon(icon, color: AppTheme.onSurfaceVariant, size: 18),
        filled: true,
        fillColor: AppTheme.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
