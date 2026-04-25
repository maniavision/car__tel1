import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/reset_password_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      routes: {
        '/login': (context) => const Scaffold(body: Text('Login Page')),
      },
      home: ResetPasswordPage(supabaseClient: mockSupabaseClient),
    );
  }

  testWidgets('ResetPasswordPage shows inputs and handles update password', (tester) async {
    final ts = TranslationService();
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.textContaining(RegExp(ts.translate('reset_password_title'), caseSensitive: false)), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).at(0), 'newpassword123!');
    await tester.enterText(find.byType(TextField).at(1), 'newpassword123!');
    
    when(() => mockAuth.updateUser(any())).thenAnswer((_) async => MockUserResponse());

    final submitBtn = find.text(ts.translate('reset_access_btn').toUpperCase());
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    verify(() => mockAuth.updateUser(any())).called(1);
    
    expect(find.text('Login Page'), findsOneWidget);
  });

  testWidgets('ResetPasswordPage shows error when passwords do not match', (tester) async {
    final ts = TranslationService();
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField).at(0), 'password123');
    await tester.enterText(find.byType(TextField).at(1), 'password456');

    final submitBtn = find.text(ts.translate('reset_access_btn').toUpperCase());
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
