// HalcyonApp.swift
// アプリケーションのエントリポイント。
// macOS メニューバーに常駐し、popover ウィンドウで UI を表示する。
// Dock には表示されない（Info.plist の LSUIElement = true）。

import SwiftUI

/// アプリ起動直後にウェルカムウインドウを表示するための AppDelegate
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        guard !hasSeenWelcome else { return }
        UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
        showWelcomeWindow()
    }

    /// AppKit で直接ウェルカムウインドウを生成・表示する
    static func showWelcomeWindow() {
        // 既にウインドウが存在する場合は最前面に移動するだけ
        for window in NSApp.windows where window.title == "Halcyon へようこそ" {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(rootView: WelcomeView())
        hostingView.setFrameSize(hostingView.fittingSize)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Halcyon へようこそ"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func showWelcomeWindow() {
        AppDelegate.showWelcomeWindow()
    }
}

@main
struct HalcyonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// アプリ全体の状態を保持する ViewModel（設定値・監視制御を一元管理）
    @StateObject private var appState = AppState()

    init() {
        UpdateChecker.checkOnLaunch()
    }

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
