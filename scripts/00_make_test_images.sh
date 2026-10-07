#!/usr/bin/env bash
# 產生合成測試圖 images/original/graphic.png：
#   - 上半：平滑漸層（量化後最容易看到色帶）
#   - 中間：藍底紅字、細線（chroma subsampling 最容易出現顏色溢出）
#   - 下半：黑白細線與棋盤格（JPEG 在銳利邊緣附近會出現振鈴 / 蚊噪）
# images/original/photo.png 是 scikit-image 內建的 NASA 太空人照（公有領域），直接放在 repo 裡。
source "$(dirname "$0")/_common.sh"

section "產生 graphic.png"

"${IM[@]}" -size 512x512 xc:white \
  \( -size 512x128 gradient:'#1e3a8a'-'#f97316' \) -geometry +0+0 -composite \
  \( -size 512x40 -define gradient:direction=east gradient:'#000000'-'#ffffff' \) -geometry +0+128 -composite \
  -fill '#1d4ed8' -draw 'rectangle 0,184 511,320' \
  -fill '#ef4444' "${FONT_ARGS[@]}" -pointsize 44 -draw "text 24,240 'RED on BLUE'" \
  -fill '#22c55e' -pointsize 28 -draw "text 24,290 'green text 1234567890'" \
  -stroke black -strokewidth 1 \
  -draw 'line 20,340 492,340' -draw 'line 20,346 492,346' -draw 'line 20,352 492,352' \
  -draw 'line 20,360 492,380' -draw 'line 20,384 492,420' \
  -stroke none -fill black "${FONT_ARGS[@]}" -pointsize 16 \
  -draw "text 24,450 'Small text: The quick brown fox jumps over the lazy dog.'" \
  \( -size 4x4 xc:white -fill black -draw 'rectangle 0,0 1,1' -draw 'rectangle 2,2 3,3' \
     -write mpr:cb +delete \) \
  \( -size 160x40 tile:mpr:cb \) -geometry +330+462 -composite \
  -depth 8 -strip "$ORIG/graphic.png"

echo "→ $ORIG/graphic.png"
