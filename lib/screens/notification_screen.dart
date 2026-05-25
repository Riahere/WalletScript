import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────
class AppColors {
  static const navy = Color(0xFF0D1B3E);
  static const navyLight = Color(0xFF1A2D5A);
  static const yellow = Color(0xFFF5C842);
  static const green = Color(0xFF1DB87A);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF0F2F7);
  static const textMuted = Color(0xFF8A96B0);
  static const divider = Color(0xFFE8ECF4);
}

// ─────────────────────────────────────────────
//  CURRENCY FORMATTER
// ─────────────────────────────────────────────
final _rupiahFmt = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String rp(int amount) => _rupiahFmt.format(amount);

// ─────────────────────────────────────────────
//  MODEL
// ─────────────────────────────────────────────
enum NotifCategory { reminder, transaction, budget, insight, tips }

extension NotifCategoryExt on NotifCategory {
  String get label {
    switch (this) {
      case NotifCategory.reminder:
        return 'Reminder';
      case NotifCategory.transaction:
        return 'Transaction';
      case NotifCategory.budget:
        return 'Budget';
      case NotifCategory.insight:
        return 'Insight';
      case NotifCategory.tips:
        return 'Tips';
    }
  }

  Color get color {
    switch (this) {
      case NotifCategory.reminder:
        return AppColors.yellow;
      case NotifCategory.transaction:
        return AppColors.green;
      case NotifCategory.budget:
        return const Color(0xFFFF6B6B);
      case NotifCategory.insight:
        return const Color(0xFF6B8EFF);
      case NotifCategory.tips:
        return const Color(0xFFFF9F43);
    }
  }

  Color get onColor {
    switch (this) {
      case NotifCategory.reminder:
        return AppColors.navy;
      default:
        return AppColors.white;
    }
  }

  IconData get icon {
    switch (this) {
      case NotifCategory.reminder:
        return Icons.alarm_rounded;
      case NotifCategory.transaction:
        return Icons.receipt_long_rounded;
      case NotifCategory.budget:
        return Icons.account_balance_wallet_rounded;
      case NotifCategory.insight:
        return Icons.lightbulb_rounded;
      case NotifCategory.tips:
        return Icons.tips_and_updates_rounded;
    }
  }
}

