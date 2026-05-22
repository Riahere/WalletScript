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
const _green = Color(0xFF1DB87A);
const _greenDark = Color(0xFF18a06a);
const _bgWhite = Color(0xFFF4F6F9);

const double _gcHeight = 240.0;
const double _gcHalfAbove = 120.0;

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

  late AnimationController _floatCtrl;
  late AnimationController _staggerCtrl;
  late AnimationController _balanceCtrl;
  late Animation<double> _balanceAnim;

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

  Animation<double> _stagger(int i, {int total = 8}) {
    final start = i / (total + 2);
    final end = (i + 2) / (total + 2);
    return CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  List<AppTransaction> _filteredChart(List<AppTransaction> all) {
    if (_chartFilter == 'ALL') return all;
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return all.where((t) => t.date.isAfter(cutoff)).toList();
  }

  List<AppTransaction> _filteredDash(List<AppTransaction> all) {
    List<AppTransaction> r = all;
    if (_txFilter == 'Income') {
      r = r.where((t) => t.type == 'income').toList();
    } else if (_txFilter == 'Expense') {
      r = r.where((t) => t.type == 'expense').toList();
    } else if (_txFilter != 'All') {
      r = r.where((t) => t.category == _txFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      r = r
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return r;
  }

  List<_BarPoint> _buildBars(List<AppTransaction> txs) {
    if (txs.isEmpty) return [];
    txs.sort((a, b) => a.date.compareTo(b.date));
    final Map<String, double> map = {};
    double running = 0;
    for (final t in txs) {
      if (t.type == 'transfer') continue;
      final key = DateFormat('dd/MM').format(t.date);
      running += t.type == 'income' ? t.amount : -t.amount;
      map[key] = running;
    }
    if (map.isEmpty) return [];
    final vals = map.values.toList();
    final len = map.length;
    return List.generate(
      len > 7 ? 7 : len,
      (i) => _BarPoint(
        map.keys.toList()[len > 7 ? len - 7 + i : i],
        vals[len > 7 ? len - 7 + i : i],
      ),
    );
  }

  Map<String, double> _categoryTotals(List<AppTransaction> txs) {
    final Map<String, double> m = {};
    for (final t in txs) {
      if (t.type == 'expense') m[t.category] = (m[t.category] ?? 0) + t.amount;
    }
    return m;
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
  Color _col(int i) => _catColors[i % _catColors.length];

  AppNote? _nextReminder(List<AppNote> notes) {
    final now = DateTime.now();
    final list = notes
        .where((n) =>
            n.hasReminder &&
            n.reminderDate != null &&
            n.reminderDate!.isAfter(now.subtract(const Duration(hours: 1))))
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.reminderDate!.compareTo(b.reminderDate!));
    return list.first;
  }

  String _reminderSubtitle(AppNote? note) {
    if (note == null) return 'No upcoming reminders.';
    final diff = note.reminderDate!.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${note.title} — in ${diff.inMinutes}m';
    if (diff.inHours < 24) return '${note.title} — in ${diff.inHours}h';
    return '${note.title} — ${DateFormat('d MMM HH:mm').format(note.reminderDate!)}';
  }

  String _insightSubtitle(TransactionProvider tx) {
    if (tx.totalIncome == 0 && tx.totalExpense == 0) {
      return 'No transactions yet. Start recording now!';
    }
    final ratio = tx.totalIncome > 0 ? tx.totalExpense / tx.totalIncome : 1.0;
    if (ratio >= 0.9) return 'Spending nearly exceeds income! Be careful.';
    if (ratio >= 0.7) {
      return 'Spending is ${(ratio * 100).toStringAsFixed(0)}% of income.';
    }
    final now = DateTime.now();
    final monthTx = tx.transactions
        .where((t) =>
            t.type == 'expense' &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .toList();
    if (monthTx.isEmpty) return 'Your finances look healthy!';
    final Map<String, double> cats = {};
    for (final t in monthTx) {
      cats[t.category] = (cats[t.category] ?? 0) + t.amount;
    }
    final top = cats.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = (top.value / tx.totalExpense * 100).toStringAsFixed(0);
    return 'Top: ${top.key} is $pct% of spending.';
  }

  String _trendText(List<AppTransaction> txs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    double net = 0, prev = 0;
    for (final t in txs) {
      if (t.type == 'transfer') continue;
      if (t.date.isAfter(cutoff)) {
        net += t.type == 'income' ? t.amount : -t.amount;
      } else {
        prev += t.type == 'income' ? t.amount : -t.amount;
      }
    }
    if (prev == 0) return net >= 0 ? '+∞%' : '-∞%';
    final pct = (net / prev.abs() * 100);
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% last 30d';
  }

  bool _trendPos(List<AppTransaction> txs) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    double net = 0;
    for (final t
        in txs.where((t) => t.date.isAfter(cutoff) && t.type != 'transfer')) {
      net += t.type == 'income' ? t.amount : -t.amount;
    }
    return net >= 0;
  }

  static const _navyIconData = [
    [Icons.bar_chart_rounded, 0.03, 0.06, 22.0, 0.0],
    [Icons.monetization_on_outlined, 0.82, 0.04, 20.0, 0.5],
    [Icons.trending_up_rounded, 0.48, 0.34, 18.0, 0.2],
    [Icons.credit_card_rounded, 0.78, 0.32, 18.0, 0.3],
    [Icons.savings_outlined, 0.05, 0.68, 20.0, 0.8],
    [Icons.account_balance_outlined, 0.80, 0.60, 18.0, 0.9],
    [Icons.receipt_long_outlined, 0.38, 0.12, 16.0, 0.6],
    [Icons.currency_exchange_rounded, 0.60, 0.16, 16.0, 0.4],
    [Icons.pie_chart_outline_rounded, 0.12, 0.20, 17.0, 0.7],
    [Icons.wallet_outlined, 0.72, 0.42, 17.0, 0.55],
    [Icons.show_chart_rounded, 0.42, 0.58, 18.0, 0.35],
    [Icons.percent_rounded, 0.25, 0.56, 15.0, 0.65],
    [Icons.swap_horiz_rounded, 0.28, 0.80, 16.0, 0.45],
    [Icons.arrow_upward_rounded, 0.64, 0.34, 14.0, 0.75],
  ];

  List<Widget> _navyBgIcons(double heroH) {
    return _navyIconData.map((d) {
      final yo =
          math.sin((_floatCtrl.value + (d[4] as double)) * math.pi * 2) * 6;
      return Positioned(
        left: (d[1] as double) * 300,
        top: (d[2] as double) * heroH + yo,
        child: Icon(d[0] as IconData,
            size: d[3] as double, color: Colors.white.withOpacity(0.07)),
      );
    }).toList();
  }

  static const _whiteIconData = [
    [Icons.bar_chart_rounded, 0.03, 10.0, 26.0, 0.0],
    [Icons.monetization_on_outlined, 0.88, 14.0, 22.0, 0.5],
    [Icons.trending_up_rounded, 0.44, 8.0, 20.0, 0.2],
    [Icons.credit_card_rounded, 0.03, 80.0, 20.0, 0.3],
    [Icons.account_balance_outlined, 0.88, 78.0, 22.0, 0.9],
    [Icons.percent_rounded, 0.36, 84.0, 18.0, 0.6],
    [Icons.receipt_long_outlined, 0.05, 160.0, 20.0, 0.8],
    [Icons.savings_outlined, 0.88, 166.0, 22.0, 0.4],
    [Icons.swap_horiz_rounded, 0.42, 170.0, 18.0, 0.7],
    [Icons.monetization_on_outlined, 0.04, 250.0, 20.0, 0.35],
    [Icons.wallet_outlined, 0.88, 256.0, 22.0, 0.55],
    [Icons.show_chart_rounded, 0.38, 262.0, 19.0, 0.65],
    [Icons.pie_chart_outline_rounded, 0.03, 340.0, 20.0, 0.1],
    [Icons.bar_chart_rounded, 0.88, 346.0, 22.0, 0.8],
    [Icons.arrow_upward_rounded, 0.44, 352.0, 18.0, 0.45],
    [Icons.currency_exchange_rounded, 0.04, 440.0, 22.0, 0.2],
    [Icons.trending_up_rounded, 0.88, 446.0, 20.0, 0.6],
    [Icons.account_balance_wallet_outlined, 0.40, 452.0, 18.0, 0.75],
  ];

  List<Widget> _whiteBgIcons(double width) {
    return _whiteIconData.map((d) {
      final yo =
          math.sin((_floatCtrl.value + (d[4] as double)) * math.pi * 2) * 6;
      return Positioned(
        left: (d[1] as double) * width,
        top: (d[2] as double) + yo,
        child: Icon(d[0] as IconData,
            size: d[3] as double, color: _navy.withOpacity(0.045)),
      );
    }).toList();
  }

  Widget _anim(Widget child, Animation<double> a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position:
              Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(a),
          child: child,
        ),
      );

  void _showFilter(BuildContext ctx, List<String> cats) {
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
                      color: _navy.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Filter Transactions',
              style: GoogleFonts.dmSans(
                  color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final f in ['All', 'Income', 'Expense', ...cats])
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
                          fontSize: 13)),
                ),
              ),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showAddTransaction(BuildContext ctx) {
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
                      color: _navy.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Add Transaction',
              style: GoogleFonts.dmSans(
                  color: _navy, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _addTxOption(
                icon: Icons.arrow_downward_rounded,
                label: 'Income',
                color: _green,
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _addTxOption(
                icon: Icons.arrow_upward_rounded,
                label: 'Expense',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _addTxOption(
                icon: Icons.swap_horiz_rounded,
                label: 'Transfer',
                color: const Color(0xFF6C63FF),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  static Widget _addTxOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: color, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final txP = context.watch<TransactionProvider>();
    final noteP = context.watch<NoteProvider>();
    final accP = context.watch<AccountProvider>();
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final totalBalance =
        accP.accounts.isNotEmpty ? accP.totalBalance : txP.balance;
    final bars = _buildBars(_filteredChart(txP.transactions));
    final catTotals = _categoryTotals(txP.transactions);
    final totalExp = catTotals.values.fold(0.0, (a, b) => a + b);
    final catList = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final nextReminder = _nextReminder(noteP.notes);
    final dashTxs = _filteredDash(txP.transactions);
    final allCats = txP.transactions.map((t) => t.category).toSet().toList();
    final byGroup = accP.accountsByGroup;
    final trendTxt = _trendText(txP.transactions);
    final trendUp = _trendPos(txP.transactions);

    return Scaffold(
      backgroundColor: _bgWhite,
      body: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          return LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── HERO SLIVER ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            color: _navy,
                            child: SafeArea(
                              bottom: false,
                              child: Stack(children: [
                                Positioned.fill(
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
                                    maxHeight: 260,
                                    child: SizedBox(
                                      height: 260,
                                      width: w,
                                      child: Stack(children: _navyBgIcons(260)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 16, 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _anim(
                                        Row(children: [
                                          const Expanded(child: AppTopBar()),
                                          if (_syncing)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8),
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white
                                                            .withOpacity(0.4)),
                                              ),
                                            ),
                                        ]),
                                        _stagger(0),
                                      ),
                                      const SizedBox(height: 10),
                                      _anim(
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(_greeting(),
                                                  style: GoogleFonts.dmSans(
                                                      color: Colors.white
                                                          .withOpacity(0.5),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500)),
                                              const SizedBox(height: 3),
                                              Text('WalletScript User',
                                                  style: GoogleFonts.dmSans(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                            ]),
                                        _stagger(1),
                                      ),
                                      const SizedBox(
                                          height: 16 + _gcHeight / 2),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          Container(
                            height: _gcHeight / 2 + 16,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: _bgWhite,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(56),
                                topRight: Radius.circular(56),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 16,
                        left: 24,
                        right: 24,
                        child: _anim(
                          _buildGreenCard(
                              ctx, fmt, totalBalance, txP, trendTxt, trendUp),
                          _stagger(2),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── WHITE SECTION ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: _bgWhite,
                    child: Stack(children: [
                      Positioned.fill(
                        child: OverflowBox(
                          maxHeight: 1200,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            height: 1200,
                            width: w,
                            child: Stack(children: _whiteBgIcons(w)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── NOTICE CARDS ─────────────────────────────
                            _anim(
                              Row(children: [
                                Expanded(
                                    child: _noticeCard(
                                  icon: Icons.notifications_active_rounded,
                                  iconBg: const Color(0xFFFFF3C2),
                                  iconColor: const Color(0xFFB8860B),
                                  title: 'Reminder',
                                  subtitle: _reminderSubtitle(nextReminder),
                                  hasBadge: nextReminder != null,
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationScreen())),
                                )),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: _noticeCard(
                                  icon: Icons.lightbulb_outline_rounded,
                                  iconBg: const Color(0xFFE3F0FF),
                                  iconColor: const Color(0xFF3A7BD5),
                                  title: 'Insight',
                                  subtitle: _insightSubtitle(txP),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationScreen())),
                                )),
                              ]),
                              _stagger(3),
                            ),
                            const SizedBox(height: 10),

                            // ── BAR CHART ─────────────────────────────────
                            _anim(_buildBarChart(bars), _stagger(4)),
                            const SizedBox(height: 10),

                            // ── SPENDING OVERVIEW ──────────────────────────
                            _anim(
                              _buildSpendingOverview(
                                  catList, totalExp, fmt, context),
                              _stagger(5),
                            ),
                            const SizedBox(height: 14),

                            // ── WALLETS header ─────────────────────────────
                            _anim(
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('WALLETS',
                                        style: GoogleFonts.dmSans(
                                            color: _navy,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8)),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const WalletAllScreen())),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                            color: _navy,
                                            shape: BoxShape.circle),
                                        child: const Icon(Icons.add,
                                            color: Colors.white, size: 13),
                                      ),
                                    ),
                                  ]),
                              _stagger(6),
                            ),
                            const SizedBox(height: 10),

                            // ── PEEK STACK WALLET CARDS ────────────────────
                            _anim(
                              byGroup.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(18)),
                                      child: Center(
                                          child: Text('No wallets yet',
                                              style: GoogleFonts.dmSans(
                                                  color:
                                                      _navy.withOpacity(0.4)))))
                                  : _PeekStackWallets(
                                      byGroup: byGroup,
                                      formatter: fmt,
                                      onNavigateToAll: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const WalletAllScreen()),
                                      ),
                                    ),
                              _stagger(6),
                            ),
                            const SizedBox(height: 20),

                            // ── HISTORY header ─────────────────────────────
                            _anim(
                              _buildHistoryHeader(context, allCats),
                              _stagger(7),
                            ),

                            if (_searchActive) ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: _searchCtrl,
                                autofocus: true,
                                style: GoogleFonts.dmSans(
                                    color: _navy, fontSize: 14),
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search transactions...',
                                  hintStyle: GoogleFonts.dmSans(
                                      color: _navy.withOpacity(0.4),
                                      fontSize: 14),
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
                                              size: 18))
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),

                            // ── HISTORY CARD ────────────────────────────────
                            _anim(
                              _buildHistoryCard(dashTxs, txP, fmt, context),
                              _stagger(7),
                            ),
                            // Extra bottom padding so history card is never cut off
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GREEN BALANCE CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGreenCard(BuildContext ctx, NumberFormat fmt, double balance,
      TransactionProvider txP, String trendTxt, bool trendUp) {
    return _PressableWidget(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WalletAllScreen())),
      child: Container(
        height: _gcHeight,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_green, _greenDark],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: _green.withOpacity(0.40),
                blurRadius: 32,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Stack(children: [
          Positioned(
              right: -14,
              top: -18,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle))),
          Positioned(
              right: 30,
              bottom: 50,
              child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      shape: BoxShape.circle))),
          Positioned(
              left: 8,
              bottom: 60,
              child: Icon(Icons.pie_chart_outline_rounded,
                  size: 18, color: Colors.white.withOpacity(0.1))),
          Positioned(
              right: 52,
              top: 8,
              child: Icon(Icons.payments_rounded,
                  size: 14, color: Colors.white.withOpacity(0.1))),
          Positioned(
              left: 26,
              top: 10,
              child: Icon(Icons.trending_up_rounded,
                  size: 13, color: Colors.white.withOpacity(0.1))),
          Positioned(
              right: 14,
              bottom: 60,
              child: Icon(Icons.monetization_on_outlined,
                  size: 13, color: Colors.white.withOpacity(0.1))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Account Balance',
                    style: GoogleFonts.dmSans(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _balanceHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      key: ValueKey(_balanceHidden),
                      color: Colors.white.withOpacity(0.45),
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 13),
                ),
              ]),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _balanceHidden
                    ? Text('••••••••••',
                        key: const ValueKey('h'),
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800))
                    : AnimatedBuilder(
                        key: const ValueKey('s'),
                        animation: _balanceAnim,
                        builder: (_, __) {
                          final raw = fmt.format(balance * _balanceAnim.value);
                          final parts = raw.split(' ');
                          final symbol = parts.isNotEmpty ? parts[0] : 'Rp';
                          final number = parts.length > 1
                              ? parts.sublist(1).join(' ')
                              : '0';
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(symbol,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(width: 3),
                              Text(number,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5)),
                            ],
                          );
                        }),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _gcSub('Income', '+${fmt.format(txP.totalIncome)}'),
                const SizedBox(width: 16),
                _gcSub('Expenses', '-${fmt.format(txP.totalExpense)}'),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        trendTxt.isNotEmpty
                            ? (trendUp
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded)
                            : Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 10),
                    const SizedBox(width: 3),
                    Text(trendTxt.isNotEmpty ? trendTxt : 'View wallets',
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: Row(
                  children: [
                    _gcActionBtn(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Transfer',
                      onTap: () {},
                    ),
                    _gcDivider(),
                    _gcActionBtn(
                      icon: Icons.arrow_downward_rounded,
                      label: 'Income',
                      onTap: () {},
                    ),
                    _gcDivider(),
                    _gcActionBtn(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Expense',
                      onTap: () {},
                    ),
                    _gcDivider(),
                    _gcActionBtn(
                      icon: Icons.add_rounded,
                      label: 'Add',
                      isAccent: true,
                      onTap: () => _showAddTransaction(ctx),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  static Widget _gcDivider() => Container(
        width: 1,
        height: 28,
        color: Colors.white.withOpacity(0.15),
      );

  static Widget _gcActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isAccent = false,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isAccent
                      ? Colors.white.withOpacity(0.30)
                      : Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: isAccent
                      ? Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1.5)
                      : null,
                ),
                child:
                    Icon(icon, color: Colors.white, size: isAccent ? 18 : 16),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(isAccent ? 1.0 : 0.85),
                      fontSize: 10,
                      fontWeight:
                          isAccent ? FontWeight.w700 : FontWeight.w600)),
            ],
          ),
        ),
      );

  static Widget _gcSub(String label, String val) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(val,
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ],
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTICE CARD
  // ═══════════════════════════════════════════════════════════════════════════
  static Widget _noticeCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) =>
      _PressableWidget(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: _navy.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: iconBg, borderRadius: BorderRadius.circular(7)),
                  child: Icon(icon, color: iconColor, size: 12)),
              if (hasBadge)
                Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle))),
            ]),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF222222),
                            fontWeight: FontWeight.w700,
                            fontSize: 10)),
                    Text(subtitle,
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFF555555),
                            fontSize: 9.5,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
          ]),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // BAR CHART
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBarChart(List<_BarPoint> bars) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _navy.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Balance Trend',
                style: GoogleFonts.dmSans(
                    color: _navy, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(
                _chartFilter == '30D'
                    ? 'Past 30 days activity'
                    : 'All time activity',
                style: GoogleFonts.dmSans(
                    color: _navy.withOpacity(0.45), fontSize: 11)),
          ]),
          Row(children: [
            _chip('ALL', _chartFilter == 'ALL',
                () => setState(() => _chartFilter = 'ALL')),
            const SizedBox(width: 5),
            _chip('30D', _chartFilter == '30D',
                () => setState(() => _chartFilter = '30D')),
          ]),
        ]),
        const SizedBox(height: 10),
        bars.isEmpty
            ? SizedBox(
                height: 52,
                child: Center(
                    child: Text('No transaction data yet',
                        style: GoogleFonts.dmSans(
                            color: _navy.withOpacity(0.4), fontSize: 11))))
            : SizedBox(
                height: 52,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: bars.map((b) {
                    final maxV =
                        bars.map((x) => x.value.abs()).reduce(math.max);
                    final pct = maxV == 0 ? 0.5 : (b.value.abs() / maxV);
                    final isYellow = b.value >= 0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: 0.1 + pct * 0.9,
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isYellow
                                        ? _yellow
                                        : _navy.withOpacity(0.55 + pct * 0.45),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(b.label.substring(0, 1),
                                style: GoogleFonts.dmSans(
                                    fontSize: 9,
                                    color: _navy.withOpacity(0.4))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ]),
    );
  }

  static Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: active ? _navy : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: GoogleFonts.dmSans(
                  color: active ? Colors.white : const Color(0xFF8A8FA3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // SPENDING OVERVIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSpendingOverview(List<MapEntry<String, double>> catList,
      double totalExp, NumberFormat fmt, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _navy.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Spending Overview',
              style: GoogleFonts.dmSans(
                  color: _navy, fontWeight: FontWeight.w700, fontSize: 13)),
          GestureDetector(
            onTap: () => Navigator.push(
                ctx, MaterialPageRoute(builder: (_) => SpendingDetailScreen())),
            child:
                Icon(Icons.more_vert, color: _navy.withOpacity(0.4), size: 18),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          SizedBox(
            width: 64,
            height: 64,
            child: totalExp == 0
                ? Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF0F2F5), width: 8)),
                    child: Center(
                        child: Text('No\ndata',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFFC8CBD6),
                                fontSize: 9,
                                height: 1.3),
                            textAlign: TextAlign.center)))
                : Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                      size: const Size(64, 64),
                      painter: _DonutPainter(
                        catList.map((e) => e.value).toList(),
                        totalExp,
                        List.generate(catList.length, (i) => _col(i)),
                      ),
                    ),
                    Text(fmt.format(totalExp),
                        style: GoogleFonts.dmSans(
                            fontSize: 8,
                            color: _navy,
                            fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center),
                  ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: catList.isEmpty
                ? Center(
                    child: Text('No spending yet',
                        style: GoogleFonts.dmSans(
                            color: const Color(0xFFC8CBD6), fontSize: 12)))
                : Column(children: [
                    for (int i = 0; i < catList.take(3).length; i++) ...[
                      if (i > 0)
                        Divider(height: 12, color: _navy.withOpacity(0.07)),
                      _spendRow(
                        ctx: ctx,
                        label: catList[i].key,
                        color: _col(i),
                        pct: totalExp > 0
                            ? '${((catList[i].value / totalExp) * 100).toStringAsFixed(0)}%'
                            : '0%',
                        amt: fmt.format(catList[i].value),
                      ),
                    ],
                  ]),
          ),
        ]),
      ]),
    );
  }

  static Widget _spendRow({
    required BuildContext ctx,
    required String label,
    required Color color,
    required String pct,
    required String amt,
  }) =>
      GestureDetector(
        onTap: () => _showCatDetail(ctx, label, color, pct, amt),
        child: Row(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(color: _navy, fontSize: 12))),
          Text(pct,
              style: GoogleFonts.dmSans(
                  color: _navy.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              size: 12, color: _navy.withOpacity(0.3)),
        ]),
      );

  static void _showCatDetail(
      BuildContext ctx, String label, Color color, String pct, String amt) {
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
                  Text('$pct of total spending',
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
            Text(amt,
                style: GoogleFonts.dmSans(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HISTORY HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryHeader(BuildContext ctx, List<String> cats) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('History',
          style: GoogleFonts.dmSans(
              color: _navy, fontSize: 13, fontWeight: FontWeight.w700)),
      Row(children: [
        GestureDetector(
          onTap: () => _showFilter(ctx, cats),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _txFilter != 'All'
                  ? _navy.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: _txFilter != 'All' ? _navy : _navy.withOpacity(0.15)),
            ),
            child: Row(children: [
              Icon(Icons.tune_rounded,
                  color: _txFilter != 'All' ? _navy : _navy.withOpacity(0.4),
                  size: 14),
              if (_txFilter != 'All') ...[
                const SizedBox(width: 4),
                Text(_txFilter,
                    style: GoogleFonts.dmSans(
                        color: _navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ]),
          ),
        ),
        const SizedBox(width: 8),
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
              color:
                  _searchActive ? _navy.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: _searchActive ? _navy : Colors.transparent),
            ),
            child: Icon(Icons.search_rounded,
                color: _searchActive ? _navy : _navy.withOpacity(0.4),
                size: 18),
          ),
        ),
      ]),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HISTORY CARD — full width, never clipped
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHistoryCard(List<AppTransaction> txs, TransactionProvider txP,
      NumberFormat fmt, BuildContext ctx) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _navy.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5))
          ]),
      child: txs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined,
                    size: 44, color: _navy.withOpacity(0.18)),
                const SizedBox(height: 12),
                Text('No transactions yet',
                    style: GoogleFonts.dmSans(
                        color: _navy.withOpacity(0.35), fontSize: 13)),
              ]),
            )
          : Column(children: [
              ...txs.take(5).map((t) => _txTile(t, fmt)).toList(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: const Color(0xFFF0F2F5), width: 1)),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Center(
                    child: Text('See all transactions',
                        style: GoogleFonts.dmSans(
                            color: _green,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ]),
    );
  }

  static const Map<String, Map<String, dynamic>> _catIcons = {
    'Makanan': {'icon': Icons.restaurant_rounded, 'bg': Color(0xFFFFF0F0)},
    'Food': {'icon': Icons.restaurant_rounded, 'bg': Color(0xFFFFF0F0)},
    'Transport': {
      'icon': Icons.directions_car_rounded,
      'bg': Color(0xFFEBF4FF)
    },
    'Shopping': {'icon': Icons.shopping_bag_rounded, 'bg': Color(0xFFFFF8E6)},
    'Belanja': {'icon': Icons.shopping_bag_rounded, 'bg': Color(0xFFFFF8E6)},
    'Entertainment': {'icon': Icons.gamepad_rounded, 'bg': Color(0xFFF0F0FF)},
    'Hiburan': {'icon': Icons.gamepad_rounded, 'bg': Color(0xFFF0F0FF)},
    'Health': {
      'icon': Icons.health_and_safety_rounded,
      'bg': Color(0xFFE8F9F3)
    },
    'Salary': {
      'icon': Icons.account_balance_wallet_rounded,
      'bg': Color(0xFFE8F9F3)
    },
    'Gaji': {
      'icon': Icons.account_balance_wallet_rounded,
      'bg': Color(0xFFE8F9F3)
    },
    'Travel': {'icon': Icons.flight_takeoff_rounded, 'bg': Color(0xFFE0F2FE)},
    'Bills': {'icon': Icons.bolt_rounded, 'bg': Color(0xFFF0F0FF)},
    'Transfer': {'icon': Icons.swap_horiz_rounded, 'bg': Color(0xFFE8F9F3)},
  };

  Widget _txTile(AppTransaction t, NumberFormat fmt) {
    final isIncome = t.type == 'income';
    final isTransfer = t.type == 'transfer';
    final catKey = isTransfer ? 'Transfer' : t.category;
    final cat = _catIcons[catKey] ??
        {'icon': Icons.receipt_rounded, 'bg': _navy.withOpacity(0.06)};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Color(0xFFF0F2F5), width: 1))),
      child: Row(children: [
        Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: cat['bg'] as Color,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(cat['icon'] as IconData,
                color: isIncome
                    ? const Color(0xFF0A8A56)
                    : isTransfer
                        ? const Color(0xFF2870C8)
                        : const Color(0xFFC0392B),
                size: 17)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title,
              style: GoogleFonts.dmSans(
                  color: _navy, fontWeight: FontWeight.w600, fontSize: 12)),
          Text(
              isTransfer
                  ? 'Transfer · ${_timeAgo(t.date)}'
                  : '${t.category} · ${_timeAgo(t.date)}',
              style: GoogleFonts.dmSans(
                  color: const Color(0xFFA0A5B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ])),
        Text(
          isTransfer
              ? fmt.format(t.amount)
              : '${isIncome ? '+' : '-'}${fmt.format(t.amount)}',
          style: GoogleFonts.dmSans(
              color: isTransfer
                  ? _navy.withOpacity(0.45)
                  : isIncome
                      ? const Color(0xFF1DB87A)
                      : const Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
              fontSize: 12),
        ),
      ]),
    );
  }

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PEEK STACK WALLET CARDS
// Full rewrite: eye toggle, tap-to-front animation, tap-front → navigate,
// AnimatedScale depth illusion, easeOutExpo curves
// ─────────────────────────────────────────────────────────────────────────────
class _PeekStackWallets extends StatefulWidget {
  final Map<String, List<AppAccount>> byGroup;
  final NumberFormat formatter;
  final VoidCallback? onNavigateToAll;

