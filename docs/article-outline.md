# 文章大綱：圖片變小了，是哪些資料不見了？——用 ImageMagick 看懂圖片壓縮

> 發布位置：GitHub Issue　｜　圖片與數字全部來自本 repo 的 `output/`

## 開場（為什麼要懂這個）

- 情境：同一張圖，`-quality 75` 從 415 KB 變 39 KB，少掉的 90% 到底是什麼？
- 本文目標：每個 ImageMagick 參數，都對應到「丟掉哪一種資料」
- 一句話導讀：**壓縮 = 找出人眼不在乎的資料丟掉 + 把剩下的資料用更短的方式寫**

---

## Part 1：原理篇

### 1. 影像的基本單位

- pixel、channel、色彩深度（8 bit × 3 = 24 bit/pixel）
- 算一次未壓縮大小：512 × 512 × 3 = 768 KB
- 無失真 vs 失真壓縮
  - 無失真：資料一樣，只是寫得更短（PNG 的 Deflate、ZIP）
  - 失真：直接丟資料，壓完回不去（JPEG、量化後的 PNG8）

### 2. 色彩空間與 Chroma Subsampling

- RGB → YCbCr：把「亮度」和「顏色」拆開
- 人眼的特性：亮度細節敏感、顏色細節遲鈍
- 4:4:4 / 4:2:2 / 4:2:0 的意思，每像素樣本數 3 → 2 → 1.5
- 📷 `output/02_channels.png`：Y 是完整照片，Cb/Cr 幾乎沒有細節

### 3. JPEG 核心：DCT + 量化

- 8×8 區塊 → DCT → 64 個頻率係數（左上低頻、右下高頻）
- 量化表：係數 ÷ 表 → 四捨五入，**資料就是在這一步不見的**
- `-quality` 其實是在縮放量化表
- 熵編碼（Huffman）：一堆 0 很好壓 → 這是無失真的步驟
- 📷 `output/01_quality_zoom.png`：8×8 方塊

### 4. PNG：無失真，但可以先量化

- 濾波器（Sub / Up / Average / Paeth）：把像素變成「和鄰居的差」，讓數字變小、變重複
- Deflate（LZ77 + Huffman）：重複越多越好壓
- 調色盤（PNG8）：顏色 ≤ 256 種時，每像素只存 1 個索引
- dither：用雜點模擬中間色（好看，但不好壓）

---

## Part 2：ImageMagick 對照 + Demo

> 每一節格式：參數 → 丟了什麼 → 指令 → 比較圖 → 數字

### Demo 01：`-quality`

- 指令：`magick photo.png -quality 20 out.jpg`
- 📷 `01_quality_zoom.png`、`01_quality_diff.png`（熱區集中在邊緣與紋理）
- 📷 `01_quality_graphic.png`（文字旁的振鈴）
- 📊 photo：q95 → 22.6%、q75 → 9.4%、q20 → 3.6%
- ⚠️ 反直覺：graphic 存 JPEG q95 是 PNG 的 **2.3 倍大**

### Demo 02：`-sampling-factor`

- 指令：`-sampling-factor 4:4:4` vs `4:2:0`
- 📷 `02_chroma_simulated.png`：只砍顏色看不出來，只砍亮度一眼就看到
- 📷 `02_sampling_jpeg.png`：藍底紅字的顏色溢出
- 📊 都省約 21%，但 graphic 的 PSNR 掉 10 dB、photo 只掉 2 dB
- 補充：IM 預設 quality < 90 用 4:2:0，≥ 90 用 4:4:4

### Demo 03：`-colors` / `-dither`

- 指令：`+dither -colors 16 PNG8:out.png`
- 📷 `03_banding.png`：漸層色帶
- 📷 `03_photo_colors.png`：dither 前後
- 📊 photo 16 色：10.1%（不 dither）vs 14.5%（dither）

### 其他常用參數（不需 demo，一句帶過）

- `-strip`：刪 metadata，不影響像素
- `-define png:compression-level=9`：更努力壓，不丟資料
- `-interlace Plane`：progressive JPEG，檔案大小差不多，但載入時先出模糊全圖
- `-resize`：最有效的壓縮，直接減少 pixel 數量

---

## 結論：怎麼選

| 圖片類型 | 建議 | 原因 |
|---|---|---|
| 照片 | JPEG，`-quality 75–85`，4:2:0 | 高頻和顏色細節本來就看不太出來 |
| 截圖 / UI / 圖表 | PNG，必要時 `-colors` 量化 | 銳利邊緣會讓 JPEG 又大又醜 |
| 漸層多的插圖 | PNG8 + dither，或 JPEG 高 quality | 避免色帶 |

- 延伸：WebP / AVIF 用的是同一套概念（色彩轉換 + 頻率轉換 + 量化），只是工具更新

## 附錄

- Repo 連結、`./scripts/run_all.sh` 一鍵重現
- 參考資料（撰寫時補上）
