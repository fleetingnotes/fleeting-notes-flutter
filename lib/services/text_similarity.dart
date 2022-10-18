import 'package:dio/dio.dart';

class TextSimilarity {
  final Dio dio = Dio();
  Future<Map<String, double>> getSentenceSimilarity(
      String text, List<String> sentences) async {
    var response = await dio.post(
      'https://us-central1-fleetingnotes-22f77.cloudfunctions.net/rank_sentence_similarity',
      data: {
        'query': text,
        'sentences': sentences,
      },
    );
    Map<String, double> linkMap = Map.from(response.data);
    return linkMap;
  }

  Future<List<String>> orderListByRelevance(
      String text, List<String> links) async {
    Map<String, double> linkMap = await getSentenceSimilarity(text, links);
    List<String> similarLinks = linkMap.keys.toList();
    similarLinks.sort((k1, k2) => linkMap[k2]!.compareTo(linkMap[k1]!));
    return similarLinks.toList();
  }
}
