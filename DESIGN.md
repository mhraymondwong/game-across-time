# 《時光裡的她》— 玩法規格（v0.1）

> 原創養成遊戲。靈感僅參考「父親培養女兒、屬性／工作／多結局」類型；**不**使用《美少女夢工場》名稱、劇情、角色、美術或音樂。
> Godot **4.7.2**｜繁體中文｜日系動畫風圖像一律 **Grok Imagine**

## 1. 定位

| 項目 | 決定 |
|------|------|
| 對象 | 大人懷舊 |
| 玩家 | 父親／監護人 |
| 主角 | 女兒（成長 12 年） |
| 世界 | 港式／台式溫馨小鎮 |
| 尺度 | 成人懷舊、無露骨 |
| 結局 | 多結局職業／人生路線 |
| 介面 | 溫柔日記／手帳 ＋ 小鎮地圖彈出面板 |

## 2. 時間結構

- **總長**：12 年（女兒約 6→17 歲）
- **成長立繪**：每 **2 年**換一階（共 6 階：年1–2／3–4／5–6／7–8／9–10／11–12）
- **季節換裝**：每季衣櫃不同（`assets/wardrobe/s{stage}_{spring|summer|autumn|winter}`；缺檔則回退同階其他季→春→鄰近階春）
- **每年**：春、夏、秋、冬四季
- **每季**：3 個月
- **每月**：玩家排 **1** 項主活動（工作／學習／休息／社交／家務等）
- **一局約**：12 × 4 × 3 = **144** 個排程格（另加地圖事件、季節事件）

季節影響：活動效果微調、小鎮氣氛、偶發天氣／節慶事件（見 §10；約五成機率主題事件，否則輕量「平靜週末」）。

## 3. 核心迴圈（每季）

1. **小鎮地圖**：可點學校、公園、商店街、住家、診所、文化中心等 → 彈出面板（資訊／偶發對話）
2. **日記排程**：為本季三個月各選 1 活動
3. **結算**：屬性／金錢／心情／人際變化；短事件卡（可選）
4. **下季**；年末可有簡單回顧插圖

重複至第 12 年末 → 結局結算。

## 4. 數值

### 角色屬性（HUD 主顯示）

- **魅力／氣質**
- **道德／品格**
- **人際／友情**
- **體力／健康**

### 輕量隱藏

- **學識**（影響教師、醫生、學者類結局門檻，不強調數值條）

### 資源

- **家計金錢**（打工賺、學費／消費花；破產有輕度救援，避免死鎖）
- **心情**（過低限制激烈活動）

屬性大致 0–100；活動有加減與上限衰減，避免無腦刷滿。

## 5. 活動類別（每月選一）

示例（實作時再平衡）：

| 類別 | 例子 | 傾向 |
|------|------|------|
| 學習 | 補習、圖書館、才藝課 | 學識↑ 體力↓ 錢↓ |
| 打工 | 咖啡店、便利店、家教 | 錢↑ 體力↓ 人際微↑ |
| 社交 | 朋友聚會、社團、鄰居 | 人際↑ 魅力微↑ |
| 休閒 | 公園散步、旅行、睡覺 | 體力↑ 心情↑ |
| 品格 | 志工、照顧長輩、家務 | 道德↑ |
| 打扮／氣質 | 穿搭、儀態、表演 | 魅力↑ 錢↓ |

地圖點地點可解鎖特殊活動或一次性事件。

## 6. 結局（職業／人生路線）

依最終屬性＋隱藏學識＋關鍵旗標解鎖，例如（名稱可再調）：

- 溫柔教師、社區醫師、設計師、咖啡店老闆、公務員、運動教練、作家、居家照顧者、旅居追夢者、普通幸福生活（預設）、疲憊失控（失敗向，溫和呈現）

結局面：日系插畫 ＋ 短文總結 ＋ 屬性雷達／分數。

## 7. 畫面與技術

- 解析度建議：**1280×720** 橫向（可後續加直式）
- 美術：日系動畫風；**全部圖像 Grok Imagine 產出後置入**
- UI：柔色大按鈕、手帳月曆、地圖熱點；參考受歡迎養成／小鎮遊戲的可讀性，**禁止**系統預設灰窗程式風
- 引擎：Godot 4.7.x（目前環境 4.7.2）

## 8. 不做（版權／範圍）

- 不抄襲既有作品劇情、角色名、結局表、UI 美術
- 第一版不做語音、線上、付費內購
- 第一版結局約 **8–12** 個可達路線即可

## 9. 實作順序（確認規格後）

