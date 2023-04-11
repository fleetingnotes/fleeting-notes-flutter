#!/bin/bash
set -e
if [ -z "$1" ]
then
  echo "Please provide a version number (e.g. ./bumpversion.sh 1.2.3 )"
  # TODO: No argument supplied, so bump the patch version.
  # perl -i -pe 's/^(version:\s+\d+\.\d+\.\d+\+)(\d+)$/$1.($2+1)/e' pubspec.yaml
  # version=`grep 'version: ' pubspec.yaml | sed 's/version: //'`
else
  # Argument supplied, so bump to version specified
  perl -i -pe 's/^(version:\s+\d+\.\d+\.\d+\+)(\d+)$/$1.($2+1)/e' pubspec.yaml
  sed -i '' "s/^version.*+/version: $1+/g" pubspec.yaml
  sed -i '' 's|\(.*"version"\): "\(.*\)",.*|\1: '"\"$1\",|" web/manifest2.json
  sed -i '' 's|\(.*"version"\): "\(.*\)",.*|\1: '"\"$1\",|" web/manifest3.json
  perl -i -pe 's/(CURRENT_PROJECT_VERSION = )(\d+)/$1.($2+1)/ge' safari/Fleeting\ Notes.xcodeproj/project.pbxproj
  sed -i '' -e "s/MARKETING_VERSION \\= [^\\;]*\\;/MARKETING_VERSION = $1;/" safari/Fleeting\ Notes.xcodeproj/project.pbxproj
  sed -i '' -e "s/version: Version.parse.*,/version: Version.parse('$1'),/" windows/build.dart
  version=$1
  git commit -m "Bump version to $version" pubspec.yaml web/manifest2.json web/manifest3.json safari/Fleeting\ Notes.xcodeproj/project.pbxproj windows/build.dart
  git tag v$version
fi
