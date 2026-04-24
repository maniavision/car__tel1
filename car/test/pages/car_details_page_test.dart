import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/car_details_page.dart';
import 'package:car/services/translation_service.dart';
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
  late MockUser mockUser;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    final widgetTester = TestWidgetsFlutterBinding.instance;
    widgetTester.platformDispatcher.implicitView!.physicalSize = const Size(800 * 3, 1200 * 3);
    widgetTester.platformDispatcher.implicitView!.devicePixelRatio = 3.0;

    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockTS = MockTranslationService();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-123');
    
    TranslationService.setMockInstance(mockTS);
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.formatPrice(any())).thenAnswer((invoc) => invoc.positionalArguments[0].toString());
  });

  testWidgets('CarDetailsPage renders car info', (WidgetTester tester) async {
    final carArgs = {
      'id': 'car-123',
      'make': 'Mercedes',
      'model': 'G63 AMG',
      'price': 185000000,
      'image_url': 'https://example.com/g63.png',
      'is_match': false,
      'is_deal': true,
    };

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(arguments: carArgs),
            builder: (_) => CarDetailsPage(supabaseClient: mockClient),
          );
        },
      ));
      
      await tester.pump();

      expect(find.text('Mercedes').first, findsOneWidget);
      expect(find.text('G63 AMG').first, findsOneWidget);
      expect(find.text('INTERESTED'), findsOneWidget);
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('CarDetailsPage renders price_label for non-deal (trending) car', (WidgetTester tester) async {
    final carArgs = {
      'id': 'car-456',
      'make': 'Mercedes',
      'model': 'G63 AMG',
      'final_price': 185000000,
      'image_url': 'https://example.com/g63.png',
      'is_match': false,
      'is_deal': false,
    };

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(arguments: carArgs),
            builder: (_) => CarDetailsPage(supabaseClient: mockClient),
          );
        },
      ));

      await tester.pump();

      verify(() => mockTS.translate('price_label')).called(greaterThanOrEqualTo(1));
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('CarDetailsPage renders price_label for deal car', (WidgetTester tester) async {
    final carArgs = {
      'id': 'car-789',
      'make': 'Toyota',
      'model': 'Corolla',
      'final_price': 18500000,
      'image_url': 'https://example.com/car.png',
      'is_match': false,
      'is_deal': true,
    };

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(arguments: carArgs),
            builder: (_) => CarDetailsPage(supabaseClient: mockClient),
          );
        },
      ));

      await tester.pump();

      verify(() => mockTS.translate('price_label')).called(greaterThanOrEqualTo(1));
    }, createHttpClient: (context) => createMockHttpClient());
  });

  testWidgets('Clicking Interested triggers insert', (WidgetTester tester) async {
    final carArgs = {
      'id': 'car-123',
      'make': 'Mercedes',
      'model': 'G63 AMG',
      'price': 185000000,
      'image_url': 'https://example.com/g63.png',
      'is_match': false,
      'is_deal': true,
    };

    final mockSchema = MockSupabaseQuerySchema();
    final carDealBuilder = MockSupabaseQueryBuilder();
    final requestsBuilder = MockSupabaseQueryBuilder();
    
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);
    when(() => mockSchema.from('car_deal')).thenAnswer((_) => carDealBuilder);
    when(() => mockSchema.from('requests')).thenAnswer((_) => requestsBuilder);
    
    mockSupabaseQuery(carDealBuilder, []);
    mockSupabaseQuery(requestsBuilder, []);

    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            settings: RouteSettings(arguments: carArgs),
            builder: (_) => CarDetailsPage(supabaseClient: mockClient),
          );
        },
        routes: {
          '/requests': (_) => const Scaffold(body: Text('Requests Page')),
        },
      ));
      
      await tester.pump();
      await tester.tap(find.text('INTERESTED'));
      
      // Advance multiple microtasks for the awaits
      for(int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      verify(() => mockSchema.from(any())).called(2);
    }, createHttpClient: (context) => createMockHttpClient());
  });
}
