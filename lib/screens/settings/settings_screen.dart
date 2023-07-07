import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/plugin_commands_setting.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/settings_item_slider.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/settings_item_switch.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/settings_title.dart';
import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:fleeting_notes_flutter/widgets/info_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components/account.dart';
import 'components/back_up.dart';
import 'components/encryption_dialog.dart';
import 'components/local_file_sync_setting.dart';
import 'dart:io';

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

  List<int> _downloadNotesAsMarkdownZIP(List<Note> notes) {
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
    return bytes!;
  }

  List<int> _downloadNotesAsJSON(List<Note> notes) {
    var json = jsonEncode(notes);
    var bytes = utf8.encode(json);
    return bytes;
  }

  Future<String?> openFolderPicker() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      return result;
    }
    return null;
  }

  void onExportPress() async {
    final db = ref.read(dbProvider);
    final noteUtils = ref.read(noteUtilsProvider);
    List<Note> notes = await db.getAllNotes();
    String? selectedDirectory;
    bool isMobile = (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);
    if (isMobile) {
      selectedDirectory = await openFolderPicker();
    }

    if (selectedDirectory == null && isMobile) {
      noteUtils.showSnackbar(context, 'Not folder selected');
    } else {
      String fileExtension = "";
      String fileName = "fleeting_notes_export";
      List<int> bytes;
      if (backupOption == 'Markdown') {
        bytes = _downloadNotesAsMarkdownZIP(notes);
        fileExtension = "zip";
      } else {
        bytes = _downloadNotesAsJSON(notes);
        fileExtension = "json";
      }

      if (selectedDirectory == null) {
        FileSaver.instance.saveFile(fileName + "." + fileExtension,
            Uint8List.fromList(bytes), fileExtension);
      } else {
        final newFile =
            File(selectedDirectory + fileName + "." + fileExtension);
        newFile.writeAsBytes(bytes);
      }
      noteUtils.showSnackbar(context, 'Exported ${notes.length} notes');
    }
  }

  void onImportPress() async {
    final db = ref.read(dbProvider);
    final noteUtils = ref.read(noteUtilsProvider);
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
    noteUtils.showSnackbar(context, 'Imported ${notes.length} notes');
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
    db.settings.delete('last-sync-time');
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

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  String getPlatform() {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isFuchsia) {
      return 'Fuchsia';
    } else {
      return 'Unknown';
    }
  }

  void openEmail() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'matthew@fleetingnotes.app',
      query: encodeQueryParameters(<String, String>{
        'subject':
            'Fleeting Notes Feedback (Device: ${getPlatform()}, Version: ${packageInfo.version})',
      }),
    );
    launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final currUser = db.supabase.currUser;
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: Navigator.of(context).pop,
          ),
          title: const Text('Settings'),
        ),
        body: Center(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                    controller: ScrollController(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        (isLoggedIn && currUser != null)
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: InfoCard(
                                    title: 'Matt Wants Your Feedback!',
                                    description:
                                        "Need Help? Bugs? Feature Requests? Feedback sent through here is directly forwarded to my email (matthew@fleetingnotes.app)",
                                    buttonText: "Send me your feedback",
                                    onPressed: () {
                                      openEmail();
                                    }),
                              )
                            : const SizedBox.shrink(),
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
                        if (isLoggedIn) const PluginCommandSetting(),
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
                        const SettingsItemSwitch(
                            settingsKey: 'auto-focus-title',
                            name: 'Enable auto focus title',
                            defaultValue: true,
                            description:
                                "Focuses title field when creating new note"),
                        const SettingsItemSwitch(
                            settingsKey: 'right-to-left',
                            name: 'Enable right to left text',
                            defaultValue: false,
                            description:
                                "Enable right to left in text when creating new note"),
                        const SettingsItemSlider(
                          settingsKey: 'text-scale-factor',
                          name: "Text scale factor",
                          description:
                              "Magnifies the text based on a factor (default: 1)",
                        ),
                        const SizedBox(height: 24),
                        const LegalLinks(),
                      ],
                    )),
              )
            ],
          ),
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
