import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
          extendBody: true,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(primaryColor, ts),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                    children: [
                      _buildNotificationCard(
                        title: ts.translate('notif_match_title'),
                        description: ts.translate('notif_match_desc'),
                        time: ts.translate('just_now'),
                        icon: Icons.star_rounded,
                        isNew: true,
                        primaryColor: primaryColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationCard(
                        title: ts.translate('notif_assign_title'),
                        description: ts.translate('notif_assign_desc'),
                        time: ts.translate('2_hours_ago'),
                        icon: Icons.person_rounded,
                        isNew: false,
                        primaryColor: primaryColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                      ),
                      const SizedBox(height: 12),
                      _buildNotificationCard(
                        title: ts.translate('notif_pay_title'),
                        description: ts.translate('notif_pay_desc'),
                        time: ts.translate('yesterday'),
                        icon: Icons.credit_card_rounded,
                        isNew: false,
                        primaryColor: primaryColor,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        mutedForeground: mutedForeground,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: 2,
            onTap: (index) {
              if (index == 0) Navigator.pushReplacementNamed(context, '/home');
              if (index == 1) Navigator.pushReplacementNamed(context, '/requests');
              if (index == 3) Navigator.pushReplacementNamed(context, '/profile');
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(top: 32),
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create-request');
              },
              backgroundColor: primaryColor,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              elevation: 8,
              child: const Icon(Icons.add_rounded, size: 32),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color primaryColor, TranslationService ts) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ts.translate('notifications'),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ts.translate('mark_all_read').toUpperCase(),
            style: GoogleFonts.dmSans(
              color: primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String time,
    required IconData icon,
    required bool isNew,
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
    required Color mutedForeground,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? cardColor : cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          if (isNew)
            Positioned(
              left: -16,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isNew ? primaryColor.withOpacity(0.1) : const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: isNew ? Border.all(color: primaryColor.withOpacity(0.2)) : null,
                ),
                child: Icon(
                  icon,
                  color: isNew ? primaryColor : mutedForeground,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.dmSans(
                            color: isNew ? primaryColor : mutedForeground,
                            fontSize: 10,
                            fontWeight: isNew ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        color: mutedForeground,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}
