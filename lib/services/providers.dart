import 'package:fleeting_notes_flutter/services/browser_ext/browser_ext.dart';
import 'package:fleeting_notes_flutter/services/note_utils.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:fleeting_notes_flutter/services/database.dart';

import '../models/search_query.dart';
import 'notifier.dart';

// init providers
final supabaseProvider = Provider<SupabaseDB>((_) => SupabaseDB());
final settingsProvider = Provider<Settings>((_) => Settings());
final browserExtensionProvider =
    Provider<BrowserExtension>((_) => BrowserExtension());
final localFileSyncProvider = Provider<LocalFileSync>((ref) {
  final settings = ref.watch(settingsProvider);
  return LocalFileSync(settings: settings);
});
final dbProvider = Provider<Database>((ref) {
  final settings = ref.watch(settingsProvider);
  final supabase = ref.watch(supabaseProvider);
  final localFileSync = ref.watch(localFileSyncProvider);
  return Database(
    settings: settings,
    supabase: supabase,
    localFileSync: localFileSync,
  );
});

final searchProvider = StateNotifierProvider<SearchNotifier, SearchQuery?>(
    (ref) => SearchNotifier());
final noteUtilsProvider = Provider<NoteUtils>((ref) {
  return NoteUtils(ref);
});
