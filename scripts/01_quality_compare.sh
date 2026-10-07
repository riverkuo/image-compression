#!/usr/bin/env bash
# Demo 01：JPEG -quality 在做什麼？
#
# 原理：JPEG 把圖切成 8x8 區塊做 DCT（轉成頻率），再把每個頻率係數「除以量化表後四捨五入」。
#       -quality 越低 → 量化表的數字越大 → 越多高頻係數被捨入成 0 → 檔案越小，
#       但細節（高頻）不見了，區塊邊界也開始看得出來（blocking）。
#
# 產出：
#   output/01_quality/*.jpg            各 quality 的 JPEG
#   output/01_quality/results.md       檔案大小 / 壓縮比 / PSNR 表
#   output/01_quality_zoom.png         同一區域放大比較（看 8x8 區塊）
#   output/01_quality_diff.png         和原圖的差異熱區圖（亮 = 被丟掉的資訊多）
#   output/01_quality_graphic.png      文字 / 線條圖在低 quality 下的振鈴（ringing）
source "$(dirname "$0")/_common.sh"

QUALITIES=(95 75 50 20 5)
D="$OUT/01_quality"
mkdir -p "$D"

section "Demo 01：不同 -quality 的 JPEG"

for img in photo graphic; do
  src="$ORIG/$img.png"
  # 基準：用固定設定重存一次 24-bit PNG，讓「原始 PNG」的大小不受原檔當初怎麼存的影響
  "${IM[@]}" "$src" -strip -define png:compression-level=9 "PNG24:$D/${img}_lossless.png"
  # 為了只比較「量化」的影響，固定使用 4:2:0（ImageMagick 在 quality < 90 時的預設值）
  for q in "${QUALITIES[@]}"; do
    "${IM[@]}" "$src" -strip -sampling-factor 4:2:0 -quality "$q" "$D/${img}_q${q}.jpg"
  done
done

# ---- 結果表 ----
{
  echo "| 圖片 | 設定 | 檔案大小 | 相對無失真 PNG | PSNR（越高越像原圖） |"
  echo "|---|---|---:|---:|---:|"
  for img in photo graphic; do
    src="$ORIG/$img.png"
    base=$(filesize "$D/${img}_lossless.png")
    echo "| $img | 無失真 PNG（24-bit） | $(kb "$base") | 100% | — |"
    for q in "${QUALITIES[@]}"; do
      f="$D/${img}_q${q}.jpg"
      s=$(filesize "$f")
      echo "| $img | -quality $q | $(kb "$s") | $(pct "$s" "$base") | $(printf "%.2f" "$(psnr "$src" "$f")") dB |"
    done
  done
} > "$D/results.md"
cat "$D/results.md"

# ---- 放大比較：太空人臉部 / 胸章附近 ----
# 裁 64x64 再放大 4 倍，每個 8x8 區塊會變成 32x32，看得出方格
GEOM="64x64+232+136"
tiles=()
zoom_crop "$ORIG/photo.png" "$GEOM" 400 "$D/zoom_orig.png"; tiles+=(-label "original" "$D/zoom_orig.png")
for q in "${QUALITIES[@]}"; do
  zoom_crop "$D/photo_q${q}.jpg" "$GEOM" 400 "$D/zoom_q${q}.png"
  tiles+=(-label "q$q  $(kb "$(filesize "$D/photo_q${q}.jpg")")" "$D/zoom_q${q}.png")
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 "${tiles[@]}" \
  -tile 6x1 -geometry +6+6 -background white "$OUT/01_quality_zoom.png"

# ---- 差異熱區圖 ----
tiles=()
for q in 75 20 5; do
  diff_heatmap "$ORIG/photo.png" "$D/photo_q${q}.jpg" "$D/diff_q${q}.png" 8
  tiles+=(-label "q$q: |orig - jpeg| x8" "$D/diff_q${q}.png")
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 \
  -label "original" "$ORIG/photo.png" "${tiles[@]}" \
  -tile 4x1 -geometry 256x256+6+6 -background white "$OUT/01_quality_diff.png"

# ---- 文字 / 線條：振鈴與蚊噪 ----
GEOM="100x56+18+334"
tiles=()
zoom_crop "$ORIG/graphic.png" "$GEOM" 400 "$D/g_orig.png"; tiles+=(-label "original PNG" "$D/g_orig.png")
for q in 75 20 5; do
  zoom_crop "$D/graphic_q${q}.jpg" "$GEOM" 400 "$D/g_q${q}.png"
  tiles+=(-label "JPEG q$q" "$D/g_q${q}.png")
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 "${tiles[@]}" \
  -tile 4x1 -geometry +6+6 -background white "$OUT/01_quality_graphic.png"

echo
echo "→ $OUT/01_quality_zoom.png"
echo "→ $OUT/01_quality_diff.png"
echo "→ $OUT/01_quality_graphic.png"
