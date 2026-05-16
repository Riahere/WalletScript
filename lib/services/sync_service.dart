// lib/services/sync_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import 'auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SyncService — Pull data dari Supabase ke local (setelah login)
//
//  Asumsi nama tabel Supabase:
//    - "transactions"  → kolom sesuai AppTransaction.toMap()
//    - "accounts"      → kolom sesuai AppAccount.toMap() (group → 'grp')
//
//  RLS (Row Level Security) Supabase harus aktif dengan policy:
//    auth.uid() = user_id
//  Dan setiap row harus punya kolom 'user_id' (UUID dari auth.users)
// ─────────────────────────────────────────────────────────────────────────────

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SupabaseClient get _db => Supabase.instance.client;
  final _auth = AuthService();

  // ─── Pull semua data dari cloud ke local ──────────────────────────────────

  /// Panggil ini setelah login berhasil.
  /// Mengembalikan map berisi list accounts dan transactions.
  Future<SyncResult> pullFromCloud() async {
    final userId = _auth.userId;
    if (userId == null) {
      debugPrint('[SyncService] pullFromCloud: user tidak login, skip.');
      return SyncResult(accounts: [], transactions: []);
    }

    try {
      debugPrint('[SyncService] Pulling data untuk user: $userId');

      final results = await Future.wait([
        _pullAccounts(userId),
        _pullTransactions(userId),
      ]);

      final accounts = results[0] as List<AppAccount>;
      final transactions = results[1] as List<AppTransaction>;

      debugPrint(
          '[SyncService] Pull selesai: ${accounts.length} akun, ${transactions.length} transaksi.');

      return SyncResult(accounts: accounts, transactions: transactions);
    } catch (e, stack) {
      debugPrint('[SyncService] Error saat pull: $e\n$stack');
      return SyncResult(accounts: [], transactions: [], error: e.toString());
    }
  }

  Future<List<AppAccount>> _pullAccounts(String userId) async {
    final response = await _db
        .from('accounts')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: true);

    return (response as List)
        .map((row) => AppAccount.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppTransaction>> _pullTransactions(String userId) async {
    final response = await _db
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return (response as List)
        .map((row) => AppTransaction.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // ─── Push: simpan transaksi baru ke cloud ─────────────────────────────────

  /// Panggil ini saat user tambah transaksi baru (opsional, kalau mau realtime sync).
  Future<void> pushTransaction(AppTransaction tx) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      final data = tx.toMap()
        ..['user_id'] = userId
        ..remove('id'); // biar Supabase yang generate id

      await _db.from('transactions').insert(data);
      debugPrint('[SyncService] Transaksi berhasil disimpan ke cloud.');
    } catch (e) {
      debugPrint('[SyncService] Gagal push transaksi: $e');
      rethrow;
    }
  }

  /// Panggil ini saat user tambah/update akun baru.
  Future<void> pushAccount(AppAccount account) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      final data = account.toMap()
        ..['user_id'] = userId
        ..remove('id');

      await _db.from('accounts').insert(data);
      debugPrint('[SyncService] Akun berhasil disimpan ke cloud.');
    } catch (e) {
      debugPrint('[SyncService] Gagal push akun: $e');
      rethrow;
    }
  }

  // ─── Update balance akun di cloud ─────────────────────────────────────────

  Future<void> updateAccountBalance(int accountId, double newBalance) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      await _db
          .from('accounts')
          .update({'balance': newBalance})
          .eq('id', accountId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SyncService] Gagal update balance: $e');
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteTransaction(int txId) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      await _db
          .from('transactions')
          .delete()
          .eq('id', txId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SyncService] Gagal delete transaksi: $e');
    }
  }

  Future<void> deleteAccount(int accountId) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      await _db
          .from('accounts')
          .delete()
          .eq('id', accountId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SyncService] Gagal delete akun: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SyncResult — hasil dari pullFromCloud()
// ─────────────────────────────────────────────────────────────────────────────

class SyncResult {
  final List<AppAccount> accounts;
  final List<AppTransaction> transactions;
  final String? error;

  bool get hasError => error != null;
  bool get isEmpty => accounts.isEmpty && transactions.isEmpty;

  const SyncResult({
    required this.accounts,
    required this.transactions,
    this.error,
  });
}
