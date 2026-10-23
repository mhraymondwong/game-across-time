# 《時光裡的她》

原創養成遊戲（Godot 4.7）。父親在溫馨小鎮陪女兒度過十八年：童年十二年，接著成年六年。四季 × 每月一項活動；成年後平日另有一份工作。屬性、戀愛進度與多結局。

> 靈感僅參考養成類型；不使用《美少女夢工場》名稱、劇情或美術。

## 需求

- Godot **4.7.2**（指令 `godot`，或環境變數 `GODOT_BIN`）

## 執行（視窗）

```bash
godot --path .
```

或用 Godot 編輯器開啟本資料夾，按 F5。

## 煙霧測試（無頭、完整 18 年）

```bash
godot --headless --path . --script res://scripts/smoke_test.gd
```

成功時結束碼為 `0`，並印出 `[smoke] PASS` 與結局名稱。

## 流程

標題 → 日記排程（每季 3 個月）→ 季節結算 → 下季／下年。第 13 年起平日工作固定，每月仍選一件自己的事（戀愛、進修、成家或工作）。結局在第 18 年末。成家可選，單身也能走完。

小鎮地圖可點地點查看說明（第一版 stub）。

## 網頁版（GitHub Pages）

正式站是 GitHub Pages：<https://mhraymondwong.github.io/game-across-time/>

`build/web` 已提交（Godot 4.7.2、單執行緒 HTML5）。推上 `main` 時，`.github/workflows/deploy-pages.yml` 會把這個目錄發佈到 Pages。不需要 Cloudflare secret。目錄裡除了 `index.pck`，還可以有 `packs.json` 與 `packs/*.pck`。GitHub 單檔上限是 **100 MiB**；超過就推不上去。匯出腳本會在任一檔達到 100 MiB 時失敗。

Cloudflare Workers／Pages 的單一檔案上限是 **25 MiB**。`index.wasm` 與各個 `.pck` 都超過上限，所以 **不能** 部署到 Cloudflare。`wrangler.toml` 與 [docs/deploy-cloudflare.md](docs/deploy-cloudflare.md) 只留作選用／歷史說明。

遊戲在子路徑 `/game-across-time/`。匯出的 `index.html` 使用相對網址（`index.js`、`index.pck`、`packs.json`、`packs/*.pck`）。GitHub Pages 會把沒有結尾斜線的網址轉到 `.../game-across-time/`，相對路徑就會落在這個目錄，因此不必加 `<base href>`，也不必為了 Pages 重新匯出。

開場時日記載入畫面還在，網頁先把 `packs.json` 列出的額外資源包放進引擎，遊戲才進入標題。編輯器裡直接玩不需要這些 `.pck`，圖仍在專案目錄。

改遊戲後要更新網站：在本機重新匯出並提交 `build/web`，再推上 `main`。`export-web.yml` 仍會在 CI 匯出並上傳 artifact，但那個 artifact 不會自動變成 Pages 站。怎麼再加一個資源包見 [export/README.md](export/README.md)。

```bash
./scripts/export_web.sh
python3 -m http.server -d build/web 8080
```

存檔在瀏覽器本機（`user://` → IndexedDB），不會跟到別的裝置。第一次開啟要下載 `.wasm` 與一個或多個 `.pck`，體積會比較大。

## 美術（之後）

介面目前為柔色 StyleBox 佔位。圖像一律以 **Grok Imagine** 製作後再置入。

## UI（Layout 2）
- 主畫面 `home_hub`：全屏小鎮地圖 + 底部手帳抽屜
- 標題 `title`：使用 `assets/title_bg.jpg`
- 地圖地點圖示：`assets/pins/*.png`（由 `map_pins.jpg` 裁切）
- 截圖：`shots/01_map_diary.png`
