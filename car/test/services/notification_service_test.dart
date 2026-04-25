import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockSupabaseQuerySchema mockSchema;
  late MockAudioPlayer mockAudioPlayer;
  late MockRealtimeChannel mockChannel;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFallbackValue(const {});
    registerFallbackValue(AssetSource(''));
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: '',
      value: '',
    ));
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockSchema = MockSupabaseQuerySchema();
    mockAudioPlayer = MockAudioPlayer();
    mockChannel = MockRealtimeChannel();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user-id');
    when(() => mockSupabaseClient.schema(any())).thenReturn(mockSchema);
    when(() => mockSchema.from(any())).thenAnswer((_) => mockQueryBuilder);
    when(() => mockSupabaseClient.channel(any())).thenReturn(mockChannel);
    
    // Channel mocks
    when(() => mockChannel.onPostgresChanges(
      event: any(named: 'event'),
      schema: any(named: 'schema'),
      table: any(named: 'table'),
      filter: any(named: 'filter'),
      callback: any(named: 'callback'),
    )).thenReturn(mockChannel);
    when(() => mockChannel.subscribe()).thenReturn(mockChannel);
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => '');
    
    // Auth stream mock
    when(() => mockAuth.onAuthStateChange).thenAnswer((_) => Stream.empty());

    // AudioPlayer mock
    when(() => mockAudioPlayer.play(any())).thenAnswer((_) async => {});
    when(() => mockAudioPlayer.dispose()).thenAnswer((_) async => {});

    // Default empty query mock
    mockSupabaseQuery(mockQueryBuilder, []);

    final service = NotificationService();
    service.mockClient = mockSupabaseClient;
    service.mockAudioPlayer = mockAudioPlayer;
  });

  group('NotificationService Tests', () {
    test('fetchNotifications updates notifications list', () async {
      final mockData = [
        {
          'id': '1',
          'user_id': 'user-id',
          'title': 'Test Title',
          'description': 'Test Desc',
          'type': 'info',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      mockSupabaseQuery(mockQueryBuilder, mockData);

      final service = NotificationService();
      await service.fetchNotifications();

      expect(service.notifications.length, 1);
      expect(service.notifications.first.title, 'Test Title');
      expect(service.unreadCount, 1);
    });

    test('markAsRead updates local state and calls database', () async {
      final mockData = [
        {
          'id': '1',
          'user_id': 'user-id',
          'title': 'Test Title',
          'description': 'Test Desc',
          'type': 'info',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      mockSupabaseQuery(mockQueryBuilder, mockData);

      final service = NotificationService();
      await service.fetchNotifications();
      
      expect(service.unreadCount, 1);

      // Mock update call
      when(() => mockQueryBuilder.update(any())).thenAnswer((_) => FakePostgrestBuilder([]));

      await service.markAsRead('1');

      expect(service.unreadCount, 0);
      expect(service.notifications.first.isRead, true);
    });

    test('clearAll clears local list and calls database', () async {
      final mockData = [
        {'id': '1', 'title': 'T1'},
        {'id': '2', 'title': 'T2'},
      ];
      // We need to return the deleted rows because NotificationService uses .select() after .delete()
      final mockResponse = mockData.map((d) => {...d, 'user_id': 'user-id', 'is_read': false, 'created_at': DateTime.now().toIso8601String()}).toList();

      mockSupabaseQuery(mockQueryBuilder, mockResponse);

      final service = NotificationService();
      await service.fetchNotifications();
      expect(service.notifications.length, 2);

      // Mock delete chain
      final fakeBuilder = FakePostgrestBuilder<List<Map<String, dynamic>>>(mockResponse);
      when(() => mockQueryBuilder.delete()).thenAnswer((_) => fakeBuilder);

      await service.clearAll();

      expect(service.notifications.isEmpty, true);
    });
  });
}
