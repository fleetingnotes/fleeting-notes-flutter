// ignore_for_file: avoid_web_libraries_in_flutter
@JS()
library main;

import 'dart:async';
import 'dart:js_util';
import 'package:fleeting_notes_flutter/services/browser_ext/default.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:web_browser_detect/web_browser_detect.dart';
import 'dart:html';

@JS('window.getSelectionText')
external String getSelectionTextBE(String browserType);
@JS('window.getSourceUrl')
external dynamic getSourceUrlBE(String browserType);

class BE extends d.BE {
  BE() {
    window.addEventListener('message', (event) {
      MessageEvent event2 = event as MessageEvent;
      var buffer = event2.data as Uint8List?;
      pasteController.add(buffer);
    });
    window.addEventListener('blur', (Event event) {
      blurController.add(event);
    });
  }

  @override
  Future<String> getSelectionText() async {
    try {
      String browserType = getBrowserType();
      return await promiseToFuture(getSelectionTextBE(browserType));
    } catch (e) {
      return '';
    }
  }

  @override
  Future<String> getSourceUrl({String defaultText = ''}) async {
    if (!kIsWeb) {
      return defaultText;
    }
    try {
      String browserType = getBrowserType();
      String url = await promiseToFuture(getSourceUrlBE(browserType));
      if (url.startsWith(RegExp(r'.*-extension:\/\/'))) {
        return defaultText;
      }
      return url;
    } catch (e) {
      return defaultText;
    }
  }

  String getBrowserType() {
    if (Browser().browser == 'Chrome') {
      return 'chrome';
    } else {
      return 'browser';
    }
  }
}
