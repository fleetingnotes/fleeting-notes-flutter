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