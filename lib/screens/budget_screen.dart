import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/account_provider.dart';
import '../models/budget_model.dart';
import '../models/account_model.dart';
import '../theme/app_theme.dart';
import '../screens/goal_detail_screen.dart';
import 'app_top_bar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  // ─── ADD GOAL BOTTOM SHEET ────────────────────────────────────────────────
  void _showAddGoal() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedEmoji = '🎯';
    String selectedColor = '0xFF10B981';
    String? selectedCategory;
    DateTime? deadline;

    final emojis = [
      '🎯',
      '🚗',
      '🏠',
      '✈️',
      '💻',
      '👜',
      '💍',
      '🎓',
      '🏋️',
      '🏖️',
      '📱',
      '🎸',
      '⌚',
      '🛳️',
      '🏍️',
      '💰',
      '🏆',
      '🌏',
      '🎮',
      '🏡',
    ];
    final categories = [
      'Kendaraan',
      'Properti',
      'Elektronik',
      'Fashion',
      'Pendidikan',
      'Liburan',
      'Investasi',
      'Kesehatan',
      'Hiburan',
      'Lainnya',
    ];
    final colors = [
      '0xFF10B981',
      '0xFF3B82F6',
      '0xFFF59E0B',
      '0xFFEF4444',
      '0xFF8B5CF6',
      '0xFFEC4899',
      '0xFF14B8A6',
      '0xFFF97316',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Financial Goal Baru',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),

                // Emoji picker
                const Text('Ikon Goal',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojis.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setSheet(() => selectedEmoji = emojis[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: selectedEmoji == emojis[i]
                              ? AppTheme.primary.withOpacity(0.15)
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedEmoji == emojis[i]
                                ? AppTheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(emojis[i],
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Color picker
                const Text('Warna',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: colors.map((c) {
                    final clr = Color(int.parse(c));
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: clr,
                          shape: BoxShape.circle,
                          border: selectedColor == c
                              ? Border.all(
                                  color: AppTheme.onSurface, width: 2.5)
                              : null,
                        ),
                        child: selectedColor == c
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Title
                const Text('Nama Goal',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Beli Mobil, Liburan Eropa',
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                const Text('Deskripsi (opsional)',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Ceritakan goalmu...',
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),

                // Target amount
                const Text('Target Nominal',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                    hintText: '0',
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // Category
                const Text('Kategori',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  hint: const Text('Pilih kategori'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSheet(() => selectedCategory = v),
                ),
                const SizedBox(height: 12),

                // Deadline
                const Text('Target Deadline (opsional)',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: AppTheme.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setSheet(() => deadline = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: deadline != null
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: deadline != null
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          deadline != null
                              ? DateFormat('dd MMMM yyyy', 'id')
                                  .format(deadline!)
                              : 'Pilih tanggal deadline',
                          style: TextStyle(
                            color: deadline != null
                                ? AppTheme.onSurface
                                : AppTheme.onSurfaceVariant,
                            fontWeight: deadline != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (deadline != null)
                          GestureDetector(
                            onTap: () => setSheet(() => deadline = null),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppTheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty ||
                          targetCtrl.text.trim().isEmpty) return;
                      final target =
                          double.tryParse(targetCtrl.text.trim()) ?? 0;
                      if (target <= 0) return;
                      Navigator.pop(ctx);
                      await context.read<BudgetProvider>().addBudget(AppBudget(
                            title: titleCtrl.text.trim(),
                            emoji: selectedEmoji,
                            targetAmount: target,
                            currentAmount: 0,
                            currency: 'IDR',
                            color: selectedColor,
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            deadline: deadline,
                            category: selectedCategory,
                          ));
                    },
                    child: const Text('Buat Goal',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final budgets = context.watch<BudgetProvider>().budgets;
    final accounts = context.watch<AccountProvider>().accounts;

    // Priority goal = yang isPriority, fallback ke first
    final priority = budgets.isNotEmpty
        ? (budgets.firstWhere((b) => b.isPriority, orElse: () => budgets.first))
        : null;
    final others = budgets.where((b) => b.id != priority?.id).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Top padding + header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTopBar(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Financial Goals',
                                style: TextStyle(
                                    color: AppTheme.onSurface,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800)),
                            Text('Nabung & wujudkan impianmu',
                                style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 13)),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showAddGoal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text('Goal Baru',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Priority Goal ──────────────────────────────────────────────
            if (priority != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: _PriorityGoalCard(
                    budget: priority,
                    fmt: _fmt,
                    onTap: () => _openDetail(priority),
                  ),
                ),
              ),

            // ── Liquidity Sources ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LIQUIDITY SOURCES',
                        style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    if (accounts.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.outline),
                        ),
                        child: const Text('Belum ada wallet',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 13)),
                      )
                    else
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: accounts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) =>
                              _LiquidityCard(account: accounts[i], fmt: _fmt),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Other Goals ────────────────────────────────────────────────
            if (others.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text('GOALS LAINNYA',
                      style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GoalCard(
                        budget: others[i],
                        fmt: _fmt,
                        onTap: () => _openDetail(others[i]),
                      ),
                    ),
                    childCount: others.length,
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 120)),

            // ── Empty state ────────────────────────────────────────────────
            if (budgets.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(children: const [
                      Text('🎯', style: TextStyle(fontSize: 52)),
                      SizedBox(height: 12),
                      Text('Belum ada financial goal',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      SizedBox(height: 6),
                      Text('Tap "Goal Baru" untuk mulai',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(AppBudget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailScreen(budget: budget)),
    ).then((_) {
      // Refresh saat kembali dari detail
      context.read<BudgetProvider>().loadBudgets();
    });
  }
}

// ─── PRIORITY GOAL CARD ────────────────────────────────────────────────────
class _PriorityGoalCard extends StatelessWidget {
  final AppBudget budget;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _PriorityGoalCard({
    required this.budget,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (budget.currentAmount / budget.targetAmount).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(0);
    final color = Color(int.parse(budget.color));
    final daysLeft = budget.daysLeft;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vision board image area
            Stack(
              children: [
                // Image or emoji bg
                Container(
                  height: 160,
                  width: double.infinity,
                  color: color.withOpacity(0.08),
                  child: budget.imagePath != null
                      ? Image.file(
                          File(budget.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Center(
                          child: Text(budget.emoji,
                              style: const TextStyle(fontSize: 64)),
                        ),
                ),
                // Gradient overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.surface.withOpacity(0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badges top
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: color, size: 12),
                        const SizedBox(width: 4),
                        Text('PRIORITAS',
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
                if (daysLeft != null)
                  Positioned(
                    top: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft < 0
                            ? 'Lewat deadline!'
                            : '$daysLeft hari lagi',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                // Vision board label (only if imagePath exists)
                if (budget.imagePath != null)
                  Positioned(
                    bottom: 10,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 10),
                          SizedBox(width: 4),
                          Text('Vision Board',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(budget.title,
                            style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppTheme.onSurfaceVariant),
                    ],
                  ),
                  if (budget.description != null) ...[
                    const SizedBox(height: 2),
                    Text(budget.description!,
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),

                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$percent% tercapai',
                          style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                      Text(
                        '${fmt.format(budget.currentAmount)} / ${fmt.format(budget.targetAmount)}',
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          budget.isCompleted ? Colors.amber : color),
                    ),
                  ),

                  // Monthly suggestion
                  if (budget.deadline != null && !budget.isCompleted) ...[
                    const SizedBox(height: 10),
                    _monthlySuggestion(budget, fmt),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlySuggestion(AppBudget b, NumberFormat fmt) {
    final months = b.deadline!.difference(DateTime.now()).inDays / 30;
    if (months <= 0) return const SizedBox.shrink();
    final monthly = b.remaining / months;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nabung ${fmt.format(monthly)}/bulan biar tepat waktu',
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OTHER GOALS CARD ─────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final AppBudget budget;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _GoalCard({
    required this.budget,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (budget.currentAmount / budget.targetAmount).clamp(0.0, 1.0);
    final color = Color(int.parse(budget.color));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: color.withOpacity(0.1),
              ),
              clipBehavior: Clip.hardEdge,
              child: budget.imagePath != null
                  ? Image.file(File(budget.imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: Text(budget.emoji,
                          style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(budget.title,
                            style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (budget.isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('🏆', style: TextStyle(fontSize: 14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(budget.targetAmount),
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          budget.isCompleted ? Colors.amber : color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Percent + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppTheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LIQUIDITY SOURCE CARD ─────────────────────────────────────────────────
class _LiquidityCard extends StatelessWidget {
  final AppAccount account;
  final NumberFormat fmt;

  const _LiquidityCard({required this.account, required this.fmt});

  static const _iconMap = {
    'wallet': Icons.account_balance_wallet_rounded,
    'bank': Icons.account_balance_rounded,
    'cash': Icons.payments_rounded,
    'card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
    'investment': Icons.trending_up_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(account.color));
    final icon = _iconMap[account.icon] ?? Icons.account_balance_wallet_rounded;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(account.name,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(fmt.format(account.balance),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
