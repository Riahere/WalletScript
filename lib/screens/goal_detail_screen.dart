import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/budget_model.dart';
import '../models/account_model.dart';
import '../providers/budget_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_theme.dart';

// ─── COLOR CONSTANTS ──────────────────────────────────────────────────────────
const Color _navy = Color(0xFF0D1B3E);
const Color _yellow = Color(0xFFF5C842);
const Color _white = Colors.white;

class GoalDetailScreen extends StatefulWidget {
  final AppBudget budget;
  const GoalDetailScreen({super.key, required this.budget});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen>
    with SingleTickerProviderStateMixin {
  late AppBudget _budget;
  List<GoalDeposit> _deposits = [];
  bool _loading = true;
  late TabController _tabController;
  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _tabController = TabController(length: 3, vsync: this);
    _loadDeposits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeposits() async {
    if (_budget.id == null) return;

    await context.read<BudgetProvider>().loadBudgets();

    final deps = await context.read<BudgetProvider>().getDeposits(_budget.id!);
    final updated = context
        .read<BudgetProvider>()
        .budgets
        .firstWhere((b) => b.id == _budget.id, orElse: () => _budget);

    if (mounted) {
      setState(() {
        _deposits = deps;
        _budget = updated;
        _loading = false;
      });
    }
  }

  // ─── STREAK CALCULATION ───────────────────────────────────────────────────
  int _calculateStreak() {
    if (_deposits.isEmpty) return 0;

    final monthsWithDeposit = _deposits
        .map((d) => '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}')
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (monthsWithDeposit.isEmpty) return 0;

    int streak = 1;
    for (int i = 0; i < monthsWithDeposit.length - 1; i++) {
      final current = _parseYearMonth(monthsWithDeposit[i]);
      final prev = _parseYearMonth(monthsWithDeposit[i + 1]);
      final expectedPrev = DateTime(current.year, current.month - 1);
      if (prev.year == expectedPrev.year && prev.month == expectedPrev.month) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  DateTime _parseYearMonth(String ym) {
    final parts = ym.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  // ─── ADD DEPOSIT ──────────────────────────────────────────────────────────
  void _showAddDeposit() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    AppAccount? selectedAccount;
    String? attachmentPath;
    bool deductWallet = true;

    final accounts = context.read<AccountProvider>().accounts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text('Add Deposit',
                    style: TextStyle(
                        color: _navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Saving to: ${_budget.title}',
                    style:
                        TextStyle(color: _navy.withOpacity(0.5), fontSize: 13)),
                const SizedBox(height: 24),
                const Text('Amount',
                    style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      color: _navy, fontSize: 20, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 20),
                    hintText: '0',
                    filled: true,
                    fillColor: _navy.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _yellow, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Fund Source',
                    style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('No wallets available',
                        style: TextStyle(color: _navy.withOpacity(0.5))),
                  )
                else
                  DropdownButtonFormField<AppAccount>(
                    value: selectedAccount,
                    hint: Text('Select source wallet',
                        style: TextStyle(color: _navy.withOpacity(0.5))),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _navy.withOpacity(0.06),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none),
                    ),
                    items: accounts
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Row(
                                children: [
                                  Text(a.name,
                                      style: const TextStyle(
                                          color: _navy,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text(_fmt.format(a.balance),
                                      style: const TextStyle(
                                          color: _yellow,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setSheet(() => selectedAccount = v),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: deductWallet,
                      activeColor: _yellow,
                      activeTrackColor: _navy,
                      onChanged: (v) => setSheet(() => deductWallet = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Deduct wallet balance',
                        style: TextStyle(color: _navy, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Note (optional)',
                    style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: _navy),
                  decoration: InputDecoration(
                    hintText: 'e.g. Monthly salary deposit',
                    hintStyle: TextStyle(color: _navy.withOpacity(0.4)),
                    filled: true,
                    fillColor: _navy.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _yellow, width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final result = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (result != null) {
                      setSheet(() => attachmentPath = result.path);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: attachmentPath != null
                              ? _yellow
                              : _navy.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attachmentPath != null
                              ? Icons.attach_file_rounded
                              : Icons.add_photo_alternate_outlined,
                          color: attachmentPath != null
                              ? _yellow
                              : _navy.withOpacity(0.5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            attachmentPath != null
                                ? attachmentPath!.split('/').last
                                : 'Attach receipt photo',
                            style: TextStyle(
                              color: attachmentPath != null
                                  ? _navy
                                  : _navy.withOpacity(0.5),
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (attachmentPath != null)
                          GestureDetector(
                            onTap: () => setSheet(() => attachmentPath = null),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: _navy.withOpacity(0.5)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      final raw = amountCtrl.text.trim();
                      if (raw.isEmpty) return;
                      final amount = double.tryParse(raw);
                      if (amount == null || amount <= 0) return;
                      Navigator.pop(ctx);
                      await context.read<BudgetProvider>().addDeposit(
                            budgetId: _budget.id!,
                            amount: amount,
                            sourceAccount: selectedAccount,
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                            attachmentPath: attachmentPath,
                            deductFromWallet: deductWallet,
                          );
                      await _loadDeposits();
                    },
                    child: const Text('Save Deposit',
                        style: TextStyle(
                            color: _yellow,
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

  // ─── SHARE CARD ───────────────────────────────────────────────────────────
  void _showShareCard() {
    final progress = _budget.progress;
    final percent = (progress * 100).toStringAsFixed(0);
    final streak = _calculateStreak();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: _navy.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Share Progress',
                style: TextStyle(
                    color: _navy, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Show your goal progress to friends!',
                style: TextStyle(color: _navy.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 20),

            // Share card preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _navy,
                    _navy.withOpacity(0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('WalletScript',
                            style: TextStyle(
                                color: _yellow,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      const Text('✦',
                          style: TextStyle(
                              fontSize: 18,
                              color: _yellow,
                              fontWeight: FontWeight.w300)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_budget.title,
                      style: const TextStyle(
                          color: _white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  if (_budget.description != null) ...[
                    const SizedBox(height: 2),
                    Text(_budget.description!,
                        style: TextStyle(
                            color: _white.withOpacity(0.7), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: _white.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(_yellow),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$percent% achieved',
                          style: const TextStyle(
                              color: _yellow,
                              fontWeight: FontWeight.w800,
                              fontSize: 18)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_fmt.format(_budget.currentAmount),
                              style: TextStyle(
                                  color: _white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          Text('of ${_fmt.format(_budget.targetAmount)}',
                              style: TextStyle(
                                  color: _white.withOpacity(0.55),
                                  fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (streak >= 2) ...[
                        _shareBadge('◈ $streak mo streak'),
                        const SizedBox(width: 8),
                      ],
                      if (_budget.deadline != null &&
                          _budget.daysLeft != null) ...[
                        _shareBadge('⏳ ${_budget.daysLeft} days left'),
                        const SizedBox(width: 8),
                      ],
                      if (_budget.isCompleted) _shareBadge('★ COMPLETED!'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Share buttons
            Row(
              children: [
                Expanded(
                  child: _shareButton(
                    icon: Icons.copy_rounded,
                    label: 'Copy Text',
                    color: _navy.withOpacity(0.08),
                    textColor: _navy,
                    onTap: () {
                      final text = _buildShareText(percent, streak);
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Text copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _shareButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: _navy,
                    textColor: _yellow,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final text = _buildShareText(percent, streak);
                      await Share.share(
                        text,
                        subject: 'Goal: ${_budget.title}',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildShareText(String percent, int streak) {
    return '★ Financial Goal: ${_budget.title}\n'
        '◈ Progress: $percent% (${_fmt.format(_budget.currentAmount)} / ${_fmt.format(_budget.targetAmount)})\n'
        '${streak >= 2 ? '◈ $streak month streak!\n' : ''}'
        '${_budget.deadline != null ? '⏳ Deadline: ${DateFormat('dd MMM yyyy', 'en').format(_budget.deadline!)}\n' : ''}'
        '\nMade with WalletScript ✦';
  }

  Widget _shareBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _yellow.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: _yellow, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── AUTO-DEDUCT SCHEDULE ─────────────────────────────────────────────────
  void _showAutoDeductSchedule() {
    final accounts = context.read<AccountProvider>().accounts;
    AppAccount? selectedAccount =
        _budget.autoDeductAccountId != null && accounts.isNotEmpty
            ? accounts.firstWhere(
                (a) => a.id?.toString() == _budget.autoDeductAccountId,
                orElse: () => accounts.first)
            : null;
    int selectedDay = _budget.autoDeductDay ?? 1;
    double autoAmount = _budget.autoDeductAmount ?? 0;
    final amountCtrl = TextEditingController(
        text: autoAmount > 0 ? autoAmount.toStringAsFixed(0) : '');
    bool isEnabled = _budget.autoDeductEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: _navy.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Monthly Auto-Deduct',
                              style: TextStyle(
                                  color: _navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('Automatically deduct every month',
                              style: TextStyle(
                                  color: _navy.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      activeColor: _yellow,
                      activeTrackColor: _navy,
                      onChanged: (v) => setSheet(() => isEnabled = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: isEnabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !isEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Amount per Month',
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        if (_budget.deadline != null) ...[
                          Builder(builder: (_) {
                            final months = _budget.deadline!
                                    .difference(DateTime.now())
                                    .inDays /
                                30;
                            final suggested = months > 0
                                ? (_budget.remaining / months).ceil()
                                : 0;
                            return GestureDetector(
                              onTap: () => setSheet(
                                  () => amountCtrl.text = suggested.toString()),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _yellow.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: _yellow.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline_rounded,
                                        color: Colors.amber, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Suggestion: ${_fmt.format(suggested.toDouble())}/mo to stay on track',
                                      style: const TextStyle(
                                          color: _navy,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    const Text('Use →',
                                        style: TextStyle(
                                            color: _navy,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              color: _navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            prefixText: 'Rp ',
                            prefixStyle: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 20),
                            hintText: '0',
                            filled: true,
                            fillColor: _navy.withOpacity(0.06),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _yellow, width: 2)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Deduction Date Each Month',
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 44,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 28,
                            itemBuilder: (_, i) {
                              final day = i + 1;
                              final isSelected = selectedDay == day;
                              return GestureDetector(
                                onTap: () => setSheet(() => selectedDay = day),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _navy
                                        : _navy.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? Border.all(color: _yellow, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text('$day',
                                        style: TextStyle(
                                            color: isSelected ? _yellow : _navy,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Deduction runs every $selectedDay${_ordinal(selectedDay)} of the month',
                          style: TextStyle(
                              color: _navy.withOpacity(0.5), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        const Text('Source Wallet',
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 8),
                        if (accounts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _navy.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('No wallets available',
                                style:
                                    TextStyle(color: _navy.withOpacity(0.5))),
                          )
                        else
                          DropdownButtonFormField<AppAccount>(
                            value: selectedAccount,
                            hint: Text('Select wallet',
                                style:
                                    TextStyle(color: _navy.withOpacity(0.5))),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _navy.withOpacity(0.06),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                            ),
                            items: accounts
                                .map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Row(children: [
                                        Text(a.name,
                                            style: const TextStyle(
                                                color: _navy,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 8),
                                        Text(_fmt.format(a.balance),
                                            style: const TextStyle(
                                                color: _yellow,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700)),
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setSheet(() => selectedAccount = v),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _yellow.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: _yellow.withOpacity(0.35)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Auto-deduct runs when you open the app on or after the scheduled date.',
                                  style: TextStyle(
                                      color: _navy.withOpacity(0.6),
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final amount =
                          double.tryParse(amountCtrl.text.trim()) ?? 0;
                      final updated = _budget.copyWith(
                        autoDeductEnabled: isEnabled,
                        autoDeductAmount: isEnabled ? amount : 0,
                        autoDeductDay: isEnabled ? selectedDay : null,
                        autoDeductAccountId:
                            isEnabled ? selectedAccount?.id?.toString() : null,
                      );
                      await context
                          .read<BudgetProvider>()
                          .updateBudget(updated);
                      await _loadDeposits();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEnabled
                                ? 'Auto-deduct enabled on the $selectedDay${_ordinal(selectedDay)} each month'
                                : 'Auto-deduct disabled'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: const Text('Save Schedule',
                        style: TextStyle(
                            color: _yellow,
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

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  // ─── ARCHIVE ──────────────────────────────────────────────────────────────
  void _confirmArchive() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Archive Goal?',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800)),
        content: Text(
          '"${_budget.title}" will be moved to archive. You can restore it anytime.',
          style: TextStyle(color: _navy.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: _navy.withOpacity(0.5)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BudgetProvider>().archiveBudget(_budget.id!);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Archive', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal?',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800)),
        content: Text(
          '"${_budget.title}" and all its deposits will be permanently deleted.',
          style: TextStyle(color: _navy.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: _navy.withOpacity(0.5)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BudgetProvider>().deleteBudget(_budget.id!);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── VISION BOARD ─────────────────────────────────────────────────────────
  void _showEditVisionBoard() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Vision Board Photo',
                style: TextStyle(
                    color: _navy, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Choose a dream photo for this goal',
                style: TextStyle(color: _navy.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 24),
            _sheetOption(ctx,
                icon: Icons.photo_library_rounded,
                label: 'Choose from Gallery',
                value: 'gallery'),
            const SizedBox(height: 10),
            _sheetOption(ctx,
                icon: Icons.camera_alt_rounded,
                label: 'Take a Photo',
                value: 'camera'),
            if (_budget.imagePath != null) ...[
              const SizedBox(height: 10),
              _sheetOption(ctx,
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove Photo',
                  value: 'remove',
                  color: Colors.red),
            ],
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'remove') {
      final cleared = AppBudget(
        id: _budget.id,
        title: _budget.title,
        emoji: _budget.emoji,
        targetAmount: _budget.targetAmount,
        currentAmount: _budget.currentAmount,
        currency: _budget.currency,
        deadline: _budget.deadline,
        color: _budget.color,
        imagePath: null,
        description: _budget.description,
        category: _budget.category,
        isPriority: _budget.isPriority,
      );
      await context.read<BudgetProvider>().updateBudget(cleared);
      if (mounted) setState(() => _budget = cleared);
      return;
    }

    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (result == null) return;
    final updated = _budget.copyWith(imagePath: result.path);
    await context.read<BudgetProvider>().updateBudget(updated);
    if (mounted) setState(() => _budget = updated);
  }

  Widget _sheetOption(BuildContext ctx,
      {required IconData icon,
      required String label,
      required String value,
      Color? color}) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? _navy, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color ?? _navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = _budget.progress;
    final percent = (progress * 100).toStringAsFixed(0);
    final remaining = _budget.remaining;
    final daysLeft = _budget.daysLeft;

    final milestones = [0.25, 0.5, 0.75, 1.0];
    final milestoneLabels = ['25%', '50%', '75%', '100%'];
    final milestoneIcons = ['🌱', '🌿', '🌳', '🏆'];

    return Scaffold(
      backgroundColor: _white,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: _budget.imagePath != null ? 280 : 200,
            pinned: true,
            backgroundColor: _white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: _navy,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                color: _navy,
                tooltip: 'Share',
                onPressed: _showShareCard,
              ),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                color: _navy,
                tooltip: 'Change photo',
                onPressed: _showEditVisionBoard,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: _navy),
                color: _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (v) async {
                  if (v == 'priority') {
                    await context
                        .read<BudgetProvider>()
                        .setPriority(_budget.id!);
                    await _loadDeposits();
                  } else if (v == 'unpriority') {
                    await context
                        .read<BudgetProvider>()
                        .removePriority(_budget.id!);
                    await _loadDeposits();
                  } else if (v == 'auto_deduct') {
                    _showAutoDeductSchedule();
                  } else if (v == 'archive') {
                    _confirmArchive();
                  } else if (v == 'delete') {
                    _confirmDelete();
                  }
                },
                itemBuilder: (_) => [
                  if (!_budget.isPriority)
                    const PopupMenuItem(
                      value: 'priority',
                      child: Row(children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Text('Set as Priority'),
                      ]),
                    ),
                  if (_budget.isPriority)
                    const PopupMenuItem(
                      value: 'unpriority',
                      child: Row(children: [
                        Icon(Icons.star_border_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Remove Priority'),
                      ]),
                    ),
                  PopupMenuItem(
                    value: 'auto_deduct',
                    child: Row(children: [
                      Icon(
                        Icons.autorenew_rounded,
                        color: _budget.autoDeductEnabled ? _navy : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Auto-Deduct'),
                          Text(
                            _budget.autoDeductEnabled
                                ? 'Active · day ${_budget.autoDeductDay}'
                                : 'Not configured',
                            style: TextStyle(
                              color: _budget.autoDeductEnabled
                                  ? _navy
                                  : Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(children: [
                      Icon(Icons.archive_rounded, color: Colors.grey, size: 18),
                      SizedBox(width: 8),
                      Text('Archive Goal'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Goal', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_budget.imagePath != null)
                    Image.file(File(_budget.imagePath!), fit: BoxFit.cover)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _navy.withOpacity(0.08),
                            _yellow.withOpacity(0.12),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_budget.emoji,
                                style: const TextStyle(fontSize: 72)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _showEditVisionBoard,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _navy.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: _navy.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: _navy.withOpacity(0.7),
                                        size: 15),
                                    const SizedBox(width: 6),
                                    Text('Add vision board photo',
                                        style: TextStyle(
                                            color: _navy.withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _white.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_budget.imagePath != null)
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: _yellow, size: 12),
                            SizedBox(width: 4),
                            Text('Vision Board',
                                style: TextStyle(
                                    color: _white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Container(
              color: _white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_budget.title,
                            style: const TextStyle(
                                color: _navy,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                      ),
                      if (_budget.autoDeductEnabled) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _showAutoDeductSchedule,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _navy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _navy.withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.autorenew_rounded,
                                    color: _navy, size: 12),
                                SizedBox(width: 3),
                                Text('Auto',
                                    style: TextStyle(
                                        color: _navy,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_budget.isPriority) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _yellow.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: _yellow, size: 14),
                              SizedBox(width: 4),
                              Text('Priority',
                                  style: TextStyle(
                                      color: _navy,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (_budget.description != null) ...[
                    const SizedBox(height: 4),
                    Text(_budget.description!,
                        style: TextStyle(
                            color: _navy.withOpacity(0.5), fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$percent% achieved',
                          style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(_fmt.format(_budget.currentAmount),
                          style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w800,
                              fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: _navy.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _budget.isCompleted ? _yellow : _navy),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statChip(Icons.flag_rounded, 'Target',
                          _fmt.format(_budget.targetAmount)),
                      const SizedBox(width: 8),
                      _statChip(Icons.savings_outlined, 'Remaining',
                          _fmt.format(remaining < 0 ? 0 : remaining)),
                      const SizedBox(width: 8),
                      if (daysLeft != null)
                        _statChip(
                          Icons.calendar_today_rounded,
                          'Days left',
                          daysLeft < 0 ? 'Overdue!' : '$daysLeft days',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_budget.deadline != null && !_budget.isCompleted)
              _monthlySuggestionBanner(),
            if (_budget.autoDeductEnabled) _autoDeductBanner(),
            Container(
              color: _white,
              child: TabBar(
                controller: _tabController,
                labelColor: _navy,
                unselectedLabelColor: _navy.withOpacity(0.4),
                indicatorColor: _yellow,
                indicatorWeight: 3,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'History'),
                  Tab(text: 'Milestones'),
                  Tab(text: 'Info'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHistoryTab(),
                  _buildMilestoneTab(
                      milestones, milestoneLabels, milestoneIcons),
                  _buildInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _budget.isCompleted
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddDeposit,
              backgroundColor: _navy,
              icon: const Icon(Icons.add_rounded, color: _yellow),
              label: const Text('Add Deposit',
                  style:
                      TextStyle(color: _yellow, fontWeight: FontWeight.w700)),
            ),
    );
  }

  // ─── AUTO-DEDUCT ACTIVE BANNER ────────────────────────────────────────────
  Widget _autoDeductBanner() {
    return GestureDetector(
      onTap: _showAutoDeductSchedule,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _navy.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.autorenew_rounded, color: _navy, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Auto-deduct active · ${_fmt.format(_budget.autoDeductAmount ?? 0)}/mo on day ${_budget.autoDeductDay}',
                style: const TextStyle(
                    color: _navy, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _navy, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: _navy.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(label,
                    style:
                        TextStyle(color: _navy.withOpacity(0.5), fontSize: 10)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: _navy, fontWeight: FontWeight.w700, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _monthlySuggestionBanner() {
    final months = _budget.deadline!.difference(DateTime.now()).inDays / 30;
    if (months <= 0) return const SizedBox.shrink();
    final monthly = _budget.remaining / months;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _yellow.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _yellow.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Save ${_fmt.format(monthly)}/month to reach your target on time',
              style: const TextStyle(
                  color: _navy, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HISTORY TAB ──────────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }
    if (_deposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No deposits yet',
                style: TextStyle(color: _navy.withOpacity(0.5))),
            const SizedBox(height: 6),
            Text('Tap "Add Deposit" to get started',
                style: TextStyle(color: _navy.withOpacity(0.35), fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _deposits.length,
      itemBuilder: (ctx, i) {
        final d = _deposits[i];
        final isImage = d.attachmentPath != null &&
            (d.attachmentPath!.toLowerCase().endsWith('.jpg') ||
                d.attachmentPath!.toLowerCase().endsWith('.jpeg') ||
                d.attachmentPath!.toLowerCase().endsWith('.png') ||
                d.attachmentPath!.toLowerCase().endsWith('.webp'));
        return Dismissible(
          key: Key(d.id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                backgroundColor: _white,
                title: const Text('Delete deposit?',
                    style:
                        TextStyle(color: _navy, fontWeight: FontWeight.w800)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text('Cancel',
                          style: TextStyle(color: _navy.withOpacity(0.5)))),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            await context.read<BudgetProvider>().deleteDeposit(
                  depositId: d.id!,
                  budgetId: d.budgetId,
                  depositAmount: d.amount,
                );
            await _loadDeposits();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _navy.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: _navy.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.savings_rounded,
                          color: _yellow, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fmt.format(d.amount),
                              style: const TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          Text(
                            d.sourceAccountName != null
                                ? 'from ${d.sourceAccountName}'
                                : 'Manual',
                            style: TextStyle(
                                color: _navy.withOpacity(0.5), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(d.date),
                      style: TextStyle(
                          color: _navy.withOpacity(0.45), fontSize: 11),
                    ),
                  ],
                ),
                if (d.note != null) ...[
                  const SizedBox(height: 8),
                  Text(d.note!,
                      style: TextStyle(
                          color: _navy.withOpacity(0.6), fontSize: 13)),
                ],
                if (d.attachmentPath != null) ...[
                  const SizedBox(height: 8),
                  if (isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(d.attachmentPath!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _navy.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded,
                              size: 14, color: _navy),
                          const SizedBox(width: 6),
                          Text(d.attachmentPath!.split('/').last,
                              style:
                                  const TextStyle(color: _navy, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── MILESTONE TAB ────────────────────────────────────────────────────────
  Widget _buildMilestoneTab(
      List<double> milestones, List<String> labels, List<String> icons) {
    final streak = _calculateStreak();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: streak >= 3
                  ? _yellow.withOpacity(0.5)
                  : _navy.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: streak >= 1
                          ? _yellow.withOpacity(0.15)
                          : _navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      streak >= 6
                          ? '🔥'
                          : streak >= 3
                              ? '⚡'
                              : streak >= 1
                                  ? '✨'
                                  : '💤',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saving Streak',
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(
                          streak == 0
                              ? 'No deposits yet this month'
                              : streak == 1
                                  ? 'Just started, keep going!'
                                  : '$streak months in a row!',
                          style: TextStyle(
                              color: _navy.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$streak',
                        style: TextStyle(
                            color: streak >= 1 ? _navy : _navy.withOpacity(0.3),
                            fontWeight: FontWeight.w800,
                            fontSize: 28),
                      ),
                      Text(
                        streak == 1 ? 'month' : 'months 🔥',
                        style: TextStyle(
                            color: _navy.withOpacity(0.45), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              if (_deposits.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildStreakDots(),
              ],
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 13, color: _navy.withOpacity(0.45)),
                    const SizedBox(width: 6),
                    Text(
                      '${_deposits.length}x total deposits · ${_fmt.format(_budget.currentAmount)} saved',
                      style: TextStyle(
                          color: _navy.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text('ACHIEVEMENTS',
            style: TextStyle(
                color: _navy.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
        const SizedBox(height: 12),
        ...List.generate(milestones.length, (i) {
          final reached = _budget.progress >= milestones[i];
          final isCurrent =
              !reached && (i == 0 || _budget.progress >= milestones[i - 1]);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: reached ? _navy.withOpacity(0.05) : _white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: reached
                    ? _navy.withOpacity(0.2)
                    : isCurrent
                        ? _yellow.withOpacity(0.5)
                        : _navy.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Text(icons[i], style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Milestone ${labels[i]}',
                          style: TextStyle(
                              color: reached ? _navy : _navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(
                        _fmt.format(_budget.targetAmount * milestones[i]),
                        style: TextStyle(
                            color: _navy.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (reached)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _yellow,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.check_rounded, color: _navy, size: 16),
                  )
                else if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            color: _yellow,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  )
                else
                  Icon(Icons.lock_outline_rounded,
                      color: _navy.withOpacity(0.25), size: 20),
              ],
            ),
          );
        }),
        if (_budget.isCompleted) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _yellow.withOpacity(0.2),
                  _navy.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _yellow.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text('Goal Achieved!',
                    style: TextStyle(
                        color: _navy,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Congratulations! You have reached your target.',
                    style:
                        TextStyle(color: _navy.withOpacity(0.6), fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStreakDots() {
    final now = DateTime.now();
    final monthsWithDeposit = _deposits
        .map((d) => '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}')
        .toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final month = DateTime(now.year, now.month - (5 - i));
        final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        final hasDeposit = monthsWithDeposit.contains(key);
        final isCurrentMonth =
            month.year == now.year && month.month == now.month;
        return Tooltip(
          message: DateFormat('MMM yyyy').format(month),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: hasDeposit
                        ? _navy
                        : isCurrentMonth
                            ? _yellow.withOpacity(0.2)
                            : _navy.withOpacity(0.07),
                    shape: BoxShape.circle,
                    border: isCurrentMonth
                        ? Border.all(color: _yellow, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      hasDeposit ? '🔥' : (isCurrentMonth ? '?' : '○'),
                      style: TextStyle(
                        fontSize: hasDeposit ? 14 : 11,
                        color: hasDeposit ? _white : _navy.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM').format(month),
                  style: TextStyle(color: _navy.withOpacity(0.45), fontSize: 9),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── INFO TAB ─────────────────────────────────────────────────────────────
  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        _infoRow(Icons.track_changes_rounded, 'Goal', _budget.title, _navy),
        _infoRow(Icons.monetization_on_rounded, 'Target',
            _fmt.format(_budget.targetAmount), Colors.green),
        _infoRow(Icons.savings_rounded, 'Saved',
            _fmt.format(_budget.currentAmount), Colors.teal),
        _infoRow(
            Icons.remove_circle_outline_rounded,
            'Remaining',
            _fmt.format(_budget.remaining < 0 ? 0 : _budget.remaining),
            Colors.orange),
        if (_budget.deadline != null)
          _infoRow(
              Icons.event_rounded,
              'Deadline',
              DateFormat('dd MMMM yyyy').format(_budget.deadline!),
              Colors.blue),
        if (_budget.category != null)
          _infoRow(Icons.label_rounded, 'Category', _budget.category!,
              Colors.purple),
        _infoRow(Icons.bar_chart_rounded, 'Progress',
            '${(_budget.progress * 100).toStringAsFixed(1)}%', _navy),
        _infoRow(Icons.receipt_long_rounded, 'Total Deposits',
            '${_deposits.length}x', Colors.indigo),
        _infoRow(Icons.local_fire_department_rounded, 'Saving Streak',
            '${_calculateStreak()} months in a row', Colors.orange),
        if (_budget.autoDeductEnabled)
          _infoRow(
              Icons.autorenew_rounded,
              'Auto-Deduct',
              '${_fmt.format(_budget.autoDeductAmount ?? 0)}/mo · day ${_budget.autoDeductDay}',
              _navy),
        if (_deposits.isNotEmpty)
          _infoRow(
              Icons.calendar_month_rounded,
              'Last Deposit',
              DateFormat('dd MMM yyyy HH:mm').format(_deposits.first.date),
              Colors.grey),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _navy.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(color: _navy.withOpacity(0.55), fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    color: _navy, fontWeight: FontWeight.w700, fontSize: 13),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
