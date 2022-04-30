#!/bin/bash
set -e

#Build the web version of the flutter app
echo "Building flutter app for web extension"
rm -rf build/web build/web-ext
flutter build web --web-renderer html --csp --release
mv build/web build/web-ext
echo "Finished building flutter app"

#Replace remote library references with packed js
echo "Replacing remote js libraries with packed versions"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sed -i -e 's|https\:\/\/www.gstatic\.com\/||g' $SCRIPT_DIR/build/web-ext/main.dart.js

cd build/web-ext
#ZIP chrome 
cp manifest3.json manifest.json
zip -r ../mainfest3.zip .

#ZIP firefox
cp manifest2.json manifest.json
zip -r ../mainfest2.zip . 

rm manifest.json
echo "Finished building web extension in build/manifest2.zip and build/manifest3.zip"