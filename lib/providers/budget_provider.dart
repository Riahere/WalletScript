import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<AppBudget> _budgets = [];
  List<AppBudget> get budgets => _budgets;

  Future<void> loadBudgets() async {
    _budgets = await DatabaseService.instance.getBudgets();
    notifyListeners();
  }

  Future<void> addBudget(AppBudget budget) async {
    await DatabaseService.instance.insertBudget(budget);
    await loadBudgets();
  }

  Future<void> updateAmount(int id, double amount) async {
    await DatabaseService.instance.updateBudgetAmount(id, amount);
    await loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await DatabaseService.instance.deleteBudget(id);
    await loadBudgets();
  }
}
