import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/pages/notification_details_page.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/models/notification_model.dart';
import '../mocks.dart';

void main() {
  late MockTranslationService mockTS;

  setUp(() {
    mockTS = MockTranslationService();
    TranslationService.setMockInstance(mockTS);
    when(() => mockTS.translate(any())).thenAnswer((invoc) => invoc.positionalArguments[0] as String);
    when(() => mockTS.currentLanguage).thenReturn('Français');
  });

  testWidgets('NotificationDetailsPage renders notification info', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user-123',
      title: 'Test Notification',
      description: 'Test Description',
      type: 'match',
      createdAt: DateTime.now(),
      isRead: false,
    );

    await tester.pumpWidget(MaterialApp(
      home: NotificationDetailsPage(notification: notification),
    ));
    
    expect(find.text('Test Notification'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('VOIR_TOUT'), findsOneWidget);
  });
}
