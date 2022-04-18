1. Ensure you can run app on iOS, Android, and Web
2. Checkout a new release branch
```
git checkout -b vX.X.X
```
3. [Update Version/Build Number for iOS](build_for_ios.md). Then commit changes.
4. [Run bumpversion script and push changes / tags](bump_version_for_release.md)
5. On github create a new release with vX.X.X tags and add the changes made
6. Distribute app on App Store Connect, Google Play Store, Firefox Extension, Google Extension