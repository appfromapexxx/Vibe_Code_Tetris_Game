# Tetris

SwiftUI 版本的俄羅斯方塊，支援 macOS 與 iOS。核心玩法完整，並加入現代化的 UI 與鍵盤操作。

## 功能特色
- **SwiftUI 介面**：網格棋盤、玻璃質感資訊卡與控制面板。
- **動態音效**：旋轉、移動、掉落、消行、遊戲結束等事件會播放不同提示音。
- **鍵盤控制（macOS）**：  
  - `← / →`：方塊左右移動  
  - `↓`：軟降  
  - `⌘↓`：硬降  
  - `SPACE`：旋轉  
- **觸控／滑鼠**：拖曳手勢可控制方塊方向，點擊棋盤可旋轉。

## 專案結構
- `Tetris/ContentView.swift`：主要 UI 與遊戲邏輯（棋盤、控制、音效）。
- `Tetris/TetrisApp.swift`：App 入口。
- `.vscode/tasks.json`：VS Code 建置指令（使用 `xcodebuild`）。
- `build/`：`xcodebuild` 產生的中繼檔案（可清除）。

## 安裝/移除 (macOS)
1. 前往 [GitHub Releases](https://github.com/appfromapexxx/Vibe_Code_Tetris_Game/releases) 下載最新 `Tetris.dmg`。
2. 開啟磁碟映像，將 `Tetris.app` 拖曳到 `Applications`（或你偏好的資料夾）。

要完全移除時，只需刪除 `/Applications/Tetris.app`（或當初拷貝的位置），本 App 不會在系統放任何額外檔案。
