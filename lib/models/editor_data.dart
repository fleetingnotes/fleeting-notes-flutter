import 'package:fleeting_notes_flutter/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/Note.dart';
import '../models/exceptions.dart';
import 'package:path/path.dart' as p;

// utilities to help do things with notes
class EditorData {
  ProviderRef ref;
  EditorData(this.ref);
  TextEditingController titleController = TextEditingController();
  MutableDocument contentDoc = MutableDocument();
  TextEditingController sourceController = TextEditingController();
}
