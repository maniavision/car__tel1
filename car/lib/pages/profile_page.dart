import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const ProfilePage({super.key, this.supabaseClient});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final SupabaseClient _supabase;
  final ts = TranslationService();
  bool _isUploading = false;
  Map<String, dynamic>? _profileData;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .schema('cartel')
          .from('profiles')
          .select('*, country:country_calling_codes(country_name, iso_alpha_2)')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _profileData = response;
          _isLoadingProfile = false;
        });
        // Sync the translation service state with the profile data
        if (response['language_preference'] != null) {
          ts.loadUserPreferences();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
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
    
    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = 'avatar.$fileExt';
      final filePath = '${user.id}/$fileName';

      await _supabase.storage.from('profiles').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage.from('profiles').getPublicUrl(filePath);

      await _supabase
          .schema('cartel')
          .from('profiles')
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'avatar_url': publicUrl,
          },
        ),
      );

      if (mounted) {
        _fetchProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ts.translate('profile_updated'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ts.translate('error')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const cardColor = Color(0xFF111111);
    const mutedForeground = Color(0xFF888888);
    const borderColor = Color(0xFF222222);
    const secondaryColor = Color(0xFF1A1A1A);

    final user = _supabase.auth.currentUser;

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          extendBody: true,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(primaryColor, backgroundColor, secondaryColor, user),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(ts.translate('preferences'), primaryColor),
                      const SizedBox(height: 16),
                      _buildPreferencesCard(primaryColor, cardColor, borderColor, mutedForeground, secondaryColor),
                      const SizedBox(height: 32),
                      _buildSectionTitle(ts.translate('support_legal'), primaryColor),
                      const SizedBox(height: 16),
                      _buildSupportCard(context, cardColor, borderColor, mutedForeground, secondaryColor),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 3,
            onTap: (index) {
              if (index == 0) Navigator.pushReplacementNamed(context, '/home');
              if (index == 1) Navigator.pushReplacementNamed(context, '/requests');
              if (index == 2) Navigator.pushReplacementNamed(context, '/notifications');
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-request');
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              elevation: 8,
              child: const Icon(Icons.add_rounded, size: 32),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color primaryColor, Color backgroundColor, Color secondaryColor, User? user) {
    final avatarUrl = _profileData?['avatar_url'] ?? user?.userMetadata?['avatar_url'];
    final fullName = _profileData?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'Client CarTel';
    final emailOrBadge = user?.email ?? ts.translate('premium_member');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryColor.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isUploading ? null : _pickAndUploadImage,
            child: Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: backgroundColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: _isUploading
                        ? Center(child: CircularProgressIndicator(color: primaryColor))
                        : avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator(color: primaryColor)),
                                errorWidget: (context, url, error) => Container(
                                  color: secondaryColor,
                                  child: Icon(Icons.person_rounded, color: primaryColor.withOpacity(0.5), size: 48),
                                ),
                              )
                            : Container(
                                color: secondaryColor,
                                child: Icon(Icons.person_rounded, color: primaryColor.withOpacity(0.5), size: 48),
                              ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: backgroundColor, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emailOrBadge,
            style: GoogleFonts.dmSans(
              color: user != null ? const Color(0xFF888888) : primaryColor,
              fontSize: user != null ? 14 : 10,
              fontWeight: user != null ? FontWeight.normal : FontWeight.bold,
              letterSpacing: user != null ? 0 : 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: primaryColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2.5,
      ),
    );
  }

  Widget _buildPreferencesCard(
      Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, Color secondaryColor) {
    String countryDisplay = 'N/A';
    if (_profileData != null && _profileData!['country'] != null) {
      countryDisplay = _profileData!['country']['iso_alpha_2'] ?? _profileData!['country']['country_name'] ?? 'N/A';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.language_rounded,
            title: ts.translate('select_language'),
            trailing: _buildToggleSwitch(['EN', 'FR'], ts.currentLanguage == 'English' ? 'EN' : 'FR', primaryColor, secondaryColor, (val) {
              ts.setLanguage(val == 'EN' ? 'English' : 'Français');
            }),
            borderColor: borderColor,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
          _buildSettingsTile(
            icon: Icons.payments_outlined,
            title: ts.translate('currency'),
            trailing: _buildToggleSwitch(['USD', 'FCFA'], ts.currentCurrency, primaryColor, secondaryColor, (val) {
              ts.setCurrency(val);
            }),
            borderColor: borderColor,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
          _buildSettingsTile(
            icon: Icons.map_outlined,
            title: ts.translate('country_of_residence'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                countryDisplay,
                style: GoogleFonts.dmSans(
                  color: mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            borderColor: Colors.transparent,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, Color cardColor, Color borderColor, Color mutedForeground, Color secondaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: ts.translate('help_center'),
            showArrow: true,
            borderColor: borderColor,
            primaryColor: const Color(0xFFD4AF37),
            secondaryColor: secondaryColor,
          ),
          _buildSettingsTile(
            icon: Icons.shield_outlined,
            title: ts.translate('privacy_policy'),
            showArrow: true,
            borderColor: borderColor,
            primaryColor: const Color(0xFFD4AF37),
            secondaryColor: secondaryColor,
          ),
          _buildSettingsTile(
            icon: Icons.logout_rounded,
            title: ts.translate('log_out'),
            titleColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            borderColor: Colors.transparent,
            primaryColor: const Color(0xFFD4AF37),
            secondaryColor: Colors.redAccent.withOpacity(0.1),
            onTap: () async {
              NotificationService().logout();
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    bool showArrow = false,
    required Color borderColor,
    required Color primaryColor,
    required Color secondaryColor,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: titleColor ?? Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (showArrow) const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(List<String> options, String selected, Color primaryColor, Color secondaryColor, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: options.map((option) {
          bool isSelected = option == selected;
          return GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                option,
                style: GoogleFonts.dmSans(
                  color: isSelected ? Colors.black : const Color(0xFF888888),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
