import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/stripe_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/services/email_service.dart';

class PaymentPage extends StatefulWidget {
  final SupabaseClient? supabaseClient;
  const PaymentPage({super.key, this.supabaseClient});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final SupabaseClient _supabase;
  bool _isLoading = false;
  String _loadingMessage = '';
  Map<String, dynamic>? _request;

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabaseClient ?? Supabase.instance.client;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _request = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
  }

  Future<void> _makePayment() async {
    if (_request == null) return;

    final ts = TranslationService();
    final String currency = ts.currentCurrency == 'USD' ? 'USD' : 'XAF';
    // 30,000 FCFA is the base fee. If USD, we convert it.
    // In Stripe, amounts are in cents for USD (30000 / 600 * 100 = 5000 cents = $50)
    // For XAF, it's the amount itself (30000).
    final String amount = ts.currentCurrency == 'USD' ? '5000' : '30000';

    setState(() {
      _isLoading = true;
      _loadingMessage = ts.translate('traitement') ?? 'Processing...';
    });

    try {
      debugPrint('Stripe Publishable Key: ${Stripe.publishableKey}');
      if (Stripe.publishableKey == null || Stripe.publishableKey!.isEmpty) {
        setState(() => _loadingMessage = 'Initializing Stripe...');
        debugPrint('Stripe not initialized. Attempting initialization...');
        await StripeService().initialize().timeout(const Duration(seconds: 15));
        debugPrint('Stripe initialization after retry: ${Stripe.publishableKey}');
      }

      if (Stripe.publishableKey == null || Stripe.publishableKey!.isEmpty) {
        throw Exception('Stripe could not be initialized. Please check your connection.');
      }

      // 1. Fetch user data for billing
      setState(() => _loadingMessage = 'Fetching user info...');
      final user = _supabase.auth.currentUser;
      String userName = 'Valued Customer';
      if (user != null) {
        try {
          final profileResponse = await _supabase
              .schema('cartel')
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .maybeSingle();
          if (profileResponse != null && profileResponse['full_name'] != null) {
            userName = profileResponse['full_name'];
          }
        } catch (e) {
          debugPrint('Error fetching user profile for billing: $e');
        }
      }

      // 2. Create Payment Intent on the backend
      setState(() => _loadingMessage = 'Creating Payment Intent...');
      debugPrint('Creating payment intent for amount: $amount $currency');
      final paymentIntentData = await _createPaymentIntent(
        amount,
        currency,
      ).timeout(const Duration(seconds: 15));
      debugPrint('Payment intent created: ${paymentIntentData['id']}');

      // 2. Initialize Payment Sheet
      setState(() => _loadingMessage = 'Initializing Payment Sheet...');
      debugPrint('Initializing payment sheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'CarTel Sourcing',
          style: ThemeMode.dark,
          returnURL: 'cartel://redirect',
          allowsDelayedPaymentMethods: true,
          billingDetails: BillingDetails(
            name: userName,
            email: user?.email,
          ),
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFFD4AF37),
              background: Color(0xFF0A0A0A),
              componentBackground: Color(0xFF141414),
              componentDivider: Color(0xFF2A2A2A),
              primaryText: Colors.white,
              secondaryText: Color(0xFFA3A3A3),
              placeholderText: Color(0xFF525252),
              icon: Color(0xFFD4AF37),
            ),
          ),
        ),
      ).timeout(const Duration(seconds: 15));
      debugPrint('Payment sheet initialized successfully');

      // 3. Display Payment Sheet
      setState(() => _loadingMessage = 'Displaying Payment Sheet...');
      final bool paymentSuccessful = await _displayPaymentSheet(paymentIntentData['id']);

      if (paymentSuccessful && mounted) {
        debugPrint('Payment succeeded, proceeding to success page');
        Navigator.pushReplacementNamed(context, '/payment-success');
      }
    } catch (e) {
      debugPrint('Payment error in _makePayment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ts.translate('payment_failed_prefix')}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(String amount, String currency) async {
    try {
      debugPrint('Invoking stripe-payment function...');
      final response = await _supabase.functions.invoke(
        'stripe-payment',
        body: {
          'action': 'create-payment-intent',
          'amount': amount,
          'currency': currency.toLowerCase()
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('Response status: ${response.status}');
      debugPrint('Response data: ${response.data}');

      if (response.status != 200) {
        throw Exception('Failed to create payment intent: ${response.status} - ${response.data}');
      }

      final data = response.data;
      if (data == null || data['client_secret'] == null) {
        throw Exception('Invalid response from payment service: Missing client_secret');
      }

      return data;
    } catch (err) {
      debugPrint('Error in _createPaymentIntent: $err');
      rethrow;
    }
  }

  Future<bool> _displayPaymentSheet(String paymentIntentId) async {
    debugPrint('Starting _displayPaymentSheet for ID: $paymentIntentId');
    try {
      debugPrint('Calling Stripe.instance.presentPaymentSheet()...');
      
      // We remove the timeout here because the native payment sheet can take longer
      // or the user might take longer to complete it.
      // If it really hangs, we catch specific platform exceptions.
      await Stripe.instance.presentPaymentSheet();
      
      debugPrint('Payment sheet presented and completed successfully');

      // Payment successful!
      // 4. Update database
      final user = _supabase.auth.currentUser;
      debugPrint('Current user: ${user?.id}');
      debugPrint('Request object: $_request');

      if (user != null && _request != null) {
        try {
          // Update request status
          debugPrint('Updating request status in cartel.requests...');
          await _supabase.schema('cartel').from('requests').update({
            'payment_status': 'Paid',
          }).eq('id', _request!['id']);
          debugPrint('Request status updated successfully');

          // 5. Send receipt email
          debugPrint('Sending receipt email...');
          final ts = TranslationService();
          final String currency = ts.currentCurrency == 'USD' ? 'USD' : 'XAF';
          final String amount = ts.currentCurrency == 'USD' ? '50.00' : '30,000';

          // Get user profile data for email
          final profileResponse = await _supabase
              .schema('cartel')
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .single();

          final String userName = profileResponse['full_name'] ?? user.userMetadata?['full_name'] ?? 'Valued Customer';
          final String userEmail = user.email ?? '';

          if (userEmail.isNotEmpty) {
            final emailSent = await EmailService().sendPaymentReceipt(
              userEmail: userEmail,
              userName: userName,
              transactionId: paymentIntentId,
              amount: amount,
              currency: currency,
              paymentDate: DateTime.now(),
            );

            if (emailSent) {
              debugPrint('Receipt email sent successfully');
            } else {
              debugPrint('Failed to send receipt email');
            }
          } else {
            debugPrint('User email not available, skipping receipt email');
          }
        } catch (dbError) {
          debugPrint('Database Error during payment update: $dbError');
        }
      } else {
        debugPrint('Warning: User or Request is null. Skipping database update.');
      }

      return true;
    } on StripeException catch (e) {
      final ts = TranslationService();
      debugPrint('Stripe error: ${e.error.code} - ${e.error.localizedMessage}');
      debugPrint('Stripe full error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ts.translate('payment_cancelled_prefix')}: ${e.error.localizedMessage}')),
        );
      }
      return false;
    } catch (e) {
      final ts = TranslationService();
      debugPrint('Unexpected Error in _displayPaymentSheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ts.translate('unexpected_error')}: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    final ts = TranslationService();

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor.withOpacity(0.8),
                floating: true,
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F).withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                title: Text(
                  ts.translate('paiement'),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    color: borderColor.withOpacity(0.4),
                    height: 1,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${ts.translate('step')} 2 ${ts.translate('of')} 2',
                                style: GoogleFonts.plusJakartaSans(
                                  color: primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                ts.translate('confirmation'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: mutedForeground,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F1F),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Request Summary Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: primaryColor.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ts.translate('search_summary'),
                              style: GoogleFonts.plusJakartaSans(
                                color: mutedForeground,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${ts.translate('search_request')} ',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'CARTEL',
                                    style: GoogleFonts.montserrat(
                                      color: primaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.only(top: 24),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: borderColor.withOpacity(0.4))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ts.translate('service_fee'),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: mutedForeground,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ts.formatPrice(30000),
                                        style: GoogleFonts.montserrat(
                                          color: primaryColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        ts.translate('currency_label'),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: mutedForeground,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ts.currentCurrency == 'USD' ? 'USD' : 'XAF / CFA',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Payment Method Section
                      Text(
                        ts.translate('payment_method'),
                        style: GoogleFonts.plusJakartaSans(
                          color: mutedForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Stripe Only Option
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F1F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor.withOpacity(0.5)),
                              ),
                              child: const Icon(Icons.credit_card_rounded, color: Color(0xFF635BFF), size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stripe',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    ts.translate('currency_subtitle'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: mutedForeground,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor, width: 5),
                                color: backgroundColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Security Notice
                      Center(
                        child: Text(
                          ts.translate('secure_transaction_msg'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: mutedForeground,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pay Button
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: _isLoading ? null : _makePayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: primaryColor.withOpacity(0.25),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                    )
                                  else
                                    const Icon(Icons.lock_rounded, size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isLoading 
                                      ? _loadingMessage
                                      : '${ts.translate('pay_amount')} ${ts.formatPrice(30000)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isLoading) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () => setState(() => _isLoading = false),
                                child: Text(
                                  ts.translate('cancel') ?? 'Annuler',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: mutedForeground,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
