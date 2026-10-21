# 《時光裡的她》

原創養成遊戲（Godot 4.7）。父親在溫馨小鎮養育女兒十二年：四季 × 每月一項活動、屬性與多結局。

> 靈感僅參考養成類型；不使用《美少女夢工場》名稱、劇情或美術。

## 需求

- Godot **4.7.x**（本機環境：`/home/box/bin/godot` → 4.7.2）

## 執行（視窗）

```bash
/home/box/bin/godot --path "/workspace/agents/Game Designer/time-with-her"
```

或用 Godot 編輯器開啟本資料夾，按 F5。

## 煙霧測試（無頭、完整 12 年）

```bash
/home/box/bin/godot --headless --path "/workspace/agents/Game Designer/time-with-her" --script res://scripts/smoke_test.gd
```

成功時結束碼為 `0`，並印出 `[smoke] PASS` 與結局名稱。

## 流程

標題 → 日記排程（每季 3 個月）→ 季節結算 → 下季／下年 → 第 12 年末結局。

小鎮地圖可點地點查看說明（第一版 stub）。

## 美術（之後）

介面目前為柔色 StyleBox 佔位。圖像一律以 **Grok Imagine** 製作後再置入。

## UI（Layout 2）
- 主畫面 `home_hub`：全屏小鎮地圖 + 底部手帳抽屜
- 標題 `title`：使用 `assets/title_bg.jpg`
- 地圖地點圖示：`assets/pins/*.png`（由 `map_pins.jpg` 裁切）
- 截圖：`shots/01_map_diary.png`
