import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseDB extends Mock implements SupabaseDB {
  @override
  Future<String?> getEncryptionKey() async => null;

  @override
  SupabaseClient client = MockSupabaseClient();

  @override
  Future<SubscriptionTier> getSubscriptionTier() async =>
      SubscriptionTier.freeSub;
}
