import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../models/budget_model.dart';
import '../theme/app_theme.dart';
import 'app_top_bar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
    });
  }

  void _showAddGoal() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '??');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Financial Goal Baru',
                style: TextStyle(color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(
              controller: emojiCtrl,
              style: const TextStyle(fontSize: 24),
              decoration: InputDecoration(
                hintText: 'Emoji (contoh: ??)',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Nama goal (contoh: Beli Mobil)',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Target nominal (Rp)',
                prefixText: 'Rp ',
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  if (titleCtrl.text.isEmpty || targetCtrl.text.isEmpty) return;
                  context.read<BudgetProvider>().addBudget(AppBudget(
                    title: titleCtrl.text,
                    emoji: emojiCtrl.text.isEmpty ? '??' : emojiCtrl.text,
                    targetAmount: double.parse(targetCtrl.text.replaceAll('.', '')),
                    currentAmount: 0,
                    currency: 'IDR',
                    color: '0xFF10B981',
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Buat Goal',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgets = context.watch<BudgetProvider>().budgets;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final active = budgets.isNotEmpty ? budgets.first : null;
    final secondary = budgets.length > 1 ? budgets.sublist(1) : <AppBudget>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
                          style: TextStyle(color: AppTheme.onSurface, fontSize: 26, fontWeight: FontWeight.w800)),
                      Text('Strategic capital allocation engine',
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                  // Tombol tambah goal — visible selalu
                  GestureDetector(
                    onTap: _showAddGoal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4),
                          Text('Goal Baru',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (active != null) ...[
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
                          const Text('ACTIVE PRIORITY',
                              style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                          Text(formatter.format(active.targetAmount),
                              style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(active.title,
                              style: const TextStyle(color: AppTheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800)),
                          const Text('Target Goal',
                              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Center(child: Text(active.emoji, style: const TextStyle(fontSize: 60))),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Vision Board',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${((active.currentAmount / active.targetAmount) * 100).toStringAsFixed(0)}% Complete',
                            style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text('${formatter.format(active.currentAmount)} saved',
                              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: active.targetAmount > 0
                              ? (active.currentAmount / active.targetAmount).clamp(0, 1)
                              : 0,
                          minHeight: 10,
                          backgroundColor: AppTheme.surfaceContainer,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text('LIQUIDITY SOURCES',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _liquidityCard('??', 'Bank Vault', 'Rp 12.450.000')),
                  const SizedBox(width: 12),
                  Expanded(child: _liquidityCard('??', 'Mutual Funds', 'Rp 18.150.000')),
                ],
              ),
              const SizedBox(height: 20),

              if (secondary.isNotEmpty) ...[
                const Text('SECONDARY TRACKS',
                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                ...secondary.map((b) => _secondaryCard(b, formatter)),
              ],

              if (budgets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(children: const [
                      Text('??', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Belum ada financial goal',
                          style: TextStyle(color: AppTheme.onSurfaceVariant)),
                      SizedBox(height: 8),
                      Text('Tap "Goal Baru" untuk mulai',
                          style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liquidityCard(String emoji, String title, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(amount,
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _secondaryCard(AppBudget b, NumberFormat formatter) {
    final progress = b.targetAmount > 0
        ? (b.currentAmount / b.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.surfaceContainer, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(b.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title,
                    style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Target: ${formatter.format(b.targetAmount)}',
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceContainer,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}
