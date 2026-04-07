import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/services/translation_service.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const mutedForeground = Color(0xFFA3A3A3);
    const borderColor = Color(0xFF2A2A2A);

    final ts = TranslationService();

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF121212).withOpacity(0.95),
        border: Border(top: BorderSide(color: borderColor.withOpacity(0.4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            icon: currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
            label: ts.translate('home'),
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
            primaryColor: primaryColor,
            mutedForeground: mutedForeground,
          ),
          _buildNavItem(
            icon: currentIndex == 1 ? Icons.description_rounded : Icons.description_outlined,
            label: ts.translate('demandes'),
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
            primaryColor: primaryColor,
            mutedForeground: mutedForeground,
          ),
          const SizedBox(width: 60), // Space for FAB
          _buildNavItem(
            icon: currentIndex == 2 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
            label: ts.translate('alerts'),
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
            primaryColor: primaryColor,
            mutedForeground: mutedForeground,
          ),
          _buildNavItem(
            icon: currentIndex == 3 ? Icons.person_rounded : Icons.person_outline_rounded,
            label: ts.translate('profile'),
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
            primaryColor: primaryColor,
            mutedForeground: mutedForeground,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color mutedForeground,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryColor : mutedForeground,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isActive ? primaryColor : mutedForeground,
                fontSize: 9,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
