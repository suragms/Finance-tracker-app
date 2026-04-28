import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/dio_errors.dart';
import '../../../core/providers.dart';
import '../application/session_notifier.dart';
import '../data/auth_api.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  bool _passwordVisible = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final authApi = ref.read(authApiProvider);
      final tokens = await authApi.login(email, password);
      final storage = ref.read(tokenStorageProvider);
      await storage.saveTokens(
        access: tokens.access,
        refresh: tokens.refresh,
        sessionId: tokens.sessionId,
      );
      if (tokens.user?.email != null) {
        await storage.setUserEmail(tokens.user!.email);
      } else {
        await storage.setUserEmail(email);
      }
      ref.read(sessionProvider.notifier).setLoggedIn(true);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(dioErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Branding
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE1FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3953BD).withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.account_balance_wallet_rounded, size: 40, color: Color(0xFF3953BD)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MoneyFlow',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF191C1E),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Welcome Text
              Text(
                'Welcome back!',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your buddy missed you. Let's check your balance.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF444653),
                ),
              ),
              const SizedBox(height: 48),

              // Fields
              _AuthField(
                controller: _emailController,
                hint: 'Email Address',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _AuthField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: !_passwordVisible,
                suffix: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF757684),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3953BD),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3953BD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 8,
                    shadowColor: const Color(0xFF3953BD).withValues(alpha: 0.3),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Log In',
                              style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: const Color(0xFFC5C5D5))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF757684), letterSpacing: 1),
                    ),
                  ),
                  Expanded(child: Divider(color: const Color(0xFFC5C5D5))),
                ],
              ),
              const SizedBox(height: 32),

              // Social Buttons
              Row(
                children: [
                  Expanded(child: _SocialBtn(label: 'Google', icon: Icons.g_mobiledata)),
                  const SizedBox(width: 16),
                  Expanded(child: _SocialBtn(label: 'Apple', icon: Icons.apple)),
                ],
              ),
              const SizedBox(height: 40),

              // Signup Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF444653)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF3953BD)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF191C1E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFF757684), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF757684), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  const _SocialBtn({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Color(0xFFC5C5D5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: const Color(0xFF191C1E)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF191C1E)),
          ),
        ],
      ),
    );
  }
}
