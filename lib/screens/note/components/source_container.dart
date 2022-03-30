import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class SourceContainer extends StatefulWidget {
  const SourceContainer({
    Key? key,
    required this.controller,
    this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool autofocus;

  @override
  State<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends State<SourceContainer> {
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

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: widget.autofocus,
      style: Theme.of(context).textTheme.bodyText2,
      controller: widget.controller,
      onChanged: (text) {
        if (widget.onChanged != null) widget.onChanged!();
      },
      decoration: InputDecoration(
        hintText: "Source",
        border: InputBorder.none,
        suffixIcon: IconButton(
          tooltip: 'Open URL',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => launchURLBrowser(widget.controller.text, context),
        ),
      ),
    );
  }
}
