import 'package:fleeting_notes_flutter/models/search_query.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Plugin {
  final String key;
  final String title;
  final String description;
  final String commandId;

  Plugin(
      {required this.key,
      required this.title,
      required this.description,
      required this.commandId});
}

class PluginCard extends StatefulWidget {
  const PluginCard({
    Key? key,
    required this.plugin,
    this.onSelect,
    this.onTap,
    this.sQuery,
    this.isActive = false,
    this.isSelected = false,
    this.expanded = false,
    this.maxLines,
  }) : super(key: key);

  final bool isActive;
  final bool isSelected;
  final bool expanded;
  final VoidCallback? onSelect;
  final VoidCallback? onTap;
  final Plugin plugin;
  final SearchQuery? sQuery;
  final int? maxLines;

  @override
  State<PluginCard> createState() => _PluginCardState();
}

class _PluginCardState extends State<PluginCard> {
  bool hovering = false;

  onSelect(bool? value) {
    if (value == true) {
      widget.onSelect?.call();
    }
    if (value == false && widget.isSelected) {
      widget.onTap?.call();
    }
  }

  void onPressedPreview(String url) {
    Uri uri = Uri.parse(url);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    double elevation = (widget.isSelected) ? 1 : 0;
    return GestureDetector(
      onLongPress: widget.onSelect,
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() {
          hovering = true;
        }),
        onExit: (_) => setState(() {
          hovering = false;
        }),
        child: Card(
          clipBehavior: Clip.hardEdge,
          elevation: elevation,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.plugin.title.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                widget.plugin.title,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: widget.maxLines,
                              ),
                            ),
                          if (widget.plugin.description.isNotEmpty)
                            Flexible(
                              fit: (widget.expanded)
                                  ? FlexFit.tight
                                  : FlexFit.loose,
                              child: Text(
                                widget.plugin.description,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: widget.maxLines,
                              ),
                            ),
                          if (widget.expanded &&
                              widget.plugin.description.isEmpty)
                            const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
