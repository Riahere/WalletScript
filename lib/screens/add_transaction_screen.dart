import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'expense';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'Makanan';

  // Wallet dipilih by ID, bukan hardcoded name
  AppAccount? _selectedAccount;

  DateTime _date = DateTime.now();

  final List<Map<String, dynamic>> _expenseCategories = [
    {'label': 'Makanan', 'icon': Icons.restaurant_rounded},
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Belanja', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Rumah', 'icon': Icons.home_rounded},
    {'label': 'Kesehatan', 'icon': Icons.health_and_safety_rounded},
    {'label': 'Transport', 'icon': Icons.directions_car_rounded},
    {'label': 'Edu', 'icon': Icons.school_rounded},
    {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'label': 'Gaji', 'icon': Icons.account_balance_wallet_rounded},
    {'label': 'Freelance', 'icon': Icons.laptop_rounded},
    {'label': 'Investasi', 'icon': Icons.trending_up_rounded},
    {'label': 'Hadiah', 'icon': Icons.card_giftcard_rounded},
    {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  // Icon per group (sama dengan di home_screen)
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

  // Warna per group (sama dengan di home_screen agar konsisten)
  static const List<Color> _groupColors = [
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

  Color _colorForGroup(String group) {
    final groups = AccountProvider.allGroups;
    final idx = groups.indexOf(group);
    return _groupColors[(idx < 0 ? 0 : idx) % _groupColors.length];
  }

  IconData _iconForGroup(String group) {
    return _groupIcons[group] ?? Icons.wallet_rounded;
  }

  @override
  void initState() {
    super.initState();
    // Pastikan accounts sudah diload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountProvider = context.read<AccountProvider>();
      accountProvider.loadAccounts().then((_) {
        if (mounted && accountProvider.accounts.isNotEmpty) {
          setState(() => _selectedAccount = accountProvider.accounts.first);
        }
      });
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominal tidak boleh kosong!')));
      return;
    }
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih wallet terlebih dahulu!')));
      return;
    }

    final amount = double.parse(raw);
    final accountProvider = context.read<AccountProvider>();

    // Hitung balance baru setelah transaksi
    double newBalance = _selectedAccount!.balance;
    if (_type == 'expense') {
      newBalance -= amount;
    } else if (_type == 'income') {
      newBalance += amount;
    }
    // Transfer: tidak ubah balance di sini (perlu pilih akun tujuan — bisa dikembangkan)

    final tx = AppTransaction(
      title: _category,
      amount: amount,
      type: _type,
      category: _category,
      currency: 'IDR',
      accountId: _selectedAccount!.id.toString(),
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    // Simpan transaksi
    context.read<TransactionProvider>().addTransaction(tx);

    // Update balance akun yang dipilih
    if (_type != 'transfer') {
      accountProvider.updateBalance(_selectedAccount!.id!, newBalance);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Transaksi tersimpan')));
  }

  @override
  Widget build(BuildContext context) {
    final cats = _type == 'expense' ? _expenseCategories : _incomeCategories;
    if (!cats.any((c) => c['label'] == _category)) {
      _category = cats.first['label'] as String;
    }

    // Ambil data akun real dari provider
    final accountProvider = context.watch<AccountProvider>();
    final accounts = accountProvider.accounts;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Auto-select akun pertama kalau belum ada yang dipilih
    if (_selectedAccount == null && accounts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedAccount = accounts.first);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Transaction',
            style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 2),
              color: AppTheme.surfaceContainer,
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.primary, size: 20),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _typeBtn('expense', 'Expense'),
                  _typeBtn('income', 'Income'),
                  _typeBtn('transfer', 'Transfer'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Amount
            Center(
              child: Column(
                children: [
                  const Text('ENTER AMOUNT',
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text('Rp ',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          )),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 42,
                                fontWeight: FontWeight.w800),
                            contentPadding: EdgeInsets.zero,
                            filled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── SELECT WALLET — dari AccountProvider (real data)
            const Text('Select Wallet',
                style: TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 12),

            accounts.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.onSurfaceVariant, size: 18),
                      SizedBox(width: 8),
                      Text('Belum ada wallet. Tambah dulu di halaman Wallet.',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    ]),
                  )
                : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: accounts.length,
                      itemBuilder: (ctx, i) {
                        final acc = accounts[i];
                        final isSelected = _selectedAccount?.id == acc.id;
                        final groupColor = _colorForGroup(acc.group);
                        final groupIcon = _iconForGroup(acc.group);

                        return GestureDetector(
                          onTap: () => setState(() => _selectedAccount = acc),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? groupColor : AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isSelected ? groupColor : AppTheme.outline,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: groupColor.withOpacity(0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ]
                                  : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(groupIcon,
                                      color: isSelected
                                          ? Colors.white
                                          : groupColor,
                                      size: 18),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 14),
                                ]),
                                const Spacer(),
                                Text(acc.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    )),
                                const SizedBox(height: 2),
                                Text(formatter.format(acc.balance),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.75)
                                          : AppTheme.onSurfaceVariant,
                                      fontSize: 10,
                                    )),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),

            // Category
            const Text('Category',
                style: TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: cats.length,
              itemBuilder: (ctx, i) {
                final c = cats[i];
                final isSelected = _category == c['label'];
                return GestureDetector(
                  onTap: () => setState(() => _category = c['label'] as String),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(c['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.onSurfaceVariant,
                            size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(c['label'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction Date',
                            style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 11)),
                        Text(
                          DateFormat('d MMMM yyyy', 'id').format(_date),
                          style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(Icons.notes_rounded,
                        color: AppTheme.onSurfaceVariant, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      style: const TextStyle(
                          color: AppTheme.onSurface, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Add a note...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                        filled: false,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(Icons.attach_file_rounded,
                        color: AppTheme.onSurfaceVariant, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Receipt attachment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Receipt Attachment',
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _attachBtn(Icons.camera_alt_rounded, 'Camera'),
                      const SizedBox(width: 12),
                      _attachBtn(Icons.photo_library_rounded, 'Gallery'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Transaction',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String type, String label) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedAccount = null; // reset pilihan saat ganti tipe
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
          ),
        ),
      ),
    );
  }

  Widget _attachBtn(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
