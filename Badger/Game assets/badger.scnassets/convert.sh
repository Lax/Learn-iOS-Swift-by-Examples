#!/bin/bash

# usage: convert.sh <folder with png images>

STARTTIME=$(date +%s)

myfiles=`find "$1" -iname '*_normal.png' -o -iname '*_albedo.png'`

for file in $myfiles
do
  echo
    echo Processing $(basename "$file")...

  ASTC_STARTTIME=$(date +%s)
  `xcode-select -p`/Platforms/iPhoneOS.platform/Developer/usr/bin/texturetool -e ASTC --compression-mode-fast --block-width-4 --block-height-4 -o "$(dirname "$file")/$(basename "$file" .png).ktx" -f KTX "$file"
  ASTC_ENDTIME=$(date +%s)

  echo $(($ASTC_ENDTIME - $ASTC_STARTTIME)) seconds to process $(basename "$file").
done

ENDTIME=$(date +%s)

echo $(($ENDTIME - $STARTTIME)) seconds to convert images of $(basename "$1").

