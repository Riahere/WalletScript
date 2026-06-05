import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyCurrency = 'settings_currency';
  static const _keyLanguage = 'settings_language';
  static const _keyDarkMode = 'settings_dark_mode';
  static const _keyNotifications = 'settings_notifications';

  String _currency = 'IDR';
  String _language = 'id';
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  String get currency => _currency;
  String get language => _language;
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString(_keyCurrency) ?? 'IDR';
    _language = prefs.getString(_keyLanguage) ?? 'id';
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? false;
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, _isDarkMode);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }
}
