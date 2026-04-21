import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/notification_details_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/models/notification_model.dart';
import '../mocks.dart';

NotificationModel _makeNotification({
  String type = 'match',
  String? titleEn,
  String? descriptionEn,
}) =>
    NotificationModel(
      id: '1',
      userId: 'user-123',
      title: 'Test Notification',
      description: 'Test Description',
      titleEn: titleEn,
      descriptionEn: descriptionEn,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
    );

void main() {
  late MockTranslationService mockTS;

  setUp(() {
    mockTS = MockTranslationService();
    TranslationService.setMockInstance(mockTS);
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.currentLanguage).thenReturn('Français');
  });

  testWidgets('renders notification title and description', (tester) async {
    final notification = _makeNotification();

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
    ));

    expect(find.text('Test Notification'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });

  testWidgets('shows action button for match type', (tester) async {
    final notification = _makeNotification(type: 'match');

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
      routes: {'/requests': (_) => const Scaffold(body: Text('Requests'))},
    ));

    expect(find.text('voir_tout'), findsOneWidget);
  });

  testWidgets('shows action button for found type', (tester) async {
    final notification = _makeNotification(type: 'found');

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
      routes: {'/requests': (_) => const Scaffold(body: Text('Requests'))},
    ));

    expect(find.text('voir_tout'), findsOneWidget);
  });

  testWidgets('hides action button for payment type', (tester) async {
    final notification = _makeNotification(type: 'payment');

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
    ));

    expect(find.text('voir_tout'), findsNothing);
  });

  testWidgets('hides action button for assignment type', (tester) async {
    final notification = _makeNotification(type: 'assignment');

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
    ));

    expect(find.text('voir_tout'), findsNothing);
  });

  testWidgets('renders localized title when titleEn is provided and language is English', (tester) async {
    when(() => mockTS.currentLanguage).thenReturn('English');

    final notification = _makeNotification(
      type: 'match',
      titleEn: 'New Vehicle Match EN',
      descriptionEn: 'We found your car EN',
    );

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
      routes: {'/requests': (_) => const Scaffold(body: Text('Requests'))},
    ));

    expect(find.text('New Vehicle Match EN'), findsOneWidget);
    expect(find.text('We found your car EN'), findsOneWidget);
  });
}
