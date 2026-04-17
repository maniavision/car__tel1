import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  @visibleForTesting
  static void setMockInstance(NotificationService mock) {
    _instance = mock;
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  RealtimeChannel? _channel;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await fetchNotifications();
    _subscribeToNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .schema('cartel')
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _channel?.unsubscribe();
    
    _channel = _supabase
        .channel('cartel:notifications_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'cartel',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (payload.eventType == PostgresChangeEvent.insert) {
              _notifications.insert(0, NotificationModel.fromJson(payload.newRecord));
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final updated = NotificationModel.fromJson(payload.newRecord);
              final index = _notifications.indexWhere((n) => n.id == updated.id);
              if (index != -1) {
                _notifications[index] = updated;
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final deletedId = payload.oldRecord['id'].toString();
              _notifications.removeWhere((n) => n.id == deletedId);
            }
            notifyListeners();
          },
        );
    
    _channel!.subscribe();
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .schema('cartel')
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1 || _notifications[index].isRead) return;

      await _supabase
          .schema('cartel')
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      _notifications[index] = _notifications[index].copyWith(isRead: true);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      debugPrint('Attempting to delete notification: $notificationId for user: ${user.id}');

      // Use .match for multiple filters which is often more reliable in PostgREST
      final response = await Supabase.instance.client
          .schema('cartel')
          .from('notifications')
          .delete()
          .match({
            'id': notificationId,
            'user_id': user.id,
          })
          .select();

      if (response.isNotEmpty) {
        debugPrint('Successfully deleted notification from backend: $notificationId');
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
        return true;
      } else {
        debugPrint('No notification deleted in backend (empty response). Possible RLS issue.');
        
        // Check if it's already gone (maybe real-time delete event fired)
        final existsLocally = _notifications.any((n) => n.id == notificationId);
        if (!existsLocally) {
          debugPrint('Notification $notificationId already removed from local list.');
          return true;
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('Exception during notification deletion: $e');
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      debugPrint('Attempting to clear all notifications for user: ${user.id}');

      final response = await Supabase.instance.client
          .schema('cartel')
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .select();

      debugPrint('Clear all response size: ${response.length}');
      
      _notifications.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      return false;
    }
  }

  void logout() {
    _channel?.unsubscribe();
    _channel = null;
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
