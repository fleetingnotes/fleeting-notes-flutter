import 'package:mocktail/mocktail.dart';
import 'package:fleeting_notes_flutter/services/settings.dart';

import 'mock_box.dart';

class MockSettings extends Mock implements Settings {
  @override
  var box = MockBox();

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
