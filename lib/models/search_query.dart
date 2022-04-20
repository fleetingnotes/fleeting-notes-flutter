import 'Note.dart';

class SearchQuery {
  final String queryRegex;
  final bool searchByTitle;
  final bool searchByContent;
  final bool searchBySource;
  final SortOptions sortBy;

  SearchQuery({
    required this.queryRegex,
    this.searchByTitle = true,
    this.searchByContent = true,
    this.searchBySource = true,
    this.sortBy = SortOptions.dateASC,
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
      n2.timestamp.compareTo(n1.timestamp),
  SortOptions.dateDESC: (Note n1, Note n2) =>
      n1.timestamp.compareTo(n2.timestamp),
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
