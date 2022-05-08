import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:fleeting_notes_flutter/screens/settings/components/auth.dart';
import 'package:fleeting_notes_flutter/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen(
      {Key? key, required this.db, required this.onNotesChange})
      : super(key: key);

  final Database db;
  final VoidCallback onNotesChange;
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String exportOption = 'Markdown';
  String email = '';

  @override
  void initState() {
    super.initState();
    widget.db.getEmail().then((e) {
      setState(() {
        email = e.toString();
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

  void importFiles(FilePickerResult? jsonFile) async {
    if (jsonFile != null) {
      String file = String.fromCharCodes(jsonFile.files.single.bytes!);
      bool allValid = true;
      if (file.isNotEmpty) {
        List<dynamic> contents = await json.decode(file);
        List<Note> newNoteList = [];
        for (var note in contents) {
          // Checks if JSON is valid
          if (note['_id'] == null ||
              note['title'] == null ||
              note['content'] == null ||
              note['timestamp'] == null ||
              note['source'] == null ||
              (note['content'].toString().isEmpty &&
                  note['title'].toString().isEmpty &&
                  note['source'].toString().isEmpty) ||
              note['_id'].toString().isEmpty ||
              RegExp('[${Note.invalidChars}]').firstMatch(note['title']) !=
                  null ||
              await widget.db.titleExists(note['_id'], note['title'])) {
            allValid = false;
            break;
          }
          newNoteList.add(Note.fromMap(note));
        }
        if (!allValid) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Invalid JSON: Could not load all of the notes"),
            duration: Duration(seconds: 2),
          ));
        } else {
          await widget.db.updateNotes(newNoteList);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Imported JSON Successfully!"),
            duration: Duration(seconds: 2),
          ));
          widget.onNotesChange();
        }
      }
    }
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
                      Navigator.pop(context);
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
              SingleChildScrollView(
                  controller: ScrollController(),
                  padding:
                      EdgeInsets.all(Theme.of(context).custom.kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Export Notes",
                          style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      Padding(
                        padding: EdgeInsets.all(
                            Theme.of(context).custom.kDefaultPadding / 2),
                        child: Row(children: [
                          DropdownButton(
                            underline: const SizedBox(),
                            value: exportOption,
                            onChanged: (String? newValue) {
                              setState(() {
                                exportOption = newValue!;
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
                              onPressed: (exportOption != 'JSON')
                                  ? null
                                  : () async {
                                      importFiles(await FilePicker.platform
                                          .pickFiles(
                                              type: FileType.custom,
                                              allowedExtensions: ['json']));
                                    },
                              child: const Text('Import')),
                          ElevatedButton(
                              onPressed: () async {
                                List<Note> notes =
                                    await widget.db.getAllNotes();
                                if (exportOption == 'Markdown') {
                                  _downloadNotesAsMarkdownZIP(notes);
                                } else {
                                  _downloadNotesAsJSON(notes);
                                }
                                widget.db.firebase.analytics.logEvent(
                                    name: 'export_notes',
                                    parameters: {
                                      'file_type': exportOption,
                                    });
                              },
                              child: const Text('Export')),
                        ]),
                      ),
                      SizedBox(
                          height: Theme.of(context).custom.kDefaultPadding / 2),
                      const Text("Sync", style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      (widget.db.isLoggedIn())
                          ? Padding(
                              padding: EdgeInsets.all(
                                  Theme.of(context).custom.kDefaultPadding / 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(email),
                                    const Spacer(),
                                    ElevatedButton(
                                        onPressed: () {
                                          widget.db.logout();
                                          widget.onNotesChange();
                                          setState(() {});
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
                                          widget.db.firebase.analytics.logEvent(
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
                                widget.onNotesChange();
                                setState(() {
                                  email = e;
                                });
                              }),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
