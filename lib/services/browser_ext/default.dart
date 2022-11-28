import 'dart:async';
import 'package:flutter/foundation.dart';

class BE {
  StreamController<Uint8List?> pasteController =
      StreamController<Uint8List?>.broadcast();
  Future<String> getSelectionText() async => '';
  Future<String> getSourceUrl({String defaultText = ''}) async => defaultText;
  Future<String?> getClipboardPermissionState() async => null;
}
