import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';

class RealmDB {
  // TODO: pass collection as parameter
  RealmDB({required this.collection});

  final MongoCollection collection;

  Future<List<Map<String, String>>> getNotes() async {
    List<MongoDocument> docs = await collection.find();

    var notes = docs
        .map((item) => {
              "id": item.get("_id").toString(),
              "title": item.get("title").toString(),
              "content": item.get("content").toString(),
            })
        .toList();
    return notes;
  }
}
