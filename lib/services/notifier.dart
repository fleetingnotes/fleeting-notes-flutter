import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/search_query.dart';

class SearchNotifier extends StateNotifier<SearchQuery?> {
  SearchNotifier() : super(null);

  void updateSearch(SearchQuery? sq) {
    state = sq?.copy();
  }
}
