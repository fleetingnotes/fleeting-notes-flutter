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
flutter run --no-sound-null-safety
```

## Building Web Extension

1. Checkout web extension branch and rebase with main
```
git checkout web_ext
git rebase main
```
2. Build the web application
```
flutter build web --web-renderer html --csp --no-sound-null-safety
```
3. Navigate to `build/web/main.dart.js` and search / replace the following:
```
# Note: `../` is an actual path

../stitch.js -> stitch/stitch.js
../stitchUtils.js -> stitch/stitchUtils.js
```
4. Go to browser and `Load unpacked`