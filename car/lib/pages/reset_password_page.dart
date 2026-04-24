import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const ResetPasswordPage({super.key, this.supabaseClient});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  SupabaseClient get _supabase => widget.supabaseClient ?? Supabase.instance.client;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) return;
    if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
        );
        return;
    }

    setState(() => _isLoading = true);
    final ts = TranslationService();

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ts.translate('password_reset_success')),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ts.translate('error_occurred')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    final ts = TranslationService();

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Background Blurs
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Back Button
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.4),
                              shape: BoxShape.circle,
                              border: Border.all(color: borderColor.withOpacity(0.6)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: primaryColor.withOpacity(0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shield_rounded, color: primaryColor, size: 40),
                            ),
                            const SizedBox(height: 32),

                            // Title
                            Text(
                              ts.translate('reset_password_title'),
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ts.translate('reset_password_subtitle'),
                              style: GoogleFonts.plusJakartaSans(
                                color: mutedForeground,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),

                            // Password Inputs
                            _buildPasswordField(
                                label: ts.translate('new_password'),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                mutedForeground: mutedForeground,
                            ),
                            const SizedBox(height: 24),
                            _buildPasswordField(
                                label: ts.translate('confirm_password'),
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                mutedForeground: mutedForeground,
                                icon: Icons.lock_outline_rounded,
                            ),
                            
                            const SizedBox(height: 40),

                            // Submit Button
                            GestureDetector(
                              onTap: _isLoading ? null : _handleResetPassword,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.25),
                                      blurRadius: 40,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              ts.translate('reset_access_btn').toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.black,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 48),
                            
                            // Requirements
                            Align(
                                alignment: Alignment.center,
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                        _buildRequirement(ts.translate('min_8_chars'), primaryColor),
                                        const SizedBox(height: 8),
                                        _buildRequirement(ts.translate('one_special_char'), primaryColor),
                                        const SizedBox(height: 8),
                                        _buildRequirement(ts.translate('one_number'), primaryColor),
                                    ],
                                ),
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
    required Color mutedForeground,
    IconData icon = Icons.lock_person_outlined,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.plusJakartaSans(color: mutedForeground.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: mutedForeground, size: 22),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: mutedForeground,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, Color primaryColor) {
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
              Icon(Icons.check_circle_outline_rounded, color: primaryColor, size: 14),
              const SizedBox(width: 8),
              Text(
                  text.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                  ),
              ),
          ],
      );
  }
}
