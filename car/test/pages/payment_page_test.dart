import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/payment_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/stripe_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockTranslationService mockTS;
  late MockUser mockUser;
  late MockFunctionsClient mockFunctions;
  late MockStripeService mockStripeService;
  late MockSupabaseQuerySchema mockSchema;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockTS = MockTranslationService();
    mockUser = MockUser();
    mockFunctions = MockFunctionsClient();
    mockStripeService = MockStripeService();
    mockSchema = MockSupabaseQuerySchema();

    when(() => mockClient.auth).thenAnswer((_) => mockAuth);
    when(() => mockAuth.currentUser).thenAnswer((_) => mockUser);
    when(() => mockUser.id).thenReturn('user-123');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockClient.functions).thenAnswer((_) => mockFunctions);

    TranslationService.setMockInstance(mockTS);
    StripeService.setMockInstance(mockStripeService);
    Stripe.publishableKey = 'pk_test_123';
    
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.formatPrice(any())).thenAnswer((invoc) => invoc.positionalArguments[0].toString());
    when(() => mockTS.currentCurrency).thenReturn('FCFA');
    when(() => mockTS.currentLanguage).thenReturn('English');
    
    when(() => mockStripeService.initialize()).thenAnswer((_) async {});
  });

  Widget createWidget({Map<String, dynamic>? args}) {
    return MediaQuery(
      data: const MediaQueryData(size: Size(800, 1200)),
      child: MaterialApp(
        onGenerateRoute: (settings) {
          if (settings.name == '/payment-success') {
            return MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Success Page')));
          }
          return MaterialPageRoute(
            settings: RouteSettings(arguments: args),
            builder: (_) => PaymentPage(supabaseClient: mockClient),
          );
        },
        initialRoute: '/',
      ),
    );
  }

  testWidgets('PaymentPage renders request summary correctly', (WidgetTester tester) async {
    final requestArgs = {
      'id': 'req-1',
      'make': 'Mercedes',
      'model': 'GLE 450',
    };

    await tester.pumpWidget(createWidget(args: requestArgs));
    await tester.pump();
    
    expect(find.text('search_summary'), findsOneWidget);
    expect(find.text('30000.0'), findsOneWidget);
    expect(find.text('Stripe'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('PaymentPage shows empty state if no request args', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget(args: null));
    await tester.pump();
    
    // It should still render the basic structure but maybe not the details
    expect(find.text('paiement'), findsOneWidget);
  });

  testWidgets('PaymentPage shows loading state when Pay button is pressed', (WidgetTester tester) async {
    final requestArgs = {
      'id': 'req-1',
      'make': 'Mercedes',
      'model': 'GLE 450',
    };

    // Mock functions invoke for payment intent
    when(() => mockFunctions.invoke(
      'stripe-payment',
      body: any(named: 'body'),
    )).thenAnswer((_) async => FunctionResponse(
      data: {'id': 'pi_123', 'client_secret': 'secret_123'},
      status: 200,
    ));

    // Mock profile fetch
    final mockProfiles = MockSupabaseQueryBuilder();
    when(() => mockClient.schema('cartel')).thenAnswer((_) => mockSchema);
    when(() => mockSchema.from('profiles')).thenAnswer((_) => mockProfiles);
    mockSupabaseQuery(mockProfiles, {'full_name': 'Test User'});

    await tester.pumpWidget(createWidget(args: requestArgs));
    await tester.pump();

    // Ensure button is visible before tapping
    final buttonFinder = find.byType(ElevatedButton);
    await tester.ensureVisible(buttonFinder);
    await tester.pump();

    // Tap Pay button
    await tester.tap(buttonFinder);
    await tester.pump(); // Start animation/loading

    // It moves fast because mocks are immediate
    // Let's check for one of the messages
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // We can't easily test all intermediate states because they happen in one go
    // But we should at least see the loading indicator while it's processing
    
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // After it fails (due to unmocked platform channel), it should show an error
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('PaymentPage handle back button', (WidgetTester tester) async {
    final requestArgs = {'id': 'req-1'};

    await tester.pumpWidget(MaterialApp(
      home: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  settings: RouteSettings(arguments: requestArgs),
                  builder: (_) => PaymentPage(supabaseClient: mockClient),
                ),
              ),
              child: const Text('Go to Payment'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Go to Payment'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentPage), findsOneWidget);

    final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.byType(PaymentPage), findsNothing);
  });
}
