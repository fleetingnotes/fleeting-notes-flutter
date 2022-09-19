import 'package:hive/hive.dart';

class Settings {
  // Box initialized in main.dart
  Box<dynamic> box = Hive.box('settings');

  // Settings
  dynamic get(String key, {dynamic defaultValue}) {
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> set(String key, dynamic value) async {
    await box.put(key, value);
  }

  Future<void> delete(String key) async {
    await box.delete(key);
  }

  bool isFirstTimeOpen() {
    bool isFirstTimeOpen = get('first-time-open') ?? true;
    if (isFirstTimeOpen) {
      set('first-time-open', false);
    }
    return isFirstTimeOpen;
  }
}
