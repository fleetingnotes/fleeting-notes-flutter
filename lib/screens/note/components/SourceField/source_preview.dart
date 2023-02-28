import 'package:fleeting_notes_flutter/models/url_metadata.dart';
import 'package:fleeting_notes_flutter/widgets/note_source.dart';
import 'package:flutter/material.dart';

class SourcePreview extends StatelessWidget {
  const SourcePreview({
    Key? key,
    required this.metadata,
    this.height = 100,
    this.onPressed,
    this.onClear,
  }) : super(key: key);

  final UrlMetadata metadata;
  final double height;
  final VoidCallback? onPressed;
  final VoidCallback? onClear;

  String getTitle() {
    String? title = metadata.title;
    if (title == null &&
        metadata.description == null &&
        metadata.imageUrl != null) {
      title = metadata.url.split('/').last;
    }
    return title ?? 'No title';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = metadata.imageUrl ?? metadata.url;
    final title = getTitle();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: height,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                if (metadata.imageUrl != null)
                  Container(
                    color: Colors.white,
                    width: height,
                    height: height,
                    child: NoteSource(
                      source: imageUrl,
                      fit: BoxFit.fitHeight,
                      height: height,
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tooltip(
                          message: title,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: metadata.url,
                          child: Text(
                            metadata.url,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (onClear != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
                  ),
                const SizedBox(width: 8)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
