import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/account_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'wallet_all_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthService? _auth;
  bool _supabaseReady = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  void _initAuth() {
    try {
      Supabase.instance.client; // throws jika belum init
      _auth = AuthService();
      if (mounted) setState(() => _supabaseReady = true);
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final byGroup = accountProvider.accountsByGroup;

    final name = _supabaseReady
        ? (_auth?.userName ?? 'Pengguna WalletScript')
        : 'Pengguna WalletScript';
    final email = _supabaseReady ? (_auth?.userEmail ?? '-') : '-';
    final avatar = _supabaseReady ? _auth?.userAvatar : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile',
            style: TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                      color: AppTheme.surfaceContainer,
                    ),
                    child: ClipOval(
                      child: avatar != null
                          ? Image.network(avatar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.primary,
                                  size: 50))
                          : const Icon(Icons.person_rounded,
                              color: AppTheme.primary, size: 50),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name,
                      style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(email,
                      style: const TextStyle(
                          color: AppTheme.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                    icon: const Icon(Icons.edit_rounded,
                        size: 16, color: AppTheme.primary),
                    label: const Text('Edit Profile',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(children: [
              _statCard('Total\nAkun', '${accountProvider.accounts.length}',
                  Icons.account_balance_wallet_rounded),
              const SizedBox(width: 12),
              _statCard(
                  'Total\nSaldo',
                  formatter.format(accountProvider.totalBalance),
                  Icons.savings_rounded),
              const SizedBox(width: 12),
              _statCard(
                  'Group\nAktif', '${byGroup.length}', Icons.folder_rounded),
            ]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Akun',
                        style: TextStyle(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 16),
                    _infoRow(Icons.person_outline_rounded, 'Nama', name),
                    const Divider(height: 24, color: AppTheme.outline),
                    _infoRow(Icons.email_outlined, 'Email', email),
                    const Divider(height: 24, color: AppTheme.outline),
                    _infoRow(
                        Icons.calendar_month_outlined, 'Bergabung', 'Mei 2026'),
                  ]),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('My Accounts / Wallets',
                              style: TextStyle(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const WalletAllScreen())),
                            child: const Row(children: [
                              Text('Kelola',
                                  style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.primary, size: 16),
                            ]),
                          ),
                        ]),
                    const SizedBox(height: 16),
                    if (byGroup.isEmpty)
                      const Center(
                          child: Text('Belum ada akun',
                              style:
                                  TextStyle(color: AppTheme.onSurfaceVariant)))
                    else
                      ...byGroup.entries.map((entry) {
                        final groupTotal =
                            entry.value.fold(0.0, (s, a) => s + a.balance);
                        return Column(children: [
                          _infoRow(Icons.folder_outlined, entry.key,
                              formatter.format(groupTotal)),
                          if (entry.key != byGroup.keys.last)
                            const Divider(height: 24, color: AppTheme.outline),
                        ]);
                      }),
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outline)),
        child: Column(children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 11)),
        ]),
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 20),
      const SizedBox(width: 12),
      Text(label,
          style:
              const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: const TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    ]);
  }
}
