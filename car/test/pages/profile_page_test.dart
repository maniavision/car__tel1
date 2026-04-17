import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/profile_page.dart';
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
    when(() => mockUser.userMetadata).thenReturn({});

    TranslationService.setMockInstance(mockTS);
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.currentLanguage).thenReturn('Français');
    when(() => mockTS.currentCurrency).thenReturn('FCFA');
    when(() => mockTS.loadUserPreferences()).thenAnswer((_) async {});
  });

  testWidgets('ProfilePage renders profile info', (WidgetTester tester) async {
    final mockSchema = MockSupabaseQuerySchema();
    final mockBuilder = MockSupabaseQueryBuilder();
    
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);
    when(() => mockSchema.from('profiles')).thenAnswer((_) => mockBuilder);
    
    final mockProfile = {
      'id': 'user-123',
      'full_name': 'Fortune Niama',
      'email': 'fortune@example.com',
      'avatar_url': null,
      'language_preference': 'Français',
      'currency_preference': 'FCFA',
      'country': {'country_name': 'Cameroon', 'iso_alpha_2': 'CM'},
    };
    
    mockSupabaseQuery(mockBuilder, [mockProfile]);

    await tester.pumpWidget(MaterialApp(
      home: ProfilePage(supabaseClient: mockClient),
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home')),
        '/requests': (_) => const Scaffold(body: Text('Requests')),
        '/notifications': (_) => const Scaffold(body: Text('Notifications')),
      },
    ));
    
    await tester.pump(); // Fetch starts
    await tester.pump(); // Data loaded

    expect(find.text('Fortune Niama'), findsOneWidget);
    expect(find.text('preferences'), findsOneWidget);
    expect(find.text('CM'), findsOneWidget);
  });
}
