import 'package:flutter/material.dart';
import '../models/account_model.dart';
import '../services/database_service.dart';

class AccountProvider extends ChangeNotifier {
  List<AppAccount> _accounts = [];
  List<AppAccount> get accounts => _accounts;

  // Semua group yang tersedia
  static const List<String> allGroups = [
    'Cash',
    'Accounts',
    'Card',
    'Debit Card',
    'Savings',
    'Top-Up/Prepaid',
    'Investments',
    'Overdrafts',
    'Loan',
    'Insurance',
    'Others',
  ];

  // Total balance semua akun
  double get totalBalance => _accounts.fold(0, (sum, a) => sum + a.balance);

  // Balance per group
  Map<String, double> get balanceByGroup {
    final Map<String, double> map = {};
    for (final a in _accounts) {
      map[a.group] = (map[a.group] ?? 0) + a.balance;
    }
    return map;
  }

  // Akun per group
  Map<String, List<AppAccount>> get accountsByGroup {
    final Map<String, List<AppAccount>> map = {};
    for (final a in _accounts) {
      map[a.group] = [...(map[a.group] ?? []), a];
    }
    return map;
  }

  // Group yang punya akun (untuk dashboard — hanya tampil yang ada isinya)
  List<String> get activeGroups => accountsByGroup.keys.toList();

  Future<void> loadAccounts() async {
    _accounts = await DatabaseService.instance.getAccounts();
    notifyListeners();
  }

  Future<void> addAccount(AppAccount account) async {
    final saved = await DatabaseService.instance.insertAccount(account);
    _accounts.add(saved);
    notifyListeners();
  }

  Future<void> updateAccount(AppAccount account) async {
    await DatabaseService.instance.updateAccount(account);
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) _accounts[idx] = account;
    notifyListeners();
  }

  Future<void> deleteAccount(int id) async {
    await DatabaseService.instance.deleteAccount(id);
    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> updateBalance(int id, double newBalance) async {
    await DatabaseService.instance.updateAccountBalance(id, newBalance);
    final idx = _accounts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _accounts[idx] = _accounts[idx].copyWith(balance: newBalance);
    }
    notifyListeners();
  }
}
