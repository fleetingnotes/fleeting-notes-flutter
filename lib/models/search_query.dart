import 'Note.dart';

class SearchQuery {
  String query;
  bool searchByTitle;
  bool searchByContent;
  bool searchBySource;
  SortOptions sortBy;
  int limit;

  SearchQuery({
    this.query = '',
    this.searchByTitle = true,
    this.searchByContent = true,
    this.searchBySource = true,
    this.sortBy = SortOptions.createdASC,
    this.limit = 50,
  });
}

enum SortOptions {
  modifiedASC,
  modifiedDESC,
  createdASC,
  createdDESC,
  titleASC,
  titleDESC,
  contentASC,
  contentDESC,
  sourceASC,
  sourceDESC,
}

Map<String, SortOptions> sortOptionMap = {
  'modified-asc': SortOptions.modifiedASC,
  'modified-desc': SortOptions.modifiedDESC,
  'created-asc': SortOptions.createdASC,
  'created-desc': SortOptions.createdDESC,
  'title-asc': SortOptions.titleASC,
  'title-desc': SortOptions.titleDESC,
  'content-asc': SortOptions.contentASC,
  'content-desc': SortOptions.contentDESC,
  'source-asc': SortOptions.sourceASC,
  'source-desc': SortOptions.sourceDESC,
};

final Map sortMap = {
  SortOptions.modifiedDESC: (Note n1, Note n2) =>
      n2.modifiedAt.compareTo(n1.modifiedAt),
  SortOptions.modifiedASC: (Note n1, Note n2) =>
      n1.modifiedAt.compareTo(n2.modifiedAt),
  SortOptions.createdDESC: (Note n1, Note n2) =>
      n2.createdAt.compareTo(n1.createdAt),
  SortOptions.createdASC: (Note n1, Note n2) =>
      n1.createdAt.compareTo(n2.createdAt),
  SortOptions.titleASC: (Note n1, Note n2) =>
      n1.title.toLowerCase().compareTo(n2.title.toLowerCase()),
  SortOptions.titleDESC: (Note n1, Note n2) =>
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
