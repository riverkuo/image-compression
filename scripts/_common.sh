#!/usr/bin/env bash
# 共用設定：給每個 demo 腳本 source。
# 同時支援 ImageMagick 7（magick）和 ImageMagick 6（convert / compare / identify）。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORIG="$ROOT/images/original"
OUT="$ROOT/output"
mkdir -p "$OUT"

if command -v magick >/dev/null 2>&1; then
  IM=(magick)
  CMP=(magick compare)
  IDENT=(magick identify)
  MONTAGE=(magick montage)
elif command -v convert >/dev/null 2>&1; then
  IM=(convert)
  CMP=(compare)
  IDENT=(identify)
  MONTAGE=(montage)
else
  echo "找不到 ImageMagick，請先安裝：brew install imagemagick" >&2
  exit 1
fi

# montage 的標籤需要字型；找一個系統上有的 TrueType 字型，找不到就用 ImageMagick 預設值。
FONT_ARGS=()
for f in \
  "/System/Library/Fonts/Supplemental/Arial.ttf" \
  "/Library/Fonts/Arial.ttf" \
  "/System/Library/Fonts/Helvetica.ttc" \
  "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf" \
  "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"; do
  if [ -f "$f" ]; then FONT_ARGS=(-font "$f"); break; fi
done

# 檔案大小（bytes）
filesize() { wc -c < "$1" | tr -d ' '; }

# bytes -> 易讀格式（KB）
kb() { awk -v b="$1" 'BEGIN { printf "%.1f KB", b / 1024 }'; }

# 百分比：$1 相對 $2
pct() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f%%", a * 100 / b }'; }

# 兩張圖的 PSNR（dB）。數字越高越接近原圖；> 40 dB 肉眼通常看不出差異。
psnr() {
  # compare 把 metric 寫到 stderr，且有差異時 exit code 為 1，所以要吞掉
  "${CMP[@]}" -metric PSNR "$1" "$2" null: 2>&1 >/dev/null | awk '{print $1}' || true
}

# 不重複的顏色數
unique_colors() { "${IDENT[@]}" -format '%k' "$1"; }

# 把差異放大成熱區圖：|A-B| 轉灰階後放大 N 倍，再上偽色（黑=沒差、亮=差很多）
diff_heatmap() {
  local a="$1" b="$2" out="$3" gain="${4:-8}"
  "${IM[@]}" "$a" "$b" -compose difference -composite \
    -colorspace gray -evaluate multiply "$gain" \
    \( -size 1x1 xc:black xc:navy xc:red xc:yellow xc:white \
       +append -filter triangle -resize '256x1!' \) -clut \
    "$out"
}

# 從圖片裁一塊並用最近鄰放大（看得到一顆顆 pixel / 8x8 區塊）
zoom_crop() {
  local in="$1" geom="$2" scale="$3" out="$4"
  "${IM[@]}" "$in" -crop "$geom" +repage -filter point -resize "${scale}%" "$out"
}

section() { printf '\n== %s ==\n' "$1"; }
