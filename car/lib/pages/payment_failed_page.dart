import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:car/services/translation_service.dart';

class PaymentFailedPage extends StatefulWidget {
  const PaymentFailedPage({super.key});

  @override
  State<PaymentFailedPage> createState() => _PaymentFailedPageState();
}

class _PaymentFailedPageState extends State<PaymentFailedPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const destructiveColor = Color(0xFF990000);
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
                      top: -100,
                      left: -100,
                      child: Container(
                        width: 500,
                        height: 500,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: destructiveColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      right: -50,
                      child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: destructiveColor.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAnimatedIcon(destructiveColor),
                                const SizedBox(height: 40),
                                Text(
                                  ts.translate('payment_failed'),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  ts.translate('payment_failed_desc'),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.dmSans(
                                    color: mutedForeground,
                                    fontSize: 14,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 48),
                                _buildDetailsCard(destructiveColor, mutedForeground, cardColor, borderColor, ts),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildBottomButtons(context, destructiveColor, ts),
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

  Widget _buildAnimatedIcon(Color destructiveColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: destructiveColor.withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Rings
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 96 + (32 * _controller.value),
              height: 96 + (32 * _controller.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: destructiveColor.withOpacity(0.2 * (1 - _controller.value))),
              ),
            );
          },
        ),
        // Main Icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: destructiveColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: [
              BoxShadow(
                color: destructiveColor.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(Color destructiveColor, Color mutedForeground, Color cardColor, Color borderColor, TranslationService ts) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildDetailRow(ts.translate('error_code'), 'ERR_P_402', destructiveColor, mutedForeground, isMono: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildDetailRow(ts.translate('amount'), ts.formatPrice(30000), Colors.white, mutedForeground, isBold: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ts.translate('statut'),
                style: GoogleFonts.dmSans(
                  color: mutedForeground,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: destructiveColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: destructiveColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: destructiveColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ts.translate('transaction_failed'),
                      style: GoogleFonts.dmSans(
                        color: destructiveColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, Color mutedForeground,
      {bool isMono = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: isMono
              ? GoogleFonts.jetBrainsMono(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)
              : GoogleFonts.dmSans(
                  color: valueColor, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context, Color destructiveColor, TranslationService ts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: destructiveColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                elevation: 10,
                shadowColor: destructiveColor.withOpacity(0.25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ts.translate('try_again'),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.refresh_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                ts.translate('change_method'),
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
