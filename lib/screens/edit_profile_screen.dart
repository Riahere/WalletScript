import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  bool _uploadingPhoto = false;

  AuthService? _auth;
  String? _avatarUrl; // URL tersimpan di Supabase
  File? _localImage; // File baru yang belum diupload

  @override
  void initState() {
    super.initState();
    try {
      _auth = AuthService();
    } catch (_) {}

    _nameCtrl = TextEditingController(text: _auth?.userName ?? '');
    _emailCtrl = TextEditingController(text: _auth?.userEmail ?? '');

    // Load avatar URL dari user metadata
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    _avatarUrl = meta?['avatar_url'] as String?;
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

  // ── Pick & upload photo ────────────────────────────────────────────────────
  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();

    // Bottom sheet pilihan sumber foto
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Change Photo',
                style: TextStyle(
                    color: _C.navy, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.navy.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: _C.navy, size: 22),
                ),
                title: const Text('Take Photo',
                    style:
                        TextStyle(color: _C.navy, fontWeight: FontWeight.w600)),
                subtitle: Text('Use camera',
                    style: TextStyle(
                        color: _C.navy.withOpacity(0.5), fontSize: 12)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: _C.green, size: 22),
                ),
                title: const Text('Choose from Gallery',
                    style:
                        TextStyle(color: _C.navy, fontWeight: FontWeight.w600)),
                subtitle: Text('Pick from your photos',
                    style: TextStyle(
                        color: _C.navy.withOpacity(0.5), fontSize: 12)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() {
      _localImage = File(picked.path);
      _uploadingPhoto = true;
    });

    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final ext = picked.path.split('.').last.toLowerCase();
      final path = '$uid/avatar.$ext';

      // Upload ke Supabase Storage bucket "avatars"
      await Supabase.instance.client.storage.from('avatars').upload(
            path,
            _localImage!,
            fileOptions: const FileOptions(upsert: true),
          );

      // Ambil public URL
      final publicUrl =
          Supabase.instance.client.storage.from('avatars').getPublicUrl(path);

      // Simpan ke user metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );

      if (mounted) {
        setState(() => _avatarUrl = publicUrl);
        _showSnack('Photo updated!');
      }
    } catch (e) {
      if (mounted) _showSnack('Upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  // ── Save profile ───────────────────────────────────────────────────────────
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

      // Update display name
      await client.auth.updateUser(
        UserAttributes(
          data: {'full_name': _nameCtrl.text.trim()},
        ),
      );

      // Update email jika berubah
      final currentEmail = _auth?.userEmail ?? '';
      if (_emailCtrl.text.trim().isNotEmpty &&
          _emailCtrl.text.trim() != currentEmail) {
        await client.auth.updateUser(
          UserAttributes(email: _emailCtrl.text.trim()),
        );
      }

      // Update password jika diisi
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

  // ── Delete account ─────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account',
            style: TextStyle(color: _C.navy, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will permanently delete your account and all financial data. '
          'This action cannot be undone.',
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

  // ── Avatar widget ──────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    ImageProvider? imageProvider;

    if (_localImage != null) {
      imageProvider = FileImage(_localImage!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      // cache-bust supaya foto terbaru langsung muncul
      imageProvider = NetworkImage(
          '$_avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}');
    }

    return Center(
      child: GestureDetector(
        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
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
              child: ClipOval(
                child: _uploadingPhoto
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: _C.navy, strokeWidth: 2),
                      )
                    : imageProvider != null
                        ? Image(
                            image: imageProvider,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: _C.navy,
                              size: 46,
                            ),
                          )
                        : const Icon(Icons.person_rounded,
                            color: _C.navy, size: 46),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration:
                    const BoxDecoration(color: _C.navy, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded,
                    color: _C.white, size: 15),
              ),
            ),
          ],
        ),
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
              // ── Avatar ───────────────────────────────────────────────
              _buildAvatar(),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                  child: Text(
                    _uploadingPhoto ? 'Uploading...' : 'Change photo',
                    style: TextStyle(
                        color: _uploadingPhoto ? _C.grey : _C.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Personal Info ─────────────────────────────────────────
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

              // ── Contact ───────────────────────────────────────────────
              _sectionLabel('Contact'),
              _fieldCard([
                _buildField(
                  label: 'EMAIL',
                  controller: _emailCtrl,
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Email is required';
                    }
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

              // ── Security ──────────────────────────────────────────────
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

              // ── Save button ───────────────────────────────────────────
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

              // ── Delete account ────────────────────────────────────────
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
                        fontWeight: FontWeight.w700,
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

  // ── Helper widgets ─────────────────────────────────────────────────────────

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
