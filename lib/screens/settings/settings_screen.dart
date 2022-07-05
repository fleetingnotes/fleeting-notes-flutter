import 'package:file_picker/file_picker.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
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

  @override
  void initState() {
    super.initState();

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
        // checks if title is invalid
        if (RegExp('[${Note.invalidChars}]').firstMatch(title) != null ||
            await widget.db.getNoteByTitle(title) != null) {
          continue;
        }
        var note = Note.newNoteFromFile(title, content);
        notes.add(note);
      }
    }
    await widget.db.updateNotes(notes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Imported ${notes.length} notes'),
      duration: const Duration(seconds: 2),
    ));
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
                        Row(children: [
                          const Text("Auto Fill Source",
                              style: TextStyle(fontSize: 12)),
                          Switch(
                              value: widget.db.fillSource(),
                              onChanged: autoFilledToggled)
                        ]),
                        const Divider(thickness: 1, height: 1),
                        SizedBox(
                            height:
                                Theme.of(context).custom.kDefaultPadding / 2),
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
                            height:
                                Theme.of(context).custom.kDefaultPadding / 2),
                        const Text("Sync", style: TextStyle(fontSize: 12)),
                        const Divider(thickness: 1, height: 1),
                        (isLoggedIn)
                            ? Padding(
                                padding: EdgeInsets.all(
                                    Theme.of(context).custom.kDefaultPadding /
                                        2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(email),
                                      const Spacer(),
                                      ElevatedButton(
                                          onPressed: () async {
                                            await widget.db.logout();
                                            setState(() {
                                              isLoggedIn = false;
                                            });
                                          },
                                          child: const Text('Logout'))
                                    ]),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: Theme.of(context)
                                              .custom
                                              .kDefaultPadding),
                                      child: ElevatedButton(
                                          onPressed: () {
                                            widget.db.firebase.analytics
                                                .logEvent(
                                                    name: 'force_sync_notes');
                                            widget.db
                                                .getAllNotes(forceSync: true);
                                          },
                                          child: const Text('Force Sync')),
                                    ),
                                  ],
                                ),
                              )
                            : Auth(
                                db: widget.db,
                                onLogin: (e) {
                                  setState(() {
                                    isLoggedIn = true;
                                    email = e;
                                  });
                                }),
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
