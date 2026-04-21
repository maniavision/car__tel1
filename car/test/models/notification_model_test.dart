import 'package:flutter_test/flutter_test.dart';
import 'package:car/models/notification_model.dart';

void main() {
  group('NotificationModel.getDisplayTitle', () {
    test('returns titleEn when language is English and titleEn is set', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base Title', description: 'd',
        titleEn: 'English Title', type: 'match',
        createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('English'), 'English Title');
    });

    test('returns titleFr when language is Français and titleFr is set', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base Title', description: 'd',
        titleFr: 'Titre Français', type: 'match',
        createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('Français'), 'Titre Français');
    });

    test('falls back to "New Vehicle Match" for match type in English without titleEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base', description: 'd',
        type: 'match', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('English'), 'New Vehicle Match');
    });

    test('falls back to "New Vehicle Match" for found type in English without titleEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base', description: 'd',
        type: 'found', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('English'), 'New Vehicle Match');
    });

    test('falls back to "Agent Assigned" for assignment type in English without titleEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base', description: 'd',
        type: 'assignment', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('English'), 'Agent Assigned');
    });

    test('falls back to "Payment Confirmed" for payment type in English without titleEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base', description: 'd',
        type: 'payment', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('English'), 'Payment Confirmed');
    });

    test('falls back to title for Français when titleFr is not set', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Titre de base', description: 'd',
        type: 'match', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('Français'), 'Titre de base');
    });

    test('ignores empty titleEn and falls back for English', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 'Base', description: 'd',
        titleEn: '', type: 'payment', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayTitle('English'), 'Payment Confirmed');
    });
  });

  group('NotificationModel.getDisplayDescription', () {
    test('returns descriptionEn when language is English and set', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 't', description: 'base',
        descriptionEn: 'English Description', type: 'match',
        createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayDescription('English'), 'English Description');
    });

    test('returns descriptionFr when language is Français and set', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 't', description: 'base',
        descriptionFr: 'Description Française', type: 'match',
        createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayDescription('Français'), 'Description Française');
    });

    test('falls back to match description in English without descriptionEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 't', description: 'base',
        type: 'match', createdAt: DateTime(2024), isRead: false,
      );
      expect(
        model.getDisplayDescription('English'),
        'A new match has been found for your request.',
      );
    });

    test('falls back to assignment description in English without descriptionEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 't', description: 'base',
        type: 'assignment', createdAt: DateTime(2024), isRead: false,
      );
      expect(
        model.getDisplayDescription('English'),
        'An agent has been assigned to your request.',
      );
    });

    test('falls back to payment description in English without descriptionEn', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 't', description: 'base',
        type: 'payment', createdAt: DateTime(2024), isRead: false,
      );
      expect(
        model.getDisplayDescription('English'),
        'Your payment has been successfully processed.',
      );
    });

    test('falls back to description for Français when descriptionFr is not set', () {
      final model = NotificationModel(
        id: '1', userId: 'u', title: 't', description: 'Description de base',
        type: 'match', createdAt: DateTime(2024), isRead: false,
      );
      expect(model.getDisplayDescription('Français'), 'Description de base');
    });
  });

  group('NotificationModel.fromJson', () {
    test('constructs from a complete JSON map', () {
      final json = {
        'id': '42',
        'user_id': 'user-1',
        'title': 'Hello',
        'description': 'World',
        'title_en': 'Hello EN',
        'title_fr': 'Bonjour FR',
        'description_en': 'World EN',
        'description_fr': 'Monde FR',
        'type': 'payment',
        'created_at': '2024-01-01T00:00:00.000Z',
        'is_read': true,
      };
      final model = NotificationModel.fromJson(json);

      expect(model.id, '42');
      expect(model.userId, 'user-1');
      expect(model.title, 'Hello');
      expect(model.description, 'World');
      expect(model.titleEn, 'Hello EN');
      expect(model.titleFr, 'Bonjour FR');
      expect(model.descriptionEn, 'World EN');
      expect(model.descriptionFr, 'Monde FR');
      expect(model.type, 'payment');
      expect(model.isRead, true);
    });

    test('defaults isRead to false when not provided', () {
      final json = {
        'id': '1',
        'user_id': 'u',
        'title': 't',
        'description': 'd',
        'type': 'match',
        'created_at': '2024-06-01T12:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.isRead, false);
    });

    test('handles null optional fields gracefully', () {
      final json = {
        'id': '1',
        'user_id': 'u',
        'title': 't',
        'description': 'd',
        'title_en': null,
        'title_fr': null,
        'type': 'match',
        'created_at': '2024-06-01T12:00:00.000Z',
        'is_read': false,
      };
      final model = NotificationModel.fromJson(json);
      expect(model.titleEn, isNull);
      expect(model.titleFr, isNull);
    });
  });

  group('NotificationModel.copyWith', () {
    test('copyWith isRead updates only isRead', () {
      final original = NotificationModel(
        id: '1', userId: 'u', title: 'Original', description: 'd',
        type: 'match', createdAt: DateTime(2024), isRead: false,
      );
      final copy = original.copyWith(isRead: true);

      expect(copy.isRead, true);
      expect(copy.id, original.id);
      expect(copy.userId, original.userId);
      expect(copy.title, original.title);
      expect(copy.type, original.type);
    });

    test('copyWith without args returns identical values', () {
      final original = NotificationModel(
        id: '1', userId: 'u', title: 'Title', description: 'Desc',
        titleEn: 'EN', titleFr: 'FR', type: 'payment',
        createdAt: DateTime(2024), isRead: true,
      );
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.title, original.title);
      expect(copy.titleEn, original.titleEn);
      expect(copy.isRead, original.isRead);
    });
  });
}
