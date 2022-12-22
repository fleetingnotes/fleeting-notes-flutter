import 'dart:async';
import 'package:watcher/watcher.dart';
import 'package:fleeting_notes_flutter/services/sync/local_file_sync.dart';

class MockLocalFileSync extends LocalFileSync {
  MockLocalFileSync({required super.settings, super.fs});
  StreamController<WatchEvent> dirController = StreamController.broadcast();

  @override
  Stream<WatchEvent> get dirStream => dirController.stream;
}
