import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  late ScrollController _hotDealsScrollController;
  Timer? _timer;
  bool _isUserInteractingTrending = false;
  bool _isUserInteractingHotDeals = false;
  Timer? _resumeTrendingTimer;
  Timer? _resumeHotDealsTimer;
  List<Map<String, dynamic>> _trendingCars = [];
  List<Map<String, dynamic>> _hotDeals = [];
  bool _isLoadingTrending = true;
  bool _isLoadingHotDeals = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _hotDealsScrollController = ScrollController();
    _fetchTrendingCars();
    _fetchHotDeals();
    _fetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .schema('cartel')
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _profileData = response;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _fetchHotDeals() async {
    try {
      final response = await Supabase.instance.client
          .schema('cartel')
          .from('car_deal')
          .select()
          .eq('status', 'Available')
          .order('created_at', ascending: false)
          .limit(10);
      
      if (mounted) {
        setState(() {
          _hotDeals = List<Map<String, dynamic>>.from(response);
          _isLoadingHotDeals = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching hot deals: $e');
      if (mounted) {
        setState(() => _isLoadingHotDeals = false);
      }
    }
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
          _isLoadingTrending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTrending = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTrendingTimer?.cancel();
    _resumeHotDealsTimer?.cancel();
    _scrollController.dispose();
    _hotDealsScrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients && !_isUserInteractingTrending) {
        _performAutoScroll(_scrollController);
      }
      if (_hotDealsScrollController.hasClients && !_isUserInteractingHotDeals) {
        _performAutoScroll(_hotDealsScrollController);
      }
    });
  }

  void _performAutoScroll(ScrollController controller) {
    double maxScroll = controller.position.maxScrollExtent;
    double currentScroll = controller.position.pixels;
    double nextScroll = currentScroll - 1.0;

    if (nextScroll <= 0) {
      controller.jumpTo(maxScroll);
    } else {
      controller.jumpTo(nextScroll);
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

    final ts = TranslationService();
    final user = Supabase.instance.client.auth.currentUser;

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          extendBody: true,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ts.translate('welcome_back'),
                              style: GoogleFonts.dmSans(
                                color: mutedForeground,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _profileData?['full_name'] ?? user?.userMetadata?['full_name'] ?? 'Fortune Niama',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/notifications'),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: secondaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: backgroundColor, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                                  color: secondaryColor,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: (_profileData?['avatar_url'] ?? user?.userMetadata?['avatar_url']) != null
                                      ? Image.network(_profileData?['avatar_url'] ?? user!.userMetadata!['avatar_url'], fit: BoxFit.cover)
                                      : Icon(Icons.person_rounded, color: primaryColor.withOpacity(0.5), size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hero Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      height: 192,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: primaryColor.withOpacity(0.1),
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.network(
                              'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/XSw5ckPj4Vj/components/M1cNogNa5tI.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.6),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ts.translate('hero_title'),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ts.translate('hero_subtitle'),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nouveau ici ?
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/how-it-works');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.help_center_rounded, color: primaryColor, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ts.translate('nouveau_ici'),
                                    style: GoogleFonts.dmSans(
                                      color: primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    ts.translate('comment_ca_marche'),
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: mutedForeground, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 32),

              // Trending Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ts.translate('trending_now').toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/trending'),
                      child: Text(
                        ts.translate('view_all').toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 280,
                child: _isLoadingTrending
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _trendingCars.isEmpty
                        ? Center(child: Text(ts.translate('no_trending_cars'), style: TextStyle(color: mutedForeground)))
                        : NotificationListener<UserScrollNotification>(
                            onNotification: (notification) {
                              setState(() => _isUserInteractingTrending = true);
                              _resumeTrendingTimer?.cancel();
                              _resumeTrendingTimer = Timer(const Duration(seconds: 3), () {
                                if (mounted) setState(() => _isUserInteractingTrending = false);
                              });
                              return false;
                            },
                            child: ListView.separated(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: _trendingCars.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 16),
                                itemBuilder: (context, index) {
                                  final car = _trendingCars[index];
                                  
                                  String imageUrl = '';
                                  final rawImage = car['image_url'];
                                  if (rawImage is List && rawImage.isNotEmpty) {
                                    imageUrl = rawImage[0].toString();
                                  } else {
                                    imageUrl = rawImage?.toString() ?? '';
                                  }

                                  if (imageUrl.isEmpty) {
                                    imageUrl = 'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/CZTKBqqeLr7.png';
                                  }

                                  final year = (ts.currentLanguage == 'English' ? (car['year_en'] ?? car['year']?.toString() ?? '') : (car['year_fr'] ?? car['year']?.toString() ?? '')).toString();
                                  
                                  return _buildCarCard(
                                    context,
                                    car,
                                    '${car['make'] ?? car['name'] ?? ''} ${car['model'] ?? ''}'.trim(),
                                    ts.formatPrice((car['final_price'] ?? 0).toDouble()),
                                    car['mileage'] ?? '',
                                    year,
                                    imageUrl,
                                    primaryColor,
                                    cardColor,
                                    borderColor,
                                  );
                                },
                              ),
                        ),
              ),

              const SizedBox(height: 40),

              // Hot Deals Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fireplace_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          ts.translate('hot_deals').toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/deals'),
                      child: Text(
                        ts.translate('voir_tout').toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 280,
                child: _isLoadingHotDeals
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : NotificationListener<UserScrollNotification>(
                        onNotification: (notification) {
                          setState(() => _isUserInteractingHotDeals = true);
                          _resumeHotDealsTimer?.cancel();
                          _resumeHotDealsTimer = Timer(const Duration(seconds: 3), () {
                            if (mounted) setState(() => _isUserInteractingHotDeals = false);
                          });
                          return false;
                        },
                        child: ListView.separated(
                            controller: _hotDealsScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _hotDeals.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final car = _hotDeals[index];
                              
                              String imageUrl = '';
                              final rawImages = car['image_urls'];
                              if (rawImages is List && rawImages.isNotEmpty) {
                                imageUrl = rawImages[0].toString();
                              }
                              
                              if (imageUrl.isEmpty) {
                                imageUrl = 'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/CZTKBqqeLr7.png';
                              }

                              final double finalPrice = (car['final_price'] ?? 0).toDouble();
                              final double oldPrice = finalPrice / 0.92;

                              return _buildHotDealCard(
                                context,
                                car,
                                '${car['make']} ${car['model']}',
                                ts.formatPrice(finalPrice),
                                ts.formatPrice(oldPrice),
                                '${car['mileage'] ?? 0} KM',
                                car['year']?.toString() ?? '',
                                imageUrl,
                                primaryColor,
                                cardColor,
                                borderColor,
                                ts,
                              );
                            },
                          ),
                    ),
              ),

              const SizedBox(height: 40),

              // Testimonial Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  ts.translate('experiences_clients').toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.network(
                        'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/XSw5ckPj4Vj/components/7tAvnT4URpv.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1F1F1F),
                          child: const Center(child: Icon(Icons.image_rounded, color: Colors.white24, size: 40)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.9), Colors.black.withOpacity(0.4), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ts.translate('testimonial_text'),
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                                    image: const DecorationImage(
                                      image: NetworkImage('https://randomuser.me/api/portraits/men/44.jpg'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'ALPHONSE M., DOUALA',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
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
              ),
              const SizedBox(height: 120),

            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushReplacementNamed(context, '/requests');
          if (index == 2) Navigator.pushReplacementNamed(context, '/notifications');
          if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
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

  Widget _buildHotDealCard(
    BuildContext context,
    Map<String, dynamic> car,
    String title,
    String price,
    String oldPrice,
    String distance,
    String year,
    String imageUrl,
    Color primaryColor,
    Color cardColor,
    Color borderColor,
    TranslationService ts,
  ) {
    final int interestedCount = car['number_people_interested'] ?? 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/car-details', arguments: {
          ...car,
          'is_match': false,
          'is_deal': true,
        });
        _fetchHotDeals();
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline_rounded, color: Colors.white, size: 10),
                        const SizedBox(width: 4),
                        Text(
                          '$interestedCount INTERESTED',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (year.isNotEmpty)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        year.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
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
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            price,
                            style: GoogleFonts.dmSans(
                              color: primaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (oldPrice.isNotEmpty)
                            Text(
                              oldPrice,
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF990000),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: Color(0xFF888888), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF888888),
                              fontSize: 11,
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

  Widget _buildCarCard(
    BuildContext context,
    Map<String, dynamic> car,
    String title,
    String price,
    String distance,
    String year,
    String imageUrl,
    Color primaryColor,
    Color cardColor,
    Color borderColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/car-details', arguments: {
          ...car,
          'is_match': false,
        });
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: const Color(0xFF1F1F1F),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      color: const Color(0xFF1F1F1F),
                      child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40)),
                    ),
                  ),
                ),
                if (year.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        year.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          price,
                          style: GoogleFonts.dmSans(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.speed_rounded, color: Color(0xFF888888), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF888888),
                              fontSize: 11,
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
