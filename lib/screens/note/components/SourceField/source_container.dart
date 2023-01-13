import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class SourceContainer extends StatefulWidget {
  const SourceContainer({
    Key? key,
    this.controller,
    this.text,
    this.onChanged,
    this.overrideSourceUrl = false,
    this.readOnly = false,
  }) : super(key: key);

  final String? text;
  final TextEditingController? controller;
  final VoidCallback? onChanged;
  final bool overrideSourceUrl;
  final bool readOnly;

  @override
  State<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends State<SourceContainer> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? controller;
    controller.text = widget.text ?? controller.text;
  }

  void launchURLBrowser(String url, BuildContext context) async {
    void _failUrlSnackbar(String message) {
      var snackBar = SnackBar(
        content: Text(message),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
      return;
    }
    try {
      await launchUrl(uri);
    } catch (e) {
      String errText = 'Could not launch `$url`';
      _failUrlSnackbar(errText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: widget.readOnly,
      style: Theme.of(context).textTheme.bodyMedium,
      controller: controller,
      onChanged: (text) {
        widget.onChanged?.call();
      },
      decoration: InputDecoration(
        hintText: "Source",
        border: const OutlineInputBorder(),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            tooltip: 'Open URL',
            icon: const Icon(Icons.open_in_new),
            onPressed: (controller.text == '')
                ? null
                : () => launchURLBrowser(controller.text, context),
          ),
        ),
      ),
    );
  }
}
