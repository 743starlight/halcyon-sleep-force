// Log.swift
// アプリ全体で使用するデバッグログユーティリティ。
// os.Logger を使用し、Console.app でリアルタイムに確認できる。
//
// 使い方:
//   Log.debug("メッセージ") — isEnabled が true の場合のみ出力
//   Log.isEnabled の切替は ContentView のデバッグトグルから行う
//
// 出力先:
//   macOS の統合ログシステム（Console.app で subsystem "com.743starlight.halcyon" でフィルタ可能）
//   privacy: .public により、ログメッセージが <private> にマスクされない

import os

/// デバッグログの出力を管理するユーティリティ
/// インスタンス不要のため enum（ケースなし）で定義
enum Log {
    /// ログ出力の有効/無効（デフォルト: 無効）
    /// OSAllocatedUnfairLock で保護し、メインスレッドとバックグラウンドスレッド間のデータ競合を防止
    private static let _isEnabled = OSAllocatedUnfairLock(initialState: false)
    static var isEnabled: Bool {
        get { _isEnabled.withLock { $0 } }
        set { _isEnabled.withLock { $0 = newValue } }
    }

    /// os.Logger インスタンス（subsystem でアプリを識別、category で用途を分類）
    private static let logger = Logger(subsystem: "com.743starlight.halcyon", category: "monitor")

    /// デバッグメッセージを統合ログに出力する
    /// isEnabled が false の場合は何もしない
    /// バックグラウンドスレッド（terminationHandler 等）からも安全に呼び出し可能
    static func debug(_ message: String) {
        guard isEnabled else { return }
        logger.info("[Halcyon] \(message, privacy: .public)")
    }
}
