import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NoteSource extends StatelessWidget {
  const NoteSource({
    Key? key,
    required this.source,
    this.height,
    this.width,
    this.fit = BoxFit.fitWidth,
  }) : super(key: key);

  final String source;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      width: double.infinity,
      imageUrl: source,
      imageBuilder: (context, imageProvider) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        );
      },
      errorWidget: (context, url, err) => const Icon(Icons.image, size: 50),
    );
  }
}
