import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/pages/requests_page.dart';
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

  testWidgets('RequestsPage renders requests list', (WidgetTester tester) async {
    final mockSchema = MockSupabaseQuerySchema();
    final mockBuilder = MockSupabaseQueryBuilder();
    
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);
    when(() => mockSchema.from('requests')).thenAnswer((_) => mockBuilder);
    
    final mockData = [
      {
        'id': 'req-1',
        'user_id': 'user-123',
        'make': 'Toyota',
        'model': 'Corolla',
        'status': 'In Progress',
        'created_at': DateTime.now().toIso8601String(),
        'budget_max': 20000000.0,
        'agents': {'name': 'Agent Smith', 'avatar_url': null},
        'agent_id': 'agent-1',
      }
    ];
    
    mockSupabaseQuery(mockBuilder, mockData);

    await tester.pumpWidget(MaterialApp(
      home: RequestsPage(supabaseClient: mockClient),
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home')),
        '/notifications': (_) => const Scaffold(body: Text('Notifications')),
        '/profile': (_) => const Scaffold(body: Text('Profile')),
      },
    ));
    
    await tester.pump(); // Start fetching
    await tester.pump(); // After data loaded

    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Agent Smith'), findsOneWidget);
  });

  testWidgets('RequestsPage filters by Found status', (WidgetTester tester) async {
    final mockSchema = MockSupabaseQuerySchema();
    final mockBuilder = MockSupabaseQueryBuilder();
    
    when(() => mockClient.schema('cartel')).thenReturn(mockSchema);
    when(() => mockSchema.from('requests')).thenAnswer((_) => mockBuilder);
    
    final mockData = [
      {
        'id': 'req-1',
        'user_id': 'user-123',
        'make': 'Toyota',
        'model': 'Corolla',
        'status': 'Found',
        'created_at': DateTime.now().toIso8601String(),
        'budget_max': 20000000.0,
        'agents': {'name': 'Agent Smith', 'avatar_url': null},
        'agent_id': 'agent-1',
      },
      {
        'id': 'req-2',
        'user_id': 'user-123',
        'make': 'Honda',
        'model': 'Civic',
        'status': 'In Progress',
        'created_at': DateTime.now().toIso8601String(),
        'budget_max': 15000000.0,
        'agents': {'name': 'Agent Smith', 'avatar_url': null},
        'agent_id': 'agent-1',
      }
    ];
    
    mockSupabaseQuery(mockBuilder, mockData);

    await tester.pumpWidget(MaterialApp(
      home: RequestsPage(supabaseClient: mockClient),
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home')),
        '/notifications': (_) => const Scaffold(body: Text('Notifications')),
        '/profile': (_) => const Scaffold(body: Text('Profile')),
      },
    ));
    
    await tester.pump(); // Start fetching
    await tester.pump(); // After data loaded

    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Honda Civic'), findsOneWidget);

    // Tap on "trouve" filter (mocked to return 'trouve' in TranslationService)
    await tester.tap(find.text('trouve'));
    await tester.pump();

    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Honda Civic'), findsNothing);
  });
}
