import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static EmailService? _instance;
  factory EmailService() => _instance ??= EmailService._internal();
  EmailService._internal();

  SupabaseClient? _mockClient;

  @visibleForTesting
  set mockClient(SupabaseClient client) => _mockClient = client;

  SupabaseClient get _supabase => _mockClient ?? Supabase.instance.client;

  Future<bool> sendPaymentReceipt({
    required String userEmail,
    required String userName,
    required String transactionId,
    required String amount,
    required String currency,
    required DateTime paymentDate,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-receipt-email',
        body: {
          'to': userEmail,
          'userName': userName,
          'transactionId': transactionId,
          'amount': amount,
          'currency': currency,
          'paymentDate': paymentDate.toIso8601String(),
        },
      );

      if (response.status == 200) {
        return true;
      } else {
        print('Failed to send receipt email: ${response.status}');
        return false;
      }
    } catch (e) {
      print('Error sending receipt email: $e');
      return false;
    }
  }

  Future<void> sendAdminPaymentNotification({
    required String userName,
    required String userEmail,
    required String requestId,
    required String transactionId,
    required String amount,
    required String currency,
  }) async {
    try {
      await _supabase.functions.invoke(
        'notify-admin-payment',
        body: {
          'userName': userName,
          'userEmail': userEmail,
          'requestId': requestId,
          'transactionId': transactionId,
          'amount': amount,
          'currency': currency,
        },
      );
    } catch (e) {
      print('Error sending admin notification: $e');
    }
  }
}
