import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car/widgets/bottom_nav.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/pages/notification_details_page.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD4AF37);
    const backgroundColor = Color(0xFF000000);
    const cardColor = Color(0xFF111111);
    const mutedForeground = Color(0xFF888888);
    const borderColor = Color(0xFF222222);

    final ts = TranslationService();
    final ns = NotificationService();

    return ListenableBuilder(
      listenable: Listenable.merge([ts, ns]),
      builder: (context, _) {
        final notifications = ns.notifications;
        final isLoading = ns.isLoading;

        return Scaffold(
          backgroundColor: backgroundColor,
          extendBody: true,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(primaryColor, ts, ns),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: primaryColor))
                      : notifications.isEmpty
                          ? Center(
                              child: Text(
                                ts.translate('no_notifications'),
                                style: GoogleFonts.dmSans(color: mutedForeground),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final n = notifications[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Dismissible(
                                    key: Key(n.id),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) async {
                                      final success = await ns.deleteNotification(n.id);
                                      if (!success && mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ts.translate('error_occurred')),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        ns.markAsRead(n.id);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NotificationDetailsPage(notification: n),
                                          ),
                                        );
                                      },
                                      child: _buildNotificationCard(
                                        title: n.getDisplayTitle(ts.currentLanguage),
                                        description: n.getDisplayDescription(ts.currentLanguage),
                                        time: _formatTime(n.createdAt, ts),
                                        icon: _getIconForType(n.type),
                                        isNew: !n.isRead,
                                        primaryColor: primaryColor,
                                        cardColor: cardColor,
                                        borderColor: borderColor,
                                        mutedForeground: mutedForeground,
                                      ),
                                    ),
                                  ),
                                );
                              },
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

  Widget _buildHeader(Color primaryColor, TranslationService ts, NotificationService ns) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
      ),
      child: Column(
        children: [
          Row(
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
              if (ns.notifications.isNotEmpty)
                GestureDetector(
                  onTap: () => _showClearAllConfirmation(context, ts, ns),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (ns.unreadCount > 0)
            GestureDetector(
              onTap: ns.markAllAsRead,
              child: Row(
                children: [
                  Icon(Icons.done_all_rounded, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    ts.translate('mark_all_read'),
                    style: GoogleFonts.dmSans(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context, TranslationService ts, NotificationService ns) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              ts.translate('clear_all_notifications_title') ?? 'Clear all notifications?',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ts.translate('clear_all_notifications_desc') ?? 'This action cannot be undone.',
              style: GoogleFonts.dmSans(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      ts.translate('cancel'),
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ns.clearAll();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(ts.translate('clear_all') ?? 'Clear All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime, TranslationService ts) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return ts.translate('just_now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'match':
      case 'found':
        return Icons.star_rounded;
      case 'assignment':
        return Icons.person_rounded;
      case 'payment':
        return Icons.credit_card_rounded;
      default:
        return Icons.notifications_rounded;
    }
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
      child: Row(
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
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
    );
  }
}
