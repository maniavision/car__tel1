import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaveReviewPage extends StatefulWidget {
  const LeaveReviewPage({super.key});

  @override
  State<LeaveReviewPage> createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends State<LeaveReviewPage> {
  int _rating = 0;
  final _commentController = TextEditingController();
  XFile? _imageFile;
  bool _isSubmitting = false;
  final ts = TranslationService();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _handleSubmit(Map<String, dynamic> request) async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ts.translate('give_rating_error'))),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String? imageUrl;
      if (_imageFile != null) {
        final fileExt = _imageFile!.path.split('.').last;
        final folderName = '${user.id}${request['id']}';
        final fileName = 'testimonial_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '$folderName/$fileName';

        await Supabase.instance.client.storage.from('reviews').upload(
              filePath,
              File(_imageFile!.path),
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
        imageUrl = Supabase.instance.client.storage.from('reviews').getPublicUrl(filePath);
      }

      // Fetch user profile for name and location
      final profile = await Supabase.instance.client
          .schema('cartel')
          .from('profiles')
          .select('full_name, country_id')
          .eq('id', user.id)
          .maybeSingle();

      await Supabase.instance.client.schema('cartel').from('testimonials').insert({
        'client_name': profile?['full_name'] ?? 'Client CarTel',
        'location': profile?['country_id'] ?? 'Douala',
        'content': _commentController.text.trim(),
        'image_url': imageUrl,
        'stars': _rating,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ts.translate('thank_you_review'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ts.translate('error_prefix')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: backgroundColor.withOpacity(0.8),
            floating: true,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F).withOpacity(0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            title: Text(
              ts.translate('votre_experience'),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: borderColor.withOpacity(0.4),
                height: 1,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Icon Header
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.star_rounded, color: primaryColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ts.translate('partagez_avis'),
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ts.translate('avis_subtitle'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Vehicle Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor.withOpacity(0.6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: primaryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ts.translate('vehicule_livre'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                '${request['make']} ${request['model']}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '#${request['id'].toString().substring(0, 8).toUpperCase()} • 12 Oct 2023',
                                style: GoogleFonts.plusJakartaSans(
                                  color: mutedForeground,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Rating Section
                  Text(
                    ts.translate('notez_experience'),
                    style: GoogleFonts.plusJakartaSans(
                      color: mutedForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            index < _rating ? Icons.star_rounded : Icons.star_rounded,
                            color: index < _rating ? primaryColor : const Color(0xFF262626),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // Comment Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ts.translate('commentaire_label'),
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: ts.translate('commentaire_hint'),
                      hintStyle: GoogleFonts.plusJakartaSans(color: mutedForeground.withOpacity(0.3), fontSize: 14),
                      filled: true,
                      fillColor: cardColor.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Photo Upload
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      ts.translate('photo_vehicule'),
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: borderColor.withOpacity(0.6),
                            style: _imageFile == null ? BorderStyle.solid : BorderStyle.none,
                            width: 2,
                          ),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1F1F1F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_a_photo_rounded, color: mutedForeground),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    ts.translate('ajouter_photo'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ts.translate('photo_specs'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: mutedForeground,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _handleSubmit(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 10,
                        shadowColor: primaryColor.withOpacity(0.3),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ts.translate('publier_avis'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.send_rounded, size: 16),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