class NotifItem {
  final String id;
  final String title;
  final String body;
  final String detail;
  final NotifCategory category;
  final DateTime time;
  bool isRead;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.detail,
    required this.category,
    required this.time,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────
//  DUMMY DATA (Rupiah)
// ─────────────────────────────────────────────
List<NotifItem> _generateDummyNotifs() {
  final now = DateTime.now();
  return [
    NotifItem(
      id: '1',
      title: 'Electricity Bill Due',
      body: 'Tagihan listrik jatuh tempo besok — bayar sebelum dikenai denda.',
      detail: 'Tagihan listrik PLN sebesar ${rp(450000)} jatuh tempo besok. '
          'Hindari denda keterlambatan sebesar ${rp(50000)} dengan membayar sebelum tengah malam. '
          'Kamu bisa bayar melalui fitur transfer atau marketplace favoritmu.',
      category: NotifCategory.reminder,
      time: now.subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotifItem(
      id: '2',
      title: 'Transaction Recorded',
      body: 'Pengeluaran ${rp(87500)} di Indomaret sudah dicatat.',
      detail:
          'Transaksi sebesar ${rp(87500)} di Indomaret telah berhasil dicatat '
          'ke kategori Makanan & Minuman. Saldo anggaran kategori ini sekarang tersisa ${rp(312500)}. '
          'Ketuk untuk melihat detail transaksi lengkap.',
      category: NotifCategory.transaction,
      time: now.subtract(const Duration(hours: 3)),
      isRead: false,
    ),
    NotifItem(
      id: '3',
      title: 'Budget Almost Exhausted',
      body: 'Makanan & Minuman sudah 90% dari limit bulanan.',
      detail:
          'Kamu sudah menggunakan ${rp(1800000)} dari anggaran ${rp(2000000)} '
          'untuk kategori Makanan & Minuman bulan ini. '
          'Hanya tersisa ${rp(200000)} untuk sisa bulan ini — coba kurangi makan di luar yuk!',
      category: NotifCategory.budget,
      time: now.subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    NotifItem(
      id: '4',
      title: 'Weekly Insight',
      body: 'Pengeluaranmu 12% lebih hemat dari minggu lalu. Keren!',
      detail:
          'Minggu ini kamu menghabiskan ${rp(1230000)}, turun dari ${rp(1398000)} '
          'minggu lalu — penghematan sebesar ${rp(168000)}. '
          'Kategori terbesar yang berhasil dikurangi adalah makan di luar. Pertahankan ya!',
      category: NotifCategory.insight,
      time: now.subtract(const Duration(hours: 6)),
      isRead: true,
    ),
    NotifItem(
      id: '5',
      title: 'Finance Tip',
      body: 'Coba aturan 50/30/20 untuk kelola pengeluaran bulanan kamu.',
      detail:
          'Alokasikan 50% penghasilan untuk kebutuhan, 30% untuk keinginan, '
          'dan 20% untuk tabungan atau cicilan. '
          'Berdasarkan penghasilan kamu ${rp(8000000)}, artinya ${rp(1600000)} bisa masuk ke tabungan tiap bulan.',
      category: NotifCategory.tips,
      time: now.subtract(const Duration(hours: 8)),
      isRead: true,
    ),
    NotifItem(
      id: '6',
      title: 'Health Insurance Reminder',
      body: 'Iuran BPJS bulan ini belum dibayar.',
      detail: 'Iuran BPJS Kesehatan kamu sebesar ${rp(150000)} untuk bulan ini '
          'belum terbayar. Batas pembayaran tanggal 10. '
          'Jangan sampai telat ya agar manfaatnya tetap aktif!',
      category: NotifCategory.reminder,
      time: now.subtract(const Duration(days: 1, hours: 2)),
      isRead: true,
    ),
    NotifItem(
      id: '7',
      title: 'Income Received',
      body: 'Transfer gaji ${rp(8500000)} sudah masuk ke rekening.',
      detail:
          'Gaji sebesar ${rp(8500000)} telah berhasil masuk ke rekening BCA kamu '
          'yang berakhiran 4521. Anggaran bulanan kamu juga sudah otomatis diperbarui. '
          'Yuk alokasikan sesuai rencana keuanganmu!',
      category: NotifCategory.transaction,
      time: now.subtract(const Duration(days: 1, hours: 4)),
      isRead: true,
    ),
    NotifItem(
      id: '8',
      title: 'Monthly Budget Reset',
      body: 'Anggaran bulanan sudah direset untuk periode ini.',
      detail: 'Periode anggaran baru telah dimulai. Alokasi bulan ini: '
          'Makanan ${rp(2000000)} · Transportasi ${rp(500000)} · '
          'Hiburan ${rp(300000)} · Tabungan ${rp(1600000)}. '
          'Semangat kelola keuangan bulan ini!',
      category: NotifCategory.budget,
      time: now.subtract(const Duration(days: 1, hours: 7)),
      isRead: true,
    ),
    NotifItem(
      id: '9',
      title: 'Shopping Saving Tip',
      body: 'Promo akhir bulan biasanya kasih diskon paling besar.',
      detail:
          'Tokopedia, Shopee, dan Lazada biasanya mengadakan promo besar di akhir bulan. '
          'Pertimbangkan menunda pembelian yang tidak mendesak untuk mendapatkan '
          'penghematan hingga 30%. Aktifkan wishlist sekarang!',
      category: NotifCategory.tips,
      time: now.subtract(const Duration(days: 2, hours: 1)),
      isRead: true,
    ),
    NotifItem(
      id: '10',
      title: 'Weekly Report Ready',
      body: 'Ringkasan keuangan minggu lalu sudah siap dilihat.',
      detail:
          'Ringkasan minggu lalu: Pemasukan ${rp(0)} · Pengeluaran ${rp(1230000)} · '
          'Kategori terbesar: Makanan & Minuman (${rp(560000)}). '
          'Tingkat tabungan minggu ini 0% — gaji kamu cair minggu depan kok!',
      category: NotifCategory.insight,
      time: now.subtract(const Duration(days: 2, hours: 3)),
      isRead: true,
    ),
    NotifItem(
      id: '11',
      title: 'Large Transaction Alert',
      body: 'Pengeluaran ${rp(2450000)} di Tokopedia sudah dicatat.',
      detail: 'Transaksi besar sebesar ${rp(2450000)} terdeteksi di Tokopedia. '
          'Jumlah ini melebihi batas notifikasi transaksi besar kamu (${rp(500000)}). '
          'Apakah transaksi ini benar? Jika tidak, segera hubungi bank kamu.',
      category: NotifCategory.transaction,
      time: now.subtract(const Duration(days: 3, hours: 2)),
      isRead: true,
    ),
    NotifItem(
      id: '12',
      title: 'Investment Reminder',
      body: 'Saatnya transfer dana investasi rutin bulanan kamu.',
      detail:
          'Transfer investasi rutin sebesar ${rp(500000)} ke akun Bibit kamu '
          'belum dilakukan bulan ini. Kamu sudah konsisten selama 8 bulan berturut-turut — '
          'jangan putus sekarang ya! Investasi konsisten adalah kunci.',
      category: NotifCategory.reminder,
      time: now.subtract(const Duration(days: 3, hours: 5)),
      isRead: true,
    ),
  ];
}

// ─────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final List<NotifItem> _allNotifs = _generateDummyNotifs();
  NotifCategory? _selectedCategory;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<NotifItem> get _filtered {
    if (_selectedCategory == null) return _allNotifs;
    return _allNotifs.where((n) => n.category == _selectedCategory).toList();
  }

  int get _unreadCount => _allNotifs.where((n) => !n.isRead).length;

  Map<String, List<NotifItem>> _groupByDay(List<NotifItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final result = <String, List<NotifItem>>{};
    for (final item in items) {
      final d = DateTime(item.time.year, item.time.month, item.time.day);
      String key;
      if (d == today) {
        key = 'Today';
      } else if (d == yesterday) {
        key = 'Yesterday';
      } else {
        key = DateFormat('d MMMM yyyy').format(d);
      }
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }

  void _markAllRead() => setState(() {
        for (final n in _allNotifs) {
          n.isRead = true;
        }
      });

  void _markRead(String id) {
    setState(() {
      final idx = _allNotifs.indexWhere((n) => n.id == id);
      if (idx != -1) _allNotifs[idx].isRead = true;
    });
  }

  void _openDetail(NotifItem item) {
    _markRead(item.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotifDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(_filtered);
    final dayKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(
              child: _filtered.isEmpty
                  ? _buildEmpty()
                  : FadeTransition(
                      opacity: _fadeCtrl,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                        itemCount: dayKeys.length,
                        itemBuilder: (ctx, i) {
                          final key = dayKeys[i];
                          final items = grouped[key]!;
                          return _buildDaySection(key, items);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_unreadCount > 0)
                  Text(
                    '$_unreadCount unread',
                    style: const TextStyle(
                      color: AppColors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (_unreadCount > 0)
            GestureDetector(
              onTap: _markAllRead,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── FILTER BAR ───────────────────────────────
  Widget _buildFilterBar() {
    final categories = [null, ...NotifCategory.values];
    return Container(
      color: AppColors.navy,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final isSelected = _selectedCategory == cat;
                final activeColor = cat == null ? AppColors.yellow : cat.color;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat;
                    _fadeCtrl.forward(from: 0);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : AppColors.navyLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat == null ? 'All' : cat.label,
                      style: TextStyle(
                        color: isSelected
                            ? (cat == null ? AppColors.navy : cat.onColor)
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 16,
            decoration: const BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DAY SECTION ──────────────────────────────
  Widget _buildDaySection(String dayLabel, List<NotifItem> items) {
    final catCounts = <NotifCategory, int>{};
    for (final item in items) {
      catCounts[item.category] = (catCounts[item.category] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              dayLabel,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: catCounts.entries.map((e) {
                    return Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: e.key.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: e.key.color.withOpacity(0.25)),
                      ),
                      child: Text(
                        '${e.key.label} (${e.value})',
                        style: TextStyle(
                          color: e.key.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _buildNotifCard(item)),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── NOTIF CARD ───────────────────────────────
  Widget _buildNotifCard(NotifItem item) {
    final timeStr = DateFormat('HH:mm').format(item.time);

    return GestureDetector(
      onTap: () => _openDetail(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              item.isRead ? AppColors.white : AppColors.navy.withOpacity(0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? AppColors.divider
                : item.category.color.withOpacity(0.45),
            width: item.isRead ? 0.8 : 1.5,
          ),
          boxShadow: item.isRead
              ? []
              : [
                  BoxShadow(
                    color: item.category.color.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.category.icon,
                    color: item.category.color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: item.category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: item.isRead
                            ? AppColors.textMuted
                            : AppColors.navy.withOpacity(0.6),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.label,
                            style: TextStyle(
                              color: item.category.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.textMuted.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── EMPTY STATE ──────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.notifications_off_rounded,
                color: AppColors.textMuted, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _selectedCategory != null
                ? 'No ${_selectedCategory!.label} notifications found'
                : "You're all caught up!",
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────
class _NotifDetailSheet extends StatelessWidget {
  final NotifItem item;

  const _NotifDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final cat = item.category;
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(item.time);
    final timeStr = DateFormat('HH:mm').format(item.time);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 24),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        cat.label,
                        style: TextStyle(
                          color: cat.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.offWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 16),

          // Detail text
          Text(
            item.detail,
            style: const TextStyle(
              color: Color(0xFF3D4B6B),
              fontSize: 14,
              height: 1.65,
            ),
          ),

          const SizedBox(height: 18),

          // Meta info row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _metaItem(Icons.calendar_today_rounded, dateStr),
                Container(
                  width: 1,
                  height: 16,
                  color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                _metaItem(Icons.access_time_rounded, timeStr),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
