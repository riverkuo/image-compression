#!/usr/bin/env bash
# 一鍵跑完所有 demo，並把所有結果表彙整到 output/RESULTS.md
source "$(dirname "$0")/_common.sh"
DIR="$(cd "$(dirname "$0")" && pwd)"

version="$("${IM[@]}" -version | head -1)"
echo "使用：$version"

# graphic.png 是腳本產生的；不存在才產生，避免不同字型讓結果每次不一樣
[ -f "$ORIG/graphic.png" ] || bash "$DIR/00_make_test_images.sh"

bash "$DIR/01_quality_compare.sh"
bash "$DIR/02_chroma_subsampling.sh"
bash "$DIR/03_color_quantization.sh"

{
  echo "# Demo 結果"
  echo
  echo "> 產生時間：$(date '+%Y-%m-%d %H:%M')　｜　$version"
  echo ">"
  echo "> 不同 ImageMagick 版本 / libjpeg 實作的數字會略有差異，但趨勢相同。"
  echo
  echo "## 01. JPEG -quality"
  echo
  cat "$OUT/01_quality/results.md"
  echo
  echo "## 02. Chroma subsampling"
  echo
  cat "$OUT/02_chroma/results.md"
  echo
  echo "## 03. PNG 調色盤量化"
  echo
  cat "$OUT/03_quantize/results.md"
} > "$OUT/RESULTS.md"

section "完成"
echo "比較圖：$OUT/*.png"
echo "數字彙整：$OUT/RESULTS.md"
