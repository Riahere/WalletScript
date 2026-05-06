import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';
import 'app_top_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Semua';
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _filters = ['Semua', 'Makanan', 'Transport', 'Belanja', 'Pemasukan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final allTx = txProvider.transactions;
    final filtered = allTx.where((t) {
      final matchFilter = _filter == 'Semua' ||
          (_filter == 'Pemasukan' && t.type == 'income') ||
          t.category == _filter;
      final matchSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();

    final Map<String, List<AppTransaction>> grouped = {};
    for (final t in filtered) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      String key;
      if (txDate == today) key = 'TODAY';
      else if (txDate == yesterday) key = 'YESTERDAY';
      else key = DateFormat('d MMMM yyyy', 'id').format(t.date).toUpperCase();
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  const AppTopBar(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari transaksi...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant),
                      filled: true,
                      fillColor: AppTheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _filters.map((f) {
                        final isSelected = _filter == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('Tidak ada transaksi',
                            style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: grouped.length,
                      itemBuilder: (context, i) {
                        final dateKey = grouped.keys.elementAt(i);
                        final txList = grouped[dateKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(dateKey,
                                  style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                                  )),
                            ),
                            ...txList.map((t) => _buildTxTile(t, formatter, context)),
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

  Widget _buildTxTile(AppTransaction t, NumberFormat formatter, BuildContext context) {
    final isIncome = t.type == 'income';
    final Map<String, Map<String, dynamic>> categoryIcons = {
      'Makanan': {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFD1FAE5)},
      'Transport': {'icon': Icons.directions_car_rounded, 'color': const Color(0xFFDBEAFE)},
      'Belanja': {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEDE9FE)},
      'Hiburan': {'icon': Icons.gamepad_rounded, 'color': const Color(0xFFFEF3C7)},
      'Kesehatan': {'icon': Icons.health_and_safety_rounded, 'color': const Color(0xFFFFE4E6)},
      'Gaji': {'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFD1FAE5)},
    };
    final cat = categoryIcons[t.category] ?? {'icon': Icons.receipt_rounded, 'color': AppTheme.surfaceContainer};

    return Dismissible(
      key: Key(t.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.error),
      ),
      onDismissed: (_) {
        context.read<TransactionProvider>().deleteTransaction(t.id!);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi dihapus')));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: cat['color'] as Color, borderRadius: BorderRadius.circular(12)),
              child: Icon(cat['icon'] as IconData, color: AppTheme.onSurface, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title,
                    style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${t.category} • ${DateFormat('hh:mm a').format(t.date)}',
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
              ]),
            ),
            Text(
              '${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
              style: TextStyle(
                color: isIncome ? AppTheme.primary : const Color(0xFFDC2626),
                fontWeight: FontWeight.w700, fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
