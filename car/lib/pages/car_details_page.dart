import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  final ts = TranslationService();
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final bool isMatch = args['is_match'] == true;

    List<String> images = [];
    final rawImages = args['image_urls'] ?? args['image_url'];
    if (rawImages is List) {
      images = List<String>.from(rawImages.map((e) => e.toString()));
    } else if (rawImages != null && rawImages.toString().isNotEmpty) {
      images = [rawImages.toString()];
    }

    if (images.isEmpty) {
      images = [
        'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/CZTKBqqeLr7.png'
      ];
    }

    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildContent(args, primaryColor, borderColor, mutedForeground, isMatch, images),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
                _buildHeader(context, borderColor),
                _buildBottomActions(context, primaryColor, backgroundColor, isMatch, borderColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color borderColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderButton(
              onTap: () => Navigator.pop(context),
              icon: Icons.arrow_back_ios_new_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required VoidCallback onTap, required IconData icon, double size = 22}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: size)),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> car, Color primaryColor, Color borderColor, Color mutedForeground, bool isMatch, List<String> images) {
    final year = car['year']?.toString() ?? '2022';
    final make = car['make'] ?? car['name'] ?? 'Mercedes-Benz';
    final model = car['model'] ?? 'GLE 450';
    final mileage = car['mileage']?.toString() ?? '24.500';
    final engine = car['engine'] ?? 'V6 Turbo Hybride';
    final transmission = car['transmission'] ?? '9G-Tronic Auto';
    final exteriorColor = car['exterior_color'] ?? 'Silver Met.';
    final interiorColor = car['interior_color'] ?? 'Espresso Br.';

    final isDeal = car['is_deal'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainImage(car, images, primaryColor, isDeal),
          const SizedBox(height: 24),
          _buildThumbnails(images, primaryColor),
          const SizedBox(height: 48),
          
          // Title Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -2.0,
                        height: 0.9,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      make.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: mutedForeground,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ts.formatPrice((car['final_price'] ?? 0).toDouble()),
                      style: GoogleFonts.montserrat(
                        color: primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      ts.translate('prix_exportation').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: mutedForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          
          // Specs Section
          _buildSpecsHeader(ts.translate('fiche_technique'), primaryColor),
          const SizedBox(height: 24),
          _buildSpecRow(ts.translate('marque'), make, Icons.car_rental_rounded, primaryColor),
          _buildSpecRow(ts.translate('modele'), model, Icons.directions_car_rounded, primaryColor),
          _buildSpecRow(ts.translate('annee'), year, Icons.calendar_today_rounded, primaryColor),
          _buildSpecRow(ts.translate('kilometrage'), '$mileage KM', Icons.speed_rounded, primaryColor, isHighlight: true),
          _buildSpecRow(ts.translate('moteur'), engine, Icons.gas_meter_rounded, primaryColor),
          _buildSpecRow(ts.translate('boite'), transmission, Icons.settings_rounded, primaryColor),
          
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildColorSpec(ts.translate('peinture_ext'), exteriorColor, Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: _buildColorSpec(ts.translate('cuir_int'), interiorColor, const Color(0xFF3D2B1F))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage(Map<String, dynamic> car, List<String> images, Color primaryColor, bool isDeal) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 80,
              offset: const Offset(0, 40),
              spreadRadius: -15,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullScreenImage(context, images, index),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            if (isDeal)
              Positioned(
                top: 24,
                left: 24,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, color: primaryColor, size: 14),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${car['number_people_interested'] ?? 0} ${ts.translate('interested')}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavArrow(Icons.arrow_back_ios_new_rounded, () {
                      _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
                    }),
                    _buildNavArrow(Icons.arrow_forward_ios_rounded, () {
                      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
                    }),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(images.length, (index) {
                        final isSelected = index == _currentImageIndex;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isSelected ? 24 : 6,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildThumbnails(List<String> images, Color primaryColor) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final isSelected = index == _currentImageIndex;
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
            },
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSelected ? primaryColor : Colors.white.withOpacity(0.1), width: isSelected ? 2 : 1),
                boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)] : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Opacity(
                opacity: isSelected ? 1 : 0.4,
                child: Image.network(images[index], fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecsHeader(String title, Color primaryColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon, Color primaryColor, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlight ? primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: isHighlight ? primaryColor : Colors.white38, size: 20),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: isHighlight ? primaryColor : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSpec(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, Color primaryColor, Color backgroundColor, bool isMatch, Color borderColor) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final isDeal = args['is_deal'] == true;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [backgroundColor, backgroundColor.withOpacity(0)],
          ),
        ),
        child: SafeArea(
          child: isMatch
              ? Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF141414),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: const BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                              title: Text(
                                ts.translate('accepter_offre'),
                                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              content: Text(
                                ts.translate('confirm_accept_match_desc'),
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA3A3A3)),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(ts.translate('cancel'), style: const TextStyle(color: Color(0xFFA3A3A3))),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(ts.translate('accepter'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          setState(() => _isProcessing = true);
                          try {
                            final supabase = Supabase.instance.client;
                            final matchId = args['id'];
                            final requestId = args['request_id'];

                            if (requestId == null) throw 'Request ID missing';

                            // 1. Update the match status to Accepted
                            await supabase
                                .schema('cartel')
                                .from('matches')
                                .update({'status': 'Accepted'})
                                .eq('id', matchId);

                            // 2. Update the request status to Complete
                            await supabase
                                .schema('cartel')
                                .from('requests')
                                .update({
                                  'status': 'Complete',
                                })
                                .eq('id', requestId);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ts.translate('match_accepte_success')), backgroundColor: Colors.green),
                              );
                              Navigator.pop(context, true); // Pop back to request details
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${ts.translate('error')}: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isProcessing = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                        ),
                        child: _isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                ts.translate('accepter').toUpperCase(),
                                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                              ),
                      ),
                    ),
                  ],
                )
              : isDeal
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : () async {
                          setState(() => _isProcessing = true);
                          try {
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user == null) return;

                            final carDealId = args['car_deal_id'] ?? args['id'];
                            await Supabase.instance.client.schema('cartel').from('car_deal').update({
                              'number_people_interested': (args['number_people_interested'] ?? 0) + 1
                            }).eq('id', carDealId);

                            await Supabase.instance.client.schema('cartel').from('requests').insert({
                              'user_id': user.id,
                              'make': args['make'],
                              'model': args['model'],
                              'budget_min': args['price'],
                              'budget_max': args['final_price'],
                              'car_deal_id': carDealId,
                              'status': 'Initiated'
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Demande envoyée avec succès')),
                              );
                              Navigator.pushReplacementNamed(context, '/requests');
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isProcessing = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            else
                              const Icon(Icons.favorite_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              ts.translate('interested').toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-request');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              ts.translate('start_sourcing').toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _FullScreenImageViewer(images: images, initialIndex: initialIndex),
    );
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({required this.images, required this.initialIndex});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 60,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
