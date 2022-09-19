import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:hive/hive.dart';

import '../models/Note.dart';

class Settings {
  // Box initialized in main.dart
  Box<dynamic> box = Hive.box('settings');
  Map<String, Type> settingsMap = {
    'analytics-enabled': bool,
    'auto-fill-source': bool,
    'dark-mode': bool,
    'first-time-open': bool,
    'local-sync-enabled': bool,
    'local-sync-dir': String,
    'local-sync-template': String,
    'unsaved-note': Note,
  };

  // Settings
  dynamic get(String key, {dynamic defaultValue}) {
    checkValidKeyValue(key, value: defaultValue);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> set(String key, dynamic value) async {
    checkValidKeyValue(key, value: value);
    await box.put(key, value);
  }

  Future<void> delete(String key) async {
    checkValidKeyValue(key);
    await box.delete(key);
  }

  checkValidKeyValue(String key, {dynamic value}) {
    if (!settingsMap.containsKey(key)) {
      throw FleetingNotesException('Key provided is not in settingsMap');
    }
    if (value != null && value.runtimeType != settingsMap[key]) {
      throw FleetingNotesException('Settings type mismatch');
    }
  }

  bool isFirstTimeOpen() {
    bool isFirstTimeOpen = get('first-time-open') ?? true;
    if (isFirstTimeOpen) {
      set('first-time-open', false);
    }
    return isFirstTimeOpen;
  }
}
