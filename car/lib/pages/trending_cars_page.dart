import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/services/translation_service.dart';

class TrendingCarsPage extends StatefulWidget {
  const TrendingCarsPage({super.key});

  @override
  State<TrendingCarsPage> createState() => _TrendingCarsPageState();
}

class _TrendingCarsPageState extends State<TrendingCarsPage> {
  final ts = TranslationService();
  String selectedFilter = 'all';
  List<Map<String, dynamic>> _trendingCars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrendingCars();
  }

  Future<void> _fetchTrendingCars() async {
    try {
      final response = await Supabase.instance.client
          .schema('cartel')
          .from('trending_cars')
          .select();
      
      if (mounted) {
        setState(() {
          _trendingCars = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredCars() {
    if (selectedFilter == 'all') return _trendingCars;
    return _trendingCars.where((car) {
      final type = car['type']?.toString().toLowerCase() ?? '';
      return type == selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const cardColor = Color(0xFF111111);
    const borderColor = Color(0xFF222222);
    const mutedForeground = Color(0xFF888888);

    final filters = [
      {'key': 'all', 'label': ts.translate('all')},
      {'key': 'suv', 'label': ts.translate('suv')},
      {'key': 'sports', 'label': ts.translate('sports')},
      {'key': 'sedan', 'label': ts.translate('sedan')},
    ];

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor.withOpacity(0.8),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            title: Text(
              ts.translate('trending_now').toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: borderColor,
                height: 1,
              ),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 24),
              // Filter Bar
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final filter = filters[index];
                    final isSelected = selectedFilter == filter['key'];
                    return GestureDetector(
                      onTap: () => setState(() => selectedFilter = filter['key']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(100),
                          border: isSelected ? null : Border.all(color: borderColor),
                        ),
                        child: Text(
                          filter['label']!.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Cars List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _getFilteredCars().isEmpty
                        ? Center(child: Text(ts.translate('no_trending_cars'), style: const TextStyle(color: mutedForeground)))
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                            itemCount: _getFilteredCars().length,
                            separatorBuilder: (context, index) => const SizedBox(height: 24),
                            itemBuilder: (context, index) {
                              final car = _getFilteredCars()[index];
                              
                              List<String> imageUrls = [];
                              final rawImages = car['image_url'];
                              if (rawImages is List) {
                                imageUrls = List<String>.from(rawImages.map((e) => e.toString()));
                              } else if (rawImages != null && rawImages.toString().isNotEmpty) {
                                imageUrls = [rawImages.toString()];
                              }

                              final year = (ts.currentLanguage == 'English' ? (car['year_en'] ?? car['year']?.toString() ?? '') : (car['year_fr'] ?? car['year']?.toString() ?? '')).toString();
                              
                              return TrendingCarCard(
                                car: car,
                                title: '${car['make'] ?? car['name'] ?? ''} ${car['model'] ?? ''}'.trim(),
                                subtitle: year.isNotEmpty ? '$year Model' : '',
                                price: ts.formatPrice((car['price'] ?? 0).toDouble()),
                                distance: car['mileage'] ?? '',
                                type: car['fuel_type'] ?? 'Petrol',
                                badge: car['badge'] ?? '',
                                imageUrls: imageUrls,
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                mutedForeground: mutedForeground,
                                isTransmission: car['transmission'] == 'Auto',
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TrendingCarCard extends StatefulWidget {
  final Map<String, dynamic> car;
  final String title;
  final String subtitle;
  final String price;
  final String distance;
  final String type;
  final String badge;
  final List<String> imageUrls;
  final Color primaryColor;
  final Color cardColor;
  final Color borderColor;
  final Color mutedForeground;
  final bool isTransmission;

  const TrendingCarCard({
    super.key,
    required this.car,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.distance,
    required this.type,
    required this.badge,
    required this.imageUrls,
    required this.primaryColor,
    required this.cardColor,
    required this.borderColor,
    required this.mutedForeground,
    this.isTransmission = false,
  });

  @override
  State<TrendingCarCard> createState() => _TrendingCarCardState();
}

class _TrendingCarCardState extends State<TrendingCarCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/car-details', arguments: widget.car);
      },
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: widget.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 240,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    child: widget.imageUrls.isEmpty
                        ? Container(
                            color: const Color(0xFF1F1F1F),
                            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40)),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            itemCount: widget.imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                widget.imageUrls[index],
                                fit: BoxFit.cover,
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
                  ),
                ),
                if (widget.badge.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        widget.badge.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: widget.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                if (widget.imageUrls.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(widget.imageUrls.length, (index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentPage == index ? 8 : 4,
                                height: _currentPage == index ? 8 : 4,
                                decoration: BoxDecoration(
                                  color: _currentPage == index ? widget.primaryColor : Colors.white.withOpacity(0.4),
                                  shape: BoxShape.circle,
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
            Padding(
              padding: const EdgeInsets.all(24),
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
                            Text(
                              widget.title,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle.toUpperCase(),
                              style: GoogleFonts.dmSans(
                                color: widget.mutedForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.price,
                          style: GoogleFonts.montserrat(
                            color: widget.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: widget.borderColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed_rounded, color: widget.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.distance,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isTransmission ? Icons.settings_input_component_rounded : Icons.local_gas_station_rounded,
                              color: widget.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.type,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
