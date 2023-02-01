import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:flutter/foundation.dart';

class BE {
  StreamController<Uint8List?> pasteController =
      StreamController<Uint8List?>.broadcast();
  StreamController blurController = StreamController<Event>.broadcast();
  Future<String> getSelectionText() async => '';
  Future<String> getSourceUrl({String defaultText = ''}) async => defaultText;
}
