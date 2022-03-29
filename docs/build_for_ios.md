1. [Bumpversion for release](bump_version_for_release.md)
2. Add developer profile (Xcode > Preferences > Accounts)
3. Open Xcode and under `Runner` and `Identity`, update `Version` and `Build` to build number
4. Run `flutter build ipa`
5. Open `build/ios/archive/MyApp.xcarchive` in Xcode.
6. Click `Validate App`
7. `Distribute App` to App Store

For more details visit: https://docs.flutter.dev/deployment/ios#create-a-build-archive-with-xcode