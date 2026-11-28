# KOReader 縱書版

[English](README.md) | [日本語](README.md#日本語) | **繁體中文**

這個 KOReader 衍生版提供台灣繁體中文介面，支援中文與日文 EPUB 電子書直排，也能從右往左讀漫畫。

## 下載適合你裝置的安裝包

到 [GitHub Releases](https://github.com/aminztw/koreader-tategumi/releases/latest) 展開 **Assets（下載檔案）**，下載檔名有版本號的 ZIP 或 APK。如果不確定 Kindle 該下載哪個檔案，先在裝置資訊確認機型和韌體版本，再看下表。

| 裝置 | 安裝包檔名開頭 | 適用條件 |
| --- | --- | --- |
| KindleHF | `koreader-kindlehf-` | 韌體 5.16.3 以上 |
| Kindle PW2 | `koreader-kindlepw2-` | 第二代 Paperwhite（PW2）起的觸控機型，使用 5.16.3 以前的韌體 |
| 一般 Kindle | `koreader-kindle-` | Kindle 4、Kindle Touch（K5）、第一代 Paperwhite（PW1） |
| Kindle legacy | `koreader-kindle-legacy-` | 這個檔案目前和一般 Kindle 安裝包相同，使用更舊的 K2、DX 或 K3 時，請先核對上游相容性及安裝包 |
| Kobo | `koreader-kobo-`、`koreader-kobov5-` | Kobo 韌體 5.x 選 `kobov5` |
| Android（含 BOOX） | `koreader-android-arm64-`、`koreader-android-` | 分別對應 ARM64 和 32 位元 ARM |
| PocketBook | `koreader-pocketbook-`、`koreader-pocketbookhf-` | 依機型選擇一般版或 HF 版 |
| Cervantes | `koreader-cervantes-` | 使用對應 ZIP |
| reMarkable | `koreader-remarkable-`、`koreader-remarkable-aarch64-` | 分別對應 armhf 和 aarch64 |

其他安裝步驟請依各平台指南操作。[Kindle 機型與安裝指南](https://github.com/koreader/koreader/wiki/Installation-on-Kindle-devices#err-there-are-four-kindle-packages-to-choose-from-which-do-i-pick) · [Kobo 安裝](https://github.com/koreader/koreader/wiki/Installation-on-Kobo-devices) · [Android 安裝](https://github.com/koreader/koreader/wiki/Installation-on-Android-devices)

## Kindle 手動安裝與啟動

1. 確認越獄與必要的後續步驟已完成，再依機型與韌體下載 ZIP。已有 KOReader 時，先退出程式並備份安裝目錄、設定與閱讀進度。
2. 在電腦解壓縮 ZIP。打開 Kindle 磁碟，停在看得到 `documents` 資料夾的畫面，把解壓後的 `koreader/` 和 ZIP 裡附帶的 `documents/` 拖到這個畫面。請複製整個 `koreader/` 資料夾，裡面的所有檔案和子資料夾都要一起帶過去。如果系統詢問如何處理同名資料夾，請合併內容並保留原有書籍。下圖只列出幾個位置供你確認：

   ```text
   Kindle 磁碟
   ├── documents/
   │   ├── KOReader-TW.sh（ZIP 有附才會出現）
   │   └── …（原有書籍和其他檔案）
   ├── extensions/（使用 KUAL 或相容啟動器時才需複製）
   └── koreader/
       ├── koreader.sh
       └── …（其餘程式檔案與子資料夾，全部保留）
   ```

3. 安全退出 USB 連線後，依越獄環境啟動。支援書庫 scriptlet 的 Véra 裝置可在書庫點開 **KOReaderTW**。Véra 從書庫啟動時可以略過 ZIP 裡的 `extensions/`。如果用 KUAL 或相容啟動器開啟 KOReader，請一起複製 `extensions/`，它提供 KOReader 的啟動選單。

較新的 KindleHF 和 Kindle PW2 ZIP 會附上書庫啟動器。解壓縮後可確認是否有 `documents/KOReader-TW.sh`。一般 Kindle 和 legacy 安裝包沿用原有啟動方式。手動複製安裝無須設定 KPM。英文與日文指南中的現有 KPM 指令則會安裝上游 `m-tky/koreader-tategumi` 的版本。

## 從原版切換與更新

### 切換前先備份

退出 KOReader，備份既有 KOReader 目錄、設定、書籤與閱讀進度。手動升級時，將新版檔案覆蓋到原安裝位置，保留原有目錄及使用者資料。

- **電子書閱讀器**：依裝置的安裝指南，把對應 ZIP 的內容覆蓋到原安裝位置。若你確定裝置使用舊版更新器，也可以參考 [進階遷移說明（英文）](README.md#switching-from-vanilla-koreader)。
- **Android**：下載對應架構的 APK。若 Android 因簽章不同而拒絕覆蓋，先確認資料已備份且可還原，再解除安裝舊版，接著安裝這裡下載的版本。後續版本可從應用程式內檢查更新，再由 Android 安裝程式完成更新。

### 檢查更新

在支援更新的裝置上，從選單選「更新 → 檢查更新」。可在「更新 → 設定 → 更新頻道」切換頻道。**穩定版**來自 `aminztw/koreader-tategumi`，**開發版（每夜建置）**來自上游 `m-tky/koreader-tategumi`。想持續收到這裡發布的正式版本，請選「穩定版」。

## 繁中介面、直排與漫畫翻頁

- **繁中介面**：在「設定 → 語言」選擇「繁體中文（台灣）」，依提示重新啟動 KOReader。
- **中文與日文 EPUB 直排**：電子書已設定成直排時，開啟後就會直排。如果你想把橫排書改成直排，可點頁面圖示，再選「文件設定 → 直排閱讀」。設定會記在這本書上。原本為橫排設計的書，改成直排後可能需要調整樣式。
- **直排字型**：可使用 Noto Sans CJK JP 或 Noto Serif CJK JP。字型應支援 OpenType 的 `vert` 和 `vrt2`，並將「字距調整」維持在「最佳」。
- **漫畫從右往左讀**：如果 EPUB 已標明翻頁方向，或 CBZ、CBR、CBT 的 `ComicInfo.xml` 有相應設定，第一次開啟時會自動套用。若方向不合，可以到「輕觸與手勢 → 翻頁 → 切換翻頁方向」手動調整。設定會記在這本書上。
- **排版限制**：同一本書可在不同頁使用橫排與直排，同頁混排仍可能顯示異常。若段首看起來縮排兩次，可試著在「樣式表調整」將「段落首行縮排」設為 0。直排注音群組間的空白也可能來自 EPUB 本身。

## 常見問題與回報

| 現象 | 先檢查 |
| --- | --- |
| 書庫沒有 **KOReaderTW** | ZIP 是否隨附啟動器、`KOReader-TW.sh` 是否在 Kindle 根目錄下的 `documents/`、越獄環境是否支援書庫 scriptlet |
| 點開後立即退出 | 安裝包是否對應機型與韌體，以及程式是否位於 `koreader/koreader.sh`，有沒有多包一層解壓資料夾 |
| 直排標點仍是橫向 | 選用支援 `vert` 和 `vrt2` 的中日文字型，將「字距調整」設為「最佳」 |
| Android 無法覆蓋安裝 | 先核對 APK 架構。若系統提示簽章不同，按上面的備份與切換步驟處理 |

回報時請附上裝置型號、韌體、KOReader 版本、安裝包檔名和重現步驟。若是 Kindle 啟動問題，也請註明使用的是書庫、KUAL 或 KPM。[回報問題](https://github.com/aminztw/koreader-tategumi/issues) · [完整 README](README.md)
