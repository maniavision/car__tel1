import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockSupabaseQuerySchema mockSchema;

  setUpAll(() {
    registerFallbackValue(const {});
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'column',
      value: 'value',
    ));
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSchema = MockSupabaseQuerySchema();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-id');
    when(() => mockSupabaseClient.schema(any())).thenReturn(mockSchema);
    when(() => mockSchema.from(any())).thenAnswer((_) => mockQueryBuilder);
    
    // Mock realtime channel
    final mockChannel = MockRealtimeChannel();
    when(() => mockSupabaseClient.channel(any())).thenReturn(mockChannel);
    when(() => mockChannel.onPostgresChanges(
      event: any(named: 'event'),
      schema: any(named: 'schema'),
      table: any(named: 'table'),
      filter: any(named: 'filter'),
      callback: any(named: 'callback'),
    )).thenReturn(mockChannel);
    when(() => mockChannel.onBroadcast(
      event: any(named: 'event'),
      callback: any(named: 'callback'),
    )).thenReturn(mockChannel);
    when(() => mockChannel.subscribe()).thenReturn(mockChannel);
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
    when(() => mockChannel.sendBroadcastMessage(
      event: any(named: 'event'),
      payload: any(named: 'payload'),
    )).thenAnswer((_) async => ChannelResponse.ok);
  });

  Widget createWidgetUnderTest({Map<String, dynamic>? arguments}) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => ChatPage(supabaseClient: mockSupabaseClient),
          settings: RouteSettings(arguments: arguments),
        );
      },
      home: Builder(builder: (context) {
        return ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/chat', arguments: arguments),
          child: const Text('Go to Chat'),
        );
      }),
    );
  }

  testWidgets('ChatPage loads messages and agent info', (tester) async {
    final mockRequest = {
      'id': 'req-123',
      'agent_id': 'agent-456',
      'agents': {
        'name': 'Agent Marcus',
        'avatar_url': null,
        'specialty': 'Luxe',
      }
    };

    // Mock ensureConversation
    mockSupabaseQuery(mockQueryBuilder, [{'id': 'conv-789'}]);
    
    // Mock fetchMessages
    final mockMessages = [
      {
        'id': 'msg-1',
        'conversation_id': 'conv-789',
        'sender_id': 'agent-456',
        'sender_role': 'Agent',
        'content': 'Hello from Agent',
        'created_at': DateTime.now().toIso8601String(),
        'read_at': null,
      }
    ];
    
    // We need to be careful with multiple queries to the same builder
    // First query is for conversations, second is for messages
    var queryCount = 0;
    when(() => mockQueryBuilder.select(any())).thenAnswer((_) {
      queryCount++;
      if (queryCount == 1) return FakePostgrestBuilder([{'id': 'conv-789'}]);
      return FakePostgrestBuilder(mockMessages);
    });
    
    when(() => mockQueryBuilder.update(any())).thenAnswer((_) => FakePostgrestBuilder([]));

    await tester.pumpWidget(createWidgetUnderTest(arguments: mockRequest));
    await tester.tap(find.text('Go to Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Agent Marcus'), findsOneWidget);
    expect(find.text('Hello from Agent'), findsOneWidget);
  });

  testWidgets('ChatPage can send a message', (tester) async {
    final mockRequest = {
      'id': 'req-123',
      'agent_id': 'agent-456',
      'agents': {'name': 'Agent Marcus'}
    };

    mockSupabaseQuery(mockQueryBuilder, [{'id': 'conv-789'}]);

    await tester.pumpWidget(createWidgetUnderTest(arguments: mockRequest));
    await tester.tap(find.text('Go to Chat'));
    await tester.pumpAndSettle();

    final input = find.byType(TextField);
    await tester.enterText(input, 'Hello I am interested');
    
    // Mock insert
    when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => FakePostgrestBuilder({
      'id': 'msg-user-1',
      'conversation_id': 'conv-789',
      'sender_id': 'user-id',
      'sender_role': 'Client',
      'content': 'Hello I am interested',
      'created_at': DateTime.now().toIso8601String(),
    }));

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Hello I am interested'), findsOneWidget);
  });
}
