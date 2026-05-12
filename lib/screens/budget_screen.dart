import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/budget_provider.dart';
import '../providers/account_provider.dart';
import '../models/budget_model.dart';
import '../models/account_model.dart';
import '../theme/app_theme.dart';
import '../screens/goal_detail_screen.dart';
import 'app_top_bar.dart';

// ─── Goal icon data ───────────────────────────────────────────────────────
class _GoalIcon {
  final IconData icon;
  final Color color;
  final String label;
  const _GoalIcon(this.icon, this.color, this.label);
}

const _goalIcons = [
  _GoalIcon(Icons.directions_car_rounded, Color(0xFF3B82F6), 'Mobil'),
  _GoalIcon(Icons.home_rounded, Color(0xFF10B981), 'Rumah'),
  _GoalIcon(Icons.flight_rounded, Color(0xFF6366F1), 'Liburan'),
  _GoalIcon(Icons.laptop_rounded, Color(0xFF8B5CF6), 'Laptop'),
  _GoalIcon(Icons.smartphone_rounded, Color(0xFF06B6D4), 'HP'),
  _GoalIcon(Icons.school_rounded, Color(0xFFF59E0B), 'Pendidikan'),
  _GoalIcon(Icons.favorite_rounded, Color(0xFFEF4444), 'Pernikahan'),
  _GoalIcon(Icons.savings_rounded, Color(0xFF10B981), 'Tabungan'),
  _GoalIcon(Icons.trending_up_rounded, Color(0xFF059669), 'Investasi'),
  _GoalIcon(Icons.two_wheeler_rounded, Color(0xFFF97316), 'Motor'),
  _GoalIcon(Icons.watch_rounded, Color(0xFF6B7280), 'Jam'),
  _GoalIcon(Icons.shopping_bag_rounded, Color(0xFFEC4899), 'Fashion'),
  _GoalIcon(Icons.sports_esports_rounded, Color(0xFF7C3AED), 'Gaming'),
  _GoalIcon(Icons.camera_alt_rounded, Color(0xFF0EA5E9), 'Kamera'),
  _GoalIcon(Icons.music_note_rounded, Color(0xFFF43F5E), 'Musik'),
  _GoalIcon(Icons.fitness_center_rounded, Color(0xFF84CC16), 'Gym'),
  _GoalIcon(Icons.beach_access_rounded, Color(0xFF06B6D4), 'Pantai'),
  _GoalIcon(Icons.directions_boat_rounded, Color(0xFF1D4ED8), 'Kapal'),
  _GoalIcon(Icons.emoji_events_rounded, Color(0xFFF59E0B), 'Trophy'),
  _GoalIcon(Icons.rocket_launch_rounded, Color(0xFF7C3AED), 'Bisnis'),
];

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _fmt =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  // ─── SORT BOTTOM SHEET ───────────────────────────────────────────────────
  void _showSortSheet() {
    final provider = context.read<BudgetProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Urutkan Goals',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ...BudgetSortBy.values.map((sort) {
                final labels = {
                  BudgetSortBy.dateAdded: (
                    'Tanggal Dibuat',
                    Icons.access_time_rounded
                  ),
                  BudgetSortBy.progress: (
                    'Progress Tertinggi',
                    Icons.trending_up_rounded
                  ),
                  BudgetSortBy.deadline: (
                    'Deadline Terdekat',
                    Icons.event_rounded
                  ),
                  BudgetSortBy.targetAmount: (
                    'Target Terbesar',
                    Icons.attach_money_rounded
                  ),
                };
                final isSelected = provider.sortBy == sort;
                return GestureDetector(
                  onTap: () {
                    provider.setSortBy(sort);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withOpacity(0.1)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(labels[sort]!.$2,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                            size: 18),
                        const SizedBox(width: 12),
                        Text(labels[sort]!.$1,
                            style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_rounded,
                              color: AppTheme.primary, size: 18),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FILTER SHEET ────────────────────────────────────────────────────────
  void _showFilterSheet() {
    final provider = context.read<BudgetProvider>();
    final categories = [
      null, // all
      'Kendaraan', 'Properti', 'Elektronik', 'Fashion',
      'Pendidikan', 'Liburan', 'Investasi', 'Kesehatan', 'Hiburan', 'Lainnya',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const Text('Filter Kategori',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final label = cat ?? 'Semua';
                  final isSelected = provider.filterCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      provider.setFilterCategory(cat);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── QUICK DEPOSIT BOTTOM SHEET ──────────────────────────────────────────
  void _showQuickDeposit(AppBudget budget) {
    final amountCtrl = TextEditingController();
    AppAccount? selectedAccount;
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppTheme.outline,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Goal info header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _goalColor(budget).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: buildGoalIcon(budget, size: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Setor ke "${budget.title}"',
                            style: const TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        Text(
                          '${(budget.progress * 100).toStringAsFixed(0)}% tercapai · sisa ${_fmt.format(budget.remaining < 0 ? 0 : budget.remaining)}',
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Quick amount chips
              Wrap(
                spacing: 8,
                children: [50000, 100000, 250000, 500000].map((amt) {
                  return GestureDetector(
                    onTap: () =>
                        setSheet(() => amountCtrl.text = amt.toString()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Text(
                        _fmt.format(amt.toDouble()),
                        style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22),
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
              if (accounts.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<AppAccount>(
                  value: selectedAccount,
                  hint: const Text('Pilih sumber dana (opsional)'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
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
                                      color: AppTheme.onSurface,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Text(_fmt.format(a.balance),
                                  style: const TextStyle(
                                      color: AppTheme.primary, fontSize: 12)),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) => setSheet(() => selectedAccount = v),
                ),
              ],
              const SizedBox(height: 20),
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
                          budgetId: budget.id!,
                          amount: amount,
                          sourceAccount: selectedAccount,
                          deductFromWallet: selectedAccount != null,
                        );
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
    );
  }

  Color _goalColor(AppBudget budget) {
    final idx = int.tryParse(budget.emoji);
    if (idx != null && idx >= 0 && idx < _goalIcons.length) {
      return _goalIcons[idx].color;
    }
    try {
      return Color(int.parse(budget.color));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  // ─── ADD GOAL BOTTOM SHEET ────────────────────────────────────────────────
  void _showAddGoal() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int selectedIconIndex = 0;
    String? selectedCategory;
    DateTime? deadline;
    String? imagePath;
    bool isPriority = false;

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final selectedIcon = _goalIcons[selectedIconIndex];

          Future<void> pickImage(ImageSource source) async {
            final picker = ImagePicker();
            final result =
                await picker.pickImage(source: source, imageQuality: 85);
            if (result != null) setSheet(() => imagePath = result.path);
          }

          return Padding(
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

                  // ── Foto Vision Board ──────────────────────────────────
                  const Text('Foto Vision Board (opsional)',
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final choice = await showModalBottomSheet<String>(
                        context: ctx,
                        backgroundColor: AppTheme.surface,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20))),
                        builder: (c) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppTheme.outline,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              _photoSheetTile(c, Icons.photo_library_rounded,
                                  'Pilih dari Galeri', 'gallery'),
                              const SizedBox(height: 10),
                              _photoSheetTile(c, Icons.camera_alt_rounded,
                                  'Ambil Foto', 'camera'),
                              if (imagePath != null) ...[
                                const SizedBox(height: 10),
                                _photoSheetTile(c, Icons.delete_outline_rounded,
                                    'Hapus Foto', 'remove',
                                    color: Colors.red),
                              ],
                            ],
                          ),
                        ),
                      );
                      if (choice == 'gallery')
                        await pickImage(ImageSource.gallery);
                      else if (choice == 'camera')
                        await pickImage(ImageSource.camera);
                      else if (choice == 'remove')
                        setSheet(() => imagePath = null);
                    },
                    child: Container(
                      height: imagePath != null ? 160 : 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: imagePath != null
                              ? AppTheme.primary
                              : AppTheme.outline,
                          width: imagePath != null ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: imagePath != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(File(imagePath!), fit: BoxFit.cover),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_rounded,
                                            color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Ganti',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: AppTheme.onSurfaceVariant, size: 28),
                                const SizedBox(height: 6),
                                const Text('Tambah foto impianmu',
                                    style: TextStyle(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 13)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Icon Goal ──────────────────────────────────────────
                  const Text('Ikon Goal',
                      style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _goalIcons.length,
                      itemBuilder: (_, i) {
                        final gi = _goalIcons[i];
                        final selected = selectedIconIndex == i;
                        return GestureDetector(
                          onTap: () => setSheet(() => selectedIconIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? gi.color.withOpacity(0.15)
                                  : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? gi.color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(gi.icon,
                                  color: selected
                                      ? gi.color
                                      : AppTheme.onSurfaceVariant,
                                  size: 22),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(selectedIcon.icon,
                          color: selectedIcon.color, size: 14),
                      const SizedBox(width: 6),
                      Text(selectedIcon.label,
                          style: TextStyle(
                              color: selectedIcon.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Nama Goal ──────────────────────────────────────────
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

                  // ── Deskripsi ──────────────────────────────────────────
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

                  // ── Target Nominal ──────────────────────────────────────
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

                  // ── Kategori ───────────────────────────────────────────
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

                  // ── Deadline ───────────────────────────────────────────
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
                        initialDate:
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
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
                  const SizedBox(height: 12),

                  // ── Jadikan Prioritas ──────────────────────────────────
                  GestureDetector(
                    onTap: () => setSheet(() => isPriority = !isPriority),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isPriority
                            ? AppTheme.primary.withOpacity(0.08)
                            : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPriority
                              ? AppTheme.primary.withOpacity(0.4)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPriority
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isPriority
                                ? Colors.amber
                                : AppTheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jadikan Prioritas',
                                style: TextStyle(
                                    color: isPriority
                                        ? AppTheme.onSurface
                                        : AppTheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              const Text(
                                'Goal ini akan tampil di bagian atas',
                                style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Switch(
                            value: isPriority,
                            activeColor: AppTheme.primary,
                            onChanged: (v) => setSheet(() => isPriority = v),
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
                        final gi = _goalIcons[selectedIconIndex];
                        final colorHex =
                            '0xFF${gi.color.value.toRadixString(16).substring(2).toUpperCase()}';
                        Navigator.pop(ctx);
                        await context
                            .read<BudgetProvider>()
                            .addBudget(AppBudget(
                              title: titleCtrl.text.trim(),
                              emoji: selectedIconIndex.toString(),
                              targetAmount: target,
                              currentAmount: 0,
                              currency: 'IDR',
                              color: colorHex,
                              imagePath: imagePath,
                              description: descCtrl.text.trim().isEmpty
                                  ? null
                                  : descCtrl.text.trim(),
                              deadline: deadline,
                              category: selectedCategory,
                              isPriority: isPriority,
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
          );
        },
      ),
    );
  }

  Widget _photoSheetTile(
      BuildContext ctx, IconData icon, String label, String value,
      {Color? color}) {
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

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final budgets = provider.budgets;
    final archivedBudgets = provider.archivedBudgets;
    final accounts = context.watch<AccountProvider>().accounts;

    final priorities = budgets.where((b) => b.isPriority).toList();
    final others = budgets.where((b) => !b.isPriority).toList();

    final hasActiveFilter = provider.filterCategory != null;
    final currentSort = provider.sortBy;
    final sortLabels = {
      BudgetSortBy.dateAdded: 'Terbaru',
      BudgetSortBy.progress: 'Progress',
      BudgetSortBy.deadline: 'Deadline',
      BudgetSortBy.targetAmount: 'Target',
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────
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
                    const SizedBox(height: 16),

                    // ── Sort & Filter Bar ──────────────────────────────
                    Row(
                      children: [
                        // Sort button
                        GestureDetector(
                          onTap: _showSortSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sort_rounded,
                                    size: 15, color: AppTheme.onSurfaceVariant),
                                const SizedBox(width: 5),
                                Text(sortLabels[currentSort] ?? 'Urut',
                                    style: const TextStyle(
                                        color: AppTheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Filter button
                        GestureDetector(
                          onTap: _showFilterSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: hasActiveFilter
                                  ? AppTheme.primary.withOpacity(0.1)
                                  : AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: hasActiveFilter
                                    ? AppTheme.primary.withOpacity(0.4)
                                    : AppTheme.outline,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  size: 15,
                                  color: hasActiveFilter
                                      ? AppTheme.primary
                                      : AppTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  hasActiveFilter
                                      ? provider.filterCategory!
                                      : 'Filter',
                                  style: TextStyle(
                                      color: hasActiveFilter
                                          ? AppTheme.primary
                                          : AppTheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                                if (hasActiveFilter) ...[
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () =>
                                        provider.setFilterCategory(null),
                                    child: const Icon(Icons.close_rounded,
                                        size: 13, color: AppTheme.primary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Archived toggle
                        if (archivedBudgets.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showArchived = !_showArchived),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _showArchived
                                    ? Colors.grey.withOpacity(0.15)
                                    : AppTheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.outline),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.archive_rounded,
                                      size: 15,
                                      color: _showArchived
                                          ? Colors.grey
                                          : AppTheme.onSurfaceVariant),
                                  const SizedBox(width: 5),
                                  Text('Arsip (${archivedBudgets.length})',
                                      style: TextStyle(
                                          color: _showArchived
                                              ? Colors.grey
                                              : AppTheme.onSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Priority Goals ─────────────────────────────────────────
            if (priorities.isNotEmpty && !_showArchived) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Text('PRIORITAS',
                      style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PriorityGoalCard(
                        budget: priorities[i],
                        fmt: _fmt,
                        onTap: () => _openDetail(priorities[i]),
                        onQuickDeposit: priorities[i].isCompleted
                            ? null
                            : () => _showQuickDeposit(priorities[i]),
                      ),
                    ),
                    childCount: priorities.length,
                  ),
                ),
              ),
            ],

            // ── Liquidity Sources ─────────────────────────────────────
            if (!_showArchived)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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

            // ── Other Goals ────────────────────────────────────────────
            if (others.isNotEmpty && !_showArchived) ...[
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _GoalCard(
                        budget: others[i],
                        fmt: _fmt,
                        onTap: () => _openDetail(others[i]),
                        onQuickDeposit: others[i].isCompleted
                            ? null
                            : () => _showQuickDeposit(others[i]),
                      ),
                    ),
                    childCount: others.length,
                  ),
                ),
              ),
            ],

            // ── Archived Goals ─────────────────────────────────────────
            if (_showArchived && archivedBudgets.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.archive_rounded,
                          size: 14, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      const Text('GOALS SELESAI (ARSIP)',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final b = archivedBudgets[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ArchivedGoalCard(
                          budget: b,
                          fmt: _fmt,
                          onUnarchive: () async {
                            await context
                                .read<BudgetProvider>()
                                .unarchiveBudget(b.id!);
                          },
                        ),
                      );
                    },
                    childCount: archivedBudgets.length,
                  ),
                ),
              ),
            ],

            // ── Empty state ────────────────────────────────────────────
            if (budgets.isEmpty && !_showArchived)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(children: const [
                      Icon(Icons.savings_rounded,
                          size: 52, color: AppTheme.onSurfaceVariant),
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

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
      context.read<BudgetProvider>().loadBudgets();
    });
  }
}

// ─── Helper: resolve icon from budget ─────────────────────────────────────
Widget buildGoalIcon(AppBudget budget, {double size = 26, bool large = false}) {
  final idx = int.tryParse(budget.emoji);
  if (idx != null && idx >= 0 && idx < _goalIcons.length) {
    final gi = _goalIcons[idx];
    return Icon(gi.icon, color: gi.color, size: large ? 52 : size);
  }
  return Text(budget.emoji, style: TextStyle(fontSize: large ? 52 : size));
}

Color resolveGoalColor(AppBudget budget) {
  final idx = int.tryParse(budget.emoji);
  if (idx != null && idx >= 0 && idx < _goalIcons.length) {
    return _goalIcons[idx].color;
  }
  try {
    return Color(int.parse(budget.color));
  } catch (_) {
    return const Color(0xFF10B981);
  }
}

// ─── PRIORITY GOAL CARD ────────────────────────────────────────────────────
class _PriorityGoalCard extends StatelessWidget {
  final AppBudget budget;
  final NumberFormat fmt;
  final VoidCallback onTap;
  final VoidCallback? onQuickDeposit;

  const _PriorityGoalCard({
    required this.budget,
    required this.fmt,
    required this.onTap,
    this.onQuickDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (budget.currentAmount / budget.targetAmount).clamp(0.0, 1.0);
    final percent = (progress * 100).toStringAsFixed(0);
    final idx = int.tryParse(budget.emoji);
    final gi =
        (idx != null && idx < _goalIcons.length) ? _goalIcons[idx] : null;
    final color = gi?.color ?? Color(int.parse(budget.color));
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
            // Vision board area
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  color: color.withOpacity(0.08),
                  child: budget.imagePath != null
                      ? Image.file(File(budget.imagePath!),
                          fit: BoxFit.cover, width: double.infinity)
                      : Center(
                          child: gi != null
                              ? Icon(gi.icon, color: gi.color, size: 64)
                              : Text(budget.emoji,
                                  style: const TextStyle(fontSize: 64)),
                        ),
                ),
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
                // Priority badge
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                        SizedBox(width: 4),
                        Text('PRIORITAS',
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
                // Streak badge
                if (budget.streakMonths >= 2)
                  Positioned(
                    top: 12,
                    left: 110,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text('${budget.streakMonths} bln',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
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
                        color: daysLeft < 30
                            ? Colors.red.withOpacity(0.8)
                            : Colors.black.withOpacity(0.5),
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

                  // Quick deposit button
                  if (!budget.isCompleted && onQuickDeposit != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onQuickDeposit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                color: color, size: 16),
                            const SizedBox(width: 6),
                            Text('Setor Nabung',
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
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
          const Icon(Icons.lightbulb_outline_rounded,
              color: Colors.amber, size: 16),
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
  final VoidCallback? onQuickDeposit;

  const _GoalCard({
    required this.budget,
    required this.fmt,
    required this.onTap,
    this.onQuickDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (budget.currentAmount / budget.targetAmount).clamp(0.0, 1.0);
    final idx = int.tryParse(budget.emoji);
    final gi =
        (idx != null && idx < _goalIcons.length) ? _goalIcons[idx] : null;
    final color = gi?.color ?? Color(int.parse(budget.color));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          children: [
            Row(
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
                          child: gi != null
                              ? Icon(gi.icon, color: gi.color, size: 26)
                              : Text(budget.emoji,
                                  style: const TextStyle(fontSize: 26)),
                        ),
                ),
                const SizedBox(width: 14),

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
                          if (budget.streakMonths >= 2) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥',
                                      style: TextStyle(fontSize: 9)),
                                  Text(' ${budget.streakMonths}',
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                          if (budget.isCompleted)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.emoji_events_rounded,
                                  color: Colors.amber, size: 16),
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

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppTheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),

            // Quick Deposit button
            if (!budget.isCompleted && onQuickDeposit != null) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onQuickDeposit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: color, size: 15),
                      const SizedBox(width: 5),
                      Text('Setor Nabung',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ARCHIVED GOAL CARD ────────────────────────────────────────────────────
class _ArchivedGoalCard extends StatelessWidget {
  final AppBudget budget;
  final NumberFormat fmt;
  final VoidCallback onUnarchive;

  const _ArchivedGoalCard({
    required this.budget,
    required this.fmt,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (budget.currentAmount / budget.targetAmount).clamp(0.0, 1.0);
    final idx = int.tryParse(budget.emoji);
    final gi =
        (idx != null && idx < _goalIcons.length) ? _goalIcons[idx] : null;
    final color = gi?.color ?? Color(int.parse(budget.color));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withOpacity(0.1),
                ),
                clipBehavior: Clip.hardEdge,
                child: budget.imagePath != null
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ]),
                        child: Image.file(File(budget.imagePath!),
                            fit: BoxFit.cover),
                      )
                    : Center(
                        child: Opacity(
                          opacity: 0.5,
                          child: gi != null
                              ? Icon(gi.icon, color: gi.color, size: 26)
                              : Text(budget.emoji,
                                  style: const TextStyle(fontSize: 26)),
                        ),
                      ),
              ),
              if (budget.isCompleted)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surface, width: 1.5),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.title,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${fmt.format(budget.currentAmount)} / ${fmt.format(budget.targetAmount)}',
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppTheme.surfaceContainer,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                  ),
                ),
                if (budget.archivedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diarsipkan ${DateFormat('dd MMM yyyy', 'id').format(budget.archivedAt!)}',
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUnarchive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.unarchive_rounded,
                      size: 14, color: AppTheme.onSurfaceVariant),
                  SizedBox(width: 4),
                  Text('Pulihkan',
                      style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
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
