1. Ensure you can run app on iOS, Android, and Web
2. Checkout a new release branch
```
git checkout -b version-X.X.X
```
3. [Run bumpversion script and push changes / tags](bump_version_for_release.md)
4. After github actions runs, there should be a draft with all the build assets
5. Build and release macOS app `flutter build macos --release`
6. Use these assets to distribute app on App Store Connect, Google Play Store, Firefox Extension, Google Extension,  Netlify, & MacOS
7. Drag and drop the "build/ios/ipa/*.ipa" bundle into the Apple Transport macOS app https://apps.apple.com/us/app/transporter/id1450874784