import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:car/services/translation_service.dart';

class CarDealsPage extends StatefulWidget {
  const CarDealsPage({super.key});

  @override
  State<CarDealsPage> createState() => _CarDealsPageState();
}

class _CarDealsPageState extends State<CarDealsPage> {
  final ts = TranslationService();
  List<Map<String, dynamic>> _carDeals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCarDeals();
  }

  Future<void> _fetchCarDeals() async {
    try {
      final response = await Supabase.instance.client
          .schema('cartel')
          .from('car_deal')
          .select('*')
          .eq('status', 'Available')
          .order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _carDeals = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const cardColor = Color(0xFF111111);
    const borderColor = Color(0xFF222222);
    const mutedForeground = Color(0xFF888888);

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
              ts.translate('hot_deals'),
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: borderColor,
                height: 1,
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : _carDeals.isEmpty
                  ? Center(child: Text(ts.translate('no_deals_available'), style: const TextStyle(color: mutedForeground)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      itemCount: _carDeals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final car = _carDeals[index];
                        
                        List<String> images = [];
                        final rawImages = car['image_urls'];
                        if (rawImages is List) {
                          images = List<String>.from(rawImages.map((e) => e.toString()));
                        }
                        
                        if (images.isEmpty) {
                          images = ['https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/CZTKBqqeLr7.png'];
                        }

                        final double finalPrice = (car['final_price'] ?? 0).toDouble();
                        final double oldPrice = finalPrice / 0.92;
                        final year = car['year']?.toString() ?? '';

                        return CarDealGridCard(
                          car: car,
                          title: '${car['make']} ${car['model']}',
                          price: ts.formatPrice(finalPrice),
                          oldPrice: ts.formatPrice(oldPrice),
                          distance: '${car['mileage'] ?? 0} ${ts.translate('kilometers')}',
                          year: year,
                          images: images,
                          primaryColor: primaryColor,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          mutedForeground: mutedForeground,
                          ts: ts,
                          onRefresh: _fetchCarDeals,
                        );
                      },
                    ),
        );
      },
    );
  }
}

class CarDealGridCard extends StatefulWidget {
  final Map<String, dynamic> car;
  final String title;
  final String price;
  final String oldPrice;
  final String distance;
  final String year;
  final List<String> images;
  final Color primaryColor;
  final Color cardColor;
  final Color borderColor;
  final Color mutedForeground;
  final TranslationService ts;
  final VoidCallback onRefresh;

  const CarDealGridCard({
    super.key,
    required this.car,
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.distance,
    required this.year,
    required this.images,
    required this.primaryColor,
    required this.cardColor,
    required this.borderColor,
    required this.mutedForeground,
    required this.ts,
    required this.onRefresh,
  });

  @override
  State<CarDealGridCard> createState() => _CarDealGridCardState();
}

class _CarDealGridCardState extends State<CarDealGridCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int interestedCount = widget.car['number_people_interested'] ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/car-details', arguments: {
          ...widget.car,
          'is_match': false,
          'is_deal': true,
        });
        widget.onRefresh();
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
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) => setState(() => _currentPage = page),
                      itemCount: widget.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFF1F1F1F),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1F1F1F),
                            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40)),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          '$interestedCount ${widget.ts.translate('interested')}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.year.isNotEmpty)
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
                        widget.year,
                        style: GoogleFonts.dmSans(
                          color: widget.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                if (widget.images.length > 1)
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
                            children: List.generate(widget.images.length, (index) {
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
                  Text(
                    widget.title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.price,
                            style: GoogleFonts.dmSans(
                              color: widget.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.oldPrice,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF990000),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: Color(0xFF888888), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            widget.distance,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF888888),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
