#!/usr/bin/env bash
# Demo 02：Chroma Subsampling（-sampling-factor）在丟什麼？
#
# 原理：JPEG 先把 RGB 轉成 YCbCr。Y 是亮度，Cb / Cr 是顏色差。
#       人眼對亮度細節很敏感、對顏色細節很遲鈍，所以 4:2:0 把 Cb、Cr 各縮成 1/4（長寬各一半），
#       每個 2x2 區塊只留一組顏色。原始資料量從每像素 3 個值變成 1.5 個值，直接少一半。
#       照片幾乎看不出來；但「藍底紅字」這種顏色邊界銳利的圖，顏色會糊到字的外面。
#
# 產出：
#   output/02_channels.png             原圖 / Y / Cb / Cr 四個 channel
#   output/02_chroma_simulated.png     手動把 Cb、Cr 縮小再放大（模擬 4:2:0），和原圖比較
#   output/02_sampling_jpeg.png        真正的 JPEG：4:4:4 vs 4:2:0 放大比較
#   output/02_chroma/results.md        檔案大小表
source "$(dirname "$0")/_common.sh"

D="$OUT/02_chroma"
mkdir -p "$D"

section "Demo 02：Chroma Subsampling"

# ---- 1. 拆 channel：Y 看起來就是黑白照片，Cb / Cr 幾乎沒有細節 ----
for img in photo graphic; do
  "${IM[@]}" "$ORIG/$img.png" -colorspace YCbCr -separate "$D/${img}_ycbcr_%d.png"
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 \
  -label "RGB original"        "$ORIG/photo.png" \
  -label "Y (luma)"            "$D/photo_ycbcr_0.png" \
  -label "Cb (blue diff)"      "$D/photo_ycbcr_1.png" \
  -label "Cr (red diff)"       "$D/photo_ycbcr_2.png" \
  -tile 4x1 -geometry 256x256+6+6 -background white "$OUT/02_channels.png"

# ---- 2. 模擬 4:2:0：只把 Cb、Cr 縮成一半再放大回來，Y 不動 ----
for img in photo graphic; do
  "${IM[@]}" \
    "$D/${img}_ycbcr_0.png" \
    \( "$D/${img}_ycbcr_1.png" -filter box -resize 50% -filter triangle -resize 200% \) \
    \( "$D/${img}_ycbcr_2.png" -filter box -resize 50% -filter triangle -resize 200% \) \
    -set colorspace YCbCr -combine -colorspace sRGB "$D/${img}_sim420.png"
  # 反過來：保留顏色、把亮度砍一半 → 對照組，證明人眼對亮度敏感
  "${IM[@]}" \
    \( "$D/${img}_ycbcr_0.png" -filter box -resize 50% -filter triangle -resize 200% \) \
    "$D/${img}_ycbcr_1.png" "$D/${img}_ycbcr_2.png" \
    -set colorspace YCbCr -combine -colorspace sRGB "$D/${img}_simLumaHalf.png"
done

PG="128x128+200+80"   # 太空人臉
GG="128x128+16+190"   # RED on BLUE + green text
for v in orig sim420 simLumaHalf; do
  for img in photo graphic; do
    src="$D/${img}_${v}.png"; [ "$v" = orig ] && src="$ORIG/$img.png"
    geom=$PG; [ "$img" = graphic ] && geom=$GG
    zoom_crop "$src" "$geom" 300 "$D/z_${img}_${v}.png"
  done
done
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 \
  -label "original"                  "$D/z_photo_orig.png" \
  -label "Cb/Cr halved (like 4:2:0)" "$D/z_photo_sim420.png" \
  -label "Y halved (control)"        "$D/z_photo_simLumaHalf.png" \
  -label "original"                  "$D/z_graphic_orig.png" \
  -label "Cb/Cr halved (like 4:2:0)" "$D/z_graphic_sim420.png" \
  -label "Y halved (control)"        "$D/z_graphic_simLumaHalf.png" \
  -tile 3x2 -geometry +6+6 -background white "$OUT/02_chroma_simulated.png"

# ---- 3. 真正的 JPEG：同樣 quality 90，只換 sampling-factor ----
for img in photo graphic; do
  for sf in 4:4:4 4:2:2 4:2:0; do
    "${IM[@]}" "$ORIG/$img.png" -strip -quality 90 -sampling-factor "$sf" "$D/${img}_${sf//:/}.jpg"
  done
done

{
  echo "| 圖片 | -quality 90 + sampling-factor | 每像素原始樣本數 | 檔案大小 | 相對 4:4:4 | PSNR |"
  echo "|---|---|---:|---:|---:|---:|"
  for img in photo graphic; do
    b=$(filesize "$D/${img}_444.jpg")
    for sf in "444|4:4:4|3" "422|4:2:2|2" "420|4:2:0|1.5"; do
      IFS="|" read -r key label samples <<< "$sf"
      f="$D/${img}_${key}.jpg"
      s=$(filesize "$f")
      echo "| $img | $label | $samples | $(kb "$s") | $(pct "$s" "$b") | $(printf '%.2f' "$(psnr "$ORIG/$img.png" "$f")") dB |"
    done
  done
} > "$D/results.md"
cat "$D/results.md"

zoom_crop "$D/graphic_444.jpg" "$GG" 300 "$D/zj_444.png"
zoom_crop "$D/graphic_420.jpg" "$GG" 300 "$D/zj_420.png"
"${MONTAGE[@]}" "${FONT_ARGS[@]}" -pointsize 18 \
  -label "original PNG"             "$D/z_graphic_orig.png" \
  -label "JPEG q90 4:4:4  $(kb "$(filesize "$D/graphic_444.jpg")")" "$D/zj_444.png" \
  -label "JPEG q90 4:2:0  $(kb "$(filesize "$D/graphic_420.jpg")")" "$D/zj_420.png" \
  -tile 3x1 -geometry +6+6 -background white "$OUT/02_sampling_jpeg.png"

echo
echo "→ $OUT/02_channels.png"
echo "→ $OUT/02_chroma_simulated.png"
echo "→ $OUT/02_sampling_jpeg.png"
