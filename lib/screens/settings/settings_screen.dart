import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/setting_item.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:go_router/go_router.dart';
import 'components/account.dart';
import 'components/back_up.dart';
import 'components/encryption_dialog.dart';
import 'components/notion_sync_dialog.dart';
import 'components/local_sync_setting.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, required this.db}) : super(key: key);

  final Database db;
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String backupOption = 'Markdown';
  String email = '';
  bool isLoggedIn = false;
  bool encryptionEnabled = true;

  @override
  void initState() {
    super.initState();

    widget.db.firebase.getEncryptionKey().then((key) {
      setState(() {
        encryptionEnabled = key != null;
      });
    });
    setState(() {
      isLoggedIn = widget.db.isLoggedIn();
      if (widget.db.firebase.currUser != null) {
        email = widget.db.firebase.currUser!.email ?? '';
      }
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

  void autoFilledToggled(bool value) async {
    await widget.db.settings.set('auto-fill-source', value);
    setState(() {}); // refresh settings screen
  }

  void onExportPress() async {
    List<Note> notes = await widget.db.getAllNotes();
    if (backupOption == 'Markdown') {
      _downloadNotesAsMarkdownZIP(notes);
    } else {
      _downloadNotesAsJSON(notes);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Exported ${notes.length} notes'),
      duration: const Duration(seconds: 2),
    ));
    widget.db.firebase.analytics.logEvent(name: 'export_notes', parameters: {
      'file_type': backupOption,
    });
  }

  void onImportPress() async {
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
    widget.db.firebase.analytics.logEvent(name: 'click_import_notes');
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
            (await widget.db.getNoteByTitle(note.title)) != null) {
          continue;
        }
        notes.add(note);
      }
    }
    await widget.db.updateNotes(notes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Imported ${notes.length} notes'),
      duration: const Duration(seconds: 2),
    ));
  }

  void onLogoutPress() async {
    await widget.db.logout();
    setState(() {
      isLoggedIn = false;
    });
  }

  void onDeleteAccountPress() async {
    try {
      widget.db.firebase.analytics.logEvent(name: 'click_delete_account');
      await widget.db.firebase.deleteAccount();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        onLogoutPress();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Deleting an account requires a recent login. Please log in again to delete your account'),
          duration: Duration(seconds: 2),
        ));
      } else {
        rethrow;
      }
    }
    setState(() {
      isLoggedIn = false;
    });
  }

  void onForceSyncPress() async {
    widget.db.firebase.analytics.logEvent(name: 'force_sync_notes');
    widget.db.getAllNotes(forceSync: true);
  }

  void onEnableEncryptionPress() async {
    showDialog(
      context: context,
      builder: (_) {
        return EncryptionDialog(setEncryptionKey: (key) async {
          await widget.db.firebase.setEncryptionKey(key);
          setState(() {
            encryptionEnabled = true;
          });
          widget.db.refreshApp();
        });
      },
    );
  }

  void onNotionSyncPress() async {
    showDialog(
      context: context,
      builder: (_) {
        return NotionDialog(setNotionCredentials: (token, id) async {
          await widget.db.firebase.setNotionCredentials(token, id);
          widget.db.refreshApp();
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(
                    Theme.of(context).custom.kDefaultPadding / 3),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      context.go('/');
                    },
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
              const Divider(
                thickness: 1,
                height: 1,
              ),
              Expanded(
                child: SingleChildScrollView(
                    controller: ScrollController(),
                    padding: EdgeInsets.all(
                        Theme.of(context).custom.kDefaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Account", style: TextStyle(fontSize: 12)),
                        const Divider(thickness: 1, height: 1),
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
                            : Auth(
                                db: widget.db,
                                onLogin: (e) {
                                  setState(() {
                                    isLoggedIn = true;
                                    email = e;
                                  });
                                }),
                        SizedBox(
                            height: Theme.of(context).custom.kDefaultPadding),
                        const Text("Backup", style: TextStyle(fontSize: 12)),
                        const Divider(thickness: 1, height: 1),
                        Backup(
                          backupOption: backupOption,
                          onImportPress: onImportPress,
                          onExportPress: onExportPress,
                          onBackupOptionChange: onBackupDropdownChange,
                        ),
                        SizedBox(
                            height: Theme.of(context).custom.kDefaultPadding),
                        const Text("Sync", style: TextStyle(fontSize: 12)),
                        const Divider(thickness: 1, height: 1),
                        SettingItem(
                          title: 'Notion Sync (One-way)',
                          description: 'Add notes to a database',
                          widget: ElevatedButton(
                            onPressed: onNotionSyncPress,
                            child: const Text('Modify'),
                          ),
                        ),
                        LocalSyncSetting(
                          settings: widget.db.settings,
                          getAllNotes: widget.db.getAllNotes,
                        ),
                        SizedBox(
                            height: Theme.of(context).custom.kDefaultPadding),
                        const Text("Other Settings",
                            style: TextStyle(fontSize: 12)),
                        const Divider(thickness: 1, height: 1),
                        Row(children: [
                          const Text("Auto Fill Source",
                              style: TextStyle(fontSize: 12)),
                          Switch(
                              value: widget.db.settings
                                  .get('auto-fill-source', defaultValue: false),
                              onChanged: autoFilledToggled)
                        ]),
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
