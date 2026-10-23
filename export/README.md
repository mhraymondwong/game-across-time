# 網頁資源包

Godot 4.7.2 的 Web 匯出寫進 `build/web/`。GitHub 不接受單檔 **100 MiB**（含）以上。主包是 `index.pck`；`export/packs.json` 列出的目錄另外輸出成 `packs/<id>.pck`。GitHub Pages 把整個 `build/web` 發出去，不在 Actions 裡重匯。

正式站在子路徑 `/game-across-time/`。`index.html`、`packs.json`、`packs/*.pck` 都用相對網址。Pages 會把沒有結尾斜線的網址轉到目錄，所以不要加 `<base href>`。

貼圖維持無損匯入。不要把 `.import` 改成 Lossy 來躲過 100 MiB。

## 開場時怎麼載入

1. 日記載入畫面出現後，`export/web_shell.html` 讀取同目錄的 `packs.json`。
2. 每個 `file` 用 `Engine.preloadFile` 放進網頁引擎的檔案系統，虛擬路徑是 `/packs/...pck`。
3. 引擎啟動後、標題場景之前，自動載入 `ResourcePacks`（`scripts/resource_packs.gd`）呼叫 `ProjectSettings.load_resource_pack`。
4. 編輯器或 `godot --path .` 時資源本來就在專案裡。清單上的 probe 檔還在，就不必有 `.pck`。

`packs.json` 也打進主包（Web preset 的 `include_filter`）。網頁那份在 `build/web/packs.json`，給載入畫面用，並帶上每個檔的 `bytes`。

## 現在的分割

| id | 目錄 | 輸出 |
|----|------|------|
| `family` | `res://assets/family/` | `build/web/packs/family.pck` |

家人年齡段圖是目前最重的一組。遠行靜圖之後可以照下面的步驟另開一包，不必改載入器。

## 再加一包

1. 把新圖放進自己的目錄，例如 `assets/travel/`（目錄要已經存在；probe 要是裡面真的有的一個檔）。
2. 在 `export/packs.json` 的 `packs` 陣列加一筆：

```json
{
  "id": "travel",
  "file": "packs/travel.pck",
  "include": ["res://assets/travel/"],
  "probe": "res://assets/travel/travel_china_family.jpg"
}
```

`id` 用小寫英數。`file` 必須是相對路徑、以 `.pck` 結尾，不能是 `http://` 或 `/` 開頭。

3. 編輯 `export_presets.cfg` 的 **Web** preset（不是 Web Pack），在 `exclude_filter` 加上對應的萬用字元，跟現有項目用逗號接起來：

```
exclude_filter="assets/family/*,assets/travel/*,addons/resource_packs/*"
```

`addons/resource_packs/*` 要留著，那是匯出用的編輯器外掛，不該進遊戲包。

4. 匯出並檢查：

```bash
python3 scripts/pack_manifest.py check
./scripts/export_web.sh
```

`check` 不需要 Godot。它會確認清單、兩個 preset、以及殼頁仍用相對網址。`export_web.sh` 會：

- 對每一包設定 `RESOURCE_PACK_ROLE`，用 preset **Web Pack** 跑 `--export-pack`
- 用 preset **Web** 匯出 `build/web/index.html`（主包排除那些目錄）
- 寫出 `build/web/packs.json`
- 任一檔 ≥ 100 MiB 就失敗
- 確認 probe 只在它自己的 `.pck`、不在 `index.pck`
- 再用 Godot 打開每個額外包（`scripts/check_exported_packs.gd`）

5. 提交 `build/web`（含新的 `packs/*.pck` 與 `packs.json`）再推上 `main`。Pages 工作流程會上傳整個目錄，並再擋一次 100 MiB。

在編輯器裡手動匯出時：Web 是遊戲；Web Pack 的 `resource_packs/role` 預設是 `family`。要匯另一包，把那個選項改成清單裡的 `id`，或照腳本設環境變數 `RESOURCE_PACK_ROLE`。平常用 `./scripts/export_web.sh` 就會逐包設好。

## 本機看網頁

```bash
python3 -m http.server -d build/web 8080
```

用網站根目錄當伺服器時，不要假設網址裡有 `/game-across-time/`。相對路徑會對著 `build/web`。
