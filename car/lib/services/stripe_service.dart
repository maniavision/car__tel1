import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StripeService {
  static StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  @visibleForTesting
  static void setMockInstance(StripeService mock) {
    _instance = mock;
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Completer<void>? _initCompleter;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    try {
      debugPrint('Initializing Stripe keys from Edge Function...');
      final session = Supabase.instance.client.auth.currentSession;
      final res = await Supabase.instance.client.functions.invoke(
        'get-stripe-key',
        body: {
          'name': 'Functions'
        },
        headers: session != null ? {
          'Authorization': 'Bearer ${session.accessToken}',
        } : {},
      );

      final data = res.data;
      if (data != null && data['publishableKey'] != null) {
        Stripe.publishableKey = data['publishableKey'];
        Stripe.urlScheme = 'cartel';
        await Stripe.instance.applySettings();
        _isInitialized = true;
        debugPrint('Stripe initialized successfully with key: ${Stripe.publishableKey?.substring(0, 8)}...');
      } else {
        debugPrint('Error: Stripe keys not found in Edge Function response');
      }
      _initCompleter!.complete();
    } catch (e) {
      debugPrint('Error initializing Stripe keys: $e');
      _initCompleter!.completeError(e);
      _initCompleter = null; // Allow retry on error
    }
  }
}
