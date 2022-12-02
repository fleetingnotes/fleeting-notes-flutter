import 'dart:async';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';
import 'mocks/mock_supabase.dart';

class MockGoTrueClient extends Mock implements GoTrueClient {
  final _onAuthStateChangeController = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get onAuthStateChange =>
      _onAuthStateChangeController.stream;
}

class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  GoTrueClient auth = MockGoTrueClient();
}

MockSupabaseClient getBaseMockSupabaseClient() {
  var mockSupabaseClient = MockSupabaseClient();
  when(() => mockSupabaseClient.auth.signInWithPassword(
          email: any(named: "email"), password: any(named: "password")))
      .thenAnswer((_) => Future.value(AuthResponse(user: getUser())));
  when(() => mockSupabaseClient.auth.currentUser).thenAnswer((_) => null);
  return mockSupabaseClient;
}

// ignore: empty_constructor_bodies
class MockSupabaseDB extends SupabaseDB {
  @override
  SupabaseClient get client => getBaseMockSupabaseClient();
}

void main() {
  setUpAll(() {
    registerFallbackValue(getUser());
  });
  test('supabase login sets currUser', () async {
    var mockSupabase = MockSupabaseDB();
    expect(mockSupabase.currUser, isNull);
    await mockSupabase.login('test@test.test', '222222');
    expect(mockSupabase.currUser, isNotNull);
  });
}
