import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_model.dart';
import '../models/account_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

enum BudgetSortBy { dateAdded, progress, deadline, targetAmount }

class BudgetProvider extends ChangeNotifier {
  List<AppBudget> _budgets = [];
  List<AppBudget> _archivedBudgets = [];
  BudgetSortBy _sortBy = BudgetSortBy.dateAdded;
  String? _filterCategory;

  List<AppBudget> get budgets => _sorted(_budgets);
  List<AppBudget> get archivedBudgets => _archivedBudgets;
  BudgetSortBy get sortBy => _sortBy;
  String? get filterCategory => _filterCategory;

  List<AppBudget> get priorityBudgets =>
      _sorted(_budgets.where((b) => b.isPriority).toList());
  List<AppBudget> get otherBudgets =>
      _sorted(_budgets.where((b) => !b.isPriority).toList());

  // Keep for compatibility
  List<AppBudget> get priorityBudget => priorityBudgets;

  double get totalSaved => _budgets.fold(0, (sum, b) => sum + b.currentAmount);
  double get totalTarget => _budgets.fold(0, (sum, b) => sum + b.targetAmount);

  List<AppBudget> _sorted(List<AppBudget> list) {
    final filtered = _filterCategory != null
        ? list.where((b) => b.category == _filterCategory).toList()
        : list;
    final copy = List<AppBudget>.from(filtered);
    switch (_sortBy) {
      case BudgetSortBy.dateAdded:
        copy.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
        break;
      case BudgetSortBy.progress:
        copy.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case BudgetSortBy.deadline:
        copy.sort((a, b) {
          if (a.deadline == null && b.deadline == null) return 0;
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
        break;
      case BudgetSortBy.targetAmount:
        copy.sort((a, b) => b.targetAmount.compareTo(a.targetAmount));
        break;
    }
    return copy;
  }

  void setSortBy(BudgetSortBy sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  Future<void> loadBudgets() async {
    _budgets = await DatabaseService.instance.getBudgets();
    _archivedBudgets = await DatabaseService.instance.getArchivedBudgets();
    notifyListeners();
  }

  Future<void> addBudget(AppBudget budget) async {
    await DatabaseService.instance.insertBudget(budget);
    await loadBudgets();
  }

  Future<void> updateBudget(AppBudget budget) async {
    await DatabaseService.instance.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> setPriority(int id) async {
    await DatabaseService.instance.togglePriorityBudget(id, true);
    await loadBudgets();
  }

  Future<void> removePriority(int id) async {
    await DatabaseService.instance.togglePriorityBudget(id, false);
    await loadBudgets();
  }

  Future<void> archiveBudget(int id) async {
    await DatabaseService.instance.archiveBudget(id);
    await loadBudgets();
  }

  Future<void> unarchiveBudget(int id) async {
    await DatabaseService.instance.unarchiveBudget(id);
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

    final budget = _budgets.firstWhere((b) => b.id == budgetId);
    final newAmount = budget.currentAmount + amount;
    await DatabaseService.instance.updateBudgetAmount(budgetId, newAmount);

    // Update streak
    await _updateStreak(budget);

    // Check milestone notifications
    await _checkMilestoneNotif(budget, newAmount);

    if (deductFromWallet && sourceAccount != null) {
      final newBalance = sourceAccount.balance - amount;
      await DatabaseService.instance
          .updateAccountBalance(sourceAccount.id!, newBalance);
    }

    await loadBudgets();
  }

  Future<void> _updateStreak(AppBudget budget) async {
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);
    final lastMonth =
        DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1));

    int newStreak = budget.streakMonths;
    if (budget.lastDepositMonth == null) {
      newStreak = 1;
    } else if (budget.lastDepositMonth == currentMonth) {
      // Same month, streak unchanged
      return;
    } else if (budget.lastDepositMonth == lastMonth) {
      newStreak = budget.streakMonths + 1;
    } else {
      // Break streak
      newStreak = 1;
    }

    await DatabaseService.instance
        .updateStreakData(budget.id!, newStreak, currentMonth);
  }

  Future<void> _checkMilestoneNotif(AppBudget budget, double newAmount) async {
    final oldProgress = budget.progress;
    final newProgress = budget.targetAmount > 0
        ? (newAmount / budget.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final milestones = [0.25, 0.5, 0.75, 1.0];
    final labels = ['25%', '50%', '75%', '100%'];
    final emojis = ['🌱', '🌿', '🌳', '🏆'];

    for (int i = 0; i < milestones.length; i++) {
      if (oldProgress < milestones[i] && newProgress >= milestones[i]) {
        final notifId = (budget.id! * 10) + i;
        final title = newProgress >= 1.0
            ? '🏆 Goal "${budget.title}" Tercapai!'
            : '${emojis[i]} Milestone ${labels[i]} tercapai!';
        final body = newProgress >= 1.0
            ? 'Selamat! Kamu berhasil mencapai target ${budget.title}!'
            : 'Goal "${budget.title}" sudah ${labels[i]} dari target!';
        await NotificationService().showNow(
          id: notifId,
          title: title,
          body: body,
        );
        break;
      }
    }
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
