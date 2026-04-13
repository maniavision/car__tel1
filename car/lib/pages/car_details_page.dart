import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
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
    final ts = TranslationService();

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
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    _buildContent(args, ts, primaryColor, borderColor, mutedForeground, isMatch, images),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
              _buildHeader(context, borderColor),
              _buildBottomActions(context, ts, primaryColor, backgroundColor, isMatch, borderColor),
            ],
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
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
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

  Widget _buildContent(Map<String, dynamic> car, TranslationService ts, Color primaryColor, Color borderColor, Color mutedForeground, bool isMatch, List<String> images) {
    final year = car['year']?.toString() ?? '2022';
    final make = car['make'] ?? car['name'] ?? 'Mercedes-Benz';
    final model = car['model'] ?? 'GLE 450';
    final mileage = car['mileage']?.toString() ?? '24.500';
    final engine = car['engine'] ?? 'V6 Turbo Hybride';
    final transmission = car['transmission'] ?? '9G-Tronic Auto';
    final exteriorColor = car['exterior_color'] ?? 'Silver Met.';
    final interiorColor = car['interior_color'] ?? 'Espresso Br.';
    final agentNotes = car['agent_notes'] ?? ts.translate('default_expertise_note');
    
    final agentData = car['agents'];
    final agentName = agentData?['name'] ?? 'Jean-Paul Moukoko';
    final agentAvatar = agentData?['avatar_url'] ?? 'https://randomuser.me/api/portraits/men/32.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMainImage(images, primaryColor),
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
                      ts.formatPrice((car['final_price'] ?? 0).toDouble()).replaceAll(' FCFA', 'M FCFA'),
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
          
          const SizedBox(height: 48),
          
          _buildAgentVerdict(agentName, agentAvatar, agentNotes, primaryColor, ts),
        ],
      ),
    );
  }

  Widget _buildMainImage(List<String> images, Color primaryColor) {
    return AspectRatio(
      aspectRatio: 1.6, // 16/10
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(48),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            // Navigation Arrows
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
            // Dots
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
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: Image.network(images[index], fit: BoxFit.cover),
                ),
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
        Text(
          title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.05))),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon, Color primaryColor, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: isHighlight
            ? Border.all(color: primaryColor.withOpacity(0.3))
            : Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: isHighlight ? primaryColor : primaryColor.withOpacity(0.7), size: 20),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFA3A3A3),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                color: isHighlight ? primaryColor : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSpec(String label, String value, Color colorDot) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFA3A3A3),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorDot,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgentVerdict(String name, String avatar, String notes, Color primaryColor, TranslationService ts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(0.1), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -16,
            right: -16,
            child: Opacity(
              opacity: 0.05,
              child: Icon(Icons.format_quote_rounded, size: 80, color: primaryColor),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                      image: DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VERDICT EXPERT',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Luxe & Performance',
                          style: GoogleFonts.plusJakartaSans(
                            color: primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '"$notes"',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleInterested(Map<String, dynamic> car) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Increment number_people_interested in cartel.car_deal
      await Supabase.instance.client
          .schema('cartel')
          .from('car_deal')
          .update({
            'number_people_interested': (car['number_people_interested'] ?? 0) + 1,
          })
          .eq('id', car['id']);

      // 2. Create a request in cartel.requests
      final price = (car['final_price'] ?? 0).toDouble();
      final data = {
        'user_id': user.id,
        'car_deal_id': car['id'],
        'make': car['make'] ?? 'Unknown',
        'model': car['model'] ?? 'Unknown',
        'year_min': car['year'],
        'year_max': car['year'],
        'budget_min': price,
        'budget_max': price,
        'mileage': car['mileage']?.toString() ?? '0',
        'currency': 'FCFA',
        'car_condition': 'Used',
        'exterior_color': car['exterior_color'],
        'status': 'initialisée',
        'payment_status': 'pending',
      };

      await Supabase.instance.client
          .schema('cartel')
          .from('requests')
          .insert(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request created! Redirecting to payment...'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamed(context, '/payment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildBottomActions(BuildContext context, TranslationService ts, Color primaryColor, Color backgroundColor, bool isMatch, Color borderColor) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final bool isDeal = args['is_deal'] == true;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, backgroundColor.withOpacity(0.95), backgroundColor],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, offset: const Offset(0, 25))],
          ),
          child: isMatch 
            ? Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.15),
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: Colors.green.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 20),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              ts.translate('accepter').toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: Colors.red.withOpacity(0.2)),
                        ),
                      ),
                      child: Text(
                        ts.translate('refuser').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : isDeal
              ? SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isProcessing ? null : () => _handleInterested(args),
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
                          'INTERESTED'.toUpperCase(),
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
