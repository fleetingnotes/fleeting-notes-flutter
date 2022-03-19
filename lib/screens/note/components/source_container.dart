@JS()
library main;

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'dart:js_util';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

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
  bool sourceFieldVisible = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      sourceFieldVisible = widget.controller.text.isNotEmpty || !kIsWeb;
    });
  }

  void launchURLBrowser(String url, BuildContext context) async {
    void _failUrlSnackbar(String message) {
      var snackBar = SnackBar(
        content: Text(message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    Uri? uri = Uri.tryParse(url);
    String newUrl = '';
    if (uri == null) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
      return;
    }
    newUrl =
        (uri.scheme.isEmpty) ? 'https://' + uri.toString() : uri.toString();

    if (await canLaunch(newUrl)) {
      await launch(newUrl);
    } else {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
    }
  }

  Future<String> getSourceUrl({String defaultText = ''}) async {
    try {
      var queryOptions = jsify({'active': true, 'currentWindow': true});
      dynamic tabs = await promiseToFuture(queryTabs(queryOptions));
      return getProperty(tabs[0], 'url');
    } catch (e) {
      return defaultText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: (sourceFieldVisible)
          ? TextField(
              style: Theme.of(context).textTheme.bodyText2,
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: "Source",
                border: InputBorder.none,
                suffixIcon: IconButton(
                  tooltip: 'Open URL',
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () =>
                      launchURLBrowser(widget.controller.text, context),
                ),
              ),
            )
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
