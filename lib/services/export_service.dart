import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExportService {
  // ── Build CSV string dari transactions ────────────────────────────────────
  static String _buildCsv(List<dynamic> rows) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Amount,Note,Account ID');
    for (final row in rows) {
      final note = (row['note'] ?? '').toString().replaceAll('"', "'");
      buffer.writeln(
        '${row['date']},'
        '${row['type'] ?? ''},'
        '${row['category'] ?? ''},'
        '${row['amount']},'
        '"$note",'
        '${row['account_id'] ?? ''}',
      );
    }
    return buffer.toString();
  }

  // ── Fetch transactions dari Supabase ──────────────────────────────────────
  static Future<List<dynamic>> _fetchTransactions() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    return await Supabase.instance.client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false);
  }

  // ── Export via Share (WhatsApp, Email, dll) ───────────────────────────────
  static Future<String> shareExport(BuildContext context) async {
    final rows = await _fetchTransactions();
    if (rows.isEmpty) return 'No transactions to export';

    final csv = _buildCsv(rows);

    // Tulis ke temp directory
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/walletscript_export.csv');
    await file.writeAsString(csv);

    // Share
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'WalletScript Financial Export',
      text: 'Exported ${rows.length} transactions from WalletScript',
    );

    return 'Shared ${rows.length} transactions';
  }

  // ── Save ke Downloads folder ──────────────────────────────────────────────
  static Future<String> saveToDownloads() async {
    // Request permission (Android < 10)
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdk();
      if (sdk <= 29) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return 'Storage permission denied';
      }
    }

    final rows = await _fetchTransactions();
    if (rows.isEmpty) return 'No transactions to export';

    final csv = _buildCsv(rows);

    Directory? saveDir;
    if (Platform.isAndroid) {
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        saveDir = await getExternalStorageDirectory();
      }
    } else {
      saveDir = await getApplicationDocumentsDirectory();
    }

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
    final filePath = '${saveDir!.path}/walletscript_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    return 'Saved to Downloads:\nwalletscript_$timestamp.csv';
  }

  // ── Helper: get Android SDK version ──────────────────────────────────────
  static Future<int> _getAndroidSdk() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30;
    }
  }
}
