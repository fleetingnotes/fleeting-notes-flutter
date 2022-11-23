import 'package:fleeting_notes_flutter/services/database.dart';
import 'package:hive/hive.dart';
import 'mock_box.dart';

class MockDatabase extends Database {
  MockDatabase({required super.supabase, required super.settings});
  Box? _currBox;

  @override
  Future<Box> getBox() async {
    _currBox ??= MockBox();
    return _currBox!;
  }
}
