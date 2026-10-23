# 部署到 Cloudflare（HTML5）

> **正式站是 GitHub Pages，不是 Cloudflare。**
>
> Cloudflare Workers 與 Cloudflare Pages 的單一檔案上限是 **25 MiB**。已匯出的 `build/web/index.pck`、`build/web/packs/*.pck` 與 `build/web/index.wasm` 都超過這個上限，所以這包遊戲不能部署到 Cloudflare。GitHub 的單檔上限是 100 MiB；額外資源包就是為了那個上限，見 [export/README.md](../export/README.md)。
>
> 線上版本：<https://mhraymondwong.github.io/game-across-time/>
>
> 發佈用 `.github/workflows/deploy-pages.yml`（推上 `main`，或手動 `workflow_dispatch`）。它只上傳已 commit 的 `build/web`，不會在 CI 裡重跑約 118 MiB 的 Godot 匯出，也不需要任何 Cloudflare secret。
>
> 子路徑 `/game-across-time/` **不需要** `<base href>`，也 **不需要** 為了 Pages 重新匯出。`index.html` 的 `index.js`、`index.wasm`、`index.pck`、`packs.json`、`packs/*.pck` 都是相對網址。GitHub Pages 會把 `https://mhraymondwong.github.io/game-across-time` 301 到結尾有斜線的目錄，相對路徑就留在 `/game-across-time/` 裡。這與 `game-chromablock-out` 相同。若寫死 `<base href="/game-across-time/">`，本機用網站根目錄預覽 `build/web` 時會抓錯檔。`export_presets.cfg` 的 `html/head_include` 維持空白。
>
> 下面的 `wrangler.toml`、`export-web.yml` 與 Dashboard 清單是選用／歷史說明。

English: the live host is GitHub Pages. Cloudflare Workers/Pages reject a single file over 25 MiB, and this export exceeds that (`index.pck`, `packs/*.pck`, and `index.wasm`). GitHub's own cap is 100 MiB per file; extra packs are how the web build stays under it (`export/README.md`). Relative asset URLs, including `packs.json`, are enough under `/game-across-time/` because Pages redirects to a trailing slash. No `<base href>` and no re-export. The Cloudflare scaffold below is optional and historical.

《時光裡的她》是 Godot 4.7.2 專案。瀏覽器版是已匯出的 HTML5 靜態檔（`build/web`）。Workers 與 Pages 不會執行 Godot。下面是先前為 Cloudflare 準備的清單；正式站不走這條路。

## 這個 repo 已備好的檔案

| 檔案 | 作用 |
| --- | --- |
| `export_presets.cfg` | 名為 `Web` 的 release preset，輸出 `build/web/index.html`。視窗仍是 `project.godot` 的 1280×720；網頁畫布為 Adaptive。**未開 threads**。 |
| `public/_headers` | `.wasm` → `application/wasm`，`.pck` → `application/octet-stream`，`.js` → `application/javascript`。匯出腳本會複製到 `build/web/_headers`。 |
| `wrangler.toml` | Workers Static Assets，名稱 `game-across-time`，目錄 `build/web`。 |
| `scripts/export_web.sh` | 用 Godot 4.7.2（`godot` 或 `GODOT_BIN`）無頭匯出。 |
| `.github/workflows/deploy-pages.yml` | **正式站。** 推上 `main`（或手動 `workflow_dispatch`）時，把已 commit 的 `build/web` 發到 GitHub Pages。 |
| `.github/workflows/export-web.yml` | 仍會下載 Godot 4.7.2 與 export templates、匯出、上傳 artifact `game-across-time-web`。Cloudflare 發佈只在兩個 secret 都有值時才跑，而且 **不會** 更新 GitHub Pages。 |

`build/web`（含 `index.wasm` 與 `index.pck`）**要 commit**。GitHub Pages 直接發佈這個目錄。改遊戲後用 `./scripts/export_web.sh` 重新匯出並提交 `build/web`，Pages 才會更新。

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

## 方案 A — Cloudflare Pages（選用／歷史；目前無法發布這包檔案）

Cloudflare Pages **只托管靜態檔**，但單一檔案上限 25 MiB，本遊戲的 `.pck` 與 `.wasm` 超過上限。這一節留作紀錄，不是現在的發佈方式。

直接讓 Pages 的建置環境去跑 Godot **很重**：官方 export templates 壓縮檔約 1.2 GB，Pages 映像裡也沒有 Godot。不建議把 Build command 設成安裝 Godot。

比較穩的做法：

1. 維持本 repo 的 GitHub Actions 負責匯出（artifact 名稱 `game-across-time-web`）。
2. 之後要發佈時，用已設定的 secret 跑 `wrangler pages deploy`（workflow 裡有註解好的指令），**不要**同時又開一個會在 Cloudflare 端編譯 Godot 的 Build command。

若仍要在 Dashboard 連結 repo，請看下方清單。`build/web` 現在有 commit（給 GitHub Pages 用）。Cloudflare 仍然拒絕這兩個大檔，把輸出目錄指過去也不會發布成功。

## 方案 B — Workers Static Assets + wrangler（選用／歷史）

`wrangler.toml` 已指向 `build/web`。這不是正式站。Workers Static Assets 同樣有 25 MiB 單檔上限。正式發佈請用 GitHub Pages。若日後檔案變小、且已設定 token，才用 `npx wrangler deploy`。

本機：

```bash
./scripts/export_web.sh
npx wrangler deploy
```

`account_id` 可以留在 `wrangler.toml` 註解裡，改由環境變數 `CLOUDFLARE_ACCOUNT_ID` 提供。

## Dashboard 清單（選用；GitHub Pages 不需要這些 secret）

發佈到 GitHub Pages **不必**做下面任何一步，也 **不必** 設定 `CLOUDFLARE_API_TOKEN` 或 `CLOUDFLARE_ACCOUNT_ID`。推 `main` 時，`deploy-pages.yml` 會更新正式站；`export-web.yml` 沒有 Cloudflare secret 也不會失敗。下面只在你之後仍想試 Cloudflare（而且單檔已小於 25 MiB）時才需要。

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
