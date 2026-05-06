import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
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
  String _selectedWallet = 'Personal';
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

  final List<Map<String, dynamic>> _wallets = [
    {'label': 'Personal', 'icon': Icons.account_balance_wallet_rounded, 'balance': 'Rp 4.250.000'},
    {'label': 'Tabungan', 'icon': Icons.savings_rounded, 'balance': 'Rp 12.000.000'},
    {'label': 'Bank', 'icon': Icons.credit_card_rounded, 'balance': 'Rp 1.120.000'},
  ];

  void _save() {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominal tidak boleh kosong!')));
      return;
    }
    final tx = AppTransaction(
      title: _category,
      amount: double.parse(raw),
      type: _type,
      category: _category,
      currency: 'IDR',
      accountId: '1',
      date: _date,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );
    context.read<TransactionProvider>().addTransaction(tx);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi tersimpan')));
  }

  @override
  Widget build(BuildContext context) {
    final cats = _type == 'expense' ? _expenseCategories : _incomeCategories;
    if (!cats.any((c) => c['label'] == _category)) {
      _category = cats.first['label'] as String;
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
            style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 2),
              color: AppTheme.surfaceContainer,
            ),
            child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 20),
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
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

            // Wallet selector
            const Text('Select Wallet',
                style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _wallets.length,
                itemBuilder: (ctx, i) {
                  final w = _wallets[i];
                  final isSelected = _selectedWallet == w['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedWallet = w['label'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 110,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.outline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(w['icon'] as IconData,
                              color: isSelected ? Colors.white : AppTheme.primary,
                              size: 22),
                          const Spacer(),
                          Text(w['label'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              )),
                          Text(w['balance'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.7)
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
                style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16)),
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
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(c['icon'] as IconData,
                            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                            size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(c['label'] as String,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                    const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction Date',
                            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
                        Text(
                          DateFormat('d MMMM yyyy', 'id').format(_date),
                          style: const TextStyle(
                              color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.onSurfaceVariant),
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
                    child: Icon(Icons.notes_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
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
                    child: Icon(Icons.attach_file_rounded, color: AppTheme.onSurfaceVariant, size: 20),
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
                      style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Transaction',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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
        onTap: () => setState(() => _type = type),
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
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
