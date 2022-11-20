import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:fleeting_notes_flutter/services/database.dart';

// init providers
final supabaseProvider = Provider<SupabaseDB>((_) => SupabaseDB());
final settingsProvider = Provider<Settings>((_) => Settings());
final dbProvider = Provider<Database>((ref) {
  final settings = ref.watch(settingsProvider);
  final supabase = ref.watch(supabaseProvider);
  return Database(settings: settings, supabase: supabase);
});
