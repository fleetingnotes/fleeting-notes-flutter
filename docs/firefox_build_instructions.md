1. Ubuntu 20.04
2. Install Flutter (v3.0.1) (https://docs.flutter.dev/get-started/install)
3. Run `flutter pub get`
4. Run `./build_web_app.sh`
5. Run `./build_web_ext.sh`
6. Build will be contained in `build/web-ext-2.zip`

Here is github actions for reference:
```
name: release
on:
  push:
    tags:
      - "v*.*.*"
jobs:
  release-web:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '2.x'
        channel: 'stable'
    - run: flutter pub get
    - run: flutter analyze
    - run: flutter test --platform chrome
    - run: ./build_web_app.sh
    - run: ./build_web_ext.sh
    - uses: softprops/action-gh-release@v1 
      if: startsWith(github.ref, 'refs/tags/')
      with:
        files: |
          build/web-ext-2.zip
          build/web-ext-3.zip
          build/web-app.zip
        draft: true
        fail_on_unmatched_files: true
```