import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/forgot_password_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(const {});
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ForgotPasswordPage(supabaseClient: mockSupabaseClient),
    );
  }

  testWidgets('ForgotPasswordPage shows input and handles reset password', (tester) async {
    final ts = TranslationService();
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text(ts.translate('forgot_password')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'test@example.com');
    
    when(() => mockAuth.resetPasswordForEmail(
      any(),
      redirectTo: any(named: 'redirectTo'),
    )).thenAnswer((_) async => {});

    final sendBtn = find.text(ts.translate('send_link').toUpperCase());
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn);
    await tester.pump();

    verify(() => mockAuth.resetPasswordForEmail('test@example.com', redirectTo: 'cartel://login-callback')).called(1);
    
    // Check for success snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(ts.translate('reset_link_sent')), findsOneWidget);
  });

  testWidgets('ForgotPasswordPage shows error on AuthException', (tester) async {
    final ts = TranslationService();
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.enterText(find.byType(TextField), 'error@example.com');
    
    when(() => mockAuth.resetPasswordForEmail(
      any(),
      redirectTo: any(named: 'redirectTo'),
    )).thenThrow(const AuthException('User not found'));

    final sendBtn = find.text(ts.translate('send_link').toUpperCase());
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn);
    await tester.pump();

    expect(find.text('User not found'), findsOneWidget);
  });
}
