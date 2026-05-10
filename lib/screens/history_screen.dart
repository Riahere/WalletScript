import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'app_top_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchActive = false;

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

  List<AppTransaction> _filtered(List<AppTransaction> all) {
    List<AppTransaction> result = all;
    if (_filter == 'Income')
      result = result.where((t) => t.type == 'income').toList();
    else if (_filter == 'Expense')
      result = result.where((t) => t.type == 'expense').toList();
    else if (_filter == 'Transfer')
      result = result.where((t) => t.type == 'transfer').toList();

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
    final Map<String, List<AppTransaction>> map = {};
    for (final t in txs) {
      final key = DateFormat('d MMMM yyyy', 'id').format(t.date);
      map[key] = [...(map[key] ?? []), t];
    }
    return map;
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TransactionProvider>();
    final ap = context.watch<AccountProvider>();
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final allTxs = tp.transactions;
    final filtered = _filtered(allTxs);
    final grouped = _groupByDate(filtered);
    final dateKeys = grouped.keys.toList();

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
            // ── AppTopBar (sama persis kayak Home)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AppTopBar(),
            ),

            // ── Title + search/filter icons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(children: [
                const Text('Flow History',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() => _searchActive = !_searchActive);
                    if (!_searchActive) {
                      _searchCtrl.clear();
                      _searchQuery = '';
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _searchActive
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _searchActive
                              ? AppTheme.primary
                              : Colors.transparent),
                    ),
                    child: Icon(Icons.search_rounded,
                        color: _searchActive
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                        size: 19),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _filter != 'All'
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _filter != 'All'
                              ? AppTheme.primary
                              : Colors.transparent),
                    ),
                    child: Icon(Icons.tune_rounded,
                        color: _filter != 'All'
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                        size: 19),
                  ),
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

            // ── Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final f in ['All', 'Income', 'Expense', 'Transfer'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _filter == f
                                ? AppTheme.primary
                                : AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                color: _filter == f
                                    ? Colors.white
                                    : AppTheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ),
                    ),
                ]),
              ),
            ),

            // ── Summary chips
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  _summaryChip(
                    label: 'Pemasukan',
                    amount: formatter.format(totalIncome),
                    color: AppTheme.primary,
                    icon: Icons.arrow_downward_rounded,
                  ),
                  const SizedBox(width: 10),
                  _summaryChip(
                    label: 'Pengeluaran',
                    amount: formatter.format(totalExpense),
                    color: AppTheme.error,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ]),
              ),

            const SizedBox(height: 10),

            // ── Transaction list
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
                                  '${dayTotal >= 0 ? '+' : ''}${formatter.format(dayTotal)}',
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
                                    _buildTxTile(txsForDate[j], formatter, ap),
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

  Widget _buildTxTile(
      AppTransaction t, NumberFormat formatter, AccountProvider ap) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';

    final Map<String, Map<String, dynamic>> categoryIcons = {
      'Makanan': {
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFFD1FAE5)
      },
      'Transport': {
        'icon': Icons.directions_car_rounded,
        'color': const Color(0xFFDBEAFE)
      },
      'Belanja': {
        'icon': Icons.shopping_bag_rounded,
        'color': const Color(0xFFEDE9FE)
      },
      'Hiburan': {
        'icon': Icons.gamepad_rounded,
        'color': const Color(0xFFFEF3C7)
      },
      'Kesehatan': {
        'icon': Icons.health_and_safety_rounded,
        'color': const Color(0xFFFFE4E6)
      },
      'Gaji': {
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFFD1FAE5)
      },
      'Travel': {
        'icon': Icons.flight_takeoff_rounded,
        'color': const Color(0xFFE0F2FE)
      },
      'Edu': {'icon': Icons.school_rounded, 'color': const Color(0xFFE0F2FE)},
      'Transfer': {
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFFF3E8FF)
      },
      'Saldo Awal': {
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFFD1FAE5)
      },
    };

    final cat = categoryIcons[t.category] ??
        {'icon': Icons.receipt_rounded, 'color': AppTheme.surfaceContainer};

    String accountName = '';
    if (ap.accounts.isNotEmpty) {
      final fromId = int.tryParse(t.accountId);
      final acc = fromId != null
          ? ap.accounts.where((a) => a.id == fromId).firstOrNull
          : null;
      accountName = acc?.name ?? '';
    }

    return Padding(
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
        Text(
          isTransfer
              ? formatter.format(t.amount)
              : '${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
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
      ]),
    );
  }

  Widget _summaryChip({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
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

  void _showFilterSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
            const Text('Filter Transaksi',
                style: TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in ['All', 'Income', 'Expense', 'Transfer'])
                GestureDetector(
                  onTap: () {
                    setState(() => _filter = f);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _filter == f
                          ? AppTheme.primary
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          color:
                              _filter == f ? Colors.white : AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                  ),
                ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
