import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = 'Mobile Money';

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const cardColor = Color(0xFF111111);
    const mutedForeground = Color(0xFF888888);
    const borderColor = Color(0xFF222222);

    final ts = TranslationService();

    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              IgnorePointer(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      right: 0,
                      child: Container(
                        width: 288,
                        height: 288,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    _buildHeader(context, borderColor, primaryColor, ts),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProgressIndicator(primaryColor, mutedForeground),
                            const SizedBox(height: 32),
                            _buildFeeSummary(primaryColor, mutedForeground, cardColor, borderColor, ts),
                            const SizedBox(height: 32),
                            _buildMethodSelection(primaryColor, mutedForeground, cardColor, borderColor),
                            const SizedBox(height: 32),
                            _buildEncryptionNotice(mutedForeground),
                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomButton(context, primaryColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color borderColor, Color primaryColor, TranslationService ts) {
    return Container(
      padding: const EdgeInsets.only(top: 48, bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          Text(
            ts.translate('paiement'),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: 40,
            child: Icon(Icons.verified_user_outlined, color: primaryColor.withOpacity(0.7), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Color primaryColor, Color mutedForeground) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FINALIZING',
                  style: GoogleFonts.dmSans(
                    color: mutedForeground,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Secure Checkout',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Text(
                'Step 2 of 2',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.6), primaryColor],
              ),
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
      ],
    );
  }

  Widget _buildFeeSummary(Color primaryColor, Color mutedForeground, Color cardColor, Color borderColor, TranslationService ts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'SERVICE SOURCING FEE',
            style: GoogleFonts.dmSans(
              color: mutedForeground.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ts.formatPrice(30000),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCheckItem(primaryColor, 'Priority Search'),
                const SizedBox(width: 16),
                _buildCheckItem(primaryColor, 'Expert Curated'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(Color primaryColor, String text) {
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, color: primaryColor.withOpacity(0.6), size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.dmSans(
            color: const Color(0xFF888888).withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodSelection(Color primaryColor, Color mutedForeground, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT METHOD',
          style: GoogleFonts.montserrat(
            color: mutedForeground.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodTile(
          'Mobile Money',
          'Wave, Orange, MTN',
          Icons.smartphone_rounded,
          primaryColor,
          true,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          'Debit / Credit Card',
          'Visa, Mastercard',
          Icons.credit_card_rounded,
          primaryColor,
          false,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String title, String subtitle, IconData icon, Color primaryColor, bool isSelected) {
    isSelected = selectedMethod == title;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? primaryColor.withOpacity(0.4) : Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
              ),
              child: Icon(icon, color: isSelected ? primaryColor : const Color(0xFF888888), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF888888),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.white.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionNotice(Color mutedForeground) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: mutedForeground.withOpacity(0.4), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Your payment information is encrypted and securely processed. By confirming, you agree to initiate the specialized vehicle sourcing process.',
              style: GoogleFonts.dmSans(
                color: mutedForeground.withOpacity(0.6),
                fontSize: 10,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, Color primaryColor) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8), Colors.black],
          ),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/payment-success');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            elevation: 10,
            shadowColor: primaryColor.withOpacity(0.25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PAY 30,000 FCFA',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.keyboard_double_arrow_right_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
