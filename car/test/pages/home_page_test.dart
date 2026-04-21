import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/home_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
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
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final widgetTester = TestWidgetsFlutterBinding.instance;
    widgetTester.platformDispatcher.implicitView!.physicalSize = const Size(1200, 2000);
    widgetTester.platformDispatcher.implicitView!.devicePixelRatio = 1.0;

    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockTS = MockTranslationService();
    mockNS = MockNotificationService();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');
    
    TranslationService.setMockInstance(mockTS);
    NotificationService.setMockInstance(mockNS);
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.formatPrice(any())).thenAnswer((invoc) => invoc.positionalArguments[0].toString());
    when(() => mockTS.currentLanguage).thenReturn('Français');
    when(() => mockTS.currentCurrency).thenReturn('FCFA');
    when(() => mockNS.unreadCount).thenReturn(0);

    // Mock queries
    final mockSchema = MockSupabaseQuerySchema();
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);

    final mockTestimonialsBuilder = MockSupabaseQueryBuilder();
    when(() => mockSchema.from('testimonials')).thenAnswer((_) => mockTestimonialsBuilder);
    mockSupabaseQuery(mockTestimonialsBuilder, [
      {'id': 1, 'content': 'Great service!', 'location': '1', 'name': 'John Doe', 'avatar_url': null}
    ]);

    final mockCountriesBuilder = MockSupabaseQueryBuilder();
    when(() => mockSchema.from('country_calling_codes')).thenAnswer((_) => mockCountriesBuilder);
    mockSupabaseQuery(mockCountriesBuilder, [
      {'id': 1, 'country_name': 'Cameroon'}
    ]);

    final mockProfilesBuilder = MockSupabaseQueryBuilder();
    when(() => mockSchema.from('profiles')).thenAnswer((_) => mockProfilesBuilder);
    mockSupabaseQuery(mockProfilesBuilder, {'full_name': 'Fortune Niama', 'avatar_url': null});

    final mockHotDealsBuilder = MockSupabaseQueryBuilder();
    when(() => mockSchema.from('car_deal')).thenAnswer((_) => mockHotDealsBuilder);
    mockSupabaseQuery(mockHotDealsBuilder, [
      {'id': 1, 'make': 'Toyota', 'model': 'Corolla', 'price': 18500000, 'old_price': 22000000, 'image_url': 'https://example.com/car.png', 'status': 'Available'}
    ]);

    final mockTrendingBuilder = MockSupabaseQueryBuilder();
    when(() => mockSchema.from('trending_cars')).thenAnswer((_) => mockTrendingBuilder);
    mockSupabaseQuery(mockTrendingBuilder, [
      {'id': 1, 'make': 'Mercedes', 'model': 'G63', 'price': 185000000, 'image_url': 'https://example.com/g63.png'}
    ]);
  });

  testWidgets('HomePage renders starting_from label in trending cards', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        home: HomePage(supabaseClient: mockClient),
      ));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      verify(() => mockTS.translate('starting_from')).called(greaterThanOrEqualTo(1));
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('HomePage renders sections', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        home: HomePage(supabaseClient: mockClient),
      ));
      
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('TRENDING_NOW'), findsOneWidget);
      expect(find.text('HOT_DEALS'), findsOneWidget);
      expect(find.text('EXPERIENCES_CLIENTS'), findsOneWidget);
      expect(find.text('Fortune Niama'), findsOneWidget);
    }, createHttpClient: (context) => createMockHttpClient());
  });
}
