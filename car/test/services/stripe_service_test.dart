import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/services/stripe_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockFunctionsClient mockFunctions;

  setUpAll(() {
    registerFallbackValue(const {});
  });

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockFunctions = MockFunctionsClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentSession).thenReturn(null);
    when(() => mockSupabaseClient.functions).thenReturn(mockFunctions);

    StripeService().reset();
    StripeService().mockClient = mockSupabaseClient;
  });

  group('StripeService Tests', () {
    test('initialize calls get-stripe-key and sets initialization state', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(200);
      when(() => mockResponse.data).thenReturn({
        'publishableKey': 'pk_test_123',
      });

      when(() => mockFunctions.invoke(
        'get-stripe-key',
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      )).thenAnswer((_) async => mockResponse);

      // Note: This might still fail if Stripe.instance.applySettings() tries to call native code.
      // We might need to mock Stripe instance too if it supports it.
      
      await StripeService().initialize(skipNative: true);

      expect(StripeService().isInitialized, isTrue);
      expect(Stripe.publishableKey, equals('pk_test_123'));

      verify(() => mockFunctions.invoke(
        'get-stripe-key',
        body: any(named: 'body'),
        headers: any(named: 'headers'),
      )).called(1);
    });
   group('StripeService Edge Cases', () {
      test('initialize handles missing publishableKey', () async {
        final mockResponse = MockFunctionResponse();
        when(() => mockResponse.status).thenReturn(200);
        when(() => mockResponse.data).thenReturn({});

        when(() => mockFunctions.invoke(
          'get-stripe-key',
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => mockResponse);

        await StripeService().initialize(skipNative: true);

        expect(StripeService().isInitialized, false);
      });
    });
  });
}
