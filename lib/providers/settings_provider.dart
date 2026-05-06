import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  String _currency = 'IDR';
  String _language = 'id';
  bool _isDarkMode = false;

  String get currency => _currency;
  String get language => _language;
  bool get isDarkMode => _isDarkMode;

  void setCurrency(String currency) {
    _currency = currency;
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
