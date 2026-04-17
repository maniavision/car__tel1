import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/payment_page.dart';
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
    when(() => mockTS.currentCurrency).thenReturn('FCFA');
  });

  testWidgets('PaymentPage renders request summary', (WidgetTester tester) async {
    final requestArgs = {
      'id': 'req-1',
      'make': 'Mercedes',
      'model': 'GLE 450',
    };

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: RouteSettings(arguments: requestArgs),
          builder: (_) => PaymentPage(supabaseClient: mockClient),
        );
      },
    ));
    
    await tester.pump();
    for (var widget in tester.widgetList<Text>(find.byType(Text))) {
      debugPrint('Found text: ${widget.data}');
    }
    
    expect(find.text('search_summary'), findsOneWidget);
    expect(find.text('30000.0'), findsOneWidget);
  });
}
