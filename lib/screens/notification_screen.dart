import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────
class AppColors {
  static const navy = Color(0xFF0D1B3E);
  static const navyLight = Color(0xFF1A2D5A);
  static const navyMid = Color(0xFF243666);
  static const yellow = Color(0xFFF5C842);
  static const green = Color(0xFF1DB87A);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF4F6FA);
  static const textMuted = Color(0xFF8A96B0);
  static const divider = Color(0xFFE8ECF4);
}

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
  final NotifCategory category;
  final DateTime time;
  bool isRead;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.time,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────
//  DUMMY DATA
// ─────────────────────────────────────────────
List<NotifItem> _generateDummyNotifs() {
  final now = DateTime.now();
  return [
    NotifItem(
        id: '1',
        title: 'Electricity Bill Due',
        body: 'Due tomorrow — pay before the late fee kicks in.',
        category: NotifCategory.reminder,
        time: now.subtract(const Duration(hours: 1)),
        isRead: false),
    NotifItem(
        id: '2',
        title: 'Transaction Recorded',
        body: '\$12.50 expense at Grocery Store has been logged.',
        category: NotifCategory.transaction,
        time: now.subtract(const Duration(hours: 3)),
        isRead: false),
    NotifItem(
        id: '3',
        title: 'Budget Almost Exhausted',
        body: 'Food & Beverages is at 90% of your monthly limit.',
        category: NotifCategory.budget,
        time: now.subtract(const Duration(hours: 5)),
        isRead: true),
    NotifItem(
        id: '4',
        title: 'Weekly Insight',
        body: "You spent 12% less than last week. Keep it up!",
        category: NotifCategory.insight,
        time: now.subtract(const Duration(hours: 6)),
        isRead: true),
    NotifItem(
        id: '5',
        title: 'Finance Tip',
        body: 'Try the 50/30/20 rule to better manage your monthly expenses.',
        category: NotifCategory.tips,
        time: now.subtract(const Duration(hours: 8)),
        isRead: true),
    NotifItem(
        id: '6',
        title: 'Health Insurance Reminder',
        body: "This month's health insurance payment hasn't been made yet.",
        category: NotifCategory.reminder,
        time: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: true),
    NotifItem(
        id: '7',
        title: 'Income Received',
        body: '\$2,500.00 salary transfer has been received.',
        category: NotifCategory.transaction,
        time: now.subtract(const Duration(days: 1, hours: 4)),
        isRead: true),
    NotifItem(
        id: '8',
        title: 'Monthly Budget Reset',
        body: 'Your monthly budget has been reset for this period.',
        category: NotifCategory.budget,
        time: now.subtract(const Duration(days: 1, hours: 7)),
        isRead: true),
    NotifItem(
        id: '9',
        title: 'Shopping Saving Tip',
        body: 'End-of-month sales usually offer the best discounts.',
        category: NotifCategory.tips,
        time: now.subtract(const Duration(days: 2, hours: 1)),
        isRead: true),
    NotifItem(
        id: '10',
        title: 'Weekly Report Ready',
        body: 'Your financial summary for last week is ready to view.',
        category: NotifCategory.insight,
        time: now.subtract(const Duration(days: 2, hours: 3)),
        isRead: true),
    NotifItem(
        id: '11',
        title: 'Large Transaction Detected',
        body: '\$350.00 expense at Online Store has been recorded.',
        category: NotifCategory.transaction,
        time: now.subtract(const Duration(days: 3, hours: 2)),
        isRead: true),
    NotifItem(
        id: '12',
        title: 'Investment Reminder',
        body: "Time to transfer your regular monthly investment funds.",
        category: NotifCategory.reminder,
        time: now.subtract(const Duration(days: 3, hours: 5)),
        isRead: true),
  ];
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  final List<NotifItem> _allNotifs = _generateDummyNotifs();
  NotifCategory? _selectedCategory; // null = all
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

  // Group by day
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
        key = DateFormat('MMMM d, yyyy').format(d);
      }
      result.putIfAbsent(key, () => []).add(item);
    }
    return result;
  }

  void _markAllRead() {
    setState(() {
      for (final n in _allNotifs) {
        n.isRead = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      final idx = _allNotifs.indexWhere((n) => n.id == id);
      if (idx != -1) _allNotifs[idx].isRead = true;
    });
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
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final cat = categories[i];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                      _fadeCtrl.forward(from: 0);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (cat == null ? AppColors.yellow : cat.color)
                          : AppColors.navyLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat == null ? 'All' : cat.label,
                      style: TextStyle(
                        color: isSelected
                            ? (cat == null || cat == NotifCategory.reminder
                                ? AppColors.navy
                                : AppColors.white)
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
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              dayLabel,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
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
                        color: e.key.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: e.key.color.withOpacity(0.3)),
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
    final timeStr = DateFormat('h:mm a').format(item.time);

    return GestureDetector(
      onTap: () => _markRead(item.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              item.isRead ? AppColors.white : AppColors.navy.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? AppColors.divider
                : item.category.color.withOpacity(0.4),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: item.isRead
              ? []
              : [
                  BoxShadow(
                    color: item.category.color.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.category.icon,
                    color: item.category.color, size: 20),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: item.isRead
                            ? AppColors.textMuted
                            : AppColors.navy.withOpacity(0.65),
                        fontSize: 12,
                        height: 1.4,
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
                        const SizedBox(width: 10),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.navy.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.notifications_off_rounded,
                color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedCategory != null
                ? 'No ${_selectedCategory!.label} notifications found'
                : 'You\'re all caught up!',
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
