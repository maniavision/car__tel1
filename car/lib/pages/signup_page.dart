import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/services/stripe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const SignUpPage({super.key, this.supabaseClient});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  SupabaseClient get _supabase => widget.supabaseClient ?? Supabase.instance.client;
  final ts = TranslationService();
  bool _acceptTerms = false;
  bool _isLoading = false;
  XFile? _avatarFile;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<Map<String, dynamic>> _countries = [];
  int? _selectedCountryId;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
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
        // StripeService().initialize();
        await TranslationService().loadUserPreferences();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: 'cartel://login-callback',
      );
    } catch (e) {
      if (mounted) {
        final message = e is AuthException ? e.message : ts.translate('error_occurred');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await _supabase
          .schema('cartel')
          .from('country_calling_codes')
          .select('id, country_name, calling_code')
          .order('country_name');
      
      setState(() {
        _countries = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching countries: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFD4AF37)),
              ),
              title: Text(ts.translate('take_photo'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFD4AF37)),
              ),
              title: Text(ts.translate('choose_gallery'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() {
          _avatarFile = image;
        });
      }
    }
  }

  Future<String?> _uploadAvatar(String userId) async {
    if (_avatarFile == null) return null;

    try {
      final file = File(_avatarFile!.path);
      final fileExt = _avatarFile!.path.split('.').last;
      final fileName = 'avatar.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from('profiles').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage.from('profiles').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  String _getCountryPrefix() {
    if (_selectedCountryId == null || _countries.isEmpty) return '';
    try {
      final country = _countries.firstWhere((c) => c['id'] == _selectedCountryId);
      return country['calling_code'] as String;
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleSignUp() async {

    if (_selectedCountryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ts.translate('select_country_error'))),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ts.translate('enter_phone_error'))),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ts.translate('accept_terms_error'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhone = '${_getCountryPrefix()} ${_phoneController.text.trim()}';

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'phone': fullPhone,
          'country_id': _selectedCountryId,
        },
      );

      if (response.user != null) {
        try {
          await _supabase.schema('cartel').from('profiles').upsert({
            'id': response.user!.id,
            'full_name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': fullPhone,
            'country_id': _selectedCountryId,
            'type': 'Client',
          });
        } catch (dbError) {
          debugPrint('Profile creation error: $dbError');
        }

        final avatarUrl = await _uploadAvatar(response.user!.id);
        if (avatarUrl != null) {
          await _supabase
              .schema('cartel')
              .from('profiles')
              .update({'avatar_url': avatarUrl}).eq('id', response.user!.id);
          await _supabase.auth.updateUser(
            UserAttributes(data: {'avatar_url': avatarUrl}),
          );
        }

        if (mounted) {
          NotificationService().init();
          // StripeService().initialize();
          await TranslationService().loadUserPreferences();
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
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              Positioned(
                top: -100,
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
              Positioned(
                bottom: -100,
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
              
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Column(
                    children: [
                      Center(
                        child: Image.network(
                          'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/ai/Transparent-File-01-ARxLMHKJIUT.png',
                          width: 180,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      Text(
                        ts.translate('signup_title'),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ts.translate('signup_subtitle'),
                        style: GoogleFonts.dmSans(
                          color: mutedForeground,
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor,
                                border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.1),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: _avatarFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Image.file(
                                        File(_avatarFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(Icons.person_outline_rounded, size: 40, color: mutedForeground.withOpacity(0.5)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_rounded, size: 16, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      _buildInputField(
                        label: ts.translate('full_name'),
                        placeholder: 'John Doe',
                        icon: Icons.person_outline_rounded,
                        controller: _fullNameController,
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                        cardColor: cardColor,
                      ),
                      const SizedBox(height: 20),
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
                      _buildInputField(
                        label: ts.translate('password'),
                        placeholder: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordController,
                        isPassword: true,
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                        cardColor: cardColor,
                      ),
                      const SizedBox(height: 20),
                      _buildCountryDropdown(
                        label: ts.translate('country_residence'),
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                        cardColor: cardColor,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: ts.translate('phone_number'),
                        placeholder: '690 00 00 00',
                        icon: Icons.phone_android_rounded,
                        controller: _phoneController,
                        prefixText: _getCountryPrefix(),
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                        cardColor: cardColor,
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _acceptTerms ? primaryColor : borderColor),
                                color: _acceptTerms ? primaryColor : Colors.transparent,
                              ),
                              child: _acceptTerms ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              children: [
                                Text(
                                  ts.translate('accept_terms_prefix'),
                                  style: GoogleFonts.dmSans(color: mutedForeground, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    ts.translate('terms_link'),
                                    style: GoogleFonts.dmSans(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ts.translate('and_label'),
                                  style: GoogleFonts.dmSans(color: mutedForeground, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    ts.translate('privacy_link'),
                                    style: GoogleFonts.dmSans(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: primaryColor.withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : Text(
                                  ts.translate('create_account_btn'),
                                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 12),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
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
                      const SizedBox(height: 32),

                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: ts.translate('already_have_account'),
                            style: GoogleFonts.dmSans(color: mutedForeground, fontSize: 14),
                            children: [
                              TextSpan(
                                text: ' ${ts.translate('log_in_btn')}',
                                style: GoogleFonts.dmSans(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
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
    String? prefixText,
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
            label,
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
            keyboardType: label.toLowerCase().contains('phone') ? TextInputType.phone : null,
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.dmSans(
                color: mutedForeground.withOpacity(0.4),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: mutedForeground, size: 20),
              prefixText: prefixText != null && prefixText.isNotEmpty ? '$prefixText ' : null,
              prefixStyle: GoogleFonts.dmSans(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown({
    required String label,
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
            label,
            style: GoogleFonts.dmSans(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: (_countries.any((c) => c['id'] == _selectedCountryId)) ? _selectedCountryId : null,
              isExpanded: true,
              hint: Text(
                ts.translate('select_country'),
                style: GoogleFonts.dmSans(
                  color: mutedForeground.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: mutedForeground),
              dropdownColor: cardColor,
              borderRadius: BorderRadius.circular(16),
              items: _countries.map((country) {
                return DropdownMenuItem<int>(
                  value: country['id'] as int,
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded, size: 20, color: Color(0xFFA3A3A3)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          country['country_name'] as String,
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountryId = value;
                });
              },
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
