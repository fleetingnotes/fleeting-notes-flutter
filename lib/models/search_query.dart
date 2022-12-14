import 'Note.dart';

class SearchQuery {
  final String query;
  final bool searchByTitle;
  final bool searchByContent;
  final bool searchBySource;
  final SortOptions sortBy;
  final int limit;

  SearchQuery({
    required this.query,
    this.searchByTitle = true,
    this.searchByContent = true,
    this.searchBySource = true,
    this.sortBy = SortOptions.dateASC,
    this.limit = 50,
  });
}

enum SortOptions {
  dateASC,
  dateDESC,
  titleASC,
  titleDSC,
  contentASC,
  contentDESC,
  sourceASC,
  sourceDESC,
}

final Map sortMap = {
  SortOptions.dateASC: (Note n1, Note n2) =>
      n2.createdAt.compareTo(n1.createdAt),
  SortOptions.dateDESC: (Note n1, Note n2) =>
      n1.createdAt.compareTo(n2.createdAt),
  SortOptions.titleASC: (Note n1, Note n2) =>
      n1.title.toLowerCase().compareTo(n2.title.toLowerCase()),
  SortOptions.titleDSC: (Note n1, Note n2) =>
      n2.title.toLowerCase().compareTo(n1.title.toLowerCase()),
  SortOptions.contentASC: (Note n1, Note n2) =>
      n1.content.toLowerCase().compareTo(n2.content.toLowerCase()),
  SortOptions.contentDESC: (Note n1, Note n2) =>
      n2.content.toLowerCase().compareTo(n1.content.toLowerCase()),
  SortOptions.sourceASC: (Note n1, Note n2) =>
      n1.source.toLowerCase().compareTo(n2.source.toLowerCase()),
  SortOptions.sourceDESC: (Note n1, Note n2) =>
      n2.source.toLowerCase().compareTo(n1.source.toLowerCase()),
};

RegExp getQueryRegex(String query) {
  String escapedQuery =
      query.replaceAllMapped(RegExp(r'[^a-zA-Z0-9]'), (match) {
    return '\\${match.group(0)}';
  });
  RegExp r = RegExp(escapedQuery, multiLine: true, caseSensitive: false);
  return r;
}
