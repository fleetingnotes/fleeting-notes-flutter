import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

void main() {
  // --------------------------------------------------------------------------
  // Simple Usage
  // --------------------------------------------------------------------------
  InnoSetup(
    app: InnoSetupApp(
      name: 'Fleeting Notes',
      version: Version.parse('0.8.4'),
      publisher: 'Matthew Wong',
      urls: InnoSetupAppUrls(
        homeUrl: Uri.parse('https://fleetingnotes.app/'),
      ),
    ),
    files: InnoSetupFiles(
      executable:
          File('build/windows/runner/Release/fleeting_notes_flutter.exe'),
      location: Directory('build/windows/runner/Release'),
    ),
    name: const InnoSetupName('windows_installer'),
    location: InnoSetupInstallerDirectory(
      Directory('build'),
    ),
    icon: InnoSetupIcon(
      File('icons/64.png'),
    ),
  ).make();
}
