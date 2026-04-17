import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const secondaryColor = Color(0xFF1F1F1F);
    const mutedForeground = Color(0xFFA3A3A3);
    const borderColor = Color(0xFF2A2A2A);

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
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                title: Text(
                  ts.translate('comment_ca_marche'),
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
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
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Header Image/Card
                    Container(
                      height: 192,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: borderColor.withOpacity(0.6)),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Image.network(
                              'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/J5MBSgLtOSe.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              gradient: LinearGradient(
                                colors: [backgroundColor, Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            left: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ts.translate('user_guide'),
                                  style: GoogleFonts.dmSans(
                                    color: primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ts.translate('cartel_private_sourcing'),
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Timeline Section
                    Stack(
                      children: [
                        Positioned(
                          left: 19,
                          top: 20,
                          bottom: 20,
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.8),
                                  primaryColor.withOpacity(0.2),
                                  Colors.transparent
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            _buildStep(
                              ts.translate('creez_demande_title'),
                              ts.translate('creez_demande_desc'),
                              Icons.note_add_outlined,
                              primaryColor,
                            ),
                            _buildStep(
                              ts.translate('selectionnez_vehicule_title'),
                              ts.translate('selectionnez_vehicule_desc'),
                              Icons.checklist_rtl_rounded,
                              primaryColor,
                            ),
                            _buildStep(
                              ts.translate('paiement_securise_title'),
                              ts.translate('paiement_securise_desc'),
                              Icons.account_balance_wallet_outlined,
                              primaryColor,
                            ),
                            _buildStep(
                              ts.translate('remise_cles_title'),
                              ts.translate('remise_cles_desc'),
                              Icons.vpn_key_outlined,
                              primaryColor,
                            ),
                            _buildStep(
                              ts.translate('suivi_livraison_title'),
                              ts.translate('suivi_livraison_desc'),
                              Icons.directions_boat_outlined,
                              primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Bottom Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            ts.translate('compris_y_vais'),
                            style: GoogleFonts.dmSans(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStep(String title, String description, IconData icon, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFA3A3A3),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
