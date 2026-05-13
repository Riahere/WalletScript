import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

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
    await DatabaseService.instance.insertTransaction(tx);
    await loadTransactions();
  }

  Future<void> updateTransaction(AppTransaction tx) async {
    await DatabaseService.instance.updateTransaction(tx);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseService.instance.deleteTransaction(id);
    await loadTransactions();
  }
}
