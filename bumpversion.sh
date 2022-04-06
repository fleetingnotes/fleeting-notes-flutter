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
  version=$1
  git commit -m "Bump version to $version" pubspec.yaml web/manifest2.json web/manifest3.json
  git tag v$version
fi
