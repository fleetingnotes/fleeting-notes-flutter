import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fleeting_notes_flutter/models/exceptions.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/utils/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:go_router/go_router.dart';

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
    await widget.db.setFillSource(value);
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
                        Padding(
                          padding: EdgeInsets.all(
                              Theme.of(context).custom.kDefaultPadding / 2),
                          child: Row(children: [
                            DropdownButton(
                              underline: const SizedBox(),
                              value: backupOption,
                              onChanged: (String? newValue) {
                                setState(() {
                                  backupOption = newValue!;
                                });
                              },
                              items: const [
                                DropdownMenuItem(
                                  child: Text('Markdown'),
                                  value: 'Markdown',
                                ),
                                DropdownMenuItem(
                                  child: Text('JSON'),
                                  value: 'JSON',
                                ),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                                onPressed: (backupOption) == 'Markdown'
                                    ? onImportPress
                                    : null,
                                child: const Text('Import')),
                            const SizedBox(width: 5),
                            ElevatedButton(
                                onPressed: onExportPress,
                                child: const Text('Export')),
                          ]),
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
                              value: widget.db.fillSource(),
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

class EncryptionDialog extends StatefulWidget {
  const EncryptionDialog({
    Key? key,
    required this.setEncryptionKey,
  }) : super(key: key);

  final Function setEncryptionKey;

  @override
  State<EncryptionDialog> createState() => _EncryptionDialogState();
}

class _EncryptionDialogState extends State<EncryptionDialog> {
  String errMessage = '';
  TextEditingController controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void onSubmit() async {
    try {
      await widget.setEncryptionKey(controller.text);
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        if (e is FleetingNotesException) {
          errMessage = e.message;
        } else {
          errMessage = 'Invalid encryption key';
        }
      });
      _formKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enable Encryption'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This password cannot be changed later'),
              const Text(
                  'If you forget this password, data will remain unusable forever',
                  style: TextStyle(color: Colors.red)),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Enter your encryption key',
                  border: OutlineInputBorder(),
                ),
                validator: (_) => (errMessage.isEmpty) ? null : errMessage,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSubmit,
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class Account extends StatelessWidget {
  const Account({
    Key? key,
    required this.email,
    required this.onLogout,
    required this.onForceSync,
    required this.onDeleteAccount,
    required this.onEnableEncryption,
  }) : super(key: key);

  final String email;
  final VoidCallback onLogout;
  final VoidCallback onForceSync;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEnableEncryption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingItem(
            title: 'Email',
            description: email,
            buttonLabel: 'Logout',
            onPress: onLogout,
          ),
          SettingItem(
            title: 'Force Sync',
            description: 'Sync notes from the cloud to the device',
            buttonLabel: 'Force Sync',
            onPress: onForceSync,
          ),
          SettingItem(
            title: 'End-to-end Encryption',
            description: 'Encrypt notes with end-to-end encryption',
            buttonLabel: (onEnableEncryption == null) ? 'Enabled' : 'Enable',
            onPress: onEnableEncryption,
          ),
          SettingItem(
            title: 'Delete Account',
            description: 'Delete your account and all your notes',
            buttonLabel: 'Delete',
            onPress: () {
              showDialog(
                context: context,
                builder: (context) =>
                    DeleteAccountWidget(onDelete: onDeleteAccount),
              );
            },
          )
        ],
      ),
    );
  }
}

class DeleteAccountWidget extends StatefulWidget {
  const DeleteAccountWidget({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  final VoidCallback onDelete;

  @override
  State<DeleteAccountWidget> createState() => _DeleteAccountWidgetState();
}

class _DeleteAccountWidgetState extends State<DeleteAccountWidget> {
  bool canDeleteAccount = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
              'Are you sure you want to delete your account and all your notes? This action cannot be undone.'),
          const SizedBox(height: 10),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Type "delete" to confirm',
              border: OutlineInputBorder(),
            ),
            validator: (_) => 'Type delete to confirm',
            onChanged: (String? value) {
              setState(() {
                canDeleteAccount = value == 'delete';
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canDeleteAccount
              ? () {
                  Navigator.pop(context);
                  widget.onDelete();
                }
              : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class SettingItem extends StatelessWidget {
  const SettingItem({
    Key? key,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPress,
  }) : super(key: key);

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(description),
              ],
            ),
          ),
        ),
        ElevatedButton(onPressed: onPress, child: Text(buttonLabel))
      ]),
    );
  }
}
