import 'package:fleeting_notes_flutter/constants.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/realm_db.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, required this.db}) : super(key: key);

  final RealmDB db;
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String exportOption = 'Markdown';

  _downloadNotesAsMarkdownZIP(List<Note> notes) {
    var encoder = ZipEncoder();
    var archive = Archive();

    for (var note in notes) {
      var mdContent = note.content;
      mdContent += (note.source.isNotEmpty) ? '\n\n---\n\n' + note.source : '';
      var bytes = utf8.encode(mdContent);
      ArchiveFile archiveFiles = ArchiveFile.stream(
        (note.title == '') ? note.id.toString() : note.title,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 3),
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
                  padding: const EdgeInsets.all(kDefaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Export Notes",
                          style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(kDefaultPadding / 2),
                        child: Row(children: [
                          DropdownButton(
                            underline: SizedBox(),
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
                              onPressed: () async {
                                List<Note> notes =
                                    await widget.db.getAllNotes();
                                if (exportOption == 'Markdown') {
                                  _downloadNotesAsMarkdownZIP(notes);
                                } else {
                                  _downloadNotesAsJSON(notes);
                                }
                              },
                              child: const Text('Export')),
                        ]),
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      const Text("Sync", style: TextStyle(fontSize: 12)),
                      const Divider(thickness: 1, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(kDefaultPadding / 2),
                        child: ElevatedButton(
                            onPressed: () =>
                                widget.db.getAllNotes(forceSync: true),
                            child: const Text('Force Sync')),
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
