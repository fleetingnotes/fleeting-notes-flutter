
#!/bin/bash
set -e

#Build the web version of the flutter app
echo "Building flutter app for web extension"
rm -rf build/web build/web-app
flutter build web --release
mv build/web build/web-app
echo "Finished building flutter app"

#Replace remote library references with packed js
echo "Remove unnecessary files"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
rm -rf $SCRIPT_DIR/build/web-app/firebasejs
rm $SCRIPT_DIR/build/web-app/manifest3.json $SCRIPT_DIR/build/web-app/manifest2.json $SCRIPT_DIR/build/web-app/popup.html $SCRIPT_DIR/build/web-app/web-ext.html

echo "Finished building web app in build/web-app"