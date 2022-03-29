
1. Simply run the build script.
```
flutter build web --web-renderer html --csp 
```
2. Go into `build/web` and rename either `manifest2.json` (Firefox) or `manifest3.json` (Chrome) to `manifest.json`
3. Test Package
On Chrome:
Click `Load unpacked` from the extensions page, following instructions to select the `build/web` folder and loading the extension in dev mode.

On Firefox:
Go to `about:debugging#/runtime/this-firefox` and "Load Temporary Add-on"