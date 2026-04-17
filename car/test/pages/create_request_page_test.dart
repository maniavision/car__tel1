import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/create_request_page.dart';
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
    when(() => mockTS.currentLanguage).thenReturn('Français');
  });

  testWidgets('CreateRequestPage renders form', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CreateRequestPage(supabaseClient: mockClient),
    ));
    
    expect(find.text('VEHICLE_IDENTITY'), findsOneWidget);
    expect(find.text('INVESTMENT_RANGE'), findsOneWidget);
  });
}
