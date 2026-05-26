// lib/services/sync_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../services/database_service.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  SupabaseClient get _db => Supabase.instance.client;
  final _auth = AuthService();

  // ─── Pull dari cloud + simpan ke SQLite lokal ─────────────────────────────

  Future<SyncResult> pullFromCloud() async {
    final userId = _auth.userId;
    if (userId == null) {
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

      // ── Simpan data cloud ke SQLite lokal (merge) ──────────────────────
      // Ini yang bikin data cloud muncul di app setelah login di device baru
      if (accounts.isNotEmpty) {
        await _mergeAccountsToLocal(accounts);
      }
      if (transactions.isNotEmpty) {
        await _mergeTransactionsToLocal(transactions);
      }

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
        .order('local_id', ascending: true);
    return (response as List)
        .map((row) => AppAccount.fromMap(_remapAccountRow(row)))
        .toList();
  }

  Future<List<AppTransaction>> _pullTransactions(String userId) async {
    final response = await _db
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return (response as List)
        .map((row) => AppTransaction.fromMap(_remapTxRow(row)))
        .toList();
  }

  // Remap Supabase row → format AppAccount/AppTransaction.fromMap()
  Map<String, dynamic> _remapAccountRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    if (m['local_id'] != null) m['id'] = m['local_id'];
    return m;
  }

  Map<String, dynamic> _remapTxRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    if (m['local_id'] != null) m['id'] = m['local_id'];
    return m;
  }

  // ── Merge akun dari cloud ke SQLite lokal ──────────────────────────────────
  Future<void> _mergeAccountsToLocal(List<AppAccount> cloudAccounts) async {
    final localAccounts = await DatabaseService.instance.getAccounts();
    final localIds = localAccounts.map((a) => a.id).toSet();

    for (final acc in cloudAccounts) {
      if (acc.id != null && !localIds.contains(acc.id)) {
        // Akun dari cloud belum ada di lokal — insert
        await DatabaseService.instance.insertAccount(acc);
      } else if (acc.id != null) {
        // Sudah ada — update supaya balance dll sinkron
        await DatabaseService.instance.updateAccount(acc);
      }
    }
  }

  // ── Merge transaksi dari cloud ke SQLite lokal ─────────────────────────────
  Future<void> _mergeTransactionsToLocal(List<AppTransaction> cloudTxs) async {
    final localTxs = await DatabaseService.instance.getTransactions();
    final localIds = localTxs.map((t) => t.id).toSet();

    for (final tx in cloudTxs) {
      if (tx.id != null && !localIds.contains(tx.id)) {
        // Transaksi dari cloud belum ada di lokal — insert
        await DatabaseService.instance.insertTransaction(tx);
      }
      // Kalau sudah ada, biarkan — data lokal lebih fresh
    }
  }

  // ─── Push semua data lokal ke cloud ───────────────────────────────────────

  Future<void> pushAllToCloud({
    required List<AppAccount> accounts,
    required List<AppTransaction> transactions,
  }) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      debugPrint(
          '[SyncService] Pushing ${accounts.length} akun, ${transactions.length} transaksi...');
      for (final acc in accounts) {
        await pushAccount(acc);
      }
      for (final tx in transactions) {
        await pushTransaction(tx);
      }
      debugPrint('[SyncService] pushAll selesai.');
    } catch (e) {
      debugPrint('[SyncService] pushAll error: $e');
    }
  }

  // ─── Push single account ──────────────────────────────────────────────────

  Future<void> pushAccount(AppAccount account) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      final map = account.toMap();
      final data = <String, dynamic>{
        'user_id': userId,
        'local_id': map['id'],
        'name': map['name'],
        'grp': map['grp'],
        'type': map['type'],
        'balance': map['balance'],
        'currency': map['currency'] ?? 'IDR',
        'icon': map['icon'] ?? 'wallet',
        'color': map['color'] ?? '0xFF10B981',
      };

      await _db.from('accounts').upsert(
            data,
            onConflict: 'user_id,local_id',
          );
    } catch (e) {
      debugPrint('[SyncService] pushAccount error: $e');
    }
  }

  // ─── Push single transaction ──────────────────────────────────────────────

  Future<void> pushTransaction(AppTransaction tx) async {
    final userId = _auth.userId;
    if (userId == null) return;

    try {
      final map = tx.toMap();
      final data = <String, dynamic>{
        'user_id': userId,
        'local_id': map['id'],
        'title': map['title'],
        'amount': map['amount'],
        'type': map['type'],
        'category': map['category'],
        'currency': map['currency'] ?? 'IDR',
        'accountId': map['accountId'],
        'toAccountId': map['toAccountId'],
        'date': map['date'],
        'note': map['note'],
        'attachmentPath': map['attachmentPath'],
      };

      await _db.from('transactions').upsert(
            data,
            onConflict: 'user_id,local_id',
          );
    } catch (e) {
      debugPrint('[SyncService] pushTransaction error: $e');
    }
  }

  // ─── Update balance ───────────────────────────────────────────────────────

  Future<void> updateAccountBalance(int localId, double newBalance) async {
    final userId = _auth.userId;
    if (userId == null) return;
    try {
      await _db
          .from('accounts')
          .update({'balance': newBalance})
          .eq('local_id', localId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SyncService] updateAccountBalance error: $e');
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteTransaction(int localId) async {
    final userId = _auth.userId;
    if (userId == null) return;
    try {
      await _db
          .from('transactions')
          .delete()
          .eq('local_id', localId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SyncService] deleteTransaction error: $e');
    }
  }

  Future<void> deleteAccount(int localId) async {
    final userId = _auth.userId;
    if (userId == null) return;
    try {
      await _db
          .from('accounts')
          .delete()
          .eq('local_id', localId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[SyncService] deleteAccount error: $e');
    }
  }
}

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
