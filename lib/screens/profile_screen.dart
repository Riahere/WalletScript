import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar + nama
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 3),
                      color: AppTheme.surfaceContainer,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppTheme.primary, size: 50),
                  ),
                  const SizedBox(height: 14),
                  const Text('Pengguna WalletScript',
                      style: TextStyle(color: AppTheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('walletscript@email.com',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.primary),
                    label: const Text('Edit Profile',
                        style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Stats row
            Row(
              children: [
                _statCard('Total\nTransaksi', '24', Icons.receipt_long_rounded),
                const SizedBox(width: 12),
                _statCard('Bulan\nIni', '8', Icons.calendar_today_rounded),
                const SizedBox(width: 12),
                _statCard('Goals\nAktif', '2', Icons.flag_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Info section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Akun',
                      style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  _infoRow(Icons.person_outline_rounded, 'Nama', 'Pengguna WalletScript'),
                  const Divider(height: 24, color: AppTheme.outline),
                  _infoRow(Icons.email_outlined, 'Email', 'walletscript@email.com'),
                  const Divider(height: 24, color: AppTheme.outline),
                  _infoRow(Icons.phone_outlined, 'No. HP', '+62 812-xxxx-xxxx'),
                  const Divider(height: 24, color: AppTheme.outline),
                  _infoRow(Icons.calendar_month_outlined, 'Bergabung', 'Mei 2026'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Wallet summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ringkasan Wallet',
                      style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  _infoRow(Icons.account_balance_wallet_rounded, 'Personal', 'Rp 4.250.000'),
                  const Divider(height: 24, color: AppTheme.outline),
                  _infoRow(Icons.savings_rounded, 'Tabungan', 'Rp 12.000.000'),
                  const Divider(height: 24, color: AppTheme.outline),
                  _infoRow(Icons.credit_card_rounded, 'Bank', 'Rp 1.120.000'),
                ],
              ),
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
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
