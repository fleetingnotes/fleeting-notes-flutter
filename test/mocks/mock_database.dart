import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'mock_box.dart';

Future<void> fnPumpWidget(WidgetTester tester, Widget widget) async {
  MockSettings mockSettings = MockSettings();
  MockSupabaseDB mockSupabase = MockSupabaseDB();
  MockDatabase mockDb =
      MockDatabase(settings: mockSettings, supabase: mockSupabase);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(mockDb),
      settingsProvider.overrideWithValue(MockSettings()),
      supabaseProvider.overrideWithValue(MockSupabaseDB())
    ],
    child: widget,
  ));
}

class MockSettings extends Mock implements Settings {
  @override
  get(String key, {defaultValue}) {
    Map<String, dynamic> testSettings = {
      "auto-fill-source": false,
      "analytics-enabled": true,
      "save-delay-ms": 1000,
      "max-attachment-size-mb": 1,
      "max-attachment-size-mb-premium": 1,
      "initial-notes": [],
    };
    return testSettings[key] ?? defaultValue;
  }

  @override
  Future<void> set(String key, dynamic value) async {}

  @override
  Future<void> delete(String key) async {}

  @override
  bool isFirstTimeOpen() => false;
}

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

class MockDatabase extends Database {
  MockDatabase({required super.supabase, required super.settings});
  Box? _currBox;

  @override
  Future<Box> getBox() async {
    _currBox ??= MockBox();
    return _currBox!;
  }
}
