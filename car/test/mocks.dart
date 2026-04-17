import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:car/services/notification_service.dart';
import 'package:car/services/translation_service.dart';
import 'package:car/services/stripe_service.dart';
import 'package:car/models/notification_model.dart';

class MockSupabase extends Mock implements Supabase {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockNotificationService extends Mock implements NotificationService {}

class FakeNotificationService extends Fake with ChangeNotifier implements NotificationService {
  @override
  List<NotificationModel> notifications = [];
  @override
  bool isLoading = false;
  @override
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  Future<void> fetchNotifications() async {}
  @override
  Future<void> markAllAsRead() async {}
  @override
  Future<void> markAsRead(String id) async {}
  @override
  Future<bool> deleteNotification(String id) async => true;
  @override
  Future<bool> clearAll() async => true;
}
class MockTranslationService extends Mock implements TranslationService {}
class MockStripeService extends Mock implements StripeService {}
class MockSession extends Mock implements Session {}
class MockUser extends Mock implements User {}
class MockSupabaseStorage extends Mock implements SupabaseStorageClient {}
class MockStorageFileApi extends Mock implements StorageFileApi {}
class MockSupabaseQuerySchema extends Mock implements SupabaseQuerySchema {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockFunctionsClient extends Mock implements FunctionsClient {}
class MockFunctionResponse extends Mock implements FunctionResponse {}

class FakePostgrestBuilder<T> extends Fake implements PostgrestFilterBuilder<T>, PostgrestTransformBuilder<T> {
  final dynamic _value;
  FakePostgrestBuilder(this._value);

  @override
  PostgrestFilterBuilder<T> eq(String column, Object? value) => this;
  @override
  PostgrestFilterBuilder<T> inFilter(String column, List values) => this;
  @override
  PostgrestFilterBuilder<T> order(String column, {bool? ascending, bool? nullsFirst, String? referencedTable}) => this;
  @override
  PostgrestFilterBuilder<T> limit(int count, {String? referencedTable}) => this;
  
  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    if (_value is List && (_value as List).isNotEmpty) {
      return FakePostgrestBuilder<Map<String, dynamic>>(_value[0]);
    }
    return FakePostgrestBuilder<Map<String, dynamic>>(_value as Map<String, dynamic>);
  }
  
  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    if (_value is List) {
       if ((_value as List).isEmpty) return FakePostgrestBuilder<Map<String, dynamic>?>(null);
       return FakePostgrestBuilder<Map<String, dynamic>?>(_value[0]);
    }
    return FakePostgrestBuilder<Map<String, dynamic>?>(_value as Map<String, dynamic>?);
  }
  
  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    return Future.value(_value).then((dynamic v) {
      if (v is List && T.toString().contains('List<Map<String, dynamic>>')) {
        return onValue(v.cast<Map<String, dynamic>>() as T);
      }
      return onValue(v as T);
    }, onError: onError);
  }
}

/// Helper to mock a Supabase query chain that returns [value].
void mockSupabaseQuery(MockSupabaseQueryBuilder builder, dynamic value) {
  final fake = FakePostgrestBuilder<List<Map<String, dynamic>>>(value);
  when(() => builder.select(any())).thenAnswer((_) => fake);
  when(() => builder.select()).thenAnswer((_) => fake);
  when(() => builder.insert(any())).thenAnswer((_) => fake as dynamic);
  when(() => builder.update(any())).thenAnswer((_) => fake as dynamic);
  when(() => builder.upsert(any())).thenAnswer((_) => fake as dynamic);
}
