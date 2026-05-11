import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../models/account_model.dart';
import '../services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<AppBudget> _budgets = [];
  List<AppBudget> get budgets => _budgets;

  List<AppBudget> get priorityBudget =>
      _budgets.where((b) => b.isPriority).toList();

  List<AppBudget> get otherBudgets =>
      _budgets.where((b) => !b.isPriority).toList();

  double get totalSaved => _budgets.fold(0, (sum, b) => sum + b.currentAmount);

  double get totalTarget => _budgets.fold(0, (sum, b) => sum + b.targetAmount);

  Future<void> loadBudgets() async {
    _budgets = await DatabaseService.instance.getBudgets();
    notifyListeners();
  }

  Future<void> addBudget(AppBudget budget) async {
    final inserted = await DatabaseService.instance.insertBudget(budget);
    // First budget auto-becomes priority
    if (_budgets.isEmpty) {
      await DatabaseService.instance.setPriorityBudget(inserted.id!);
    }
    await loadBudgets();
  }

  Future<void> updateBudget(AppBudget budget) async {
    await DatabaseService.instance.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> setPriority(int id) async {
    await DatabaseService.instance.setPriorityBudget(id);
    await loadBudgets();
  }

  Future<void> removePriority(int id) async {
    final budget = _budgets.firstWhere((b) => b.id == id);
    await DatabaseService.instance.updateBudget(
      budget.copyWith(isPriority: false),
    );
    await loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await DatabaseService.instance.deleteBudget(id);
    await loadBudgets();
  }

  // ─── Deposit / Setoran ────────────────────────────────────────

  Future<List<GoalDeposit>> getDeposits(int budgetId) async {
    return await DatabaseService.instance.getDepositsForBudget(budgetId);
  }

  Future<void> addDeposit({
    required int budgetId,
    required double amount,
    AppAccount? sourceAccount,
    String? note,
    String? attachmentPath,
    bool deductFromWallet = true,
  }) async {
    final deposit = GoalDeposit(
      budgetId: budgetId,
      amount: amount,
      sourceAccountId: sourceAccount?.id?.toString(),
      sourceAccountName: sourceAccount?.name,
      note: note,
      attachmentPath: attachmentPath,
      date: DateTime.now(),
    );

    await DatabaseService.instance.insertDeposit(deposit);

    // Update budget currentAmount
    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    final newAmount = budget.currentAmount + amount;
    await DatabaseService.instance.updateBudgetAmount(budgetId, newAmount);

    // Deduct from source wallet account
    if (deductFromWallet && sourceAccount != null) {
      final newBalance = sourceAccount.balance - amount;
      await DatabaseService.instance
          .updateAccountBalance(sourceAccount.id!, newBalance);
    }

    await loadBudgets();
  }

  Future<void> deleteDeposit({
    required int depositId,
    required int budgetId,
    required double depositAmount,
  }) async {
    await DatabaseService.instance.deleteDeposit(depositId);
    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    final newAmount =
        (budget.currentAmount - depositAmount).clamp(0.0, double.infinity);
    await DatabaseService.instance.updateBudgetAmount(budgetId, newAmount);
    await loadBudgets();
  }
}
