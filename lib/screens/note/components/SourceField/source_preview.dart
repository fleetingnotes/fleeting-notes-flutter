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

  @override
  Widget build(BuildContext context) {
    final imageUrl = metadata.imageUrl ?? metadata.url;
    final title = metadata.title ?? 'No Title';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: height,
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: NoteSource(
                    source: imageUrl,
                    fit: BoxFit.fitHeight,
                    height: height,
                  ),
                ),
                Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            metadata.url,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    )),
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
