# Demo 結果

> 產生時間：2026-10-07 19:38　｜　Version: ImageMagick 7.1.2-31 Q16-HDRI aarch64 8309dc92a:20260903 https://imagemagick.org
>
> 不同 ImageMagick 版本 / libjpeg 實作的數字會略有差異，但趨勢相同。

## 01. JPEG -quality

| 圖片 | 設定 | 檔案大小 | 相對無失真 PNG | PSNR（越高越像原圖） |
|---|---|---:|---:|---:|
| photo | 無失真 PNG（24-bit） | 412.5 KB | 100% | — |
| photo | -quality 95 | 93.3 KB | 22.6% | 38.28 dB |
| photo | -quality 75 | 38.8 KB | 9.4% | 33.98 dB |
| photo | -quality 50 | 26.4 KB | 6.4% | 32.05 dB |
| photo | -quality 20 | 15.1 KB | 3.6% | 29.30 dB |
| photo | -quality 5 | 5.8 KB | 1.4% | 24.11 dB |
| graphic | 無失真 PNG（24-bit） | 17.5 KB | 100% | — |
| graphic | -quality 95 | 41.0 KB | 234.5% | 32.75 dB |
| graphic | -quality 75 | 22.6 KB | 129.3% | 31.53 dB |
| graphic | -quality 50 | 17.1 KB | 97.6% | 29.76 dB |
| graphic | -quality 20 | 10.9 KB | 62.5% | 27.06 dB |
| graphic | -quality 5 | 5.9 KB | 33.6% | 23.05 dB |

## 02. Chroma subsampling

| 圖片 | -quality 90 + sampling-factor | 每像素原始樣本數 | 檔案大小 | 相對 4:4:4 | PSNR |
|---|---|---:|---:|---:|---:|
| photo | 4:4:4 | 3 | 82.3 KB | 100.0% | 38.61 dB |
| photo | 4:2:2 | 2 | 71.5 KB | 86.9% | 37.40 dB |
| photo | 4:2:0 | 1.5 | 65.0 KB | 79.0% | 36.64 dB |
| graphic | 4:4:4 | 3 | 40.1 KB | 100.0% | 43.15 dB |
| graphic | 4:2:2 | 2 | 33.5 KB | 83.4% | 35.89 dB |
| graphic | 4:2:0 | 1.5 | 31.3 KB | 78.1% | 32.53 dB |

## 03. PNG 調色盤量化

| 圖片 | 設定 | 實際顏色數 | 檔案大小 | 相對無失真 PNG |
|---|---|---:|---:|---:|
| photo | 無失真 PNG（24-bit） | 113382 | 412.5 KB | 100% |
| photo | +dither -colors 256 | 256 | 132.3 KB | 32.1% |
| photo | -dither FloydSteinberg -colors 256 | 256 | 145.0 KB | 35.2% |
| photo | +dither -colors 64 | 64 | 76.9 KB | 18.6% |
| photo | -dither FloydSteinberg -colors 64 | 64 | 94.2 KB | 22.8% |
| photo | +dither -colors 16 | 16 | 41.7 KB | 10.1% |
| photo | -dither FloydSteinberg -colors 16 | 16 | 59.8 KB | 14.5% |
| photo | +dither -colors 8 | 8 | 28.1 KB | 6.8% |
| photo | -dither FloydSteinberg -colors 8 | 8 | 44.5 KB | 10.8% |
| graphic | 無失真 PNG（24-bit） | 920 | 17.5 KB | 100% |
| graphic | +dither -colors 256 | 165 | 7.0 KB | 39.9% |
| graphic | -dither FloydSteinberg -colors 256 | 159 | 14.0 KB | 80.2% |
| graphic | +dither -colors 64 | 54 | 5.3 KB | 30.4% |
| graphic | -dither FloydSteinberg -colors 64 | 52 | 11.5 KB | 65.7% |
| graphic | +dither -colors 16 | 16 | 4.1 KB | 23.4% |
| graphic | -dither FloydSteinberg -colors 16 | 16 | 11.0 KB | 63.0% |
| graphic | +dither -colors 8 | 8 | 3.4 KB | 19.6% |
| graphic | -dither FloydSteinberg -colors 8 | 8 | 8.8 KB | 50.3% |
