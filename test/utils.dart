import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mocks/mock_database.dart';
import 'mocks/mock_settings.dart';
import 'mocks/mock_supabase.dart';

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
