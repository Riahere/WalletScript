// lib/services/supabase_service.dart
// Handles all cloud CRUD — transactions, budgets, goals, profile

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  final _auth = AuthService();

  String get _uid => _auth.userId ?? '';

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final data =
          await _client.from('profiles').select().eq('id', _uid).maybeSingle();
      return data;
    } catch (e) {
      debugPrint('getProfile error: $e');
      return null;
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    try {
      await _client.from('profiles').upsert({
        'id': _uid,
        if (fullName != null) 'full_name': fullName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });
    } catch (e) {
      debugPrint('updateProfile error: $e');
    }
  }

  // ─── Transactions ─────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', _uid)
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('getTransactions error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> insertTransaction({
    required String title,
    required double amount,
    required String type, // 'income' atau 'expense'
    String? category,
    String? note,
    DateTime? date,
    String? localId, // SQLite ID untuk tracking sync
  }) async {
    try {
      final data = await _client
          .from('transactions')
          .insert({
            'user_id': _uid,
            'title': title,
            'amount': amount,
            'type': type,
            if (category != null) 'category': category,
            if (note != null) 'note': note,
            'date': (date ?? DateTime.now()).toIso8601String(),
            if (localId != null) 'local_id': localId,
          })
          .select()
          .single();
      return data;
    } catch (e) {
      debugPrint('insertTransaction error: $e');
      return null;
    }
  }

  Future<void> updateTransaction(
      String id, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('transactions')
          .update(updates)
          .eq('id', id)
          .eq('user_id', _uid);
    } catch (e) {
      debugPrint('updateTransaction error: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _client
          .from('transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', _uid);
    } catch (e) {
      debugPrint('deleteTransaction error: $e');
    }
  }

  // ─── Budgets ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBudgets() async {
    try {
      final data = await _client
          .from('budgets')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('getBudgets error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> insertBudget({
    required String category,
    required double limitAmount,
    required String period,
    bool autoDeduct = false,
  }) async {
    try {
      final data = await _client
          .from('budgets')
          .insert({
            'user_id': _uid,
            'category': category,
            'limit_amount': limitAmount,
            'period': period,
            'auto_deduct': autoDeduct,
          })
          .select()
          .single();
      return data;
    } catch (e) {
      debugPrint('insertBudget error: $e');
      return null;
    }
  }

  Future<void> updateBudget(String id, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('budgets')
          .update(updates)
          .eq('id', id)
          .eq('user_id', _uid);
    } catch (e) {
      debugPrint('updateBudget error: $e');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _client.from('budgets').delete().eq('id', id).eq('user_id', _uid);
    } catch (e) {
      debugPrint('deleteBudget error: $e');
    }
  }

  // ─── Goals ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGoals() async {
    try {
      final data = await _client
          .from('goals')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('getGoals error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> insertGoal({
    required String title,
    required double targetAmount,
    double currentAmount = 0,
    DateTime? deadline,
  }) async {
    try {
      final data = await _client
          .from('goals')
          .insert({
            'user_id': _uid,
            'title': title,
            'target_amount': targetAmount,
            'current_amount': currentAmount,
            if (deadline != null) 'deadline': deadline.toIso8601String(),
          })
          .select()
          .single();
      return data;
    } catch (e) {
      debugPrint('insertGoal error: $e');
      return null;
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> updates) async {
    try {
      await _client
          .from('goals')
          .update(updates)
          .eq('id', id)
          .eq('user_id', _uid);
    } catch (e) {
      debugPrint('updateGoal error: $e');
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _client.from('goals').delete().eq('id', id).eq('user_id', _uid);
    } catch (e) {
      debugPrint('deleteGoal error: $e');
    }
  }

  // ─── Bulk Sync (untuk pertama kali login) ────────────────────────────────

  /// Upload semua data lokal ke Supabase (pakai upsert supaya tidak duplikat)
  Future<void> bulkUpsertTransactions(
      List<Map<String, dynamic>> transactions) async {
    if (transactions.isEmpty) return;
    try {
      final rows = transactions.map((t) => {...t, 'user_id': _uid}).toList();
      await _client.from('transactions').upsert(rows);
    } catch (e) {
      debugPrint('bulkUpsertTransactions error: $e');
    }
  }
}
