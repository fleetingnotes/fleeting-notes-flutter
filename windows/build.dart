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
      version: Version.parse('0.11.1'),
      publisher: 'Matthew Wong',
      urls: InnoSetupAppUrls(
        homeUrl: Uri.parse('https://fleetingnotes.app/'),
      ),
    ),
    files: InnoSetupFiles(
      executable: File('build/windows/runner/Release/Fleeting Notes.exe'),
      location: Directory('build/windows/runner/Release'),
    ),
    name: const InnoSetupName('FleetingNotesWindowsInstaller'),
    location: InnoSetupInstallerDirectory(
      Directory('build'),
    ),
    icon: InnoSetupIcon(
      File('assets/favicon.ico'),
    ),
  ).make();
}
