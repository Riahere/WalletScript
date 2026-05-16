// lib/screens/home_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/note_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../models/note_model.dart';
import '../models/account_model.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'app_top_bar.dart';
import 'spending_detail_screen.dart';
import 'notification_screen.dart';
import 'wallet_all_screen.dart';

const _navy = Color(0xFF0D1B3E);
const _yellow = Color(0xFFF5C842);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _balanceHidden = false;
  String _chartFilter = '30D';
  String _txFilter = 'All';
  String _searchQuery = '';
  bool _searchActive = false;
  bool _syncing = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _floatCtrl;
  late AnimationController _staggerCtrl;
  late AnimationController _balanceCtrl;
  late Animation<double> _balanceAnim;

  double _lastBalance = 0;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat(reverse: true);

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _balanceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _balanceAnim =
        CurvedAnimation(parent: _balanceCtrl, curve: Curves.easeOutCubic);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<TransactionProvider>().loadTransactions();
      context.read<NoteProvider>().loadNotes();
      context.read<AccountProvider>().loadAccounts();

      // Pull from Supabase if logged in
      final userId = AuthService().userId;
      if (userId != null) {
        setState(() => _syncing = true);
        try {
          final result = await SyncService().pullFromCloud();
          if (mounted && !result.hasError) {
            if (result.accounts.isNotEmpty) {
              context.read<AccountProvider>().loadAccounts();
            }
            if (result.transactions.isNotEmpty) {
              context.read<TransactionProvider>().loadTransactions();
            }
          }
        } catch (_) {}
        if (mounted) setState(() => _syncing = false);
      }

      _staggerCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _balanceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _staggerCtrl.dispose();
    _balanceCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Stagger helper ─────────────────────────────────────────────────────────
  Animation<double> _stagger(int index, {int total = 8}) {
    final start = index / (total + 2);
    final end = (index + 2) / (total + 2);
    return CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOutCubic),
    );
  }

  // ── Data helpers ───────────────────────────────────────────────────────────
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
      if (t.type == 'transfer') continue;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _yellow.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _navy.withOpacity(0.3), blurRadius: 20)
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(point.label,
                      style: GoogleFonts.dmMono(
                          color: Colors.white.withOpacity(0.6), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(fmt.format(point.value),
                      style: GoogleFonts.dmSans(
                          color: _yellow,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ]),
              ),
            ),
          ),
        ),
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

  String _balanceTrend(List<AppTransaction> txs) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final recent = txs
        .where((t) => t.date.isAfter(cutoff) && t.type != 'transfer')
        .toList();
    if (recent.isEmpty) return '';
    double net = 0;
    double prevBalance = 0;
    for (final t in txs) {
      if (t.date.isBefore(cutoff) && t.type != 'transfer') {
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
    for (final t
        in txs.where((t) => t.date.isAfter(cutoff) && t.type != 'transfer')) {
      net += t.type == 'income' ? t.amount : -t.amount;
    }
    return net >= 0;
  }

  // ── Finance background icons ───────────────────────────────────────────────
  List<Widget> _buildBgIcons(Size size) {
    final items = [
      [Icons.bar_chart_rounded, 0.05, 0.02, 28.0, 0.0],
      [Icons.savings_outlined, 0.80, 0.04, 22.0, 0.5],
      [Icons.trending_up_rounded, 0.90, 0.12, 26.0, 0.2],
      [Icons.monetization_on_outlined, 0.02, 0.20, 20.0, 0.8],
      [Icons.credit_card_rounded, 0.88, 0.35, 20.0, 0.3],
      [Icons.show_chart_rounded, 0.03, 0.50, 24.0, 0.9],
      [Icons.pie_chart_outline_rounded, 0.88, 0.58, 20.0, 0.7],
      [Icons.account_balance_outlined, 0.04, 0.72, 22.0, 0.4],
      [Icons.currency_exchange_rounded, 0.80, 0.80, 18.0, 0.65],
      [Icons.receipt_long_outlined, 0.45, 0.95, 20.0, 0.35],
      [Icons.wallet_outlined, 0.92, 0.90, 18.0, 0.55],
    ];
    return items.map((d) {
      final dy =
          math.sin((_floatCtrl.value + (d[4] as double)) * math.pi * 2) * 6;
      return Positioned(
        left: (d[1] as double) * size.width,
        top: (d[2] as double) * size.height + dy,
        child: Icon(d[0] as IconData,
            size: d[3] as double, color: _navy.withOpacity(0.045)),
      );
    }).toList();
  }

  // ── Slide+fade wrapper ─────────────────────────────────────────────────────
  Widget _animated(Widget child, Animation<double> anim) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  // ── Press effect wrapper ───────────────────────────────────────────────────
  Widget _pressable({required Widget child, required VoidCallback onTap}) {
    return _PressableWidget(onTap: onTap, child: child);
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
    final dashboardTxs = _filteredDashboardTx(txProvider.transactions);
    final allCategories =
        txProvider.transactions.map((t) => t.category).toSet().toList();
    final byGroup = accountProvider.accountsByGroup;
    final trendText = _balanceTrend(txProvider.transactions);
    final trendPositive = _isTrendPositive(txProvider.transactions);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          final size = MediaQuery.of(context).size;
          return Stack(
            children: [
              // ── Floating background finance icons
              ..._buildBgIcons(size),

              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TOP BAR
                      _animated(
                        Row(
                          children: [
                            const Expanded(child: AppTopBar()),
                            if (_syncing)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _navy.withOpacity(0.4),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        _stagger(0),
                      ),
                      const SizedBox(height: 16),

                      // ── REMINDER CARD
                      _animated(
                        _tappableInfoCard(
                          icon: Icons.notifications_active_rounded,
                          title: 'Reminder',
                          subtitle: _reminderSubtitle(nextReminder),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationScreen())),
                          badge: nextReminder != null,
                          accentColor: _yellow,
                        ),
                        _stagger(1),
                      ),
                      const SizedBox(height: 10),

                      // ── INSIGHT CARD
                      _animated(
                        _tappableInfoCard(
                          icon: Icons.bar_chart_rounded,
                          title: 'Insight',
                          subtitle: _insightSubtitle(txProvider),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationScreen())),
                          accentColor: _yellow,
                        ),
                        _stagger(2),
                      ),
                      const SizedBox(height: 16),

                      // ── TOTAL SALDO
                      _animated(
                        _pressable(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WalletAllScreen())),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: _navy,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                    color: _navy.withOpacity(0.25),
                                    blurRadius: 32,
                                    offset: const Offset(0, 10)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Saldo',
                                        style: GoogleFonts.dmSans(
                                            color:
                                                Colors.white.withOpacity(0.55),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    Row(children: [
                                      GestureDetector(
                                        onTap: () => setState(() =>
                                            _balanceHidden = !_balanceHidden),
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          child: Icon(
                                            _balanceHidden
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            key: ValueKey(_balanceHidden),
                                            color:
                                                Colors.white.withOpacity(0.55),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(Icons.chevron_right_rounded,
                                          color: Colors.white.withOpacity(0.4),
                                          size: 18),
                                    ]),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _balanceHidden
                                      ? Text('••••••••••',
                                          key: const ValueKey('hidden'),
                                          style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800))
                                      : AnimatedBuilder(
                                          key: const ValueKey('shown'),
                                          animation: _balanceAnim,
                                          builder: (_, __) => Text(
                                            formatter.format(totalBalance *
                                                _balanceAnim.value),
                                            style: GoogleFonts.dmSans(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                // Trend badge
                                if (trendText.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: trendPositive
                                            ? _yellow.withOpacity(0.15)
                                            : Colors.red.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                              trendPositive
                                                  ? Icons.trending_up_rounded
                                                  : Icons.trending_down_rounded,
                                              color: trendPositive
                                                  ? _yellow
                                                  : Colors.redAccent,
                                              size: 14),
                                          const SizedBox(width: 4),
                                          Text(trendText,
                                              style: GoogleFonts.dmSans(
                                                  color: trendPositive
                                                      ? _yellow
                                                      : Colors.redAccent,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                        ]),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                        color: _yellow.withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.trending_up_rounded,
                                              color: _yellow, size: 14),
                                          const SizedBox(width: 4),
                                          Text('Tap untuk lihat detail wallet',
                                              style: GoogleFonts.dmSans(
                                                  color: _yellow,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600)),
                                        ]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        _stagger(3),
                      ),
                      const SizedBox(height: 14),

                      // ── BALANCE TREND
                      _animated(
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _navy.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: _navy.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Balance Trend',
                                          style: GoogleFonts.dmSans(
                                              color: _navy,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15)),
                                      Text(
                                          _chartFilter == '30D'
                                              ? 'Past 30 days activity'
                                              : 'All time activity',
                                          style: GoogleFonts.dmSans(
                                              color: _navy.withOpacity(0.45),
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Row(children: [
                                    _chipBtn(
                                        'ALL',
                                        _chartFilter == 'ALL',
                                        () => setState(
                                            () => _chartFilter = 'ALL')),
                                    const SizedBox(width: 6),
                                    _chipBtn(
                                        '30D',
                                        _chartFilter == '30D',
                                        () => setState(
                                            () => _chartFilter = '30D')),
                                  ]),
                                ],
                              ),
                              const SizedBox(height: 16),
                              series.isEmpty
                                  ? SizedBox(
                                      height: 90,
                                      child: Center(
                                          child: Text(
                                              'Belum ada data transaksi',
                                              style: GoogleFonts.dmSans(
                                                  color: _navy.withOpacity(0.4),
                                                  fontSize: 12))))
                                  : GestureDetector(
                                      onTapDown: (details) {
                                        if (series.isEmpty) return;
                                        final box = context.findRenderObject()
                                            as RenderBox?;
                                        if (box == null) return;
                                        final localX = details.localPosition.dx;
                                        final width = box.size.width - 40;
                                        final idx = ((localX / width) *
                                                (series.length - 1))
                                            .round()
                                            .clamp(0, series.length - 1);
                                        _showChartPopup(
                                            context, series[idx], formatter);
                                      },
                                      child: SizedBox(
                                          height: 90,
                                          child: CustomPaint(
                                              size: const Size(
                                                  double.infinity, 90),
                                              painter:
                                                  _MiniChartPainter(series))),
                                    ),
                              const SizedBox(height: 8),
                              if (series.isNotEmpty)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(series.first.label,
                                        style: GoogleFonts.dmMono(
                                            color: _navy.withOpacity(0.4),
                                            fontSize: 10)),
                                    if (series.length > 2)
                                      Text(series[series.length ~/ 2].label,
                                          style: GoogleFonts.dmMono(
                                              color: _navy.withOpacity(0.4),
                                              fontSize: 10)),
                                    Text(series.last.label,
                                        style: GoogleFonts.dmMono(
                                            color: _navy.withOpacity(0.4),
                                            fontSize: 10)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        _stagger(4),
                      ),
                      const SizedBox(height: 14),

                      // ── SPENDING OVERVIEW
                      _animated(
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _navy.withOpacity(0.1), width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: _navy.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Spending Overview',
                                      style: GoogleFonts.dmSans(
                                          color: _navy,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                SpendingDetailScreen())),
                                    child: Icon(Icons.more_vert,
                                        color: _navy.withOpacity(0.4),
                                        size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(children: [
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: totalExpense == 0
                                      ? CustomPaint(
                                          painter: _DonutPainter(
                                              const [], 0, const []),
                                          child: Center(
                                              child: Text('No data',
                                                  style: GoogleFonts.dmSans(
                                                      color: _navy
                                                          .withOpacity(0.3),
                                                      fontSize: 10))))
                                      : Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CustomPaint(
                                              size: const Size(110, 110),
                                              painter: _DonutPainter(
                                                catList
                                                    .map((e) => e.value)
                                                    .toList(),
                                                totalExpense,
                                                List.generate(catList.length,
                                                    (i) => _colorForIndex(i)),
                                              ),
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('SPENT',
                                                    style: GoogleFonts.dmMono(
                                                        fontSize: 9,
                                                        color: _navy
                                                            .withOpacity(0.45),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 0.5)),
                                                const SizedBox(height: 2),
                                                Text(
                                                    formatter
                                                        .format(totalExpense),
                                                    style: GoogleFonts.dmSans(
                                                        fontSize: 11,
                                                        color: _navy,
                                                        fontWeight:
                                                            FontWeight.w800),
                                                    textAlign:
                                                        TextAlign.center),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: catList.isEmpty
                                      ? Center(
                                          child: Text('Belum ada pengeluaran',
                                              style: GoogleFonts.dmSans(
                                                  color: _navy.withOpacity(0.4),
                                                  fontSize: 12)))
                                      : Column(children: [
                                          for (int i = 0;
                                              i < catList.take(3).length;
                                              i++) ...[
                                            if (i > 0)
                                              Divider(
                                                  height: 16,
                                                  color:
                                                      _navy.withOpacity(0.08)),
                                            _spendingRowTappable(
                                              context: context,
                                              label: catList[i].key,
                                              color: _colorForIndex(i),
                                              percent: totalExpense > 0
                                                  ? '${((catList[i].value / totalExpense) * 100).toStringAsFixed(0)}%'
                                                  : '0%',
                                              amount: formatter
                                                  .format(catList[i].value),
                                            ),
                                          ],
                                        ]),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        _stagger(5),
                      ),
                      const SizedBox(height: 14),

                      // ── MY WALLETS header
                      _animated(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('My Wallets',
                                style: GoogleFonts.dmSans(
                                    color: _navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const WalletAllScreen())),
                              child: Row(children: [
                                Text('View All',
                                    style: GoogleFonts.dmSans(
                                        color: _navy.withOpacity(0.5),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Icon(Icons.chevron_right_rounded,
                                    color: _navy.withOpacity(0.5), size: 16),
                              ]),
                            ),
                          ],
                        ),
                        _stagger(6),
                      ),
                      const SizedBox(height: 12),

                      _animated(
                        byGroup.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: _navy.withOpacity(0.1))),
                                child: Center(
                                    child: Text('Belum ada wallet',
                                        style: GoogleFonts.dmSans(
                                            color: _navy.withOpacity(0.4)))))
                            : _FolderWalletCards(
                                byGroup: byGroup, formatter: formatter),
                        _stagger(6),
                      ),
                      const SizedBox(height: 20),

                      // ── FLOW HISTORY header
                      _animated(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Flow History',
                                style: GoogleFonts.dmSans(
                                    color: _navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            Row(children: [
                              GestureDetector(
                                onTap: () =>
                                    _showFilterSheet(context, allCategories),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _txFilter != 'All'
                                        ? _navy.withOpacity(0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _txFilter != 'All'
                                            ? _navy
                                            : _navy.withOpacity(0.15)),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.tune_rounded,
                                        color: _txFilter != 'All'
                                            ? _navy
                                            : _navy.withOpacity(0.4),
                                        size: 16),
                                    if (_txFilter != 'All') ...[
                                      const SizedBox(width: 4),
                                      Text(_txFilter,
                                          style: GoogleFonts.dmSans(
                                              color: _navy,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ]
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  setState(
                                      () => _searchActive = !_searchActive);
                                  if (!_searchActive) {
                                    _searchCtrl.clear();
                                    _searchQuery = '';
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: _searchActive
                                        ? _navy.withOpacity(0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _searchActive
                                            ? _navy
                                            : Colors.transparent),
                                  ),
                                  child: Icon(Icons.search_rounded,
                                      color: _searchActive
                                          ? _navy
                                          : _navy.withOpacity(0.4),
                                      size: 20),
                                ),
                              ),
                            ]),
                          ],
                        ),
                        _stagger(7),
                      ),

                      if (_searchActive) ...[
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          style: GoogleFonts.dmSans(color: _navy, fontSize: 14),
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Cari transaksi...',
                            hintStyle: GoogleFonts.dmSans(
                                color: _navy.withOpacity(0.4), fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: _navy.withOpacity(0.4), size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(() {
                                      _searchCtrl.clear();
                                      _searchQuery = '';
                                    }),
                                    child: Icon(Icons.close_rounded,
                                        color: _navy.withOpacity(0.4),
                                        size: 18),
                                  )
                                : null,
                            filled: true,
                            fillColor: _navy.withOpacity(0.05),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
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
                            child: Column(children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 48, color: _navy.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text('Belum ada transaksi',
                                  style: GoogleFonts.dmSans(
                                      color: _navy.withOpacity(0.4))),
                            ]),
                          ),
                        )
                      else
                        ...dashboardTxs
                            .take(5)
                            .map((t) => _buildTxTile(t, formatter)),

                      if (txProvider.transactions.length > 5)
                        Center(
                          child: TextButton(
                            onPressed: () {
                              final shell = context
                                  .findAncestorStateOfType<MainShellState>();
                              shell?.goTo(1);
                            },
                            child: Text('LIHAT SEMUA TRANSAKSI',
                                style: GoogleFonts.dmMono(
                                    color: _navy.withOpacity(0.4),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filter bottom sheet ────────────────────────────────────────────────────
  void _showFilterSheet(BuildContext ctx, List<String> categories) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _navy.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Filter Transaksi',
                style: GoogleFonts.dmSans(
                    color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final f in ['All', 'Income', 'Expense', ...categories])
                GestureDetector(
                  onTap: () {
                    setState(() => _txFilter = f);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _txFilter == f ? _navy : _navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f,
                        style: GoogleFonts.dmSans(
                          color: _txFilter == f ? Colors.white : _navy,
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

  // ── Info card (Reminder / Insight) ─────────────────────────────────────────
  static Widget _tappableInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color accentColor,
    bool badge = false,
  }) {
    return _PressableWidget(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _navy.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Row(children: [
          Stack(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: accentColor, size: 20)),
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
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3), size: 16),
        ]),
      ),
    );
  }

  // ── Chip button ────────────────────────────────────────────────────────────
  static Widget _chipBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? _navy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: isSelected ? _navy : _navy.withOpacity(0.2)),
        ),
        child: Text(label,
            style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : _navy.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Spending row ───────────────────────────────────────────────────────────
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
                style: GoogleFonts.dmSans(color: _navy, fontSize: 13))),
        Text(percent,
            style: GoogleFonts.dmSans(
                color: _navy.withOpacity(0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded,
            size: 14, color: _navy.withOpacity(0.3)),
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
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _navy.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.category_outlined, color: color, size: 24)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: GoogleFonts.dmSans(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  Text('$percent dari total pengeluaran',
                      style: GoogleFonts.dmSans(
                          color: _navy.withOpacity(0.45), fontSize: 12)),
                ])),
          ]),
          const SizedBox(height: 20),
          Divider(color: _navy.withOpacity(0.08)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Total',
                style: GoogleFonts.dmSans(color: _navy.withOpacity(0.45))),
            Text(amount,
                style: GoogleFonts.dmSans(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ── Transaction tile ───────────────────────────────────────────────────────
  Widget _buildTxTile(AppTransaction t, NumberFormat formatter) {
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
      'Transfer': {
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFFE0F2FE)
      },
    };
    final catKey = isTransfer ? 'Transfer' : t.category;
    final cat = categoryIcons[catKey] ??
        {'icon': Icons.receipt_rounded, 'color': _navy.withOpacity(0.06)};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: cat['color'] as Color,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(cat['icon'] as IconData, color: _navy, size: 22)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title,
              style: GoogleFonts.dmSans(
                  color: _navy, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(
            isTransfer
                ? 'TRANSFER · ${_timeAgo(t.date)}'
                : '${t.category.toUpperCase()} · ${_timeAgo(t.date)}',
            style: GoogleFonts.dmMono(
                color: _navy.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ])),
        Text(
          isTransfer
              ? formatter.format(t.amount)
              : '${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
          style: GoogleFonts.dmSans(
              color: isTransfer
                  ? _navy.withOpacity(0.45)
                  : isIncome
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
              fontSize: 14),
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

// ── Press effect widget ────────────────────────────────────────────────────────
class _PressableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableWidget({required this.child, required this.onTap});
  @override
  State<_PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<_PressableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Folder Wallet Cards ────────────────────────────────────────────────────────
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
    [Color(0xFF0D1B3E), Color(0xFF1a2f5e)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFEF4444), Color(0xFFDC2626)],
    [Color(0xFF0EA5E9), Color(0xFF0284C7)],
    [Color(0xFFEC4899), Color(0xFFDB2777)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  ];

  static const List<Color> _tabColors = [
    Color(0xFF0D1B3E),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
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
                    color: isSelected ? color : _navy.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
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
                        style: GoogleFonts.dmSans(
                          color: isSelected
                              ? Colors.white
                              : _navy.withOpacity(0.5),
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
              ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
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
                    color: gradColors[0].withOpacity(0.35),
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
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(selected.key,
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text('${selected.value.length} akun',
                          style: GoogleFonts.dmSans(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12)),
                    ])),
                GestureDetector(
                  onTap: () =>
                      setState(() => _hidden[selected.key] = !isHidden),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
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
              Text('Total Saldo',
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                isHidden ? '••••••••' : widget.formatter.format(groupTotal),
                style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5),
              ),
              if (selected.value.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.white.withOpacity(0.12)),
                const SizedBox(height: 12),
                ...selected.value.take(3).map((acc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: _yellow.withOpacity(0.7),
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(acc.name,
                                style: GoogleFonts.dmSans(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500))),
                        Text(
                          isHidden
                              ? '••••'
                              : widget.formatter.format(acc.balance),
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    )),
                if (selected.value.length > 3)
                  Text('+${selected.value.length - 3} akun lainnya',
                      style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Chart painters ─────────────────────────────────────────────────────────────
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
      ..color = _navy
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_navy.withOpacity(0.15), _navy.withOpacity(0.0)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
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
    // Dot at end
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = _navy
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        last,
        4,
        Paint()
          ..color = _yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
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
