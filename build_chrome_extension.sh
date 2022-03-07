#!/usr/bin/env bash

#Build the web version of the flutter app
echo "Building flutter app for web"
flutter build web --web-renderer html --csp --no-sound-null-safety
echo "Finished building flutter app"

#Replace remote library references with packed js
echo "Replacing remote js libraries with packed versions"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sed -i -e 's|https.*/stitch\.js|stitch/stitch\.js|g' $SCRIPT_DIR/build/web/main.dart.js
sed -i -e 's|https.*/stitchUtils\.js|stitch/stitchUtils\.js|g' $SCRIPT_DIR/build/web/main.dart.js
echo "Finished replacing"
