import 'dart:async';

import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockUser extends Mock implements User {}

User getUser({String id = ''}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: '',
    createdAt: '',
  );
}

class MockSupabaseDB extends Mock implements SupabaseDB {
  @override
  User? currUser;
  @override
  StreamController<User?> authChangeController =
      StreamController<User?>.broadcast();
  @override
  Future<String?> getEncryptionKey() async => null;

  @override
  SupabaseClient client = MockSupabaseClient();
}

MockSupabaseDB getBaseMockSupabaseDB() {
  var mockSupabase = MockSupabaseDB();
  when(() => mockSupabase.login(any(), any())).thenAnswer((_) {
    var user = getUser();
    mockSupabase.authChangeController.add(user);
    mockSupabase.currUser = user;
    return Future.value(user);
  });
  when(() => mockSupabase.logout()).thenAnswer((_) {
    mockSupabase.authChangeController.add(null);
    mockSupabase.currUser = null;
    return Future.value(true);
  });
  when(() => mockSupabase.getSubscriptionTier())
      .thenAnswer((_) => Future.value(SubscriptionTier.unknownSub));
  return mockSupabase;
}
