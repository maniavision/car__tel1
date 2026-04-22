import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'dart:async';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const HomePage({super.key, this.supabaseClient});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SupabaseClient get _supabase => widget.supabaseClient ?? Supabase.instance.client;
  late ScrollController _scrollController;
  late ScrollController _hotDealsScrollController;
  Timer? _timer;
  bool _isUserInteractingTrending = false;
  bool _isUserInteractingHotDeals = false;
  Timer? _resumeTrendingTimer;
  Timer? _resumeHotDealsTimer;
  List<Map<String, dynamic>> _trendingCars = [];
  List<Map<String, dynamic>> _hotDeals = [];
  List<Map<String, dynamic>> _testimonials = [];
  bool _isLoadingTrending = true;
  bool _isLoadingHotDeals = true;
  bool _isLoadingTestimonials = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _hotDealsScrollController = ScrollController();
    _fetchTrendingCars();
    _fetchHotDeals();
    _fetchTestimonials();
    _fetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  Future<void> _fetchTestimonials() async {
    try {
      // 1. Fetch testimonials
      final testimonialsResponse = await _supabase
          .schema('cartel')
          .from('testimonials')
          .select('*')
          .order('created_at', ascending: false)
          .limit(8);
      
      final List<Map<String, dynamic>> rawTestimonials = List<Map<String, dynamic>>.from(testimonialsResponse);
      
      if (rawTestimonials.isEmpty) {
        if (mounted) setState(() => _isLoadingTestimonials = false);
        return;
      }

      // 2. Extract unique locations (IDs)
      final List<String> locationIds = rawTestimonials
          .map((t) => t['location']?.toString())
          .where((loc) => loc != null && loc.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      Map<String, String> countryMap = {};
      
      if (locationIds.isNotEmpty) {
        // 3. Fetch country names
        final countriesResponse = await _supabase
            .schema('cartel')
            .from('country_calling_codes')
            .select('id, country_name')
            .inFilter('id', locationIds);
        
        for (var country in countriesResponse) {
          countryMap[country['id'].toString()] = country['country_name'].toString();
        }
      }

      // 4. Merge data
      final List<Map<String, dynamic>> mergedTestimonials = rawTestimonials.map((t) {
        final locId = t['location']?.toString();
        return {
          ...t,
          'display_location': (locId != null && countryMap.containsKey(locId)) 
              ? countryMap[locId] 
              : (locId ?? 'Unknown'),
        };
      }).toList();

      if (mounted) {
        setState(() {
          _testimonials = mergedTestimonials;
          _isLoadingTestimonials = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching testimonials: $e');
      if (mounted) {
        setState(() => _isLoadingTestimonials = false);
      }
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
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
      final response = await _supabase
          .schema('cartel')
          .from('car_deal')
          .select('*')
          .eq('status', 'Available')
          .order('created_at', ascending: true)
          .limit(15);
      
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
      final response = await _supabase
          .schema('cartel')
          .from('trending_cars')
          .select('*')
          .order('created_at', ascending: true);
      
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

  String _extractFirstUrl(dynamic raw) {
    if (raw == null) return '';
    if (raw is List) return raw.isNotEmpty ? raw[0].toString().trim() : '';
    final s = raw.toString().trim();
    if (s.startsWith('[')) {
      try {
        final list = jsonDecode(s) as List;
        return list.isNotEmpty ? list[0].toString().trim() : '';
      } catch (_) {}
    }
    if (s.startsWith('{') && s.endsWith('}')) {
      final inner = s.substring(1, s.length - 1);
      final parts = inner.split(',');
      return parts.isNotEmpty ? parts[0].trim().replaceAll('"', '') : '';
    }
    return s;
  }

  void _performAutoScroll(ScrollController controller) {
    double maxScroll = controller.position.maxScrollExtent;
    double currentScroll = controller.position.pixels;
    double nextScroll = currentScroll + 1.0;

    if (nextScroll >= maxScroll) {
      controller.jumpTo(0);
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
    final user = _supabase.auth.currentUser;

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
                              child: ListenableBuilder(
                                listenable: NotificationService(),
                                builder: (context, _) {
                                  final unreadCount = NotificationService().unreadCount;
                                  return Stack(
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
                                      if (unreadCount > 0)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: backgroundColor, width: 2),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
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
                                      ? CachedNetworkImage(
                                          imageUrl: _profileData?['avatar_url'] ?? user!.userMetadata!['avatar_url'] as String,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(child: CircularProgressIndicator(color: primaryColor)),
                                          errorWidget: (context, url, error) => Icon(Icons.person_rounded, color: primaryColor.withOpacity(0.5), size: 24),
                                        )
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
                            child: Opacity(
                              opacity: 0.6,
                              child: CachedNetworkImage(
                                imageUrl: 'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/XSw5ckPj4Vj/components/M1cNogNa5tI.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF1F1F1F),
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFF1F1F1F),
                                  child: const Center(child: Icon(Icons.image_rounded, color: Colors.white24, size: 40)),
                                ),
                              ),
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

                  // Note Logistique
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: primaryColor.withOpacity(0.1)),
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
                            child: const Icon(Icons.local_shipping_rounded, color: primaryColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ts.translate('note_logistique'),
                                  style: GoogleFonts.dmSans(
                                    color: primaryColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(text: '${ts.translate('shipping_fee_prefix')} '),
                                      TextSpan(
                                        text: ts.formatPrice(2700000),
                                        style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Frais de Douane
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Colors.redAccent, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ts.translate('customs_fees'),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.redAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ts.translate('customs_fees_msg'),
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/trending'),
                      child: Text(
                        ts.translate('view_all'),
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
                                  
                                  String imageUrl = _extractFirstUrl(car['image_url']);
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
                                    ts,
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
                          ts.translate('hot_deals'),
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
                        ts.translate('view_all'),
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
                              
                              String imageUrl = _extractFirstUrl(car['image_urls']);
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
                                '${car['mileage'] ?? 0} ${ts.translate('kilometers')}',
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
              if (_testimonials.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    ts.translate('experiences_clients'),
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: _testimonials.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final t = _testimonials[index];
                      return Container(
                        width: MediaQuery.of(context).size.width - 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: borderColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            if (t['image_url'] != null)
                              CachedNetworkImage(
                                imageUrl: t['image_url'],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFF1F1F1F),
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFF1F1F1F),
                                  child: const Center(child: Icon(Icons.image_rounded, color: Colors.white24, size: 40)),
                                ),
                              )
                            else
                              Container(
                                color: const Color(0xFF1F1F1F),
                                width: double.infinity,
                                height: double.infinity,
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
                                    '"${t['content']}"',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(5, (index) {
                                      final starCount = t['stars'] ?? 5;
                                      return Icon(
                                        index < starCount ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: index < starCount ? primaryColor : Colors.white24,
                                        size: 14,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF1F1F1F),
                                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                                        ),
                                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${t['client_name']}, ${t['display_location']}',
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
                      );
                    },
                  ),
                ),
              ],
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
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: const Color(0xFF1F1F1F),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: const Color(0xFF1F1F1F),
                      child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40)),
                    ),
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
                          '$interestedCount ${ts.translate('interested')}',
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
                        year,
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
    TranslationService ts,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/car-details', arguments: {
          ...car,
          'is_match': false,
          'condition': 'New',
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
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: const Color(0xFF1F1F1F),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
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
                        year,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ts.translate('starting_from').toUpperCase(),
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF888888),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              price,
                              style: GoogleFonts.montserrat(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
