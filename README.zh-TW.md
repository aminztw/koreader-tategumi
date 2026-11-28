# KOReader 縱書版

[English](README.md) | [日本語](README.md#日本語) | **繁體中文**

這是 KOReader 的衍生版本，支援日文 EPUB 直排與日式漫畫由右向左翻頁，並包含臺灣繁體中文介面。

## 下載與安裝

到 [GitHub Releases](https://github.com/aminztw/koreader-tategumi/releases/latest) 展開 **Assets**，下載符合裝置的安裝包。檔名帶有版本號的 ZIP 或 APK 適合手動安裝。

| 裝置 | 安裝包檔名開頭 |
| --- | --- |
| Kindle（符合 HF 版本要求的機型與韌體） | `koreader-kindlehf-` |
| 其他 Kindle（依機型選擇） | `koreader-kindle-`、`koreader-kindlepw2-` 或 `koreader-kindle-legacy-` |
| Kobo | `koreader-kobo-`（Kobo 韌體 5.x 另有 `koreader-kobov5-`） |
| Android（含 BOOX） | ARM64 用 `koreader-android-arm64-`，32 位元 ARM 用 `koreader-android-` |
| PocketBook、Cervantes、reMarkable | 依機型與架構選擇對應的 ZIP |

依裝置的安裝指南操作。[Kindle 安裝](https://github.com/koreader/koreader/wiki/Installation-on-Kindle-devices) · [Kobo 安裝](https://github.com/koreader/koreader/wiki/Installation-on-Kobo-devices) · [Android 安裝](https://github.com/koreader/koreader/wiki/Installation-on-Android-devices)

從原版 KOReader 切換前，先退出應用程式並備份 KOReader 目錄、設定及閱讀進度。若 Android 因簽署金鑰不同而拒絕覆蓋安裝，請先確認資料已備份，再移除舊版。從本 fork 安裝後，可在裝置的「更新」選單檢查正式版更新。

## 直排與漫畫翻頁

- **日文 EPUB 直排**：書籍已指定 `writing-mode: vertical-rl` 時會自動直排。其他 EPUB 可在頁面圖示的文件選單中，開啟文件設定的「直排閱讀」（Vertical reading），設定會按書籍儲存。
- **直排字型**：可使用 Noto Sans CJK JP 或 Noto Serif CJK JP。若標點仍是橫排字形，檢查字型是否支援 OpenType 的 `vert` 和 `vrt2`，並將字距調整（Font Kerning）維持在「最佳」。
- **由右向左翻頁**：含右開設定的 EPUB，以及含對應 `ComicInfo.xml` 資料的 CBZ、CBR、CBT，首次開啟時會自動偵測。若需要手動切換，可在「輕觸與手勢 → 翻頁 → 切換翻頁方向」調整。
- **混合排版**：同一本書可在不同頁使用橫排與直排。同一頁內嵌入不同書寫方向的區塊，例如直排正文中的橫排表格，仍可能顯示異常。

更多設定與相容性資訊請見 [完整 README](README.md)。
