@JS()
library main;

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'dart:js_util';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/source_container.dart'
    as sc;

@JS('chrome.tabs.query')
external dynamic queryTabs(dynamic queryInfo);

class SourceContainer extends StatefulWidget {
  const SourceContainer({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;

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
      dynamic tabs = await promiseToFuture(queryTabs(queryOptions));
      return getProperty(tabs[0], 'url');
    } catch (e) {
      print(e);
      return defaultText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: (sourceFieldVisible)
          ? sc.SourceContainer(
              controller: widget.controller, onChanged: widget.onChanged)
          : TextButton(
              onPressed: () async {
                widget.controller.text =
                    await getSourceUrl(defaultText: widget.controller.text);
                if (widget.onChanged != null) widget.onChanged!();
                setState(() {
                  sourceFieldVisible = true;
                });
              },
              child: const Text('Add Source URL'),
            ),
    );
  }
}
