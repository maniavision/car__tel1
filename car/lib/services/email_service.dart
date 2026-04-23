import 'package:supabase_flutter/supabase_flutter.dart';

class EmailService {
  static EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

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
}
