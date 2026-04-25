import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/signup_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/services/stripe_service.dart';
import '../mocks.dart';

class MockHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}
class MockHttpHeaders extends Mock implements HttpHeaders {}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return createMockHttpClient();
  }
}

HttpClient createMockHttpClient() {
  final client = MockHttpClient();
  final request = MockHttpClientRequest();
  final response = MockHttpClientResponse();
  final headers = MockHttpHeaders();

  when(() => client.getUrl(any())).thenAnswer((_) async => request);
  when(() => request.headers).thenReturn(headers);
  when(() => request.close()).thenAnswer((_) async => response);
  when(() => response.statusCode).thenReturn(200);
  when(() => response.contentLength).thenReturn(transparentImage.length);
  when(() => response.compressionState).thenReturn(HttpClientResponseCompressionState.notCompressed);
  
  final stream = Stream.fromIterable([transparentImage]);
  when(() => response.listen(any(),
      onDone: any(named: 'onDone'),
      onError: any(named: 'onError'),
      cancelOnError: any(named: 'cancelOnError'))).thenAnswer((invocation) {
    final onData = invocation.positionalArguments[0] as void Function(List<int>)?;
    final onDone = invocation.namedArguments[#onDone] as void Function()?;
    final onError = invocation.namedArguments[#onError] as Function?;
    final cancelOnError = invocation.namedArguments[#cancelOnError] as bool?;
    
    return stream.listen(onData, onDone: onDone, onError: onError, cancelOnError: cancelOnError);
  });
  return client;
}

final transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

void main() {
  HttpOverrides.global = MyHttpOverrides();

  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockTranslationService mockTS;
  late MockNotificationService mockNS;
  late MockStripeService mockSS;
  late StreamController<AuthState> authStateController;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(OAuthProvider.google);
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final widgetTester = TestWidgetsFlutterBinding.instance;
    widgetTester.platformDispatcher.implicitView!.physicalSize = const Size(800 * 3, 1200 * 3);
    widgetTester.platformDispatcher.implicitView!.devicePixelRatio = 3.0;

    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockTS = MockTranslationService();
    mockNS = MockNotificationService();
    mockSS = MockStripeService();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => authStateController.stream);
    
    TranslationService.setMockInstance(mockTS);
    NotificationService.setMockInstance(mockNS);
    StripeService.setMockInstance(mockSS);

    // Default translations
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);

    // Mock country fetch
    final mockSchema = MockSupabaseQuerySchema();
    final mockBuilder = MockSupabaseQueryBuilder();
    
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);
    when(() => mockSchema.from('country_calling_codes')).thenAnswer((_) => mockBuilder);
    mockSupabaseQuery(mockBuilder, [
      {'id': 1, 'country_name': 'Cameroon', 'calling_code': '+237'}
    ]);
  });

  tearDown(() {
    authStateController.close();
  });

  testWidgets('SignUpPage shows input fields', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        home: SignUpPage(supabaseClient: mockClient),
      ));

      expect(find.text('full_name'.toUpperCase()), findsOneWidget);
      expect(find.text('email'.toUpperCase()), findsOneWidget);
      expect(find.text('password'.toUpperCase()), findsOneWidget);
      expect(find.text('phone_number'.toUpperCase()), findsOneWidget);
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('Validation shows snackbars', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        home: SignUpPage(supabaseClient: mockClient),
      ));

      // Tap Sign Up without filling anything
      final signUpButton = find.text('create_account_btn').first;
      await tester.ensureVisible(signUpButton);
      await tester.tap(signUpButton);
      await tester.pump();

      expect(find.text('select_country_error'), findsOneWidget);
    }, createHttpClient: (context) => createMockHttpClient());
  });
}
