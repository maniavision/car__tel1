import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car/services/translation_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _acceptTerms = false;
  bool _isLoading = false;
  XFile? _avatarFile;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  List<Map<String, dynamic>> _countries = [];
  int? _selectedCountryId;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await Supabase.instance.client
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
              title: const Text('Prendre une photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              title: const Text('Choisir dans la galerie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

      await Supabase.instance.client.storage.from('profiles').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = Supabase.instance.client.storage.from('profiles').getPublicUrl(filePath);
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
        const SnackBar(content: Text('Veuillez sélectionner votre pays de résidence')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre numéro de téléphone')),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions d\'utilisation')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhone = '${_getCountryPrefix()} ${_phoneController.text.trim()}';

    try {
      final response = await Supabase.instance.client.auth.signUp(
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
          // Use upsert to handle cases where a database trigger might have already created the profile
          await Supabase.instance.client.schema('cartel').from('profiles').upsert({
            'id': response.user!.id,
            'full_name': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': fullPhone,
            'country_id': _selectedCountryId,
            'type': 'Client',
          });
        } catch (dbError) {
          debugPrint('Profile creation error: $dbError');
          // We still continue as the auth user was created
        }

        final avatarUrl = await _uploadAvatar(response.user!.id);
        if (avatarUrl != null) {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              data: {
                'avatar_url': avatarUrl,
              },
            ),
          );
        }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur est survenue'), backgroundColor: Colors.red),
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
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ColorFilter.mode(
                      primaryColor.withOpacity(0.05),
                      BlendMode.srcATop,
                    ),
                    child: Container(),
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
                      // Logo
                      Center(
                        child: Image.network(
                          'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/ai/Transparent-File-01-ARxLMHKJIUT.png',
                          width: 180,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Title
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
                      
                      // Avatar Picker
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
                      
                      // Form
                      _buildInputField(
                        label: ts.translate('full_name'),
                        placeholder: 'Fortune Niama',
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
                      _buildCountryDropdown(
                        label: ts.translate('country_of_residence'),
                        primaryColor: primaryColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                        cardColor: cardColor,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: ts.translate('phone'),
                        placeholder: '••• •• •• ••',
                        icon: Icons.phone_outlined,
                        prefixText: _getCountryPrefix(),
                        controller: _phoneController,
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
                      const SizedBox(height: 24),
                      
                      // Terms
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              activeColor: primaryColor,
                              checkColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: borderColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.dmSans(
                                  color: mutedForeground,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(text: '${ts.translate('accept_terms_prefix')} '),
                                  TextSpan(
                                    text: ts.translate('terms_link'),
                                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: ' ${ts.translate('and_label')} '),
                                  TextSpan(
                                    text: ts.translate('privacy_link'),
                                    style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Sign Up Button
                      GestureDetector(
                        onTap: _isLoading ? null : _handleSignUp,
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
                                    ts.translate('create_account_btn'),
                                    style: GoogleFonts.dmSans(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ts.translate('already_have_account'),
                            style: GoogleFonts.dmSans(
                              color: mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Text(
                              ts.translate('log_in_btn'),
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
            keyboardType: label.toLowerCase().contains('téléphone') || label.toLowerCase().contains('phone') ? TextInputType.phone : null,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor.withOpacity(0.6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedCountryId,
              isExpanded: true,
              hint: Text(
                'Sélectionnez votre pays',
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
}
