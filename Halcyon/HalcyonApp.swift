// HalcyonApp.swift
// アプリケーションのエントリポイント。
// macOS メニューバーに常駐し、popover ウィンドウで UI を表示する。
// Dock には表示されない（Info.plist の LSUIElement = true）。

import SwiftUI

@main
struct HalcyonApp: App {
    /// アプリ全体の状態を保持する ViewModel（設定値・監視制御を一元管理）
    @StateObject private var appState = AppState()

    var body: some Scene {
        // MenuBarExtra: メニューバーにアイコンを配置し、クリックで popover を表示
        MenuBarExtra {
            ContentView(appState: appState)
        } label: {
            // Assets.xcassets 内のカスタムアイコンをテンプレート画像として使用
            // テンプレートモードにより、macOS がライト/ダークモードに応じて色を自動調整
            Image("MenuBarIcon")
                .renderingMode(.template)
        }
        .menuBarExtraStyle(.window)
    }
}
