# 部署到 Cloudflare（HTML5）

《時光裡的她》是 Godot 4.7.2 專案。瀏覽器版必須先**匯出成 HTML5 靜態檔**，Cloudflare 只負責把那些檔案送出去。Workers 與 Pages **不會**執行 Godot，也不會在玩家的瀏覽器以外跑遊戲。

本文件是給擁有者之後自己接 Cloudflare 用的清單。這個 PR **不必**先做完 Dashboard。

English: export to HTML5 first. Workers Static Assets or Pages only host the files in `build/web`.

## 這個 repo 已備好的檔案

| 檔案 | 作用 |
| --- | --- |
| `export_presets.cfg` | 名為 `Web` 的 release preset，輸出 `build/web/index.html`。視窗仍是 `project.godot` 的 1280×720；網頁畫布為 Adaptive。**未開 threads**。 |
| `public/_headers` | `.wasm` → `application/wasm`，`.pck` → `application/octet-stream`，`.js` → `application/javascript`。匯出腳本會複製到 `build/web/_headers`。 |
| `wrangler.toml` | Workers Static Assets，名稱 `game-across-time`，目錄 `build/web`。 |
| `scripts/export_web.sh` | 用 Godot 4.7.2（`godot` 或 `GODOT_BIN`）無頭匯出。 |
| `.github/workflows/export-web.yml` | 推上 `main`（或手動 `workflow_dispatch`）時下載 Godot 4.7.2 與 export templates、匯出、上傳 artifact `game-across-time-web`。 |

`build/` 裡的 `.wasm` / `.pck` **不要 commit**。GitHub Actions 或你本機的匯出腳本會產生它們。

## 本機驗證

需要本機已安裝 **Godot 4.7.2**，以及單執行緒 web export templates（沒開 threads）：

```text
~/.local/share/godot/export_templates/4.7.2.stable/web_nothreads_release.zip
~/.local/share/godot/export_templates/4.7.2.stable/web_nothreads_debug.zip
~/.local/share/godot/export_templates/4.7.2.stable/icudt_godot.dat
```

`--export-release` 用 release zip。debug zip 也要在，因為 preset 是 runnable，Godot 檢查設定時會找它（編輯器裡「在瀏覽器執行」同樣用 debug 模板）。`icudt_godot.dat` 是同一版的文字資料，繁體中文才不會退回編輯器內建的 ICU。

編輯器選單 **Manage Export Templates** 會裝到同一層。也可以設 `GODOT_EXPORT_TEMPLATES`。

```bash
./scripts/export_web.sh
# 或
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 ./scripts/export_web.sh

npx wrangler pages dev build/web
```

`wrangler pages dev` 不需要 Cloudflare 帳號，用來確認靜態檔與 `_headers`。對應 Workers 設定時也可以：

```bash
npx wrangler dev
```

腳本在找不到二進位、版本不是 4.7.2、或缺少上述模板檔時會直接失敗並說明要裝哪一個。

## 方案 A — Cloudflare Pages（連結 GitHub repo）

適合「在 Dashboard 把 repo 接上 Pages」。Pages **只托管靜態檔**。

直接讓 Pages 的建置環境去跑 Godot **很重**：官方 export templates 壓縮檔約 1.2 GB，Pages 映像裡也沒有 Godot。不建議把 Build command 設成安裝 Godot。

比較穩的做法：

1. 維持本 repo 的 GitHub Actions 負責匯出（artifact 名稱 `game-across-time-web`）。
2. 之後要發佈時，用已設定的 secret 跑 `wrangler pages deploy`（workflow 裡有註解好的指令），**不要**同時又開一個會在 Cloudflare 端編譯 Godot 的 Build command。

若仍要在 Dashboard 連結 repo，請看下方清單。輸出目錄不要指到 git 裡的 `build/web`——那個目錄的成品沒有被 commit，Pages 直接拉 repo 會是空的。

## 方案 B — Workers Static Assets + wrangler（本 repo 預設）

`wrangler.toml` 已指向 `build/web`。這是建議路徑：Actions 匯出，之後 `npx wrangler deploy` 發佈同一個目錄。

本機：

```bash
./scripts/export_web.sh
npx wrangler deploy
```

`account_id` 可以留在 `wrangler.toml` 註解裡，改由環境變數 `CLOUDFLARE_ACCOUNT_ID` 提供。

## Dashboard 清單（現在不用做完）

之後要接上時再做。做完之前，推 `main` 只會產生 Actions artifact，**不會**因為沒有 Cloudflare secret 而失敗。

1. 登入 [Cloudflare Dashboard](https://dash.cloudflare.com)。
2. 建立 Workers 或 Pages 專案，名稱建議 `game-across-time`（與 `wrangler.toml` 的 `name` 相同）。
3. 若要連結 Git：選 GitHub repo **`mhraymondwong/game-across-time`**。
4. Production branch 設為 **`main`**。
5. 不要把 Pages Build command 設成「在 Cloudflare 裡安裝 Godot」。編譯放在 GitHub Actions。
6. 第一次啟用 Workers 的 `*.workers.dev` 子網域時，Dashboard 可能會要求同意 Workers 條款。同意一次即可。
7. 要打開 workflow 裡的發佈步驟時，到 GitHub repo **Settings → Secrets and variables → Actions** 新增：
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`（Dashboard 右側 Account ID；也可寫進 `wrangler.toml` 的 `account_id`，預設維持註解）
8. API token 建議自訂、只限這個帳號：
   - Workers 路線：Account → **Workers Scripts: Edit**，以及 **Account Settings: Read**（wrangler 會讀帳號）
   - 若改走 Pages 註解裡的 `wrangler pages deploy`：改為 Account → **Cloudflare Pages: Edit**（仍建議加上 Account Settings: Read）
9. 確認 `.github/workflows/export-web.yml` 的 deploy 步驟仍是「secret 空著就 skip」。兩個 secret 都有值時，該步驟才執行 `npx wrangler deploy`。

## 存檔與第一次開啟

- 存檔使用 Godot 的 `user://`（本專案是 `user://save_slot_0.json`）。在網頁上這是**這台瀏覽器的本機資料**（IndexedDB），不會同步到其他瀏覽器或裝置。無痕視窗通常存不住。
- 第一次開啟要下載引擎 `.wasm` 與遊戲 `.pck`。圖量不小，第一次會比較久；Cloudflare 會幫靜態檔做壓縮。檔名固定是 `index.wasm` / `index.pck`，所以 `_headers` 用 `Cache-Control: no-cache`，避免舊包一直留在瀏覽器。

## 執行緒與 COOP / COEP（選用）

目前 `export_presets.cfg` 的 `variant/thread_support=false`。單執行緒匯出**不需要**：

```text
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

這兩行寫在 `public/_headers` 的註解裡。只有在你改成開啟 threads、並重新匯出之後，才取消註解再部署。開啟後頁面會被 cross-origin isolate，第三方嵌入會失效；網站也必須是 HTTPS。
