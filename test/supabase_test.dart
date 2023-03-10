import 'dart:async';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';
import 'mocks/mock_supabase.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {
  Map<String, String?> storage = {};
  @override
  Future<void> write(
      {required String key,
      required String? value,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    storage[key] = value;
  }

  @override
  Future<String?> read(
      {required String key,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    return storage[key];
  }
}

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
  when(() => mockSupabaseClient.auth.signOut())
      .thenAnswer((_) => Future.value(null));
  return mockSupabaseClient;
}

class MockSupabaseDB extends SupabaseDB {
  @override
  SupabaseClient get client => getBaseMockSupabaseClient();

  @override
  FlutterSecureStorage get secureStorage => MockSecureStorage();
}

void main() {
  setUpAll(() {
    registerFallbackValue(getUser());
  });
  // not a valid test but keeping as an example
  test('supabase logout clears subTier', () async {
    var mockSupabase = MockSupabaseDB();
    mockSupabase.subTier = SubscriptionTier.freeSub;
    await mockSupabase.logout();
    expect(mockSupabase.currUser, isNull);
  });
}
