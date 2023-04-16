
#!/bin/bash
set -e

#Build the web version of the flutter app
echo "Building flutter app for web extension"
rm -rf build/web build/web-app
flutter build web --release --web-renderer=html --dart-define-from-file=env.json
mv build/web build/web-app
echo "Finished building flutter app"

#Replace remote library references with packed js
echo "Remove unnecessary files"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR/build/web-app
rm manifest3.json manifest2.json web-ext.html
zip -q -r ../web-app.zip .

echo "Finished building web app in build/web-app"
