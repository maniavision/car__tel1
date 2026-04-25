import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const _bg = Color(0xFF0A0A0A);
  static const _primary = Color(0xFFD4AF37);
  static const _card = Color(0xFF141414);
  static const _border = Color(0xFF2A2A2A);
  static const _muted = Color(0xFFA3A3A3);
  static const _secondary = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    final ts = TranslationService();
    return ListenableBuilder(
      listenable: ts,
      builder: (context, _) => Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_primary.withValues(alpha: 0.1), Colors.transparent],
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  color: _bg.withValues(alpha: 0.92),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    bottom: 16,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _secondary.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: _border.withValues(alpha: 0.6)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        ts.translate('privacy_policy'),
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: _primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield_rounded, color: _primary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                ts.translate('privacy_last_updated'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: _primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ts.translate('privacy_title'),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ts.translate('privacy_subtitle'),
                          style: GoogleFonts.plusJakartaSans(color: _muted, fontSize: 13, height: 1.6),
                        ),
                        const SizedBox(height: 32),

                        // Card 1
                        _buildCard(
                          icon: Icons.badge_rounded,
                          title: ts.translate('privacy_data_collection'),
                          children: [
                            _sectionLabel(ts.translate('privacy_data_collection_label')),
                            const SizedBox(height: 6),
                            _sectionBody(ts.translate('privacy_data_collection_body')),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card 2
                        _buildCard(
                          icon: Icons.visibility_rounded,
                          title: ts.translate('privacy_data_usage'),
                          children: [
                            _sectionLabel(ts.translate('privacy_data_usage_label')),
                            const SizedBox(height: 6),
                            _sectionBody(ts.translate('privacy_data_usage_body')),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Card 3
                        _buildCard(
                          icon: Icons.lock_rounded,
                          title: ts.translate('privacy_security'),
                          children: [
                            _sectionBody(ts.translate('privacy_security_body')),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Contact support
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: _primary.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.chat_rounded, color: _primary, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                ts.translate('privacy_questions'),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ts.translate('privacy_contact_subtitle'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(color: _muted, fontSize: 11, height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/help-center'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: [
                                      BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Text(
                                    ts.translate('privacy_contact_btn'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.black,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            ts.translate('privacy_copyright').toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: _muted.withValues(alpha: 0.3),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primary.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }

  Widget _sectionBody(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(color: _muted, fontSize: 13, height: 1.6),
    );
  }
}
