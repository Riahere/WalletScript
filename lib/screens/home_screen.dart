import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/note_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/note_model.dart';
import '../models/account_model.dart';
import '../main.dart';
import 'app_top_bar.dart';
import 'spending_detail_screen.dart';
import 'notification_screen.dart';
import 'wallet_all_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = false;
  String _chartFilter = '30D';
  String _txFilter = 'All';
  String _searchQuery = '';
  bool _searchActive = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<NoteProvider>().loadNotes();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  List<AppTransaction> _filteredTx(List<AppTransaction> all) {
    if (_chartFilter == 'ALL') return all;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return all.where((t) => t.date.isAfter(cutoff)).toList();
  }

  List<AppTransaction> _filteredDashboardTx(List<AppTransaction> all) {
    List<AppTransaction> result = all;
    if (_txFilter == 'Income')
      result = result.where((t) => t.type == 'income').toList();
    else if (_txFilter == 'Expense')
      result = result.where((t) => t.type == 'expense').toList();
    else if (_txFilter != 'All')
      result = result.where((t) => t.category == _txFilter).toList();

    if (_searchQuery.isNotEmpty) {
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return result;
  }

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

  Map<String, double> _categoryTotals(List<AppTransaction> txs) {
    final Map<String, double> map = {};
    for (final t in txs) {
      if (t.type == 'expense')
        map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  void _showChartPopup(BuildContext ctx, _ChartPoint point, NumberFormat fmt) {
    final overlay = Overlay.of(ctx);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(ctx).size.height * 0.38,
        left: 0,
        right: 0,
        child: Center(
            child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () => entry.remove(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12), blurRadius: 16)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(point.label,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 11)),
                const SizedBox(height: 4),
                Text(fmt.format(point.value),
                    style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ]),
            ),
          ),
        )),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

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

  AppNote? _nextReminder(List<AppNote> notes) {
    final now = DateTime.now();
    final upcoming = notes
        .where((n) =>
            n.hasReminder &&
            n.reminderDate != null &&
            n.reminderDate!.isAfter(now.subtract(const Duration(hours: 1))))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));
    return upcoming.first;
  }

  String _reminderSubtitle(AppNote? note) {
    if (note == null) return 'Catat pengeluaran harianmu sekarang.';
    final diff = note.reminderDate!.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${note.title} — ${diff.inMinutes}m lagi';
    if (diff.inHours < 24) return '${note.title} — ${diff.inHours}j lagi';
    return '${note.title} — ${DateFormat('d MMM HH:mm').format(note.reminderDate!)}';
  }

  String _insightSubtitle(TransactionProvider tx) {
    if (tx.totalIncome == 0 && tx.totalExpense == 0)
      return 'Belum ada transaksi. Mulai catat sekarang!';
    final ratio = tx.totalIncome > 0 ? tx.totalExpense / tx.totalIncome : 1.0;
    if (ratio >= 0.9) return 'Pengeluaran hampir melebihi pemasukan! Waspada.';
    if (ratio >= 0.7)
      return 'Pengeluaran ${(ratio * 100).toStringAsFixed(0)}% dari pemasukan. Hati-hati!';
    final now = DateTime.now();
    final monthTx = tx.transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList();
    if (monthTx.isEmpty) return 'Keuanganmu sehat! Pengeluaran terkontrol.';
    final Map<String, double> cats = {};
    for (final t in monthTx)
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    final top = cats.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topPct = (top.value / tx.totalExpense * 100).toStringAsFixed(0);
    return 'Terbesar: ${top.key} $topPct% dari pengeluaran bulan ini.';
  }

  Color _insightColor(TransactionProvider tx) {
    if (tx.totalIncome == 0) return const Color(0xFF1E293B);
    final ratio = tx.totalExpense / tx.totalIncome;
    if (ratio >= 0.9) return AppTheme.error;
    if (ratio >= 0.7) return Colors.orange;
    return const Color(0xFF1E293B);
  }

  String _balanceTrend(List<AppTransaction> txs) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final recent = txs.where((t) => t.date.isAfter(cutoff)).toList();
    if (recent.isEmpty) return '';
    double net = 0;
    double prevBalance = 0;
    for (final t in txs) {
      if (t.date.isBefore(cutoff)) {
        prevBalance += t.type == 'income' ? t.amount : -t.amount;
      }
    }
    for (final t in recent) {
      net += t.type == 'income' ? t.amount : -t.amount;
    }
    if (prevBalance == 0) return net >= 0 ? '+∞%' : '-∞%';
    final pct = (net / prevBalance.abs() * 100);
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% last 30d';
  }

  bool _isTrendPositive(List<AppTransaction> txs) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    double net = 0;
    for (final t in txs.where((t) => t.date.isAfter(cutoff))) {
      net += t.type == 'income' ? t.amount : -t.amount;
    }
    return net >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final noteProvider = context.watch<NoteProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final totalBalance = accountProvider.accounts.isNotEmpty
        ? accountProvider.totalBalance
        : txProvider.balance;

    final filtered = _filteredTx(txProvider.transactions);
    final series = _buildSeries(filtered);
    final catTotals = _categoryTotals(txProvider.transactions);
    final totalExpense = catTotals.values.fold(0.0, (a, b) => a + b);
    final catList = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final nextReminder = _nextReminder(noteProvider.notes);
    final insightColor = _insightColor(txProvider);
    final dashboardTxs = _filteredDashboardTx(txProvider.transactions);
    final allCategories =
        txProvider.transactions.map((t) => t.category).toSet().toList();
    final byGroup = accountProvider.accountsByGroup;

    final trendText = _balanceTrend(txProvider.transactions);
    final trendPositive = _isTrendPositive(txProvider.transactions);

    void goToNotif() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const NotificationScreen()));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(),
              const SizedBox(height: 16),

              // ── REMINDER CARD
              _tappableInfoCard(
                color: AppTheme.primary,
                icon: Icons.notifications_active_rounded,
                title: 'Reminder',
                subtitle: _reminderSubtitle(nextReminder),
                onTap: goToNotif,
                badge: nextReminder != null,
              ),
              const SizedBox(height: 10),

              // ── INSIGHT CARD
              _tappableInfoCard(
                color: insightColor,
                icon: Icons.bar_chart_rounded,
                title: 'Insight',
                subtitle: _insightSubtitle(txProvider),
                onTap: goToNotif,
              ),
              const SizedBox(height: 16),

              // ── TOTAL SALDO
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WalletAllScreen())),
                child: Container(
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
                          offset: const Offset(0, 4))
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
                              Row(children: [
                                GestureDetector(
                                  onTap: () => setState(
                                      () => _balanceHidden = !_balanceHidden),
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
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppTheme.onSurfaceVariant, size: 18),
                              ]),
                            ]),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _balanceHidden
                                ? '••••••••••'
                                : formatter.format(totalBalance),
                            key: ValueKey(_balanceHidden),
                            style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 32,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (trendText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: trendPositive
                                    ? AppTheme.primary.withOpacity(0.1)
                                    : AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  trendPositive
                                      ? Icons.trending_up_rounded
                                      : Icons.trending_down_rounded,
                                  color: trendPositive
                                      ? AppTheme.primary
                                      : AppTheme.error,
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(trendText,
                                  style: TextStyle(
                                      color: trendPositive
                                          ? AppTheme.primary
                                          : AppTheme.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded,
                                      color: AppTheme.primary, size: 14),
                                  SizedBox(width: 4),
                                  Text('Tap untuk lihat detail wallet',
                                      style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ]),
                          ),
                      ]),
                ),
              ),
              const SizedBox(height: 16),

              // ── BALANCE TREND
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
                                          fontSize: 12)),
                                ]),
                            Row(children: [
                              _chipBtn('ALL', _chartFilter == 'ALL',
                                  () => setState(() => _chartFilter = 'ALL')),
                              const SizedBox(width: 6),
                              _chipBtn('30D', _chartFilter == '30D',
                                  () => setState(() => _chartFilter = '30D')),
                            ]),
                          ]),
                      const SizedBox(height: 16),
                      series.isEmpty
                          ? const SizedBox(
                              height: 90,
                              child: Center(
                                  child: Text('Belum ada data transaksi',
                                      style: TextStyle(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 12))))
                          : GestureDetector(
                              onTapDown: (details) {
                                if (series.isEmpty) return;
                                final box =
                                    context.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final localX = details.localPosition.dx;
                                final width = box.size.width - 40;
                                final idx =
                                    ((localX / width) * (series.length - 1))
                                        .round()
                                        .clamp(0, series.length - 1);
                                _showChartPopup(
                                    context, series[idx], formatter);
                              },
                              child: SizedBox(
                                  height: 90,
                                  child: CustomPaint(
                                      size: const Size(double.infinity, 90),
                                      painter: _MiniChartPainter(series))),
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
                            ]),
                    ]),
              ),
              const SizedBox(height: 16),

              // ── SPENDING OVERVIEW
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
                                      builder: (_) => SpendingDetailScreen())),
                              child: const Icon(Icons.more_vert,
                                  color: AppTheme.onSurfaceVariant, size: 20),
                            ),
                          ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: totalExpense == 0
                              ? CustomPaint(
                                  painter: _DonutPainter(const [], 0, const []),
                                  child: const Center(
                                      child: Text('No data',
                                          style: TextStyle(
                                              color: AppTheme.onSurfaceVariant,
                                              fontSize: 10))))
                              : Stack(alignment: Alignment.center, children: [
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
                                        Text(formatter.format(totalExpense),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.onSurface,
                                                fontWeight: FontWeight.w800),
                                            textAlign: TextAlign.center),
                                      ]),
                                ]),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: catList.isEmpty
                              ? const Center(
                                  child: Text('Belum ada pengeluaran',
                                      style: TextStyle(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 12)))
                              : Column(children: [
                                  for (int i = 0;
                                      i < catList.take(3).length;
                                      i++) ...[
                                    if (i > 0)
                                      const Divider(
                                          height: 16, color: AppTheme.outline),
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
                                ]),
                        ),
                      ]),
                    ]),
              ),
              const SizedBox(height: 16),

              // ── MY WALLETS
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('My Wallets',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WalletAllScreen())),
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
              ]),
              const SizedBox(height: 12),

              if (byGroup.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline)),
                  child: const Center(
                      child: Text('Belum ada wallet',
                          style: TextStyle(color: AppTheme.onSurfaceVariant))),
                )
              else
                _FolderWalletCards(byGroup: byGroup, formatter: formatter),

              const SizedBox(height: 20),

              // ── FLOW HISTORY
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Flow History',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Row(children: [
                  GestureDetector(
                    onTap: () => _showFilterSheet(context, allCategories),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _txFilter != 'All'
                            ? AppTheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _txFilter != 'All'
                                ? AppTheme.primary
                                : AppTheme.outline),
                      ),
                      child: Row(children: [
                        Icon(Icons.tune_rounded,
                            color: _txFilter != 'All'
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                            size: 16),
                        if (_txFilter != 'All') ...[
                          const SizedBox(width: 4),
                          Text(_txFilter,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ]
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() => _searchActive = !_searchActive);
                      if (!_searchActive) {
                        _searchCtrl.clear();
                        _searchQuery = '';
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _searchActive
                            ? AppTheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _searchActive
                                ? AppTheme.primary
                                : Colors.transparent),
                      ),
                      child: Icon(Icons.search_rounded,
                          color: _searchActive
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                          size: 20),
                    ),
                  ),
                ]),
              ]),

              if (_searchActive) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  style:
                      const TextStyle(color: AppTheme.onSurface, fontSize: 14),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari transaksi...',
                    hintStyle: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 14),
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
              ],
              const SizedBox(height: 12),

              if (dashboardTxs.isEmpty)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: const [
                    Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppTheme.onSurfaceVariant),
                    SizedBox(height: 12),
                    Text('Belum ada transaksi',
                        style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  ]),
                ))
              else
                ...dashboardTxs.take(5).map((t) => _buildTxTile(t, formatter)),

              // ── LIHAT SEMUA TRANSAKSI → navigate ke History tab
              if (txProvider.transactions.length > 5)
                Center(
                  child: TextButton(
                    onPressed: () {
                      final shell =
                          context.findAncestorStateOfType<MainShellState>();
                      shell?.goTo(1);
                    },
                    child: const Text('LIHAT SEMUA TRANSAKSI',
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

  void _showFilterSheet(BuildContext ctx, List<String> categories) {
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Filter Transaksi',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in ['All', 'Income', 'Expense', ...categories])
                  GestureDetector(
                    onTap: () {
                      setState(() => _txFilter = f);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _txFilter == f
                            ? AppTheme.primary
                            : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            color: _txFilter == f
                                ? Colors.white
                                : AppTheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          )),
                    ),
                  ),
              ]),
              const SizedBox(height: 24),
            ]),
      ),
    );
  }

  static Widget _tappableInfoCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline)),
        child: Row(children: [
          Stack(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 20)),
            if (badge)
              Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle))),
          ]),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceVariant, size: 16),
        ]),
      ),
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
                fontWeight: FontWeight.w600)),
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

  static void _showCategoryDetail(BuildContext ctx, String label, Color color,
      String percent, String amount) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppTheme.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.category_outlined, color: color, size: 24)),
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
                color: AppTheme.onSurface, size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          Text('${t.category.toUpperCase()} · ${_timeAgo(t.date)}',
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ])),
        Text('${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
            style: TextStyle(
                color: isIncome ? AppTheme.primary : AppTheme.error,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
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

// ── FOLDER WALLET CARDS ───────────────────────────────────────────────────────

class _FolderWalletCards extends StatefulWidget {
  final Map<String, List<AppAccount>> byGroup;
  final NumberFormat formatter;
  const _FolderWalletCards({required this.byGroup, required this.formatter});
  @override
  State<_FolderWalletCards> createState() => _FolderWalletCardsState();
}

class _FolderWalletCardsState extends State<_FolderWalletCards> {
  int _selectedIndex = 0;
  final Map<String, bool> _hidden = {};

  static const List<List<Color>> _cardGradients = [
    [Color(0xFF6366F1), Color(0xFF4F46E5)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFF14B8A6), Color(0xFF0D9488)],
    [Color(0xFFF97316), Color(0xFFEA580C)],
    [Color(0xFF06B6D4), Color(0xFF0891B2)],
    [Color(0xFF84CC16), Color(0xFF65A30D)],
  ];

  static const List<Color> _tabColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFF84CC16),
  ];

  static const Map<String, IconData> _groupIcons = {
    'Cash': Icons.payments_rounded,
    'Accounts': Icons.account_balance_rounded,
    'Card': Icons.credit_card_rounded,
    'Debit Card': Icons.credit_card_outlined,
    'Savings': Icons.savings_rounded,
    'Top-Up/Prepaid': Icons.phone_android_rounded,
    'Investments': Icons.trending_up_rounded,
    'Overdrafts': Icons.warning_amber_rounded,
    'Loan': Icons.request_quote_rounded,
    'Insurance': Icons.health_and_safety_rounded,
    'Others': Icons.wallet_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final groups = widget.byGroup.entries.toList();
    if (_selectedIndex >= groups.length) _selectedIndex = 0;

    final selected = groups[_selectedIndex];
    final gradColors = _cardGradients[_selectedIndex % _cardGradients.length];
    final groupTotal = selected.value.fold(0.0, (s, a) => s + a.balance);
    final isHidden = _hidden[selected.key] ?? false;
    final icon = _groupIcons[selected.key] ?? Icons.wallet_rounded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            itemBuilder: (_, i) {
              final isSelected = i == _selectedIndex;
              final color = _tabColors[i % _tabColors.length];
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color : AppTheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            )
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          _groupIcons[groups[i].key] ?? Icons.wallet_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        groups[i].key,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey(_selectedIndex),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                    color: gradColors[0].withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(selected.key,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text('${selected.value.length} akun',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12)),
                    ])),
                GestureDetector(
                  onTap: () =>
                      setState(() => _hidden[selected.key] = !isHidden),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                        isHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white,
                        size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Saldo',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          isHidden
                              ? '••••••••'
                              : widget.formatter.format(groupTotal),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (selected.value.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(0.15)),
                const SizedBox(height: 12),
                ...selected.value.take(3).map((acc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(acc.name,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500))),
                        Text(
                          isHidden
                              ? '••••'
                              : widget.formatter.format(acc.balance),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    )),
                if (selected.value.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('+${selected.value.length - 3} akun lainnya',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11)),
                  ),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Painters & Models ─────────────────────────────────────────────────────────

class _ChartPoint {
  final String label;
  final double value;
  const _ChartPoint(this.label, this.value);
}

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
          ]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(toOffset(0).dx, toOffset(0).dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = toOffset(i);
      final p1 = toOffset(i + 1);
      path.cubicTo(
          (p0.dx + p1.dx) / 2, p0.dy, (p0.dx + p1.dx) / 2, p1.dy, p1.dx, p1.dy);
    }
    final last = toOffset(points.length - 1);
    final fillPath = Path.from(path)
      ..lineTo(last.dx, size.height)
      ..lineTo(toOffset(0).dx, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
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

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double total;
  final List<Color> colors;
  const _DonutPainter(this.values, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 14.0;
    double startAngle = -1.5708;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832;
      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: size.width / 2 - strokeWidth / 2),
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
