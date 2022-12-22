import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:hive/hive.dart';
import 'mock_box.dart';

class MockDatabase extends Database {
  MockDatabase({
    required super.supabase,
    required super.settings,
    required super.localFileSync,
  });
  Box? _currBox;
  Map<String, Box> allBoxes = {'local': MockBox(), 'supabase': MockBox()};
  @override
  Future<Box> getBox() async {
    var boxName = (supabase.currUser?.id == null) ? 'local' : 'supabase';
    _currBox = allBoxes[boxName];
    return _currBox!;
  }
}