1. Godot 專案骨架＋狀態機（年／季／月）
2. 地圖＋排程 UI（手帳風）
3. 屬性結算與簡單事件
4. Grok Imagine 核心立繪／地圖／UI 框
5. 結局表＋結果畫面
6. 煙霧測試與平衡

---

## 10. Phase 2 — 季節事件與成長立繪（已實作）

- `scripts/season_events.gd`：春／夏／秋／冬天氣與節慶事件（櫻花、春雨、酷熱、颱風、豐收市集、寒流、寒假聚會等）
- 每季結算後擲骰；結果寫入 `GameState.last_season_event`，於 `season_result` 顯示標題／內文／貼紙與微幅數值
- 主畫面全身立繪依年齡換圖：`daughter_child_full` → `daughter_teen` → `daughter_young`
- 貼紙素材：`assets/weather/{spring,summer,autumn,winter}.png`

**狀態**：v0.2 Phase 2 基底保留；見 §11 Phase 3。

## 11. Phase 3 — 六階成長／四季衣櫃／特別活動媒體（已實作）

| 遊戲年 | 階段 | 約略年齡 | 標籤 |
|--------|------|----------|------|
| 1–2 | 0 | 6–7 | 幼年 |
| 3–4 | 1 | 8–9 | 童年 |
| 5–6 | 2 | 10–11 | 高小 |
| 7–8 | 3 | 12–13 | 少年 |
| 9–10 | 4 | 14–15 | 青春 |
| 11–12 | 5 | 16–17 | 青年 |

- `GameConfig.growth_stage_for_year` / `wardrobe_path`：主畫面依年＋季載入全身立繪
- 特別活動（有專屬靜態圖＋短片槽位）：
  - **夏天去海灘** → `assets/events/beach.jpg` + `event_beach.mp4`／可播 `event_beach.ogv`
  - **秋天上山旅行** → `assets/events/mountain.jpg` + `event_mountain.mp4`／可播 `event_mountain.ogv`
- `season_result`：有媒體時先全屏靜態圖；優先播 `.ogv`（Theora）`VideoStreamPlayer`（loop false，可略過）；`.mp4` 為來源檔
- 春日野餐／冬日燈會等仍用天氣貼紙

**狀態**：v0.3 Phase 3；smoke 須過階段表、衣櫃路徑、144 月。


## 12. Phase 4 — 地圖地點事件／存檔讀檔（已實作）

### 地圖小事件
- `scripts/map_events.gd`（`MapEvents`）：住家／學校／公園／商店街／診所／文化中心各約 3–5 則溫馨小事件
- 點地圖 pin → 擲選事件（優先未觸發的 `once` 事件）→ 粉紅彈窗顯示標題／內文／數值摘要
- 可選「在這裡安排活動」直接開本季月活動挑選
- 旗標：`visited_<place_id>` 計次；`once` 事件寫入對應 `flag`

### 存檔
- `GameState.to_dict`／`from_dict`／`save_game`／`load_game`／`has_save`／`delete_save`
- 路徑：`user://save_slot_0.json`（JSON）
- 標題畫面：「繼續遊戲」（有存檔才可按）＋「開始養育」仍開新局
- 主畫面手帳欄：「♡ 存檔」＋短暫「已存檔」提示


### 四季衣櫃補齊
- 六階 × 四季全身立繪均已有 `assets/wardrobe/s{0–5}_{spring|summer|autumn|winter}.png`（角落去背，角色強制不透明）

**狀態**：v0.4 Phase 4；smoke 覆蓋完整衣櫃、地圖六地事件池與存檔 round-trip。

## 13. Phase 5 — 活動解鎖與心情強度閘門（已實作）

### 活動定義擴充（`activities.gd`）
- 可選欄位：`intensity`（0 輕／1 中／2 重）、`min_year`／`min_age`、各屬性 `min_*`、`require_flag`、`require_visit`、`unlock_hint`
- 未標 intensity 時依類別預設：休閒／品格→0、社交／學習／氣質→1、打工→2
- 新增解鎖活動：文化中心朗讀會、診所暑期小幫手、商店街市集擺攤、學校辯論／壁報社、公園晨跑隊、高年級才藝發表

### 可用性 API
- `availability(id, state) → { ok, reason }`；`is_available` 為其 `.ok`
- 心情：<20 僅允許 intensity 0；<35 鎖 intensity 2；中等活動不硬鎖
- 年級／年齡／屬性／旗標／地圖造訪（`visited_<place>`）不足時回傳繁中原因
- 花費超過現有家計時軟鎖「家計不足」

