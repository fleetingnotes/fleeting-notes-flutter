import 'dart:convert';

import 'package:test/test.dart';
import 'package:fleeting_notes_flutter/models/Note.dart';

void main() {
  test("Expect JSON structure to be the same", () {
    var note = Note.empty();
    var jsonNote = jsonDecode(jsonEncode(note));
    expect(jsonNote['id'].runtimeType, String);
    expect(jsonNote['title'].runtimeType, String);
    expect(jsonNote['content'].runtimeType, String);
    expect(jsonNote['created_at'].runtimeType, String);
    expect(jsonNote['modified_at'].runtimeType, String);
  });
}
