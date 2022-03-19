# fleeting_notes_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running Application for dev
```
flutter run
```

## Testing Applications on browser
```
flutter test --platform chrome
```

## Building Web Extension for dev

Simply run the build script.
```
flutter build web --web-renderer html --csp 
```
Then go to chrome and click `Load unpacked` from the extensions page, following instructions to select the `build/web` folder and loading the extension in dev mode.

## Bumpversion for release
Run the bumpversion script and specify version number
```
./bumpversion.sh 1.2.3
git push
git push --tags
```

## Building to Android App Store
1. Download `fn-upload-key.keystore` and `key.properties` from https://drive.google.com/file/d/1ZqQxFx9tCeaCDbaSlw0fGx-7HKxo6woI/view?usp=sharing
2. Place `fn-upload-key.keystore` in  `android/app` folder
3. Place `key.properties` in `android` folder
4. Run `flutter run --release`

## Update App Name
1. Go to `pubspec.yaml` file and edit `name` under `flutter_app_name`
2. Run command `flutter pub run flutter_app_name`

## Update Logo
1. Go to `pubspec.yaml` file and edit `name` under `flutter_icons` and adjust parameters (https://pub.dev/packages/flutter_launcher_icons)
2. Run command `flutter pub run flutter_launcher_icons:main`
