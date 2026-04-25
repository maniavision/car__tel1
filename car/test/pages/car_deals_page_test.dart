import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/car_deals_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockSupabaseQuerySchema mockSchema;

  setUpAll(() {
    registerFallbackValue(const {});
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSchema = MockSupabaseQuerySchema();

    when(() => mockSupabaseClient.schema(any())).thenReturn(mockSchema);
    when(() => mockSchema.from(any())).thenAnswer((_) => mockQueryBuilder);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (context) => CarDealsPage(supabaseClient: mockSupabaseClient));
      },
      home: CarDealsPage(supabaseClient: mockSupabaseClient),
    );
  }

  testWidgets('CarDealsPage shows loading indicator then list of deals', (tester) async {
    final ts = TranslationService();
    final mockDeals = [
      {
        'id': '1',
        'make': 'Porsche',
        'model': '911',
        'final_price': 150000000,
        'year': 2023,
        'mileage': 5000,
        'status': 'Available',
        'image_urls': ['https://example.com/image.png'],
        'number_people_interested': 10,
      }
    ];

    mockSupabaseQuery(mockQueryBuilder, mockDeals);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(); // Start fetch
    await tester.pump(const Duration(milliseconds: 100)); // Complete fetch

    expect(find.text('Porsche 911'), findsOneWidget);
    expect(find.text('150.0M FCFA'), findsOneWidget);
    expect(find.text('10 ${ts.translate('interested')}'), findsOneWidget);
  });

  testWidgets('CarDealsPage shows empty state when no deals available', (tester) async {
    final ts = TranslationService();
    mockSupabaseQuery(mockQueryBuilder, []);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(ts.translate('no_deals_available')), findsOneWidget);
  });
}
