import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class SourceContainer extends ConsumerStatefulWidget {
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
  ConsumerState<SourceContainer> createState() => _SourceContainerState();
}

class _SourceContainerState extends ConsumerState<SourceContainer> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? controller;
    controller.text = widget.text ?? controller.text;
  }

  @override
  Widget build(BuildContext context) {
    final noteUtils = ref.watch(noteUtilsProvider);

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
                : () => noteUtils.launchURLBrowser(controller.text, context),
          ),
        ),
      ),
    );
  }
}
