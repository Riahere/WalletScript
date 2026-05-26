import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<AppTransaction> _transactions = [];
  List<AppTransaction> get transactions => _transactions;

  double get totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  Future<void> loadTransactions() async {
    _transactions = await DatabaseService.instance.getTransactions();
    notifyListeners();
  }

  Future<void> addTransaction(AppTransaction tx) async {
    // 1. Simpan ke SQLite lokal
    final saved = await DatabaseService.instance.insertTransaction(tx);
    // 2. Push ke Supabase (fire-and-forget, tidak block UI)
    SyncService().pushTransaction(saved).catchError(
          (e) => debugPrint('[Sync] pushTransaction error: $e'),
        );
    await loadTransactions();
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    await DatabaseService.instance.updateTransaction(tx);
    // Sync update ke cloud
    SyncService().pushTransaction(tx).catchError(
          (e) => debugPrint('[Sync] pushTransaction update error: $e'),
        );
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseService.instance.deleteTransaction(id);
    // Sync delete ke cloud
    SyncService().deleteTransaction(id).catchError(
          (e) => debugPrint('[Sync] deleteTransaction error: $e'),
        );
    await loadTransactions();
  }

  // Clear in-memory (guest mode)
  void clearAll() {
    _transactions = [];
    notifyListeners();
  }
}
