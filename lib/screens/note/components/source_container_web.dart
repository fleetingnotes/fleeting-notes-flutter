@JS()
library main;

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_util';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/source_container.dart'
    as sc;
import 'package:web_browser_detect/web_browser_detect.dart';
import 'package:hive/hive.dart';

import '../../../database.dart';

@JS('chrome.tabs.query')
external dynamic queryTabsChrome(dynamic queryInfo);

@JS('browser.tabs.query')
external dynamic queryTabsBrowser(dynamic queryInfo);

class SourceContainer extends StatefulWidget {
  const SourceContainer({
    Key? key,
    required this.controller,
    this.db,
    this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool autofocus;
  final Database? db;

  @override
  State<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends State<SourceContainer> {
  bool sourceFieldVisible = !kIsWeb;

  @override
  void initState() {
    super.initState();
    setState(() {
      sourceFieldVisible = widget.controller.text.isNotEmpty || !kIsWeb;
    });
  }

  Future<String> getSourceUrl({String defaultText = ''}) async {
    if (!kIsWeb) {
      return defaultText;
    }
    try {
      var queryOptions = jsify({'active': true, 'currentWindow': true});
      dynamic tabs;
      if (Browser().browser == 'Chrome') {
        tabs = await promiseToFuture(queryTabsChrome(queryOptions));
      } else {
        tabs = await promiseToFuture(queryTabsBrowser(queryOptions));
      }
      return getProperty(tabs[0], 'url');
    } catch (e) {
      return defaultText;
    }
  }

  void setSourceUrl() async {
    widget.controller.text =
        await getSourceUrl(defaultText: widget.controller.text);
    if (widget.onChanged != null) widget.onChanged!();
    setState(() {
      sourceFieldVisible = true;
    });
  }

  sc.SourceContainer sourceContainer() {
    setSourceUrl();
    return sc.SourceContainer(
      controller: widget.controller,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: (sourceFieldVisible || widget.db == null
              ? false
              : widget.db!.fillSource())
          ? sourceContainer()
          : TextButton(
              onPressed: setSourceUrl,
              child: const Text('Add Source URL'),
            ),
    );
  }
}
