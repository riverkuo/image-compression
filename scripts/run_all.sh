#!/usr/bin/env bash
# 一鍵跑完簡報中的所有指令。
# 指令都在 images/original/ 裡執行，輸出檔也放在同一個資料夾。
# 檔名規則：原圖名稱.參數簡寫.副檔名（例如 photo.q75.jpg）

set -euo pipefail

# ── 1. 安裝 ImageMagick（已安裝就跳過）────────────────────────
if ! command -v magick >/dev/null 2>&1; then
  echo "找不到 ImageMagick，開始安裝…"
  if command -v brew >/dev/null 2>&1; then
    brew install imagemagick
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y imagemagick
  else
    echo "請手動安裝 ImageMagick 7：https://imagemagick.org/script/download.php" >&2
    exit 1
  fi
fi
if ! command -v magick >/dev/null 2>&1; then
  echo "需要 ImageMagick 7（magick 指令），目前裝到的可能是 6 版。" >&2
  exit 1
fi
magick -version | head -1

cd "$(dirname "$0")/../images/original"
echo "在 $(pwd) 執行"

step() { printf '\n── %s ──\n' "$1"; }

# ── 2. 簡報中的指令（依頁碼順序）──────────────────────────────

step "p2 第一次壓縮"
magick photo.png -quality 75 photo.q75.jpg

step "p9 拆成 Y、Cb、Cr 三張"
magick photo.png -colorspace YCbCr -separate photo.ycbcr_%d.png

step "p17 resize：先縮小再減色 vs 先減色再縮小"
magick graphic.png -resize 50% -colors 16 graphic.resize50.c16.png    # 先縮小，再減色
magick graphic.png -colors 16 -resize 50% graphic.c16.resize50.png    # 先減色再縮小：又長出新顏色，檔案變大

step "p21 photo 不同 quality"
magick photo.png -strip -sampling-factor 4:2:0 -quality 95 photo.q95.jpg
magick photo.png -strip -sampling-factor 4:2:0 -quality 75 photo.q75.jpg
magick photo.png -strip -sampling-factor 4:2:0 -quality 50 photo.q50.jpg
magick photo.png -strip -sampling-factor 4:2:0 -quality 20 photo.q20.jpg
magick photo.png -strip -sampling-factor 4:2:0 -quality 5  photo.q5.jpg

step "p18 PSNR（單位 dB）"
# 放在 p21 之後執行，photo.q75.jpg 才會是 -strip 版本
magick compare -metric PSNR photo.png photo.q75.jpg null: || true; echo

step "p22 差異熱區圖"
magick photo.png photo.q75.jpg -compose difference -composite -colorspace gray -evaluate multiply 8 photo.q75.diff.png
magick photo.png photo.q20.jpg -compose difference -composite -colorspace gray -evaluate multiply 8 photo.q20.diff.png
magick photo.png photo.q5.jpg -compose difference -composite -colorspace gray -evaluate multiply 8 photo.q5.diff.png

step "p23 graphic 不同 quality"
magick graphic.png -strip -sampling-factor 4:2:0 -quality 75 graphic.q75.jpg
magick graphic.png -strip -sampling-factor 4:2:0 -quality 20 graphic.q20.jpg
magick graphic.png -strip -sampling-factor 4:2:0 -quality 5  graphic.q5.jpg

step "p24 photo vs graphic"
magick photo.png   -strip -sampling-factor 4:2:0 -quality 75 photo.q75.jpg
magick graphic.png -strip -sampling-factor 4:2:0 -quality 95 graphic.q95.jpg

step "p25 手動模擬 chroma subsampling"
magick photo.png -colorspace YCbCr -separate photo.ycbcr_%d.png                 # 拆成 Y、Cb、Cr 三張
magick photo.ycbcr_0.png \( photo.ycbcr_1.png -resize 50% -resize 200% \) \( photo.ycbcr_2.png -resize 50% -resize 200% \) \
       -set colorspace YCbCr -combine -colorspace sRGB photo.sim_cbcr.png       # 中間：只縮 Cb/Cr
magick \( photo.ycbcr_0.png -resize 50% -resize 200% \) photo.ycbcr_1.png photo.ycbcr_2.png \
       -set colorspace YCbCr -combine -colorspace sRGB photo.sim_y.png          # 右邊：只縮 Y

step "p26 -sampling-factor 4:4:4 vs 4:2:0"
magick graphic.png -quality 90 -sampling-factor 4:4:4 graphic.q90.444.jpg
magick graphic.png -quality 90 -sampling-factor 4:2:0 graphic.q90.420.jpg

step "p27 graphic 減色"
magick graphic.png +dither -colors 64 graphic.c64.png
magick graphic.png +dither -colors 16 graphic.c16.png
magick graphic.png +dither -colors 8 graphic.c8.png
magick graphic.png -dither FloydSteinberg -colors 8 graphic.c8.dither.png

step "p28 photo 減色"
magick photo.png   +dither -colors 64 photo.c64.png
magick photo.png   -dither FloydSteinberg -colors 64 photo.c64.dither.png
magick photo.png   +dither -colors 16 photo.c16.png
magick photo.png   -dither FloydSteinberg -colors 16 photo.c16.dither.png
magick graphic.png +dither -colors 64 graphic.c64.png

# ── 3. 列出所有檔案大小 ───────────────────────────────────────
step "檔案大小"
ls -l *.png *.jpg | awk '{printf "%10s  %s\n", $5, $9}'
