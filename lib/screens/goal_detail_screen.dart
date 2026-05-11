import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/budget_model.dart';
import '../models/account_model.dart';
import '../providers/budget_provider.dart';
import '../providers/account_provider.dart';
import '../theme/app_theme.dart';

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

    // Reload from DB first
    await context.read<BudgetProvider>().loadBudgets();

    // Get fresh budget & deposits
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
                // Handle bar
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
                const Text('Tambah Setoran',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Nabung ke: ${_budget.title}',
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 13)),
                const SizedBox(height: 24),

                // Amount
                const Text('Jumlah',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20),
                    hintText: '0',
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),

                // Source wallet
                const Text('Sumber Dana',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                if (accounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Belum ada wallet',
                        style: TextStyle(color: AppTheme.onSurfaceVariant)),
                  )
                else
                  DropdownButtonFormField<AppAccount>(
                    value: selectedAccount,
                    hint: const Text('Pilih wallet sumber'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceContainer,
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
                                          color: AppTheme.onSurface,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text(_fmt.format(a.balance),
                                      style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12)),
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
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setSheet(() => deductWallet = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Potong saldo wallet',
                        style:
                            TextStyle(color: AppTheme.onSurface, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 20),

                // Note
                const Text('Catatan (opsional)',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Misalnya: gajian bulan ini',
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                // Attachment — pakai image_picker saja (tanpa file_picker)
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
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: attachmentPath != null
                              ? AppTheme.primary
                              : AppTheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          attachmentPath != null
                              ? Icons.attach_file_rounded
                              : Icons.add_photo_alternate_outlined,
                          color: attachmentPath != null
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            attachmentPath != null
                                ? attachmentPath!.split('/').last
                                : 'Lampirkan bukti foto',
                            style: TextStyle(
                              color: attachmentPath != null
                                  ? AppTheme.primary
                                  : AppTheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (attachmentPath != null)
                          GestureDetector(
                            onTap: () => setSheet(() => attachmentPath = null),
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
                    child: const Text('Simpan Setoran',
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

  void _showEditVisionBoard() async {
    // Pilih: foto dari galeri atau kamera
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
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
                color: AppTheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Foto Vision Board',
                style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Pilih foto impianmu untuk goal ini',
                style:
                    TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 24),
            _sheetOption(
              ctx,
              icon: Icons.photo_library_rounded,
              label: 'Pilih dari Galeri',
              value: 'gallery',
            ),
            const SizedBox(height: 10),
            _sheetOption(
              ctx,
              icon: Icons.camera_alt_rounded,
              label: 'Ambil Foto',
              value: 'camera',
            ),
            if (_budget.imagePath != null) ...[
              const SizedBox(height: 10),
              _sheetOption(
                ctx,
                icon: Icons.delete_outline_rounded,
                label: 'Hapus Foto',
                value: 'remove',
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'remove') {
      final updated = _budget.copyWith(imagePath: '');
      // store empty string then treat null in display
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
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.onSurface, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color ?? AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Goal?',
            style: TextStyle(color: AppTheme.onSurface)),
        content: Text(
          'Goal "${_budget.title}" dan semua setoran akan dihapus permanen.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BudgetProvider>().deleteBudget(_budget.id!);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: _budget.imagePath != null ? 280 : 200,
            pinned: true,
            backgroundColor: AppTheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppTheme.onSurface,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                color: AppTheme.onSurface,
                tooltip: 'Ganti foto',
                onPressed: _showEditVisionBoard,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.onSurface),
                color: AppTheme.surface,
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
                        Text('Jadikan Prioritas'),
                      ]),
                    ),
                  if (_budget.isPriority)
                    const PopupMenuItem(
                      value: 'unpriority',
                      child: Row(children: [
                        Icon(Icons.star_border_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus dari Prioritas'),
                      ]),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Hapus Goal', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Foto atau warna+emoji
                  if (_budget.imagePath != null)
                    Image.file(
                      File(_budget.imagePath!),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(int.parse(_budget.color)).withOpacity(0.22),
                            Color(int.parse(_budget.color)).withOpacity(0.07),
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
                                  color: Colors.black.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: Colors.white, size: 15),
                                    SizedBox(width: 6),
                                    Text('Tambah foto vision board',
                                        style: TextStyle(
                                            color: Colors.white,
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
                  // Gradient overlay bottom
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
                            AppTheme.surface.withOpacity(0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Vision Board label (kalau sudah ada foto)
                  if (_budget.imagePath != null)
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Vision Board',
                                style: TextStyle(
                                    color: Colors.white,
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
            // Header info
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_budget.title,
                            style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                      ),
                      if (_budget.isPriority)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  color: AppTheme.primary, size: 14),
                              SizedBox(width: 4),
                              Text('Prioritas',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (_budget.description != null) ...[
                    const SizedBox(height: 4),
                    Text(_budget.description!,
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),

                  // Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$percent% tercapai',
                          style: const TextStyle(
                              color: AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(_fmt.format(_budget.currentAmount),
                          style: const TextStyle(
                              color: AppTheme.primary,
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
                      backgroundColor: AppTheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _budget.isCompleted
                              ? Colors.amber
                              : AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _statChip(Icons.flag_rounded, 'Target',
                          _fmt.format(_budget.targetAmount)),
                      const SizedBox(width: 8),
                      _statChip(Icons.savings_outlined, 'Sisa',
                          _fmt.format(remaining < 0 ? 0 : remaining)),
                      const SizedBox(width: 8),
                      if (daysLeft != null)
                        _statChip(
                          Icons.calendar_today_rounded,
                          'Hari lagi',
                          daysLeft < 0 ? 'Lewat!' : '$daysLeft hari',
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Monthly suggestion banner
            if (_budget.deadline != null && !_budget.isCompleted)
              _monthlySuggestionBanner(),

            // Tabs
            Container(
              color: AppTheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.onSurfaceVariant,
                indicatorColor: AppTheme.primary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Riwayat'),
                  Tab(text: 'Milestone'),
                  Tab(text: 'Info'),
                ],
              ),
            ),

            // Tab content
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
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Setor Nabung',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
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
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nabung ${_fmt.format(monthly)}/bulan untuk capai target tepat waktu',
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_deposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🐷', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Belum ada setoran',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
            SizedBox(height: 6),
            Text('Tap "Setor Nabung" untuk mulai',
                style:
                    TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
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
                backgroundColor: AppTheme.surface,
                title: const Text('Hapus setoran?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Batal')),
                  TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Hapus',
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
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline),
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
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.savings_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_fmt.format(d.amount),
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                          Text(
                            d.sourceAccountName != null
                                ? 'dari ${d.sourceAccountName}'
                                : 'Manual',
                            style: const TextStyle(
                                color: AppTheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy', 'id').format(d.date),
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
                if (d.note != null) ...[
                  const SizedBox(height: 8),
                  Text(d.note!,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 13)),
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
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file_rounded,
                              size: 14, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(d.attachmentPath!.split('/').last,
                              style: const TextStyle(
                                  color: AppTheme.primary, fontSize: 12),
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

  Widget _buildMilestoneTab(
      List<double> milestones, List<String> labels, List<String> icons) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Streak
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Streak Setoran',
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text('${_deposits.length} total setoran dilakukan',
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text('${_deposits.length}x',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w800,
                      fontSize: 22)),
            ],
          ),
        ),

        const Text('PENCAPAIAN',
            style: TextStyle(
                color: AppTheme.onSurfaceVariant,
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
              color: reached
                  ? AppTheme.primary.withOpacity(0.08)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: reached
                    ? AppTheme.primary.withOpacity(0.3)
                    : isCurrent
                        ? AppTheme.primary.withOpacity(0.2)
                        : AppTheme.outline,
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
                              color: reached
                                  ? AppTheme.primary
                                  : AppTheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      Text(
                        _fmt.format(_budget.targetAmount * milestones[i]),
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (reached)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primary, size: 24)
                else if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  )
                else
                  const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.onSurfaceVariant, size: 20),
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
                  Colors.amber.withOpacity(0.2),
                  AppTheme.primary.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: const Column(
              children: [
                Text('🎉', style: TextStyle(fontSize: 48)),
                SizedBox(height: 8),
                Text('Goal Tercapai!',
                    style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Selamat! Kamu berhasil mencapai targetmu.',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        _infoRow(Icons.track_changes_rounded, 'Goal', _budget.title,
            AppTheme.primary),
        _infoRow(Icons.monetization_on_rounded, 'Target',
            _fmt.format(_budget.targetAmount), Colors.green),
        _infoRow(Icons.savings_rounded, 'Terkumpul',
            _fmt.format(_budget.currentAmount), Colors.teal),
        _infoRow(
            Icons.remove_circle_outline_rounded,
            'Sisa',
            _fmt.format(_budget.remaining < 0 ? 0 : _budget.remaining),
            Colors.orange),
        if (_budget.deadline != null)
          _infoRow(
              Icons.event_rounded,
              'Deadline',
              DateFormat('dd MMMM yyyy', 'id').format(_budget.deadline!),
              Colors.blue),
        if (_budget.category != null)
          _infoRow(Icons.label_rounded, 'Kategori', _budget.category!,
              Colors.purple),
        _infoRow(
            Icons.bar_chart_rounded,
            'Progress',
            '${(_budget.progress * 100).toStringAsFixed(1)}%',
            AppTheme.primary),
        _infoRow(Icons.receipt_long_rounded, 'Total Setoran',
            '${_deposits.length}x', Colors.indigo),
        if (_deposits.isNotEmpty)
          _infoRow(
              Icons.calendar_month_rounded,
              'Setoran Terakhir',
              DateFormat('dd MMM yyyy HH:mm', 'id')
                  .format(_deposits.first.date),
              Colors.grey),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
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
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
