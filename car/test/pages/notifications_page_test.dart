import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/notifications_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/models/notification_model.dart';
import '../mocks.dart';

NotificationModel _makeNotification({
  String id = '1',
  String type = 'match',
  bool isRead = false,
  String title = 'Test Notification',
  String description = 'Test Description',
}) =>
    NotificationModel(
      id: id,
      userId: 'user-123',
      title: title,
      description: description,
      titleFr: title,
      descriptionFr: description,
      type: type,
      createdAt: DateTime.now(),
      isRead: isRead,
    );

void main() {
  late MockTranslationService mockTS;
  late FakeNotificationService fakeNS;

  setUp(() {
    mockTS = MockTranslationService();
    fakeNS = FakeNotificationService();

    TranslationService.setMockInstance(mockTS);
    NotificationService.setMockInstance(fakeNS);

    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.currentLanguage).thenReturn('Français');
  });

  testWidgets('renders empty state when no notifications', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));
    expect(find.text('no_notifications'), findsOneWidget);
  });

  testWidgets('renders notification title and description in list', (tester) async {
    fakeNS.notifications = [_makeNotification()];

    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.text('Test Notification'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });

  testWidgets('mark_all_read button visible when there are unread notifications', (tester) async {
    fakeNS.notifications = [_makeNotification(isRead: false)];

    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.text('mark_all_read'), findsOneWidget);
  });

  testWidgets('mark_all_read button hidden when all notifications are read', (tester) async {
    fakeNS.notifications = [_makeNotification(isRead: true)];

    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.text('mark_all_read'), findsNothing);
  });

  testWidgets('mark_all_read button hidden when notifications list is empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.text('mark_all_read'), findsNothing);
  });

  testWidgets('delete icon visible when notifications are present', (tester) async {
    fakeNS.notifications = [_makeNotification()];

    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
  });

  testWidgets('delete icon not visible in empty state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('bottom nav is rendered with alerts tab active', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const NotificationsPage(),
      routes: {
        '/home': (_) => const Scaffold(body: Text('Home')),
        '/requests': (_) => const Scaffold(body: Text('Requests')),
        '/profile': (_) => const Scaffold(body: Text('Profile')),
        '/create-request': (_) => const Scaffold(body: Text('Create')),
      },
    ));

    expect(find.text('alerts'), findsOneWidget);
  });

  testWidgets('renders multiple notifications', (tester) async {
    fakeNS.notifications = [
      _makeNotification(id: '1', title: 'First', description: 'First desc'),
      _makeNotification(id: '2', title: 'Second', description: 'Second desc', isRead: true),
    ];

    await tester.pumpWidget(const MaterialApp(home: NotificationsPage()));

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
    expect(find.text('mark_all_read'), findsOneWidget);
  });
}
