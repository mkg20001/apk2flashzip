#!/bin/bash

APK="$1"
ZIP="$2"
SELF=$(dirname "$(readlink -f $0)")

if [ -z "$APK" ]; then
  echo "Usage: $0 /path/to/apk" 2>&1
  exit 2
fi

set -e

if [ -z "$ZIP" ]; then
  ZIP=$(echo "$APK" | sed -r "s|\\.apk$|\\.zip|")
fi

APK=$(readlink -f "$APK")
ZIP=$(readlink -f "$ZIP")

NEEDLE='\.\.\.\.\.m\.a\.n\.i\.f\.e\.s\.t\.\.\.\.\.'
REGEX='\.\.\.\.\.m\.a\.n\.i\.f\.e\.s\.t\.\.\.\.\.((([^.]\.?)+(\.\.\.)?)+)\.\.\.\.\.'
APKID=$(unzip -p "$APK" AndroidManifest.xml | sed -r "s|[^a-zA-Z0-9]|.|g" | grep "$NEEDLE" | sed -r "s|.*$REGEX.*|\1|g" | sed -r "s|\.([^.])|\1|g" | sed "s|\.\.|.|g")
APKDISPLAYNAME=$(echo "$APKID" | sed -r "s|.+\.([^.]+)$|\1|g")

sedpipe() {
  sed "s|APPID|$APKID|g" | sed "s|APPDISPLAYNAME|$APKDISPLAYNAME|g"
}

cpfile() {
  NAME="$1"
  OUTNAME=$(echo "$NAME" | sedpipe)
  mkdir -p "$TMP/$(dirname $OUTNAME)"
  echo "'$SELF/template/$NAME' -> '$TMP/$OUTNAME'"
  cat "$SELF/template/$NAME" | sedpipe > "$TMP/$OUTNAME"
  chmod 755 "$TMP/$OUTNAME"
}

echo "Turning $APK into $ZIP (id='$APKID', display='$APKDISPLAYNAME')"

TMP=$(mktemp -d)

for f in META-INF/com/google/android/update-binary 80-APPID.sh; do
  cpfile "$f"
done
cp -v "$APK" "$TMP/$APKID.apk"

cd "$TMP"
zip -r "$ZIP" .
cd /
rm -rf "$TMP"

echo "DONE!"
