import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/dialog_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/responsive.dart';
import 'components/account.dart';
import 'components/back_up.dart';
import 'components/encryption_dialog.dart';
import 'components/local_file_sync_setting.dart';
import 'components/setting_item.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String backupOption = 'Markdown';
  String email = '';
  bool isLoggedIn = false;
  bool encryptionEnabled = true;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    getEncryptionKey();
    setState(() {
      isLoggedIn = db.loggedIn;
      if (db.supabase.currUser != null) {
        email = db.supabase.currUser!.email ?? '';
      }
    });
  }

  void getEncryptionKey() {
    final db = ref.read(dbProvider);
    db.supabase.getEncryptionKey().then((key) {
      setState(() {
        encryptionEnabled = key != null;
      });
    });
  }

  _downloadNotesAsMarkdownZIP(List<Note> notes) {
    var encoder = ZipEncoder();
    var archive = Archive();

    for (var note in notes) {
      var bytes = utf8.encode(note.getMarkdownContent());
      ArchiveFile archiveFiles = ArchiveFile.stream(
        note.getMarkdownFilename(),
        bytes.length,
        InputStream(bytes),
      );
      archive.addFile(archiveFiles);
    }
    var outputStream = OutputStream(
      byteOrder: LITTLE_ENDIAN,
    );
    var bytes = encoder.encode(archive,
        level: Deflate.BEST_COMPRESSION, output: outputStream);
    FileSaver.instance.saveFile(
        'fleeting_notes_export.zip', Uint8List.fromList(bytes!), 'zip');
  }

  _downloadNotesAsJSON(List<Note> notes) {
    var json = jsonEncode(notes);
    var bytes = utf8.encode(json);
    FileSaver.instance.saveFile(
        'fleeting_notes_export.json', Uint8List.fromList(bytes), 'json');
  }

  void onExportPress() async {
    final db = ref.read(dbProvider);
    List<Note> notes = await db.getAllNotes();
    if (backupOption == 'Markdown') {
      _downloadNotesAsMarkdownZIP(notes);
    } else {
      _downloadNotesAsJSON(notes);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Exported ${notes.length} notes'),
      duration: const Duration(seconds: 2),
    ));
  }

  void onImportPress() async {
    final db = ref.read(dbProvider);
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Import Notes Notice'),
              content: const Text(
                  'Importing notes with duplicate or invalid titles will be skipped'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'))
              ],
            ));
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
      allowMultiple: true,
      allowedExtensions: ['md'],
      type: FileType.custom,
    );
    List<Note> notes = [];
    if (result != null) {
      for (var file in result.files) {
        var title = file.name.replaceFirst(r'.md$', '');
        var content = String.fromCharCodes(file.bytes!);
        var note = Note.newNoteFromFile(title, content);
        // checks if title is invalid
        if (RegExp('[${Note.invalidChars}]').firstMatch(note.title) != null ||
            (await db.getNoteByTitle(note.title)) != null) {
          continue;
        }
        notes.add(note);
      }
    }
    await db.upsertNotes(notes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Imported ${notes.length} notes'),
      duration: const Duration(seconds: 2),
    ));
  }

  void onLogoutPress() async {
    final db = ref.read(dbProvider);
    await db.logout();
    setState(() {
      isLoggedIn = false;
    });
  }

  void onDeleteAccountPress() async {
    final db = ref.read(dbProvider);
    await db.supabase.deleteAccount();
    setState(() {
      isLoggedIn = false;
    });
  }

  void onForceSyncPress() async {
    final db = ref.read(dbProvider);
    db.getAllNotes(forceSync: true);
  }

  void onEnableEncryptionPress() async {
    final db = ref.read(dbProvider);
    showDialog(
      context: context,
      builder: (_) {
        return EncryptionDialog(setEncryptionKey: (key) async {
          await db.supabase.setEncryptionKey(key);
          getEncryptionKey();
          db.refreshApp(ref);
        });
      },
    );
  }

  void onBackupDropdownChange(String? newValue) {
    setState(() {
      backupOption = newValue!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Center(
      child: Column(
        children: [
          AppBar(
            elevation: (Responsive.isMobile(context)) ? null : dialogElevation,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: Navigator.of(context).pop,
            ),
            title: const Text('Settings'),
          ),
          Expanded(
            child: SingleChildScrollView(
                controller: ScrollController(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettingsTitle(title: "Account"),
                    (isLoggedIn)
                        ? Account(
                            email: email,
                            onLogout: onLogoutPress,
                            onForceSync: onForceSyncPress,
                            onDeleteAccount: onDeleteAccountPress,
                            onEnableEncryption: (encryptionEnabled)
                                ? null
                                : onEnableEncryptionPress,
                          )
                        : Auth(onLogin: (e) {
                            getEncryptionKey();
                            setState(() {
                              isLoggedIn = true;
                              email = e;
                            });
                          }),
                    const SizedBox(height: 16),
                    const SettingsTitle(title: "Backup"),
                    Backup(
                      backupOption: backupOption,
                      onImportPress: onImportPress,
                      onExportPress: onExportPress,
                      onBackupOptionChange: onBackupDropdownChange,
                    ),
                    (!kIsWeb)
                        ? Column(
                            children: [
                              const SettingsTitle(title: "Sync"),
                              LocalSyncSetting(
                                settings: db.settings,
                                getAllNotes: db.getAllNotes,
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 8),
                    const SettingsTitle(title: "Other Settings"),
                    const SettingsItemSwitch(
                        settingsKey: 'dark-mode', name: "Dark mode"),
                    const SettingsItemSwitch(
                        settingsKey: 'append-same-source',
                        name: 'Append same source',
                        defaultValue: true,
                        description:
                            "Append shared notes with the same source"),
                    const SettingsItemSwitch(
                        settingsKey: 'search-is-list-view',
                        name: 'Enable list view',
                        defaultValue: false,
                        description:
                            "Toggles the search screen between list and grid view"),
                    const SizedBox(height: 24),
                    const LegalLinks(),
                  ],
                )),
          )
        ],
      ),
    );
  }
}

class SettingsItemSwitch extends ConsumerWidget {
  const SettingsItemSwitch({
    super.key,
    required this.settingsKey,
    this.name = '',
    this.description = '',
    this.defaultValue = false,
  });

  final String settingsKey;
  final String name;
  final String description;
  final bool defaultValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return ValueListenableBuilder(
      valueListenable: settings.box.listenable(keys: [settingsKey]),
      builder: (context, Box box, _) {
        return SettingsItem(
          name: name,
          description: description,
          actions: [
            Switch(
                value: settings.get(settingsKey, defaultValue: defaultValue),
                onChanged: (v) => settings.set(settingsKey, v))
          ],
        );
      },
    );
  }
}

class SettingsTitle extends StatelessWidget {
  final String title;

  const SettingsTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    );
  }
}

class LegalLinks extends StatelessWidget {
  const LegalLinks({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      RichText(
        text: TextSpan(
          text: 'Privacy Policy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue,
              ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Uri pricingUrl =
                  Uri.parse("https://fleetingnotes.app/privacy-policy");
              launchUrl(pricingUrl, mode: LaunchMode.externalApplication);
            },
        ),
      ),
      RichText(
        text: TextSpan(
          text: 'Terms and Conditions',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue,
              ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Uri pricingUrl =
                  Uri.parse("https://fleetingnotes.app/terms-and-conditions");
              launchUrl(pricingUrl, mode: LaunchMode.externalApplication);
            },
        ),
      ),
    ]);
  }
}
