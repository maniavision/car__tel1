import 'package:flutter/material.dart';
import 'package:car/pages/splash_page.dart';
import 'package:car/pages/language_selection_page.dart';
import 'package:car/pages/currency_selection_page.dart';
import 'package:car/pages/home_page.dart';

import 'package:car/pages/create_request_page.dart';
import 'package:car/pages/notifications_page.dart';
import 'package:car/pages/payment_page.dart';
import 'package:car/pages/payment_success_page.dart';
import 'package:car/pages/payment_failed_page.dart';
import 'package:car/pages/profile_page.dart';
import 'package:car/pages/requests_page.dart';
import 'package:car/pages/request_details_page.dart';
import 'package:car/pages/car_details_page.dart';
import 'package:car/pages/how_it_works_page.dart';
import 'package:car/pages/trending_cars_page.dart';
import 'package:car/pages/car_deals_page.dart';
import 'package:car/pages/signup_page.dart';
import 'package:car/pages/login_page.dart';
import 'package:car/pages/forgot_password_page.dart';
import 'package:car/pages/reset_password_page.dart';
import 'package:car/pages/leave_review_page.dart';
import 'package:car/pages/chat_page.dart';
import 'package:car/pages/help_center_page.dart';
import 'package:car/pages/privacy_policy_page.dart';
import 'package:car/services/translation_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://avcdscctujjkjmjjfvbm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2Y2RzY2N0dWpqa2ptampmdmJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjE1NzksImV4cCI6MjA5MDc5NzU3OX0.jpDryLmlUYMCIddv3kuFsJm1fSk4fa6G7iYosxwK2Nk',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      debugPrint('Auth event: $event');
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('Password recovery detected, navigating to /reset-password');
        // Add a small delay to ensure the navigator is ready during cold starts
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigatorKey.currentState?.pushNamed('/reset-password');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationService(),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'CarTel',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            primaryColor: const Color(0xFFD4AF37),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              secondary: Color(0xFF1A1A1A),
              surface: Color(0xFF111111),
            ),
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashPage(),
            '/language': (context) => const LanguageSelectionPage(),
            '/currency': (context) => const CurrencySelectionPage(),
            '/payment': (context) => const PaymentPage(),
            '/payment-success': (context) => const PaymentSuccessPage(),
            '/payment-failed': (context) => const PaymentFailedPage(),
            '/request-details': (context) => const RequestDetailsPage(),
            '/car-details': (context) => const CarDetailsPage(),
            '/how-it-works': (context) => const HowItWorksPage(),
            '/trending': (context) => const TrendingCarsPage(),
            '/deals': (context) => const CarDealsPage(),
            '/signup': (context) => const SignUpPage(),
            '/login': (context) => const LoginPage(),
            '/forgot-password': (context) => const ForgotPasswordPage(),
            '/reset-password': (context) => const ResetPasswordPage(),
            '/leave-review': (context) => const LeaveReviewPage(),
            '/chat': (context) => const ChatPage(),
            '/help-center': (context) => const HelpCenterPage(),
            '/privacy-policy': (context) => const PrivacyPolicyPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/create-request') {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (_, __, ___) => const CreateRequestPage(),
                transitionDuration: const Duration(milliseconds: 420),
                reverseTransitionDuration: const Duration(milliseconds: 320),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
              );
            }
            final tabPages = <String, Widget>{
              '/home': const HomePage(),
              '/requests': const RequestsPage(),
              '/notifications': const NotificationsPage(),
              '/profile': const ProfilePage(),
            };
            if (tabPages.containsKey(settings.name)) {
              return PageRouteBuilder(
                settings: settings,
                pageBuilder: (_, __, ___) => tabPages[settings.name]!,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            }
            return null;
          },
        );
      },
    );
  }
}
