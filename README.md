# image-compression

「圖片壓縮原理」分享的 demo：用 ImageMagick 跑一遍簡報中的所有指令。

## 執行

```bash
git clone https://github.com/riverkuo/image-compression.git
cd image-compression
./scripts/run_all.sh
```

- 沒有 ImageMagick 會自動安裝（macOS 用 Homebrew，Linux 用 apt）。
- 所有指令都在 `images/original/` 裡執行，輸出檔也在同一個資料夾。
- 檔名規則：`原圖名稱.參數簡寫.副檔名`，例如 `photo.q75.jpg` 是 `photo.png` 用 `-quality 75` 壓出來的。

## 原圖

| 檔案 | 說明 |
|---|---|
| `photo.png` | 太空人照片，512×512 |
| `graphic.png` | 漸層、文字、細線的圖表類圖片，512×512 |
| `white.png` | 512×512 全白 |
