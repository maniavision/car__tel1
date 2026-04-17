import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/notifications_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/models/notification_model.dart';
import '../mocks.dart';

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

  testWidgets('NotificationsPage renders empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: NotificationsPage(),
    ));
    
    expect(find.text('no_notifications'), findsOneWidget);
  });

  testWidgets('NotificationsPage renders list of notifications', (WidgetTester tester) async {
    fakeNS.notifications = [
      NotificationModel(
        id: '1',
        userId: 'user-123',
        title: 'Test Notification',
        description: 'Test Description',
        type: 'match',
        createdAt: DateTime.now(),
        isRead: false,
      ),
    ];

    await tester.pumpWidget(const MaterialApp(
      home: NotificationsPage(),
    ));
    
    expect(find.text('Test Notification'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });
}
