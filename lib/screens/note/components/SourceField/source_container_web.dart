import 'package:fleeting_notes_flutter/services/browser_ext/browser_ext.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fleeting_notes_flutter/screens/note/components/SourceField/source_container.dart'
    as sc;
import '../../../../services/database.dart';

class SourceContainer extends StatefulWidget {
  const SourceContainer({
    Key? key,
    required this.controller,
    this.db,
    this.onChanged,
    this.overrideSourceUrl = false,
  }) : super(key: key);

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool overrideSourceUrl;
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
    if (widget.db != null &&
        widget.db!.fillSource() &&
        widget.overrideSourceUrl) {
      setSourceUrl();
    }
  }

  void setSourceUrl() async {
    widget.controller.text = await BrowserExtension()
        .getSourceUrl(defaultText: widget.controller.text);
    widget.onChanged?.call();
    setState(() {
      sourceFieldVisible = true;
    });
  }

  sc.SourceContainer sourceContainer() {
    return sc.SourceContainer(
      controller: widget.controller,
      onChanged: widget.onChanged,
      overrideSourceUrl: widget.overrideSourceUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child:
          (widget.controller.text.isNotEmpty || !kIsWeb || sourceFieldVisible)
              ? sourceContainer()
              : TextButton(
                  onPressed: setSourceUrl,
                  child: const Text('Add Source URL'),
                ),
    );
  }
}
