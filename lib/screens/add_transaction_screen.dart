import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
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
  AppAccount? _selectedAccount;
  AppAccount? _fromAccount;
  AppAccount? _toAccount;

  DateTime _date = DateTime.now();
  String? _attachmentPath;
  final _imagePicker = ImagePicker();

  final List<Map<String, dynamic>> _customExpenseCategories = [];
  final List<Map<String, dynamic>> _customIncomeCategories = [];

  final List<Map<String, dynamic>> _defaultExpenseCategories = [
    {'label': 'Makanan', 'icon': Icons.restaurant_rounded},
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
    {'label': 'Belanja', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Rumah', 'icon': Icons.home_rounded},
    {'label': 'Kesehatan', 'icon': Icons.health_and_safety_rounded},
    {'label': 'Transport', 'icon': Icons.directions_car_rounded},
    {'label': 'Edu', 'icon': Icons.school_rounded},
    {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  final List<Map<String, dynamic>> _defaultIncomeCategories = [
    {'label': 'Gaji', 'icon': Icons.account_balance_wallet_rounded},
    {'label': 'Freelance', 'icon': Icons.laptop_rounded},
    {'label': 'Investasi', 'icon': Icons.trending_up_rounded},
    {'label': 'Hadiah', 'icon': Icons.card_giftcard_rounded},
    {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
  ];

  List<Map<String, dynamic>> get _expenseCategories => [
        ..._defaultExpenseCategories.where((c) => c['label'] != 'Lainnya'),
        ..._customExpenseCategories,
        {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
      ];

  List<Map<String, dynamic>> get _incomeCategories => [
        ..._defaultIncomeCategories.where((c) => c['label'] != 'Lainnya'),
        ..._customIncomeCategories,
        {'label': 'Lainnya', 'icon': Icons.more_horiz_rounded},
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
    final idx = AccountProvider.allGroups.indexOf(group);
    return _groupColors[(idx < 0 ? 0 : idx) % _groupColors.length];
  }

  IconData _iconForGroup(String group) =>
      _groupIcons[group] ?? Icons.wallet_rounded;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ap = context.read<AccountProvider>();
      ap.loadAccounts().then((_) {
        if (mounted && ap.accounts.isNotEmpty) {
          setState(() {
            _selectedAccount = ap.accounts.first;
            _fromAccount = ap.accounts.first;
            _toAccount = ap.accounts.length > 1 ? ap.accounts[1] : null;
          });
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() => _attachmentPath = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal ambil gambar: $e')),
        );
      }
    }
  }

  // ── FIX: Custom category dialog — GridView di dalam SizedBox, bukan ListView
  void _showAddCustomCategoryDialog() {
    final ctrl = TextEditingController();
    IconData selectedIcon = Icons.label_rounded;

    final iconOptions = [
      Icons.label_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
      Icons.pets_rounded,
      Icons.sports_soccer_rounded,
      Icons.music_note_rounded,
      Icons.coffee_rounded,
      Icons.cake_rounded,
      Icons.local_gas_station_rounded,
      Icons.spa_rounded,
      Icons.fitness_center_rounded,
      Icons.beach_access_rounded,
      Icons.directions_bike_rounded,
      Icons.movie_rounded,
      Icons.book_rounded,
      Icons.computer_rounded,
      Icons.phone_android_rounded,
      Icons.headphones_rounded,
    ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Buat Kategori Baru',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          // FIX: Pakai Column dengan mainAxisSize.min, GridView pakai shrinkWrap
          // tapi dibungkus SizedBox agar tidak trigger intrinsic dimensions error
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  style:
                      const TextStyle(color: AppTheme.onSurface, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Nama kategori...',
                    hintStyle:
                        const TextStyle(color: AppTheme.onSurfaceVariant),
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Icon',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                // FIX: GridView.count langsung dengan shrinkWrap, bukan GridView.builder
                // agar tidak trigger intrinsic dimensions dari AlertDialog
                GridView.count(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: iconOptions.map((ic) {
                    final isSelected = selectedIcon == ic;
                    return GestureDetector(
                      onTap: () => setDialog(() => selectedIcon = ic),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          ic,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(color: AppTheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final label = ctrl.text.trim();
                if (label.isEmpty) return;
                setState(() {
                  final newCat = {'label': label, 'icon': selectedIcon};
                  if (_type == 'expense') {
                    _customExpenseCategories.add(newCat);
                  } else {
                    _customIncomeCategories.add(newCat);
                  }
                  _category = label;
                });
                Navigator.pop(ctx);
              },
              child:
                  const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final raw = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominal tidak boleh kosong!')));
      return;
    }

    final amount = double.parse(raw);
    final ap = context.read<AccountProvider>();
    final tp = context.read<TransactionProvider>();

    if (_type == 'transfer') {
      if (_fromAccount == null || _toAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih akun asal dan tujuan!')));
        return;
      }
      if (_fromAccount!.id == _toAccount!.id) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Akun asal dan tujuan tidak boleh sama!')));
        return;
      }
      if (amount > _fromAccount!.balance) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saldo tidak mencukupi!')));
        return;
      }

      final tx = AppTransaction(
        title: 'Transfer ke ${_toAccount!.name}',
        amount: amount,
        type: 'transfer',
        category: 'Transfer',
        currency: 'IDR',
        accountId: _fromAccount!.id.toString(),
        toAccountId: _toAccount!.id.toString(),
        date: _date,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        attachmentPath: _attachmentPath,
      );
      tp.addTransaction(tx);
      ap.updateBalance(_fromAccount!.id!, _fromAccount!.balance - amount);
      ap.updateBalance(_toAccount!.id!, _toAccount!.balance + amount);
    } else {
      if (_selectedAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih wallet terlebih dahulu!')));
        return;
      }

      final tx = AppTransaction(
        title: _category,
        amount: amount,
        type: _type,
        category: _category,
        currency: 'IDR',
        accountId: _selectedAccount!.id.toString(),
        date: _date,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        attachmentPath: _attachmentPath,
      );
      tp.addTransaction(tx);

      final newBalance = _type == 'income'
          ? _selectedAccount!.balance + amount
          : _selectedAccount!.balance - amount;
      ap.updateBalance(_selectedAccount!.id!, newBalance);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Transaksi tersimpan ✓')));
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AccountProvider>();
    final accounts = ap.accounts;
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Auto-select — ambil dari accounts list biar instance-nya sama
    if (accounts.isNotEmpty) {
      if (_selectedAccount == null ||
          !accounts.any((a) => a.id == _selectedAccount!.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedAccount = accounts.first);
        });
      }
      if (_fromAccount == null ||
          !accounts.any((a) => a.id == _fromAccount!.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _fromAccount = accounts.first);
        });
      }
      if ((_toAccount == null ||
              !accounts.any((a) => a.id == _toAccount!.id)) &&
          accounts.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _toAccount = accounts[1]);
        });
      }
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
              child: Row(children: [
                _typeBtn('expense', 'Expense'),
                _typeBtn('income', 'Income'),
                _typeBtn('transfer', 'Transfer'),
              ]),
            ),
            const SizedBox(height: 28),

            // Amount
            Center(
              child: Column(children: [
                const Text('ENTER AMOUNT',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
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
                            fontWeight: FontWeight.w700)),
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
                            fontWeight: FontWeight.w800),
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
              ]),
            ),
            const SizedBox(height: 24),

            if (_type == 'transfer')
              _buildTransferSection(accounts, formatter)
            else ...[
              _buildWalletSection(accounts, formatter),
              const SizedBox(height: 20),
              _buildCategorySection(),
            ],

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
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaction Date',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 11)),
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
                ]),
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
              child: Row(children: [
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
              ]),
            ),
            const SizedBox(height: 12),

            // Receipt Attachment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
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
                  if (_attachmentPath != null) ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_attachmentPath!),
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _attachmentPath = null),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(children: [
                    _attachBtn(
                      Icons.camera_alt_rounded,
                      'Camera',
                      () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 12),
                    _attachBtn(
                      Icons.photo_library_rounded,
                      'Gallery',
                      () => _pickImage(ImageSource.gallery),
                    ),
                  ]),
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

  Widget _buildTransferSection(
      List<AppAccount> accounts, NumberFormat formatter) {
    if (accounts.length < 2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline, color: AppTheme.onSurfaceVariant, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Butuh minimal 2 wallet untuk transfer. Tambah di halaman Wallet.',
              style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ]),
      );
    }

    // FIX: Resolve _fromAccount & _toAccount ke instance dari accounts list
    final resolvedFrom = accounts.firstWhere((a) => a.id == _fromAccount?.id,
        orElse: () => accounts.first);
    final resolvedTo = accounts.firstWhere(
        (a) => a.id == _toAccount?.id && a.id != resolvedFrom.id,
        orElse: () => accounts.firstWhere((a) => a.id != resolvedFrom.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('From',
            style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 10),
        _walletDropdown(
          selected: resolvedFrom,
          accounts: accounts,
          exclude: resolvedTo,
          onChanged: (acc) {
            if (acc != null) setState(() => _fromAccount = acc);
          },
          formatter: formatter,
        ),
        const SizedBox(height: 12),

        // Swap button
        Center(
          child: GestureDetector(
            onTap: () => setState(() {
              final tmp = _fromAccount;
              _fromAccount = _toAccount;
              _toAccount = tmp;
            }),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.swap_vert_rounded,
                  color: AppTheme.primary, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 12),

        const Text('To',
            style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 10),
        _walletDropdown(
          selected: resolvedTo,
          accounts: accounts,
          exclude: resolvedFrom,
          onChanged: (acc) {
            if (acc != null) setState(() => _toAccount = acc);
          },
          formatter: formatter,
        ),

        if (resolvedFrom != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.onSurfaceVariant, size: 16),
              const SizedBox(width: 8),
              Text(
                'Saldo ${resolvedFrom.name}: ${formatter.format(resolvedFrom.balance)}',
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant, fontSize: 12),
              ),
            ]),
          ),
        ],
      ],
    );
  }

  // FIX: DropdownButton value harus dari list items (same instance by id)
  Widget _walletDropdown({
    required AppAccount? selected,
    required List<AppAccount> accounts,
    required AppAccount? exclude,
    required ValueChanged<AppAccount?> onChanged,
    required NumberFormat formatter,
  }) {
    final available = accounts.where((a) => a.id != exclude?.id).toList();

    // Resolve value ke instance yang ada di available list
    AppAccount? resolvedValue;
    if (selected != null) {
      final match = available.where((a) => a.id == selected.id);
      resolvedValue = match.isNotEmpty ? match.first : null;
    }
    resolvedValue ??= available.isNotEmpty ? available.first : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: DropdownButton<AppAccount>(
        value: resolvedValue,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppTheme.surface,
        hint: const Text('Pilih wallet',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
        items: available
            .map((acc) => DropdownMenuItem<AppAccount>(
                  value: acc,
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _colorForGroup(acc.group).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_iconForGroup(acc.group),
                          color: _colorForGroup(acc.group), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(acc.name,
                              style: const TextStyle(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          Text(formatter.format(acc.balance),
                              style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ]),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildWalletSection(
      List<AppAccount> accounts, NumberFormat formatter) {
    // Resolve _selectedAccount ke instance dari accounts list
    if (accounts.isNotEmpty && _selectedAccount != null) {
      final match = accounts.where((a) => a.id == _selectedAccount!.id);
      if (match.isNotEmpty) _selectedAccount = match.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                            color: isSelected ? groupColor : AppTheme.outline,
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
                                  color: isSelected ? Colors.white : groupColor,
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
      ],
    );
  }

  Widget _buildCategorySection() {
    final cats = _type == 'expense' ? _expenseCategories : _incomeCategories;
    if (!cats.any((c) => c['label'] == _category)) {
      _category = cats.first['label'] as String;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            final label = c['label'] as String;
            final icon = c['icon'] as IconData;
            final isSelected = _category == label;
            final isLainnya = label == 'Lainnya';

            return GestureDetector(
              onTap: () {
                if (isLainnya) {
                  _showAddCustomCategoryDialog();
                } else {
                  setState(() => _category = label);
                }
              },
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: isLainnya && !isSelected
                        ? Border.all(
                            color: AppTheme.primary.withOpacity(0.4),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          )
                        : null,
                  ),
                  child: Icon(icon,
                      color: isSelected
                          ? Colors.white
                          : isLainnya
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                      size: 24),
                ),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : isLainnya
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: isSelected || isLainnya
                          ? FontWeight.w700
                          : FontWeight.w500,
                    )),
              ]),
            );
          },
        ),
      ],
    );
  }

  Widget _typeBtn(String type, String label) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedAccount = null;
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

  Widget _attachBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}
