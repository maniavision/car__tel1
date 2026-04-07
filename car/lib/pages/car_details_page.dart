import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';

class CarDetailsPage extends StatefulWidget {
  const CarDetailsPage({super.key});

  @override
  State<CarDetailsPage> createState() => _CarDetailsPageState();
}

class _CarDetailsPageState extends State<CarDetailsPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final ts = TranslationService();

    List<String> images = [];
    final rawImages = car['image_url'];
    if (rawImages is List) {
      images = List<String>.from(rawImages.map((e) => e.toString()));
    } else if (rawImages != null && rawImages.toString().isNotEmpty) {
      images = [rawImages.toString()];
    }

    if (images.isEmpty) {
      images = [
        'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/XSw5ckPj4Vj/components/Gm55R9qfDyr.png'
      ];
    }

    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const cardColor = Color(0xFF111111);
    const secondaryColor = Color(0xFF1A1A1A);
    const borderColor = Color(0xFF222222);
    const mutedForeground = Color(0xFF888888);

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Glow effects
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: 200,
                left: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildImageGallery(context, images, primaryColor),
                    _buildMainContent(car, ts, primaryColor, cardColor, secondaryColor, borderColor, mutedForeground),
                    const SizedBox(height: 140),
                  ],
                ),
              ),

              _buildHeader(context, primaryColor),
              _buildBottomActions(context, ts, primaryColor, secondaryColor, backgroundColor, car),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildHeaderButton(
              onTap: () => Navigator.pop(context),
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required VoidCallback onTap, required IconData icon, double iconSize = 24}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: iconSize)),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, List<String> images, Color primaryColor) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF1F1F1F),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1F1F1F),
                  child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40)),
                ),
              );
            },
          ),
          // Bottom overlay gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Indicators and arrows
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: List.generate(images.length, (index) {
                      return Container(
                        width: index == _currentImageIndex ? 24 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _currentImageIndex ? primaryColor : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    }),
                  ),
                ),
                // Arrow buttons
                Row(
                  children: [
                    _buildGalleryArrow(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (_currentImageIndex > 0) {
                          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildGalleryArrow(
                      icon: Icons.arrow_forward_ios_rounded,
                      onTap: () {
                        if (_currentImageIndex < images.length - 1) {
                          _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryArrow({required IconData icon, required VoidCallback onTap}) {
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
        child: Center(child: Icon(icon, color: Colors.white, size: 16)),
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> car, TranslationService ts, Color primaryColor, Color cardColor, Color secondaryColor, Color borderColor, Color mutedForeground) {
    final year = (ts.currentLanguage == 'English' ? (car['year_en'] ?? car['year']?.toString() ?? '') : (car['year_fr'] ?? car['year']?.toString() ?? '')).toString();
    final badge = car['badge']?.toString() ?? 'Exclusive';
    
    // Translation logic for fuel and transmission
    String fuelType = car['fuel_type'] ?? 'Petrol';
    if (fuelType.toLowerCase() == 'petrol') fuelType = ts.translate('fuel_petrol');
    else if (fuelType.toLowerCase() == 'diesel') fuelType = ts.translate('fuel_diesel');
    else if (fuelType.toLowerCase() == 'electric') fuelType = ts.translate('fuel_electric');
    else if (fuelType.toLowerCase() == 'hybrid') fuelType = ts.translate('fuel_hybrid');

    String transmission = car['transmission'] ?? 'Auto';
    if (transmission.toLowerCase() == 'auto') transmission = ts.translate('trans_auto');
    else if (transmission.toLowerCase() == 'manual') transmission = ts.translate('trans_manual');

    return Transform.translate(
      offset: const Offset(0, -32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Top Card
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildStatusBadge(badge.toUpperCase(), primaryColor, Colors.black),
                                const SizedBox(width: 8),
                                _buildStatusBadge('${year.isNotEmpty ? year : '2023'} ${ts.translate('model_label')}', Colors.white.withOpacity(0.05), mutedForeground, hasBorder: true),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              car['make'] ?? car['name'] ?? 'Mercedes-Benz',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                            ),
                            Text(
                              (car['model'] ?? 'G63 AMG Magno').toString().toUpperCase(),
                              style: GoogleFonts.montserrat(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ts.translate('pricing_from'),
                            style: GoogleFonts.dmSans(
                              color: mutedForeground,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: ts.formatPrice((car['price'] ?? 0).toDouble()).split(' ').first,
                                  style: GoogleFonts.montserrat(
                                    color: primaryColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: 'FCFA',
                                  style: GoogleFonts.dmSans(
                                    color: mutedForeground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(height: 1, color: Colors.white.withOpacity(0.05)),
                  const SizedBox(height: 32),
                  // Stats Grid
                  Row(
                    children: [
                      _buildQuickStat(Icons.speed_rounded, ts.translate('kilométrage'), car['mileage'] ?? '850 km', primaryColor, secondaryColor),
                      const SizedBox(width: 8),
                      _buildQuickStat(Icons.local_gas_station_rounded, ts.translate('énergie'), fuelType, primaryColor, secondaryColor),
                      const SizedBox(width: 8),
                      _buildQuickStat(Icons.settings_input_component_rounded, ts.translate('transmission'), transmission, primaryColor, secondaryColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color bgColor, Color textColor, {bool hasBorder = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: hasBorder ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label, String value, Color primaryColor, Color secondaryColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: secondaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor.withOpacity(0.7), size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF888888),
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color primaryColor, {bool showPulse = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showPulse) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: primaryColor.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          Icon(icon, color: primaryColor, size: 18),
        ],
      ),
    );
  }

  Widget _buildTechSpec(String label, String value, IconData icon, Color primaryColor, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, color: primaryColor.withOpacity(0.7), size: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF888888),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, TranslationService ts, Color primaryColor, Color secondaryColor, Color backgroundColor, Map<String, dynamic> car) {
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
            colors: [
              backgroundColor.withOpacity(0),
              backgroundColor.withOpacity(0.95),
              backgroundColor,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    '/create-request',
                    arguments: {
                      ...car,
                      'from_car_detail': true,
                    },
                  );
                },
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ts.translate('start_sourcing'),
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.auto_fix_high_rounded, color: Colors.black, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}