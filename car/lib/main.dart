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
import 'package:car/pages/leave_review_page.dart';
import 'package:car/pages/chat_page.dart';
import 'package:car/services/translation_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://avcdscctujjkjmjjfvbm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2Y2RzY2N0dWpqa2ptampmdmJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjE1NzksImV4cCI6MjA5MDc5NzU3OX0.jpDryLmlUYMCIddv3kuFsJm1fSk4fa6G7iYosxwK2Nk',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: TranslationService(),
      builder: (context, _) {
        return MaterialApp(
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
            '/create-request': (context) => const CreateRequestPage(),
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
            '/leave-review': (context) => const LeaveReviewPage(),
            '/chat': (context) => const ChatPage(),
          },
          onGenerateRoute: (settings) {
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
