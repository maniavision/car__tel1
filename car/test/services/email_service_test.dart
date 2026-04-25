import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:car/services/email_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mocks.dart';

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockFunctionsClient mockFunctions;

  setUpAll(() {
    registerFallbackValue(const {});
  });

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockFunctions = MockFunctionsClient();
    
    when(() => mockSupabaseClient.functions).thenReturn(mockFunctions);
    
    EmailService().mockClient = mockSupabaseClient;
  });

  group('EmailService Tests', () {
    test('sendPaymentReceipt returns true on success', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(200);
      
      when(() => mockFunctions.invoke(
        'send-receipt-email',
        body: any(named: 'body'),
      )).thenAnswer((_) async => mockResponse);

      final result = await EmailService().sendPaymentReceipt(
        userEmail: 'test@example.com',
        userName: 'Test User',
        transactionId: 'tx_123',
        amount: '30.000',
        currency: 'FCFA',
        paymentDate: DateTime.now(),
      );

      expect(result, true);
      verify(() => mockFunctions.invoke('send-receipt-email', body: any(named: 'body'))).called(1);
    });

    test('sendPaymentReceipt returns false on failure', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(400);
      
      when(() => mockFunctions.invoke(
        'send-receipt-email',
        body: any(named: 'body'),
      )).thenAnswer((_) async => mockResponse);

      final result = await EmailService().sendPaymentReceipt(
        userEmail: 'test@example.com',
        userName: 'Test User',
        transactionId: 'tx_123',
        amount: '30.000',
        currency: 'FCFA',
        paymentDate: DateTime.now(),
      );

      expect(result, false);
    });

    test('sendAdminPaymentNotification calls notify-admin-payment function', () async {
      final mockResponse = MockFunctionResponse();
      when(() => mockResponse.status).thenReturn(200);
      
      when(() => mockFunctions.invoke(
        'notify-admin-payment',
        body: any(named: 'body'),
      )).thenAnswer((_) async => mockResponse);

      await EmailService().sendAdminPaymentNotification(
        userName: 'Test User',
        userEmail: 'test@example.com',
        requestId: 'req_123',
        transactionId: 'tx_123',
        amount: '30.000',
        currency: 'FCFA',
      );

      verify(() => mockFunctions.invoke('notify-admin-payment', body: any(named: 'body'))).called(1);
    });
  });
}
