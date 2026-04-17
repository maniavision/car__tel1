import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/request_details_page.dart';
import 'package:car/services/translation_service.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockTranslationService mockTS;
  late MockUser mockUser;

  setUp(() {
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

  testWidgets('RequestDetailsPage renders request info in processing state', (WidgetTester tester) async {
    final mockSchema = MockSupabaseQuerySchema();
    final mockBuilder = MockSupabaseQueryBuilder();
    
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);
    when(() => mockSchema.from('matches')).thenAnswer((_) => mockBuilder);
    
    mockSupabaseQuery(mockBuilder, []);

    final requestArgs = {
      'id': 'req-1',
      'make': 'Mercedes',
      'model': 'GLE 450',
      'status': 'Initiated',
      'budget_max': 45000000.0,
      'year_min': 2021,
      'year_max': 2023,
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: RouteSettings(arguments: requestArgs),
          builder: (_) => RequestDetailsPage(supabaseClient: mockClient),
        );
      },
    ));
    
    await tester.pump();

    expect(find.text('Mercedes GLE 450'), findsOneWidget);
    expect(find.text('SEARCHING'), findsOneWidget);
  });
}
