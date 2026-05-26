import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../theme/app_theme.dart';

class WalletAllScreen extends StatefulWidget {
  const WalletAllScreen({super.key});
  @override
  State<WalletAllScreen> createState() => _WalletAllScreenState();
}

class _WalletAllScreenState extends State<WalletAllScreen> {
  final Set<String> _expanded = {};
  final Map<String, bool> _hidden = {};

  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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

  static const Map<String, Color> _groupColors = {
    'Cash': Color(0xFF0D1B3E),
    'Accounts': Color(0xFF0D1B3E),
    'Card': Color(0xFFF5C842),
    'Debit Card': Color(0xFF0D1B3E),
    'Savings': Color(0xFF0D1B3E),
    'Top-Up/Prepaid': Color(0xFFF5C842),
    'Investments': Color(0xFF0D1B3E),
    'Overdrafts': Color(0xFFEF4444),
    'Loan': Color(0xFFF5C842),
    'Insurance': Color(0xFF0D1B3E),
    'Others': Color(0xFF64748B),
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final byGroup = provider.accountsByGroup;
    final totalBalance = provider.totalBalance;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0D1B3E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('All Wallets',
            style: TextStyle(
                color: Color(0xFF0D1B3E), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF0D1B3E)),
            onPressed: () => _showAddAccountSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Total header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _headerStat('Assets', formatter.format(totalBalance),
                      const Color(0xFFF5C842)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _headerStat('Liabilities', 'Rp 0', const Color(0xFFFC7C78)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _headerStat(
                      'Total', formatter.format(totalBalance), Colors.white),
                ],
              ),
            ),

            // ── Group list
            ...byGroup.entries.map((entry) {
              final group = entry.key;
              final accounts = entry.value;
              final groupTotal = accounts.fold(0.0, (s, a) => s + a.balance);
              final isExpanded = _expanded.contains(group);
              final isHidden = _hidden[group] ?? false;
              final color = _groupColors[group] ?? const Color(0xFF64748B);
              final icon = _groupIcons[group] ?? Icons.wallet_rounded;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => isExpanded
                          ? _expanded.remove(group)
                          : _expanded.add(group)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(group,
                                    style: const TextStyle(
                                        color: Color(0xFF0D1B3E),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                Text(
                                    '${accounts.length} ${accounts.length == 1 ? 'account' : 'accounts'}',
                                    style: const TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _hidden[group] = !isHidden),
                            child: Icon(
                              isHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppTheme.onSurfaceVariant,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isHidden
                                ? '••••••••'
                                : formatter.format(groupTotal),
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ]),
                      ),
                    ),
                    if (isExpanded) ...[
                      const Divider(height: 1, color: AppTheme.outline),
                      ...accounts.map((acc) => _accountTile(acc, color)),
                      InkWell(
                        onTap: () =>
                            _showAddAccountSheet(context, group: group),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.outline,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add_rounded,
                                  color: AppTheme.onSurfaceVariant, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Text('Add $group account',
                                style: const TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 13)),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddAccountSheet(context),
                icon: const Icon(Icons.add_rounded,
                    color: Color(0xFF0D1B3E), size: 18),
                label: const Text('Add New Account',
                    style: TextStyle(
                        color: Color(0xFF0D1B3E), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0D1B3E)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountTile(AppAccount acc, Color groupColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: groupColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.account_balance_wallet_rounded,
              color: groupColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(acc.name,
              style: const TextStyle(
                  color: Color(0xFF0D1B3E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Text(formatter.format(acc.balance),
            style: const TextStyle(
                color: Color(0xFF0D1B3E),
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showEditAccountSheet(context, acc),
          child: const Icon(Icons.more_vert_rounded,
              color: AppTheme.onSurfaceVariant, size: 18),
        ),
      ]),
    );
  }

  static Widget _headerStat(String label, String value, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 14)),
    ]);
  }

  // ── Add Account Sheet ────────────────────────────────────────────────────────

  void _showAddAccountSheet(BuildContext ctx, {String? group}) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String selectedGroup = group ?? 'Cash';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.outline,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Add Account',
                  style: TextStyle(
                      color: Color(0xFF0D1B3E),
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              const SizedBox(height: 20),

              // Group picker
              DropdownButtonFormField<String>(
                value: selectedGroup,
                dropdownColor: AppTheme.surface,
                decoration: InputDecoration(
                  labelText: 'Group',
                  labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Color(0xFF0D1B3E)),
                items: AccountProvider.allGroups
                    .map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(g,
                            style: const TextStyle(color: Color(0xFF0D1B3E)))))
                    .toList(),
                onChanged: (v) =>
                    setSheet(() => selectedGroup = v ?? selectedGroup),
              ),
              const SizedBox(height: 12),

              // Name
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Color(0xFF0D1B3E)),
                decoration: InputDecoration(
                  labelText: 'Account Name',
                  labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Initial balance
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF0D1B3E)),
                decoration: InputDecoration(
                  labelText: 'Initial Balance (Rp)',
                  labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                  filled: true,
                  fillColor: AppTheme.surfaceContainer,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B3E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final balance = double.tryParse(balanceCtrl.text) ?? 0.0;

                    final saved =
                        await ctx.read<AccountProvider>().addAccountAndReturn(
                              AppAccount(
                                name: nameCtrl.text.trim(),
                                group: selectedGroup,
                                type: selectedGroup.toLowerCase(),
                                balance: balance,
                                currency: 'IDR',
                                icon: 'wallet',
                                color: '0xFF0D1B3E',
                              ),
                            );

                    if (balance > 0 && saved.id != null) {
                      // ignore: use_build_context_synchronously
                      ctx.read<TransactionProvider>().addTransaction(
                            AppTransaction(
                              title:
                                  'Opening Balance — ${nameCtrl.text.trim()}',
                              amount: balance,
                              type: 'income',
                              category: 'Opening Balance',
                              currency: 'IDR',
                              accountId: saved.id.toString(),
                              date: DateTime.now(),
                              note:
                                  'Initial balance for account ${nameCtrl.text.trim()}',
                            ),
                          );
                    }

                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Account ${nameCtrl.text.trim()} added successfully')),
                    );
                  },
                  child: const Text('Save',
                      style: TextStyle(
                          color: Color(0xFFF5C842),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Edit Account Sheet ───────────────────────────────────────────────────────

  void _showEditAccountSheet(BuildContext ctx, AppAccount acc) {
    final nameCtrl = TextEditingController(text: acc.name);
    final balanceCtrl =
        TextEditingController(text: acc.balance.toStringAsFixed(0));

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
            Text('Edit ${acc.name}',
                style: const TextStyle(
                    color: Color(0xFF0D1B3E),
                    fontWeight: FontWeight.w800,
                    fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Color(0xFF0D1B3E)),
              decoration: InputDecoration(
                labelText: 'Account Name',
                labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF0D1B3E)),
              decoration: InputDecoration(
                labelText: 'Balance (Rp)',
                labelStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (acc.id != null) {
                      ctx.read<AccountProvider>().deleteAccount(acc.id!);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete',
                      style: TextStyle(
                          color: AppTheme.error, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D1B3E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final balance =
                        double.tryParse(balanceCtrl.text) ?? acc.balance;
                    ctx.read<AccountProvider>().updateAccount(acc.copyWith(
                        name: nameCtrl.text.trim(), balance: balance));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save',
                      style: TextStyle(
                          color: Color(0xFFF5C842),
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