### UI／結算
- 主畫面活動挑選：鎖上列顯示簡短原因＋ tooltip；心情<35 時頂部粉紅提示
- `apply_activity`／`resolve_season`：若活動不可用則改為「在家好好休息」

**狀態**：v0.5 Phase 5；smoke 覆蓋心情閘門、造訪解鎖與新活動 id。


## 14. Phase 6 — 年末回顧相簿風（已實作）

### 流程
- 冬季節算後 `advance_after_season` 若跨年：先 `build_year_review()` → `last_year_review`，年＋1，回傳 `"year_review"`
- `season_result` 導向 `scenes/year_review.tscn`；其餘季仍回主畫面
- 第 12 年冬：設 `pending_ending_after_review`，回顧後按鈕 → `finish_game` → 結局
- 第 1–11 年冬：回顧後「翻到新的一年 ♡」→ `snapshot_year_start()` → 主畫面

### 狀態
- `year_start_stats`／`year_activity_names`／`year_event_titles`／`last_year_review`／`pending_ending_after_review`
- 新局與回顧繼續時 `snapshot_year_start`；活動與季節／地圖事件標題寫入年累積
- 存檔 `to_dict`／`from_dict` 含上述欄位

### 畫面（選項 2 · 相簿貼圖風）
- 全屏 `assets/year_review/album_bg`；左側拍立得拼貼依年齡帶：`polaroids_{child|teen|young}`（缺檔回退 young→teen→child→album_bg）
- 右側手帳卡：標題「第 N 年 · 相簿回顧」、年齡／階段、溫馨摘要、成長貼紙（數值增減）、3–6 則亮點
- `GameConfig.year_review_album_bg`／`year_review_polaroid_path`／`polaroid_band_for_age`

**狀態**：v0.6 Phase 6；smoke 覆蓋回顧字典形狀、冬→year_review、y12→結局。


## 15. Phase 7 — 電影片尾風結局＋屬性雷達（已實作）

### 畫面（選項 6 · 電影片尾風）
- 全屏 `assets/endings/credits_bg`（暗色 bokeh 夜景）＋半透明深色洗底
- 左側結局靜態插畫：`GameConfig.ending_art_path(id)`（png→jpg；缺檔回退 `ordinary_happy`→`credits_bg`）
- 下方字幕帶：小字「十二年之後」、大結局名、摘要、淡字月份／家計
- 右側 `StatRadar`（`scripts/stat_radar.gd`）：五軸 魅力／道德／人際／體力／學識，`_draw` 柔粉白多邊形＋環＋標籤
- 右下半透明軟晶片：「再養育一次」「回標題」

### 結局插畫資產
`assets/endings/`：`credits_bg`、`doctor`、`teacher`、`cafe_owner`、`designer`、`ordinary_happy`、`coach`、`writer`、`burnout`、`wanderer`、`caregiver`、`civil`（各 jpg／部分附 png）

### 截圖
- `scripts/capture_ending.gd` → `shots/06_ending_credits.png`

**狀態**：v0.7 Phase 7；smoke 覆蓋 `ending_art_path`（doctor／ordinary_happy／burnout）與 StatRadar 載入。


## 16. Phase 8 — 日記封面風標題畫面（已實作）

### 畫面（選項 2 · 日記封面風）
- 全屏 `assets/title_diary_cover.jpg`（手寫書法標題「時光裡的她」＋副標「父親與女兒 · 溫馨小鎮」已烤入圖；相角／蕾絲／拍立得拼貼）
- 缺檔時回退 `assets/title_bg.jpg`
- **無**中央大塊不透明 Panel：封面即標題
- 底部輕洗底＋半透明奶油色軟浮層條：橫排「繼續遊戲／開始養育／離開」（`UiStyle.apply_button`）
- 小字註記「原創養成遊戲｜繁體中文」；飾帶 JPG（`title_diary_buttons.jpg`）因無透明底略過，改用軟色條
- 流程不變：有存檔才可「繼續遊戲」→ `home_hub`；「開始養育」→ `begin_new_game` → `home_hub`；「離開」→ quit

### 資產
- `assets/title_diary_cover.jpg` — 主封面 key art
- `assets/title_diary_buttons.jpg` — 飾帶素材（保留；目前 UI 未疊用）
- `assets/title_bg.jpg` — 舊標題底，僅作回退

### 截圖
- `scripts/capture_title.gd` → `shots/07_title_diary.png`

**狀態**：v0.8 Phase 8；smoke 覆蓋 `title_diary_cover.jpg`、`title.gd`／`title.tscn` 載入。
