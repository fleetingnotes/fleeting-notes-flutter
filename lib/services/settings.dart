import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:hive/hive.dart';

import '../models/Note.dart';

class Settings {
  // Box initialized in main.dart
  Box<dynamic> box = Hive.box('settings');
  final defaultSettings = {
    "initial-notes":
        r"""[{"title":"how to sync notes with Obsidian","content":"1. Go to the community plugins in Obsidian & download 'Fleeting Notes Sync' plugin\n2. Configure the plugin settings (Add user, pass, specify folder, etc.)\n3. Run the sync command!","source":"https://fleetingnotes.app/posts/sync-fleeting-notes-with-obsidian/"},{"title":"what are backlinks","content":"backlinks are links to notes that reference the current note","source":""},{"title":"how to build connections in Fleeting Notes","content":"The title of the note is unique and is used is to link between ideas. To build connections:\n\n1. Use the double square brackets, type `[[` to create links (if you have links, a link suggestion popup will appear)\n2. clicking text (e.g. [[START HERE]]) will show a clickable popup which will open the note or create a note.\n3. OR create a new note with the (+) button in the bottom right corner and add a title to the note. Then repeat step 1 to link the note.\n\nNote: you can use arrow keys and enter/return to select a link from the link suggestions.","source":""},{"title":"START HERE","content":"Fleeting Notes is a scratchpad for short-form notes use it to jot and connect ideas. See below for more info:\n\n- [[how to build connections in Fleeting Notes]]\n- [[how to sync notes with Obsidian]]\n- [[what are backlinks]]\n\nFor more info, click to see the FAQ below.","source":"https://fleetingnotes.app/faq/"}]""",
    "save-delay-ms": 1000,
    "max-attachment-size-mb": 10,
    "max-attachment-size-mb-premium": 25,
  };
  Map<String, Type> settingsMap = {
    // user settings
    'analytics-enabled': bool,
    'auto-fill-source': bool,
    'dark-mode': bool,
    'text-scale-factor': double,
    'first-time-open': bool,
    'unsaved-note': Note,
    'append-same-source': bool,
    'search-is-list-view': bool,
    'auto-focus-title': bool,
    'right-to-left': bool,
    // local sync settings
    'local-sync-enabled': bool,
    'local-sync-dir': String,
    'local-sync-template': String,
    'local-sync-type': String,
    // remote config settings
    "initial-notes": String,
    "save-delay-ms": int,
    "max-attachment-size-mb": int,
    "max-attachment-size-mb-premium": int,
    "last-sync-time": DateTime,
    "plugin-slash-commands": List,
    "speech-to-text-locale": String,
    "historical-searches": List<String>,
  };

  Settings() {
    setRemoteConfig();
  }

  // Settings
  dynamic get(String key, {dynamic defaultValue}) {
    if (defaultValue == null && defaultSettings.containsKey(key)) {
      defaultValue = defaultSettings[key];
    }
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

  setRemoteConfig() async {
    // set default config
    await Future.wait(defaultSettings.entries.map((e) => set(e.key, e.value)));
    // TODO: fetch configuration remotely and set it
  }

  checkValidKeyValue(String key, {dynamic value}) {
    if (!settingsMap.containsKey(key)) {
      throw FleetingNotesException('Key provided is not in settingsMap');
    }
    // if (value != null && value.runtimeType != settingsMap[key]) {
    //   throw FleetingNotesException('Settings type mismatch');
    // }
  }

  bool isFirstTimeOpen() {
    bool isFirstTimeOpen = get('first-time-open') ?? true;
    if (isFirstTimeOpen) {
      set('first-time-open', false);
    }
    return isFirstTimeOpen;
  }
}
