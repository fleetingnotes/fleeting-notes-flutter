import 'package:flutter_mongodb_realm/flutter_mongo_realm.dart';
import 'models/Note.dart';

class RealmDB {
  // TODO: pass collection as parameter
  RealmDB({required this.collection});

  final MongoCollection collection;

  Future<List<Note>> getNotes() async {
    List<MongoDocument> docs = await collection.find();

    var notes = docs
        .map((item) => Note(
              id: item.get("_id").toString(),
              title: item.get("title").toString(),
              content: item.get("content").toString(),
            ))
        .toList();
    return notes;
  }
}
