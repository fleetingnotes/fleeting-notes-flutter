// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fleeting_notes_flutter/my_app.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/one_account_dialog.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/account.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/plugin_commands_setting.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/settings_item_switch.dart';
import 'package:fleeting_notes_flutter/services/supabase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'mocks/mock_supabase.dart';
import 'utils.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Note.empty());
  });

  testWidgets('Render settings when logged in', (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await navigateToSettings(tester);
    await attemptLogin(tester);
    expect(find.byType(Auth), findsNothing);
    expect(find.byType(Account), findsOneWidget);
  });

  testWidgets('Render settings when not logged in',
      (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await navigateToSettings(tester);
    expect(find.byType(Auth), findsOneWidget);
    expect(find.byType(Account), findsNothing);
    expect(find.byType(PluginCommandSetting), findsNothing);
    expect(find.byType(SettingsItemSwitch), findsNWidgets(6));
  });

  testWidgets('Login works as expected', (WidgetTester tester) async {
    await fnPumpWidget(tester, const MyApp());
    await navigateToSettings(tester);
    await attemptLogin(tester);
    expect(find.text('Logout'), findsOneWidget);
    expect(find.byType(PluginCommandSetting), findsOneWidget);
  });

  testWidgets('Premium user sees no login dialog', (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getSubscriptionTier())
        .thenAnswer((_) => Future.value(SubscriptionTier.premiumSub));

    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await navigateToSettings(tester);
    await attemptLogin(tester);
    expect(find.byType(OneAccountDialog), findsNothing);
  });

  testWidgets('Free user sees login dialog', (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getSubscriptionTier())
        .thenAnswer((_) => Future.value(SubscriptionTier.freeSub));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await navigateToSettings(tester);
    await attemptLogin(tester);
    expect(find.byType(OneAccountDialog), findsOneWidget);
  });

  testWidgets('Unknwn user sees no login dialog', (WidgetTester tester) async {
    var mockSupabase = getBaseMockSupabaseDB();
    when(() => mockSupabase.getSubscriptionTier())
        .thenAnswer((_) => Future.value(SubscriptionTier.unknownSub));
    await fnPumpWidget(tester, const MyApp(), supabase: mockSupabase);
    await navigateToSettings(tester);
    await attemptLogin(tester);
    expect(find.byType(OneAccountDialog), findsNothing);
  });
}
