1. [Bumpversion for release](bump_version_for_release.md)
2. Download `fn-upload-key.keystore` and `key.properties` from https://drive.google.com/drive/folders/1-kk-kyLvBZVdRbG8qk_hF_FkCXF1IwQy?usp=sharing
3. Place `fn-upload-key.keystore` in  `android/app` folder
4. Place `key.properties` in `android` folder
5. Increment version and build number (e.g. 0.0.1+1 -> 0.0.2+2) with `./bumpversion` command
6. Run `flutter run --release` and test everything works as expected
7. Build flutter with `flutter build appbundle --release`