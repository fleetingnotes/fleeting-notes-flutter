import 'dart:async';

import 'package:file/file.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';

class MockLocalFileSync extends LocalFileSync {
  MockLocalFileSync({required super.settings, super.fs});
  StreamController<FileSystemEvent> dirController =
      StreamController.broadcast();

  @override
  Stream<FileSystemEvent> get dirStream => dirController.stream;
}
