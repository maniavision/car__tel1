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
  Timer? _timer;
  List<Map<String, dynamic>> _trendingCars = [];
  bool _isLoadingTrending = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchTrendingCars();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        double nextScroll = currentScroll - 1.0;

        if (nextScroll <= 0) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.jumpTo(nextScroll);
        }
      }
    });
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
                      ts.translate('trending_now'),
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/trending'),
                      child: Text(
                        ts.translate('view_all'),
                        style: GoogleFonts.dmSans(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 260,
                child: _isLoadingTrending
                    ? const Center(child: CircularProgressIndicator(color: primaryColor))
                    : _trendingCars.isEmpty
                        ? Center(child: Text(ts.translate('no_trending_cars'), style: TextStyle(color: mutedForeground)))
                        : ListView.separated(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _trendingCars.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final car = _trendingCars[index];
                              
                              // Handle potential list for image_url
                              String imageUrl = '';
                              final rawImage = car['image_url'];
                              if (rawImage is List && rawImage.isNotEmpty) {
                                imageUrl = rawImage[0].toString();
                              } else {
                                imageUrl = rawImage?.toString() ?? '';
                              }

                              final year = (ts.currentLanguage == 'English' ? (car['year_en'] ?? car['year']?.toString() ?? '') : (car['year_fr'] ?? car['year']?.toString() ?? '')).toString();
                              
                              return _buildCarCard(
                                context,
                                car,
                                '${car['make'] ?? car['name'] ?? ''} ${car['model'] ?? ''}'.trim(),
                                ts.formatPrice((car['price'] ?? 0).toDouble()),
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

              const SizedBox(height: 32),

              // Testimonial Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  ts.translate('experiences_clients'),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  height: 256,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: cardColor,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.network(
                          'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/XSw5ckPj4Vj/components/7tAvnT4URpv.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.9), Colors.transparent],
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
                            Row(
                              children: List.generate(
                                  5, (index) => const Icon(Icons.star_rounded, color: primaryColor, size: 16)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ts.translate('testimonial_text'),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '— JEAN-PAUL M., ABIDJAN',
                              style: GoogleFonts.dmSans(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
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
        Navigator.pushNamed(context, '/car-details', arguments: car);
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
