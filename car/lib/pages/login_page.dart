import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/services/stripe_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const LoginPage({super.key, this.supabaseClient});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  SupabaseClient get _supabase => widget.supabaseClient ?? Supabase.instance.client;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        NotificationService().init();
        StripeService().initialize();
        await TranslationService().loadUserPreferences();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        final ts = TranslationService();
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

  StreamSubscription<AuthState>? _authSubscription;

  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'cartel://login-callback',
      );
    } catch (e) {
      if (mounted) {
        final message = e is AuthException ? e.message : TranslationService().translate('error_occurred');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // Check if profile exists, if not create basic one (important for social sign-in)
        try {
          final user = session.user;
          final profile = await _supabase
              .schema('cartel')
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (profile == null) {
            await _supabase.schema('cartel').from('profiles').upsert({
              'id': user.id,
              'full_name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
              'email': user.email,
              'avatar_url': user.userMetadata?['avatar_url'],
              'type': 'Client',
            });
          }
        } catch (e) {
          debugPrint('Error ensuring profile exists: $e');
        }

        NotificationService().init();
        StripeService().initialize();
        await TranslationService().loadUserPreferences();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
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
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Column(
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/new_logo.png',
                          width: 220,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Title
                      Text(
                        ts.translate('login_title'),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ts.translate('login_subtitle'),
                        style: GoogleFonts.dmSans(
                          color: mutedForeground,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      
                      // Form
                      _buildInputField(
                        label: ts.translate('email'),
                        placeholder: 'votre@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                        cardColor: cardColor,
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            label: ts.translate('password'),
                            placeholder: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            isPassword: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: mutedForeground,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            primaryColor: primaryColor,
                            borderColor: borderColor,
                            mutedForeground: mutedForeground,
                            cardColor: cardColor,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                              child: Text(
                                ts.translate('forgot_password'),
                                style: GoogleFonts.dmSans(
                                  color: mutedForeground,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleLogin,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _isLoading ? primaryColor.withOpacity(0.5) : primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!_isLoading)
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : Text(
                                    ts.translate('log_in_btn'),
                                    style: GoogleFonts.dmSans(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: borderColor.withOpacity(0.4))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              ts.translate('or_continue_with'),
                              style: GoogleFonts.dmSans(
                                color: mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: borderColor.withOpacity(0.4))),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleSocialLogin(OAuthProvider.google),
                              child: _buildSocialButton(
                                icon: 'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                                label: ts.translate('google'),
                                borderColor: borderColor,
                                cardColor: cardColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _handleSocialLogin(OAuthProvider.apple),
                              child: _buildSocialButton(
                                icon: 'https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg',
                                label: ts.translate('apple'),
                                borderColor: borderColor,
                                cardColor: cardColor,
                                isApple: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      
                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ts.translate('new_to_cartel'),
                            style: GoogleFonts.dmSans(
                              color: mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/signup'),
                            child: Text(
                              ts.translate('signup_btn'),
                              style: GoogleFonts.dmSans(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    Widget? suffixIcon,
    required Color primaryColor,
    required Color borderColor,
    required Color mutedForeground,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.dmSans(
                color: mutedForeground.withOpacity(0.4),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: mutedForeground, size: 20),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required Color borderColor,
    required Color cardColor,
    bool isApple = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using Placeholder for logos as NetworkImage SVGs or specialized icons need packages
          Icon(isApple ? Icons.apple : Icons.g_mobiledata, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
