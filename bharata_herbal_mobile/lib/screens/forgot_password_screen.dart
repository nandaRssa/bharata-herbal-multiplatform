import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final AuthService _service = AuthService();
  bool _isLoading = false;
  bool _tokenSent = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendToken() async {
    if (_emailCtrl.text.trim().isEmpty) {
      _snack('Masukkan email terdaftar');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      if (result['success'] == true) {
        _tokenCtrl.text = result['data']['reset_token'] ?? '';
        setState(() => _tokenSent = true);
        _snack('Token reset password berhasil dibuat!');
      } else {
        _snack(result['message'] ?? 'Email tidak ditemukan');
      }
    } catch (e) {
      if (mounted) _snack('Gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _snack('Password baru tidak cocok');
      return;
    }
    if (_newPassCtrl.text.length < 6) {
      _snack('Password minimal 6 karakter');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await _service.resetPassword(
        _emailCtrl.text.trim(),
        _tokenCtrl.text.trim(),
        _newPassCtrl.text,
        _confirmPassCtrl.text,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        _snack('Password berhasil direset! Silakan login.');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack(result['message'] ?? 'Gagal mereset password');
      }
    } catch (e) {
      if (mounted) _snack('Gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A5C38),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Lupa Password', style: TextStyle(color: Color(0xFF0F3D25), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F3D25)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 56, color: Color(0xFF16A34A)),
            const SizedBox(height: 16),
            const Text('Reset Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F3D25))),
            const SizedBox(height: 8),
            const Text('Masukkan email terdaftar untuk mendapatkan token reset password.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 32),

            // Email
            TextField(
              controller: _emailCtrl,
              enabled: !_tokenSent,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF16A34A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A5C38), width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            if (_tokenSent) ...[
              // Token
              TextField(
                controller: _tokenCtrl,
                decoration: InputDecoration(
                  labelText: 'Token Reset',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: Color(0xFF16A34A)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A5C38), width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              // Password Baru
              TextField(
                controller: _newPassCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF16A34A)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A5C38), width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              // Konfirmasi Password
              TextField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF16A34A)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A5C38), width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kirim Token Reset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
