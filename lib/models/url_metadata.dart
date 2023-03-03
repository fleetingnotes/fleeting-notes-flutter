class UrlMetadata {
  String url;
  String? title;
  String? description;
  String? imageUrl;

  UrlMetadata({required this.url, this.title, this.description, this.imageUrl});

  bool get isEmpty => title == null && description == null && imageUrl == null;
}