  const _PeekStackWallets({
    required this.byGroup,
    required this.formatter,
    this.onNavigateToAll,
  });

  @override
  State<_PeekStackWallets> createState() => _PeekStackWalletsState();
}

class _PeekStackWalletsState extends State<_PeekStackWallets>
    with TickerProviderStateMixin {
  late List<int> _stackOrder;
  bool _hidden = false;
  int? _animatingCard;

  // Card dimensions
  static const double _cardH = 162.0;
  static const double _peek = 42.0;
  static const double _scaleStep = 0.038;

  static const List<List<Color>> _gradients = [
    [Color(0xFF0D1B3E), Color(0xFF1a2d5a)],
    [Color(0xFFC9A227), Color(0xFFe8bc30)],
    [Color(0xFF4A90C4), Color(0xFF5BA3D9)],
    [Color(0xFF1DB87A), Color(0xFF25D48F)],
    [Color(0xFFEF4444), Color(0xFFFF6B6B)],
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    [Color(0xFFEC4899), Color(0xFFF472B6)],
  ];

  static const Map<String, IconData> _bgIcons = {
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
  void initState() {
    super.initState();
    final n = widget.byGroup.length;
    _stackOrder = List.generate(n, (i) => n - 1 - i);
  }

  Future<void> _peekBring(int cid) async {
    if (_animatingCard != null) return;
    setState(() => _animatingCard = cid);
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      final idx = _stackOrder.indexOf(cid);
      _stackOrder.removeAt(idx);
      _stackOrder.add(cid);
      _animatingCard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.byGroup.entries.toList();
    final n = groups.length;
    if (n == 0) return const SizedBox.shrink();

    final stackH = (n - 1) * _peek + _cardH;

    return SizedBox(
      width: double.infinity,
      height: stackH,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(n, (si) {
          final cid = _stackOrder[si];
          final depthFromFront = n - 1 - si;
          final isFront = depthFromFront == 0;
          final scale = 1.0 - (depthFromFront * _scaleStep);
          final topPos =
              isFront ? (n - 1).toDouble() * _peek : si.toDouble() * _peek;
          final isAnimating = _animatingCard == cid;

          final group = groups[cid];
          final grads = _gradients[cid % _gradients.length];
          final groupTotal = group.value.fold(0.0, (s, a) => s + a.balance);
          final bgIcon = _bgIcons[group.key] ?? Icons.wallet_rounded;

          return AnimatedPositioned(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutExpo,
            top: topPos,
            left: 0,
            right: 0,
            height: _cardH,
            child: AnimatedScale(
              scale: isAnimating ? scale * 0.96 : scale,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isAnimating ? 0.55 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: isFront
                      ? () => widget.onNavigateToAll?.call()
                      : () => _peekBring(cid),
                  child: _buildCard(
                    group: group,
                    grads: grads,
                    bgIcon: bgIcon,
                    groupTotal: groupTotal,
                    isFront: isFront,
                    cid: cid,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCard({
    required MapEntry<String, List<AppAccount>> group,
    required List<Color> grads,
    required IconData bgIcon,
    required double groupTotal,
    required bool isFront,
    required int cid,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grads,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.09), width: 1),
        boxShadow: isFront
            ? [
                BoxShadow(
                  color: grads[0].withOpacity(0.38),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: grads[1].withOpacity(0.18),
                  blurRadius: 48,
                  spreadRadius: -6,
                  offset: const Offset(0, 22),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        // Large bg icon bottom-right
        Positioned(
          right: -16,
          bottom: -16,
          child: Icon(bgIcon, size: 110, color: Colors.white.withOpacity(0.06)),
        ),
        // Deco circles
        Positioned(
          right: -24,
          top: -24,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          left: -14,
          bottom: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),

        // ── FRONT CARD full content ──────────────────────────────────────
        if (isFront)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: masked number | eye toggle | NFC icon
                Row(children: [
                  Text(
                    '•••• •••• ${_maskedNum(cid)}',
                    style: GoogleFonts.dmMono(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 11,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const Spacer(),
                  // 👁 Eye toggle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _hidden = !_hidden),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: Icon(
                          _hidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          key: ValueKey(_hidden),
                          color: Colors.white.withOpacity(0.55),
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // NFC chip icon
                  Transform.rotate(
                    angle: math.pi / 2,
                    child: Icon(
                      Icons.wifi_rounded,
                      color: Colors.white.withOpacity(0.28),
                      size: 19,
                    ),
                  ),
                ]),

                const SizedBox(height: 8),

                // Group name + account count
                Text(
                  group.key,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  '${group.value.length} account${group.value.length > 1 ? 's' : ''} · ${group.key}',
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 10.5,
                  ),
                ),

                const Spacer(),

                // Balance row + "View all" pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Balance',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.48),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            _hidden
                                ? '••••••••'
                                : widget.formatter.format(groupTotal),
                            key: ValueKey(_hidden),
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // "View all" pill — tap hint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15), width: 1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          'View all',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withOpacity(0.85),
                          size: 11,
                        ),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ── BACK CARD peek strip ────────────────────────────────────────
        if (!isFront)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    group.key,
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _hidden
                      ? '••••'
                      : widget.formatter.format(
                          group.value.fold(0.0, (s, a) => s + a.balance)),
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.touch_app_rounded,
                    color: Colors.white.withOpacity(0.3), size: 13),
              ],
            ),
          ),
      ]),
    );
  }

  String _maskedNum(int cid) {
    const nums = ['5115', '0336', '1018', '2244', '3377', '4488', '5599'];
    return nums[cid % nums.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRESS EFFECT WIDGET
// ─────────────────────────────────────────────────────────────────────────────
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
    _scale = Tween(begin: 1.0, end: 0.97)
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

// ─────────────────────────────────────────────────────────────────────────────
class _BarPoint {
  final String label;
  final double value;
  const _BarPoint(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double total;
  final List<Color> colors;
  const _DonutPainter(this.values, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    const sw = 8.0;
    double start = -1.5708;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: size.width / 2 - sw / 2),
        start,
        sweep - 0.04,
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
