import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class _C {
  static const navy = Color(0xFF0D1B3E);
  static const yellow = Color(0xFFF5C842);
  static const green = Color(0xFF1DB87A);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF6B7280);
  static const cardBg = Color(0xFFF9FAFB);
  static const border = Color(0xFFE5E7EB);
  static const red = Color(0xFFEF4444);
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  bool _showCurrentPw = false;
  bool _showNewPw = false;
  bool _showConfirmPw = false;
  bool _loading = false;

  AuthService? _auth;

  @override
  void initState() {
    super.initState();
    try {
      _auth = AuthService();
    } catch (_) {}
    _nameCtrl = TextEditingController(text: _auth?.userName ?? '');
    _emailCtrl = TextEditingController(text: _auth?.userEmail ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _phoneCtrl,
      _usernameCtrl,
      _currentPwCtrl,
      _newPwCtrl,
      _confirmPwCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final changingPassword = _newPwCtrl.text.isNotEmpty;

    if (changingPassword) {
      if (_currentPwCtrl.text.isEmpty) {
        _showSnack('Enter your current password', isError: true);
        return;
      }
      if (_newPwCtrl.text != _confirmPwCtrl.text) {
        _showSnack('New passwords do not match', isError: true);
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final client = Supabase.instance.client;

      // Update display name in user metadata
      await client.auth.updateUser(
        UserAttributes(
          data: {'full_name': _nameCtrl.text.trim()},
        ),
      );

      // Update email if changed
      final currentEmail = _auth?.userEmail ?? '';
      if (_emailCtrl.text.trim().isNotEmpty &&
          _emailCtrl.text.trim() != currentEmail) {
        await client.auth.updateUser(
          UserAttributes(email: _emailCtrl.text.trim()),
        );
      }

      // Update password if requested
      if (changingPassword) {
        await client.auth.updateUser(
          UserAttributes(password: _newPwCtrl.text),
        );
      }

      if (mounted) {
        _showSnack('Profile updated successfully');
        Navigator.pop(context, true);
      }
    } on AuthException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (_) {
      _showSnack('Something went wrong. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(color: _C.navy, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will permanently delete your account and all financial data. This action cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _C.navy)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: _C.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // TODO: call your delete-account Supabase Edge Function / RPC here
    _showSnack('Account deletion not yet implemented', isError: true);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _C.red : _C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.white,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: _C.navy, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => _showSnack('Photo picker coming soon'),
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _C.yellow, width: 3),
                          color: _C.cardBg,
                        ),
                        child: const ClipOval(
                          child: Icon(Icons.person_rounded,
                              color: _C.navy, size: 46),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: _C.navy, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: _C.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => _showSnack('Photo picker coming soon'),
                  child: const Text(
                    'Change photo',
                    style: TextStyle(
                        color: _C.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Personal Info ─────────────────────────────────────────────
              _sectionLabel('Personal Info'),
              _fieldCard([
                _buildField(
                  label: 'FULL NAME',
                  controller: _nameCtrl,
                  hint: 'Your full name',
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Name is required' : null,
                ),
                _divider(),
                _buildField(
                  label: 'USERNAME',
                  controller: _usernameCtrl,
                  hint: 'e.g. john_doe (optional)',
                ),
              ]),
              const SizedBox(height: 20),

              // ── Contact ───────────────────────────────────────────────────
              _sectionLabel('Contact'),
              _fieldCard([
                _buildField(
                  label: 'EMAIL',
                  controller: _emailCtrl,
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                _divider(),
                _buildField(
                  label: 'PHONE (optional)',
                  controller: _phoneCtrl,
                  hint: '+62 812 3456 7890',
                  keyboardType: TextInputType.phone,
                ),
              ]),
              const SizedBox(height: 20),

              // ── Security ──────────────────────────────────────────────────
              _sectionLabel('Security'),
              _fieldCard([
                _buildPasswordField(
                  label: 'CURRENT PASSWORD',
                  controller: _currentPwCtrl,
                  show: _showCurrentPw,
                  hint: 'Enter current password',
                  onToggle: () =>
                      setState(() => _showCurrentPw = !_showCurrentPw),
                ),
                _divider(),
                _buildPasswordField(
                  label: 'NEW PASSWORD',
                  controller: _newPwCtrl,
                  show: _showNewPw,
                  hint: 'Min. 8 characters',
                  onToggle: () => setState(() => _showNewPw = !_showNewPw),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                _divider(),
                _buildPasswordField(
                  label: 'CONFIRM NEW PASSWORD',
                  controller: _confirmPwCtrl,
                  show: _showConfirmPw,
                  hint: 'Repeat new password',
                  onToggle: () =>
                      setState(() => _showConfirmPw = !_showConfirmPw),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  'Leave password fields empty to keep current password.',
                  style:
                      TextStyle(color: _C.grey.withOpacity(0.75), fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),

              // ── Save button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.navy,
                    disabledBackgroundColor: _C.navy.withOpacity(0.45),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Delete account ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _confirmDeleteAccount,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _C.red.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                        color: _C.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              color: _C.grey.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7),
        ),
      );

  Widget _fieldCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(children: children),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: _C.border);

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _C.grey, fontSize: 11, letterSpacing: 0.4)),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: _C.navy, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              errorStyle: const TextStyle(fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: _C.grey, fontSize: 11, letterSpacing: 0.4)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: !show,
                  validator: validator,
                  style: const TextStyle(color: _C.navy, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    errorStyle: const TextStyle(fontSize: 11, height: 1.3),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  show
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: _C.grey,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
