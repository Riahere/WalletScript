import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';
import 'app_top_bar.dart';
import 'spending_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = false;
  String _chartFilter = '30D'; // 'ALL' or '30D'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  List<AppTransaction> _filteredTx(List<AppTransaction> all) {
    if (_chartFilter == 'ALL') return all;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return all.where((t) => t.date.isAfter(cutoff)).toList();
  }

  /// Build daily balance series from a list of transactions (sorted oldest→newest)
  List<_ChartPoint> _buildSeries(List<AppTransaction> txs) {
    if (txs.isEmpty) return [];
    txs.sort((a, b) => a.date.compareTo(b.date));
    final Map<String, double> dailyBalance = {};
    double running = 0;
    for (final t in txs) {
      final key = DateFormat('dd/MM').format(t.date);
      running += t.type == 'income' ? t.amount : -t.amount;
      dailyBalance[key] = running;
    }
    return dailyBalance.entries
        .map((e) => _ChartPoint(e.key, e.value))
        .toList();
  }

  // ── spending by category ────────────────────────────────────────────────────

  Map<String, double> _categoryTotals(List<AppTransaction> txs) {
    final Map<String, double> map = {};
    for (final t in txs) {
      if (t.type == 'expense') {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  // ── chart tap popup ─────────────────────────────────────────────────────────

  void _showChartPopup(
      BuildContext context, _ChartPoint point, NumberFormat fmt) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
        builder: (_) => Positioned(
              top: MediaQuery.of(context).size.height * 0.38,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: () => entry.remove(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outline),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16)
                        ],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(point.label,
                            style: const TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(fmt.format(point.value),
                            style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 16)),
                      ]),
                    ),
                  ),
                ),
              ),
            ));
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ── category color map ───────────────────────────────────────────────────────

  static const List<Color> _catColors = [
    AppTheme.primary,
    Color(0xFF6C63FF),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFEC4899),
  ];

  Color _colorForIndex(int i) => _catColors[i % _catColors.length];

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final filtered = _filteredTx(txProvider.transactions);
    final series = _buildSeries(filtered);
    final catTotals = _categoryTotals(txProvider.transactions);
    final totalExpense = catTotals.values.fold(0.0, (a, b) => a + b);
    final catList = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP BAR ──────────────────────────────────────────────────────
              const AppTopBar(),
              const SizedBox(height: 16),

              // ── REMINDER CARD ─────────────────────────────────────────────────
              _infoCard(
                color: AppTheme.primary,
                icon: Icons.notifications_active_rounded,
                title: 'Reminder',
                subtitle: 'Catat pengeluaran harianmu sekarang.',
              ),
              const SizedBox(height: 10),

              // ── INSIGHT CARD ──────────────────────────────────────────────────
              _infoCard(
                color: const Color(0xFF1E293B),
                icon: Icons.bar_chart_rounded,
                title: 'Insight',
                subtitle: 'Pengeluaran makan 45% lebih tinggi dari biasanya.',
              ),
              const SizedBox(height: 16),

              // ── TOTAL SALDO CARD ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.onSurface.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Saldo',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _balanceHidden = !_balanceHidden),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _balanceHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              key: ValueKey(_balanceHidden),
                              color: AppTheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _balanceHidden
                            ? '••••••••••'
                            : formatter.format(txProvider.balance),
                        key: ValueKey(_balanceHidden),
                        style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 32,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded,
                              color: AppTheme.primary, size: 14),
                          SizedBox(width: 4),
                          Text('+2.4% last 30d',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── BALANCE TREND ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Balance Trend',
                                style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            Text(
                              _chartFilter == '30D'
                                  ? 'Past 30 days activity'
                                  : 'All time activity',
                              style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        Row(children: [
                          _chipBtn('ALL', _chartFilter == 'ALL',
                              () => setState(() => _chartFilter = 'ALL')),
                          const SizedBox(width: 6),
                          _chipBtn('30D', _chartFilter == '30D',
                              () => setState(() => _chartFilter = '30D')),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    series.isEmpty
                        ? SizedBox(
                            height: 90,
                            child: Center(
                              child: Text('Belum ada data transaksi',
                                  style: TextStyle(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 12)),
                            ),
                          )
                        : GestureDetector(
                            onTapDown: (details) {
                              // find nearest point
                              if (series.isEmpty) return;
                              final box =
                                  context.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              final localX = details.localPosition.dx;
                              final width = box.size.width - 40; // padding
                              final idx =
                                  ((localX / width) * (series.length - 1))
                                      .round()
                                      .clamp(0, series.length - 1);
                              _showChartPopup(context, series[idx], formatter);
                            },
                            child: SizedBox(
                              height: 90,
                              child: CustomPaint(
                                size: const Size(double.infinity, 90),
                                painter: _MiniChartPainter(series),
                              ),
                            ),
                          ),
                    const SizedBox(height: 8),
                    if (series.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(series.first.label,
                              style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 10)),
                          if (series.length > 2)
                            Text(series[series.length ~/ 2].label,
                                style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 10)),
                          Text(series.last.label,
                              style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── SPENDING OVERVIEW ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Spending Overview',
                            style: TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SpendingDetailScreen()),
                          ),
                          child: const Icon(Icons.more_vert,
                              color: AppTheme.onSurfaceVariant, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // donut chart
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: totalExpense == 0
                              ? CustomPaint(
                                  painter: _DonutPainter(const [], 0, const []),
                                  child: Center(
                                    child: Text('No data',
                                        style: TextStyle(
                                            color: AppTheme.onSurfaceVariant,
                                            fontSize: 10)),
                                  ),
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: const Size(110, 110),
                                      painter: _DonutPainter(
                                        catList.map((e) => e.value).toList(),
                                        totalExpense,
                                        List.generate(catList.length,
                                            (i) => _colorForIndex(i)),
                                      ),
                                    ),
                                    Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('SPENT',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color:
                                                      AppTheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5)),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatter.format(totalExpense),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.onSurface,
                                                fontWeight: FontWeight.w800),
                                            textAlign: TextAlign.center,
                                          ),
                                        ]),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 24),
                        // category list
                        Expanded(
                          child: catList.isEmpty
                              ? const Center(
                                  child: Text('Belum ada pengeluaran',
                                      style: TextStyle(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 12)))
                              : Column(
                                  children: [
                                    for (int i = 0;
                                        i < catList.take(3).length;
                                        i++) ...[
                                      if (i > 0)
                                        const Divider(
                                            height: 16,
                                            color: AppTheme.outline),
                                      _spendingRowTappable(
                                        context: context,
                                        label: catList[i].key,
                                        color: _colorForIndex(i),
                                        percent: totalExpense > 0
                                            ? '${((catList[i].value / totalExpense) * 100).toStringAsFixed(0)}%'
                                            : '0%',
                                        amount:
                                            formatter.format(catList[i].value),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // ADD CATEGORY button
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showAddCategorySheet(context),
                        icon: const Icon(Icons.add,
                            size: 14, color: AppTheme.onSurfaceVariant),
                        label: const Text('ADD CATEGORY',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── MY WALLETS ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Wallets',
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {},
                    child: const Row(children: [
                      Text('View All',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right_rounded,
                          color: AppTheme.primary, size: 16),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _walletCard('Visa Gold', 'Rp 12.450.000', 'BALANCE',
                        const Color(0xFF1E293B), Colors.white),
                    const SizedBox(width: 12),
                    _walletCard('Tabungan', 'Rp 8.000.000', 'SAVED',
                        AppTheme.primary, Colors.white),
                    const SizedBox(width: 12),
                    _walletCard('Cash', 'Rp 500.000', 'CASH',
                        AppTheme.surfaceContainer, AppTheme.onSurface),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── FLOW HISTORY ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Flow History',
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Row(children: [
                    Icon(Icons.tune_rounded,
                        color: AppTheme.onSurfaceVariant, size: 20),
                    SizedBox(width: 12),
                    Icon(Icons.search_rounded,
                        color: AppTheme.onSurfaceVariant, size: 20),
                  ]),
                ],
              ),
              const SizedBox(height: 12),

              if (txProvider.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: AppTheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      const Text('Belum ada transaksi',
                          style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    ]),
                  ),
                )
              else
                ...txProvider.transactions
                    .take(5)
                    .map((t) => _buildTxTile(t, formatter)),

              if (txProvider.transactions.length > 5)
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('SHOW OLDER TRANSACTIONS',
                        style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── helper widgets ───────────────────────────────────────────────────────────

  static Widget _infoCard(
      {required Color color,
      required IconData icon,
      required String title,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text(subtitle,
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  static Widget _chipBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.outline),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  static Widget _spendingRowTappable({
    required BuildContext context,
    required String label,
    required Color color,
    required String percent,
    required String amount,
  }) {
    return GestureDetector(
      onTap: () => _showCategoryDetail(context, label, color, percent, amount),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: AppTheme.onSurface, fontSize: 13))),
        Text(percent,
            style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded,
            size: 14, color: AppTheme.onSurfaceVariant),
      ]),
    );
  }

  static void _showCategoryDetail(BuildContext context, String label,
      Color color, String percent, String amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.category_outlined, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text('$percent dari total pengeluaran',
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 12)),
                ])),
          ]),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.outline),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
            Text(amount,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          const Text('Tambah Kategori',
              style: TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Kategori baru akan otomatis muncul\nberdasarkan transaksi yang kamu catat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _walletCard(String name, String amount, String label, Color bgColor,
      Color textColor) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(Icons.account_balance_rounded,
                color: textColor.withOpacity(0.7), size: 20),
            Text(name.toUpperCase(),
                style: TextStyle(
                    color: textColor.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ]),
          const Spacer(),
          Text(label,
              style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(amount,
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTxTile(AppTransaction t, NumberFormat formatter) {
    final isIncome = t.type == 'income';
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
    };
    final cat = categoryIcons[t.category] ??
        {'icon': Icons.receipt_rounded, 'color': AppTheme.surfaceContainer};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              color: cat['color'] as Color,
              borderRadius: BorderRadius.circular(14)),
          child: Icon(cat['icon'] as IconData,
              color: AppTheme.onSurface, size: 22),
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
            Text(
              '${t.category.toUpperCase()} · ${_timeAgo(t.date)}',
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ),
        Text(
          '${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
          style: TextStyle(
            color: isIncome ? AppTheme.primary : AppTheme.error,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ]),
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ── Chart point model ────────────────────────────────────────────────────────

class _ChartPoint {
  final String label;
  final double value;
  const _ChartPoint(this.label, this.value);
}

// ── Real-data mini chart painter ─────────────────────────────────────────────

class _MiniChartPainter extends CustomPainter {
  final List<_ChartPoint> points;
  const _MiniChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minVal = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxVal = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();

    Offset toOffset(int i) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final y = range == 0
          ? size.height / 2
          : size.height -
              (size.height * 0.85 * (points[i].value - minVal) / range) -
              size.height * 0.08;
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primary.withOpacity(0.25),
          AppTheme.primary.withOpacity(0.0)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = toOffset(i);
      final p1 = toOffset(i + 1);
      final cp1 = Offset((p0.dx + p1.dx) / 2, p0.dy);
      final cp2 = Offset((p0.dx + p1.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    final last = toOffset(points.length - 1);
    final fillPath = Path.from(path)
      ..lineTo(last.dx, size.height)
      ..lineTo(toOffset(0).dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // dot on last point
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = AppTheme.primary
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter old) => old.points != points;
}

// ── Donut chart painter ───────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double total;
  final List<Color> colors;
  const _DonutPainter(this.values, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;
    double startAngle = -1.5708; // -π/2

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832; // 2π
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
