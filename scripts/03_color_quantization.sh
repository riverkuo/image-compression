#!/usr/bin/env bash
# Demo 03：PNG 的 -colors（調色盤量化）在丟什麼？
#
# 原理：PNG 本身是無失真壓縮（濾波 + Deflate），解壓後每個像素都和原圖一樣。
#       要讓 PNG 變小，常見做法是「先失真、再無失真」：用 -colors N 把上百萬種顏色
#       合併成 N 種，存成調色盤 PNG（每像素只存 1 個 index，<= 8 bit，原本是 24 bit）。
#       顏色變少 → 重複的位元組變多 → Deflate 更好壓。
#       代價是平滑漸層會變成一階一階的色帶（banding）；-dither 用雜點假裝中間色，
#       看起來比較順，但雜點會讓 Deflate 比較難壓，檔案通常會變大一點。
#
# 產出：
#   output/03_quantize/*.png           各種色數 / dither 設定的 PNG
#   output/03_quantize/results.md      檔案大小 / 實際顏色數表
#   output/03_banding.png              漸層的色帶放大比較
#   output/03_photo_colors.png         照片在不同色數下的樣子
source "$(dirname "$0")/_common.sh"

D="$OUT/03_quantize"
mkdir -p "$D"
COLORS=(256 64 16 8)

section "Demo 03：調色盤量化（-colors）"

for img in photo graphic; do
  src="$ORIG/$img.png"
  # 基準：同一張圖用最高 Deflate 等級重存一次，排除「原檔壓縮等級不同」的影響
  "${IM[@]}" "$src" -strip -define png:compression-level=9 "PNG24:$D/${img}_lossless.png"
  for n in "${COLORS[@]}"; do
    "${IM[@]}" "$src" -strip +dither -colors "$n" -define png:compression-level=9 "PNG8:$D/${img}_c${n}_nodither.png"
    # 注意最後的 +dither：ImageMagick 7 的 PNG8 寫檔時會再量化一次，
    # 如果 dither 設定還開著，會再加一層雜點、顏色數超過 N。量化完就關掉。
    "${IM[@]}" "$src" -strip -dither FloydSteinberg -colors "$n" +dither -define png:compression-level=9 "PNG8:$D/${img}_c${n}_dither.png"
  done
done

{
  echo "| 圖片 | 設定 | 實際顏色數 | 檔案大小 | 相對無失真 PNG |"
  echo "|---|---|---:|---:|---:|"
  for img in photo graphic; do
    b=$(filesize "$D/${img}_lossless.png")
    echo "| $img | 無失真 PNG（24-bit） | $(unique_colors "$D/${img}_lossless.png") | $(kb "$b") | 100% |"
    for n in "${COLORS[@]}"; do
      for mode in nodither dither; do
        f="$D/${img}_c${n}_${mode}.png"
        label="-colors $n"; [ "$mode" = nodither ] && label="+dither $label" || label="-dither FloydSteinberg $label"
        echo "| $img | $label | $(unique_colors "$f") | $(kb "$(filesize "$f")") | $(pct "$(filesize "$f")" "$b") |"
      done
    done
  done
} > "$D/results.md"
cat "$D/results.md"

# ---- 漸層色帶：graphic 上半部 ----
G="256x168+0+0"
tiles=(-label "original" "$D/graphic_lossless.png")
for n in 64 16 8; do
  tiles+=(-label "-colors $n +dither" "$D/graphic_c${n}_nodither.png")
done
tiles+=(-label "-colors 8 -dither" "$D/graphic_c8_dither.png")
crops=()
i=0
for t in "${tiles[@]}"; do
  if [ -f "$t" ]; then
    zoom_crop "$t" "$G" 150 "$D/band_$i.png"; crops+=("$D/band_$i.png"); i=$((i+1))
  else
    crops+=("$t")
  fi
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 "${crops[@]}" \
  -tile 5x1 -geometry +6+6 -background white "$OUT/03_banding.png"

# ---- 照片：顏色越少越像海報 ----
G="200x200+160+40"
zoom_crop "$D/photo_lossless.png" "$G" 150 "$D/p_orig.png"
tiles=(-label "original  $(kb "$(filesize "$D/photo_lossless.png")")" "$D/p_orig.png")
for n in 64 16; do
  for mode in nodither dither; do
    f="$D/photo_c${n}_${mode}.png"
    zoom_crop "$f" "$G" 150 "$D/p_c${n}_${mode}.png"
    tiles+=(-label "$n colors $mode  $(kb "$(filesize "$f")")" "$D/p_c${n}_${mode}.png")
  done
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 "${tiles[@]}" \
  -tile 5x1 -geometry +6+6 -background white "$OUT/03_photo_colors.png"

echo
echo "→ $OUT/03_banding.png"
echo "→ $OUT/03_photo_colors.png"
