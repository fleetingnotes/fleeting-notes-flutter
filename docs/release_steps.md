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

## Releasing Safari Ext
8. Run `./build_web_ext.sh`
9. Open XCode for `safari` project and update version
10. Product > Archive, then upload to App Store + Automatically Sign

Release Checklist:
- [ ] iOS (https://appstoreconnect.apple.com/apps/1615226800/appstore/ios/version/inflight)
- [ ] Android (https://play.google.com/console/u/0/developers/5327230890052241772/app/4976191625623411474/tracks/production)
- [ ] firefox (https://addons.mozilla.org/en-CA/developers/addon/fleeting-notes/versions/submit/)
- [ ] Chrome (https://chrome.google.com/webstore/devconsole/4d8ee7e3-234d-4403-85bb-2b633b407fbb/gcplhmogdjioeaenmehmapbdonklmdnc/edit/package?hl=en)
- [ ] Web (https://app.netlify.com/sites/my-fleetingnotes/deploys)
- [ ] MacOS (https://appstoreconnect.apple.com/apps/1615226800/appstore/macos/version/inflight)
