import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/splash_page.dart';
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

class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  HttpOverrides.global = MyHttpOverrides();

  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockTranslationService mockTS;
  late MockNotificationService mockNS;
  late MockStripeService mockSS;

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

    when(() => mockClient.auth).thenReturn(mockAuth);
    
    TranslationService.setMockInstance(mockTS);
    NotificationService.setMockInstance(mockNS);
    StripeService.setMockInstance(mockSS);
  });

  testWidgets('SplashPage shows logo and prestige button', (WidgetTester tester) async {
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        home: SplashPage(supabaseClient: mockClient),
      ));

      expect(find.text('CURATING EXCELLENCE'), findsOneWidget);
      expect(find.text('ENTER PRESTIGE'), findsOneWidget);
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('SplashPage navigates to /language when no session', (WidgetTester tester) async {
    final mockAuth = MockGoTrueClient();
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockClient.auth).thenReturn(mockAuth);

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        routes: {
          '/language': (context) => const Scaffold(body: Text('Language Page')),
        },
        home: SplashPage(supabaseClient: mockClient),
      ));

      await tester.tap(find.text('ENTER PRESTIGE'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Language Page'), findsOneWidget);
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('SplashPage navigates to /home when session exists', (WidgetTester tester) async {
    final mockSession = MockSession();
    final mockAuth = MockGoTrueClient(); // Create new mock to be safe
    when(() => mockAuth.currentSession).thenReturn(mockSession);
    when(() => mockClient.auth).thenReturn(mockAuth);
    
    when(() => mockNS.init()).thenAnswer((_) async => {});
    when(() => mockSS.initialize()).thenAnswer((_) async => {});
    when(() => mockTS.loadUserPreferences()).thenAnswer((_) async => {});

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        routes: {
          '/home': (context) => const Scaffold(body: Text('Home Page')),
        },
        home: SplashPage(supabaseClient: mockClient),
      ));

      await tester.tap(find.text('ENTER PRESTIGE'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home Page'), findsOneWidget);
      verify(() => mockNS.init()).called(1);
      verify(() => mockSS.initialize()).called(1);
      verify(() => mockTS.loadUserPreferences()).called(1);
    }, createHttpClient: (context) => createMockHttpClient());
  });
}
