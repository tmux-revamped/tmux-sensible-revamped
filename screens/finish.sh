#!/bin/sh
set -eu

pad=34
radius=12
for png in "$@"; do
  magick "${png}" -background '#1e1e2e' -alpha remove -alpha off "${png}"
  box=$(magick "${png}" -fuzz 4% -format '%@' info:)
  height=${box#*x}
  height=${height%%+*}
  top=${box##*+}
  width=$(magick identify -format '%w' "${png}")
  full=$(magick identify -format '%h' "${png}")
  bottom=$((top + height + pad))
  if [ "${bottom}" -gt "${full}" ]; then
    bottom="${full}"
  fi
  magick "${png}" -crop "${width}x${bottom}+0+0" +repage \
    \( +clone -alpha extract -draw "fill black polygon 0,0 0,${radius} ${radius},0 fill white circle ${radius},${radius} ${radius},0" \
    \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
    -alpha off -compose CopyOpacity -composite "${png}"
  magick "${png}" -dither None -colors 256 "PNG8:${png}"
done
