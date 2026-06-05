import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// ENUM
// ─────────────────────────────────────────────
enum NotifCategory { reminder, transaction, budget, insight, tips }

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class NotifItem {
  final String id;
  final String title;
  final String body;
  final String detail;
  final DateTime time;
  final NotifCategory category;
  bool isRead;

  NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.detail,
    required this.time,
    required this.category,
    this.isRead = false,
  });
}

// ─────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────
class NotificationProvider extends ChangeNotifier {
  List<NotifItem> _items = [];

  List<NotifItem> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> load() async {
    // Seed data — ganti dengan data real dari Supabase/SharedPrefs kalau sudah ada
    final now = DateTime.now();
    _items = [
      NotifItem(
        id: '1',
        title: 'Pengingat Tagihan',
        body: 'Tagihan listrik jatuh tempo besok',
        detail:
            'Tagihan listrik bulan ini sebesar Rp 350.000 akan jatuh tempo besok. Pastikan saldo mencukupi.',
        time: now.subtract(const Duration(hours: 1)),
        category: NotifCategory.reminder,
      ),
      NotifItem(
        id: '2',
        title: 'Transaksi Berhasil',
        body: 'Transfer ke BCA Rp 500.000 berhasil',
        detail:
            'Transfer ke rekening BCA a/n Budi Santoso sebesar Rp 500.000 telah berhasil diproses pada ${now.subtract(const Duration(hours: 3))}.',
        time: now.subtract(const Duration(hours: 3)),
        category: NotifCategory.transaction,
        isRead: true,
      ),
      NotifItem(
        id: '3',
        title: 'Batas Anggaran',
        body: 'Anggaran makan sudah 80% terpakai',
        detail:
            'Kamu sudah menggunakan Rp 800.000 dari anggaran makan bulanan Rp 1.000.000. Sisa Rp 200.000.',
        time: now.subtract(const Duration(days: 1)),
        category: NotifCategory.budget,
      ),
      NotifItem(
        id: '4',
        title: 'Insight Keuangan',
        body: 'Pengeluaran minggu ini turun 15%',
        detail:
            'Selamat! Pengeluaran kamu minggu ini Rp 1.200.000, turun 15% dibanding minggu lalu Rp 1.412.000.',
        time: now.subtract(const Duration(days: 2)),
        category: NotifCategory.insight,
        isRead: true,
      ),
      NotifItem(
        id: '5',
        title: 'Tips Hemat',
        body: 'Coba metode 50/30/20 untuk atur keuangan',
        detail:
            'Metode 50/30/20: 50% untuk kebutuhan, 30% untuk keinginan, 20% untuk tabungan. Coba terapkan bulan ini!',
        time: now.subtract(const Duration(days: 3)),
        category: NotifCategory.tips,
        isRead: true,
      ),
      NotifItem(
        id: '6',
        title: 'Transaksi Baru',
        body: 'Pembelian Shopee Rp 250.000 tercatat',
        detail:
            'Transaksi pembelian di Shopee sebesar Rp 250.000 telah dicatat ke kategori Belanja Online.',
        time: now.subtract(const Duration(days: 4)),
        category: NotifCategory.transaction,
        isRead: true,
      ),
    ];
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1 && !_items[idx].isRead) {
      _items[idx].isRead = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    bool changed = false;
    for (final item in _items) {
      if (!item.isRead) {
        item.isRead = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void deleteItem(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }
}
