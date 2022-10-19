## Get web builds from file
1. Install flutter v3.3.4
```
apt-get update
apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev curl file git unzip xz-utils zip
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.3.4-stable.tar.xz --output flutter_linux_3.3.4-stable.tar.xz
tar xf flutter_linux_3.3.4-stable.tar.xz
export PATH="`pwd`/flutter/bin:$PATH"
```
2. Unzip source code and `cd` into it 
```
cd /path/to/source/code
```
3. Setup project with `flutter pub get`
4. Run build web-extension script
```
chmod a+x build_web_ext.sh
./build_web_ext.sh
```
5. The zip file created will be in `build` (firefox build will be `build/web-ext-2.zip`)

NOTE: `index.html` and `flutter_service_worker.js` will have slight differences due to different service worker versions across clean builds.