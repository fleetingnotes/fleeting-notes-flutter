
#!/bin/bash
set -e

#Build the web version of the flutter app
echo "Building flutter app for web extension"
flutter build web --release
echo "Finished building flutter app"

#Replace remote library references with packed js
echo "Remove unnecessary files"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
rm -rf $SCRIPT_DIR/build/web/firebasejs
rm $SCRIPT_DIR/build/web/manifest3.json $SCRIPT_DIR/build/web/manifest2.json $SCRIPT_DIR/build/web/popup.html $SCRIPT_DIR/build/web/web-ext.html

echo "Finished building web extension in build/manifest2.zip and build/manifest3.zip"