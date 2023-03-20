#!/bin/bash
set -e

#Build the web version of the flutter app
echo "Building flutter app for web extension"
rm -rf build/web build/web-ext
flutter build web --web-renderer html --csp --release
mv build/web build/web-ext
rm -rf build/web-ext/canvaskit
echo "Finished building flutter app"

cd build/web-ext
#ZIP chrome 
cp manifest3.json manifest.json
cp extension/background.js extension/background3.js
zip -q -x 'manifest\d.json' -r ../web-ext-3.zip .

#ZIP firefox
cp manifest2.json manifest.json
cp extension/background.js extension/background2.js
## Transform background.js & generate background2.js
sed -i '' 's/chrome\./browser\./g' extension/background2.js
sed -i '' 's/browser\.action/browser\.browserAction/g' extension/background2.js
sed -i '' "s/\'action\'/\'page_action\'/g" extension/background2.js

zip -q -x 'manifest\d.json' -r ../web-ext-2.zip . 

rm -rf ../web-ext-3
mkdir ../web-ext-3
unzip ../web-ext-3.zip -d ../web-ext-3

rm manifest.json
echo "Finished building web extension in build/manifest2.zip and build/manifest3.zip"