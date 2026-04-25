import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/services/translation_service.dart';
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

    final service = TranslationService();
    service.mockClient = mockSupabaseClient;
  });

  group('TranslationService Tests', () {
    test('Initial language should be Français', () {
      final service = TranslationService();
      expect(service.currentLanguage, 'Français');
    });

    test('Initial currency should be FCFA', () {
      final service = TranslationService();
      expect(service.currentCurrency, 'FCFA');
    });

    test('setLanguage should update language and notify listeners', () {
      final service = TranslationService();
      bool notified = false;
      service.addListener(() => notified = true);
      
      service.setLanguage('English');
      
      expect(service.currentLanguage, 'English');
      expect(notified, true);
    });

    test('setCurrency should update currency and notify listeners', () {
      final service = TranslationService();
      bool notified = false;
      service.addListener(() => notified = true);
      
      service.setCurrency('USD');
      
      expect(service.currentCurrency, 'USD');
      expect(notified, true);
    });

    test('formatPrice should correctly format FCFA', () {
      final service = TranslationService();
      service.setCurrency('FCFA');
      
      expect(service.formatPrice(30000000), '30.0M FCFA');
      expect(service.formatPrice(30000), '30.000 FCFA');
    });

    test('formatPrice should correctly format USD', () {
      final service = TranslationService();
      service.setCurrency('USD');
      
      // 30,000,000 / 600 = 50,000
      expect(service.formatPrice(30000000), '\$50,000');
      
      // 600,000,000 / 600 = 1,000,000
      expect(service.formatPrice(600000000), '1.0M USD');
    });

    test('translate should return correct values', () {
      final service = TranslationService();
      service.setLanguage('English');
      expect(service.translate('welcome_back'), 'Welcome Back,');
      
      service.setLanguage('Français');
      expect(service.translate('welcome_back'), 'Bienvenue,');
    });
  });
}
