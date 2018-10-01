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

NEEDLE='\.\.\.\.\.a\.p\.p\.l\.i\.c\.a\.t\.i\.o\.n\.\.\.\.\.'
REGEX='\.\.\.\.\.a\.p\.p\.l\.i\.c\.a\.t\.i\.o\.n\.\.\.\.\.((([^.]\.?)+(\.\.\.)?)+)\.\.\.\.\.'
APKID=$(unzip -p "$APK" AndroidManifest.xml | sed -r "s|[^a-zA-Z0-9]|.|g" | grep "$NEEDLE" | sed -r "s|.*$REGEX.*|\1|g" | sed -r "s|\.([^.])|\1|g" | sed "s|\.\.|.|g")
APKDISPLAYNAME=$(echo "$APKID" | sed "s|\.||g")

sedpipe() {
  sed "s|APPID|$APKID|g" | sed "s|APPDISPLAYNAME|$APKDISPLAYNAME|g"
}

cpfile() {
  NAME="$1"
  OUTNAME=$(echo "$NAME" | sedpipe)
  mkdir -p "$TMP/$(dirname $OUTNAME)"
  cat "$SELF/$NAME" | sedpipe > "$TMP/$OUTNAME"
  chmod 755 "$TMP/$OUTNAME"
}

echo "Turning $APK into $ZIP (id='$APKID', display='$APKDISPLAYNAME')"

TMP=$(mktemp -d)

for f in META-INF/com/google/android/update-binary 08-APPID.sh; do
  cpfile "$f"
done

cd "$TMP"
zip -r "$ZIP" .
cd /
rm -rf "$TMP"

echo "DONE!"
