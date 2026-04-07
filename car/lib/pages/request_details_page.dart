import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF0A0A0A);
    const cardColor = Color(0xFF141414);
    const borderColor = Color(0xFF2A2A2A);
    const mutedForeground = Color(0xFFA3A3A3);

    final ts = TranslationService();
    final request = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, primaryColor, borderColor, ts),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(primaryColor, cardColor, borderColor, mutedForeground, ts, request),
                    const SizedBox(height: 32),
                    _buildMatchesSection(context, primaryColor, cardColor, borderColor, mutedForeground, ts),
                    const SizedBox(height: 32),
                    _buildAgentSection(context, primaryColor, cardColor, borderColor, mutedForeground, ts),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor, Color borderColor, TranslationService ts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F).withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            ts.translate('details_demande'),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts, Map<String, dynamic>? request) {
    final title = request != null ? '${request['make']} ${request['model']}' : 'Mercedes-Benz GLE 450';
    final id = request != null ? '#${request['id'].toString().substring(0, 4).toUpperCase()}' : '#4920';
    final budget = request != null ? (request['budget_max'] ?? 0).toDouble() : 45000000.0;
    final year = request != null ? '${request['year_min']} - ${request['year_max']}' : '2021 - 2023';
    final status = request != null ? request['status']?.toString() ?? 'initialisée' : 'trouvé';
    final isFinished = status == 'terminee' || status == 'terminée' || status == 'trouvé';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBadge('Standard', primaryColor, primaryColor.withOpacity(0.1)),
                      const SizedBox(width: 8),
                      _buildBadge(id, mutedForeground, const Color(0xFF1F1F1F)),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isFinished ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isFinished ? Colors.green.withOpacity(0.3) : primaryColor.withOpacity(0.3)),
                    ),
                    child: Icon(
                      isFinished ? Icons.check_circle_rounded : Icons.pending_rounded,
                      color: isFinished ? Colors.green : primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ts.translate(status.toLowerCase().replaceAll(' ', '_')).toUpperCase(),
                    style: GoogleFonts.dmSans(
                      color: isFinished ? Colors.green : primaryColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: borderColor.withOpacity(0.4)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ts.translate('budget_prevu').toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: mutedForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ts.formatPrice(budget),
                      style: GoogleFonts.montserrat(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ts.translate('periode').toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: mutedForeground,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      year,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
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

  Widget _buildBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMatchesSection(BuildContext context, Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ts.translate('matches_trouves'),
              style: GoogleFonts.montserrat(
                color: mutedForeground,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              ts.translate('voir_tout'),
              style: GoogleFonts.dmSans(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildMatchCard(
          context,
          title: 'Mercedes GLE 450 - Silver Edition',
          subtitle: '2022 • 24,500 KM • Essence',
          price: ts.formatPrice(42500000),
          imageUrl: 'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/Xxui1AANB7v.png',
          isTopMatch: true,
          primaryColor: primaryColor,
          borderColor: borderColor,
          mutedForeground: mutedForeground,
          ts: ts,
        ),
        const SizedBox(height: 24),
        _buildMatchCard(
          context,
          title: 'Mercedes GLE 53 AMG - Night Edition',
          subtitle: '2023 • 12,000 KM • Essence',
          price: ts.formatPrice(48000000),
          imageUrl: 'https://ggrhecslgdflloszjkwl.supabase.co/storage/v1/object/public/user-assets/rRHZ5DOPVSb/components/Sb85b6rYRLP.png',
          isOverBudget: true,
          primaryColor: primaryColor,
          borderColor: borderColor,
          mutedForeground: mutedForeground,
          ts: ts,
        ),
      ],
    );
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String price,
    required String imageUrl,
    bool isTopMatch = false,
    bool isOverBudget = false,
    required Color primaryColor,
    required Color borderColor,
    required Color mutedForeground,
    required TranslationService ts,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/car-details');
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414).withOpacity(0.4),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: borderColor.withOpacity(0.6)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 192,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Text(
                        price,
                        style: GoogleFonts.dmSans(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isTopMatch)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ts.translate('top_match'),
                          style: GoogleFonts.dmSans(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  if (isOverBudget)
                    Container(
                      height: 192,
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            ts.translate('hors_budget'),
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      color: mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          ts.translate('accepter').toUpperCase(),
                          Colors.green.withOpacity(0.2),
                          Colors.green,
                          isOverBudget,
                          onTap: isOverBudget
                              ? null
                              : () {
                                  Navigator.pushNamed(context, '/car-details');
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          ts.translate('refuser').toUpperCase(),
                          Colors.red.withOpacity(0.1),
                          Colors.redAccent,
                          false,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ts.translate('match_refuse'))),
                            );
                          },
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
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, bool isDisabled, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDisabled ? bgColor.withOpacity(0.5) : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(isDisabled ? 0.1 : 0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: isDisabled ? textColor.withOpacity(0.5) : textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentSection(BuildContext context, Color primaryColor, Color cardColor, Color borderColor, Color mutedForeground, TranslationService ts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ts.translate('agent_responsable'),
          style: GoogleFonts.montserrat(
            color: mutedForeground,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage('https://randomuser.me/api/portraits/men/12.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Jean-Paul Moukoko',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expert Mercedes & Luxe • Dossier Finalisé',
                      style: GoogleFonts.dmSans(
                        color: mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ts.translate('chat_agent'))),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
