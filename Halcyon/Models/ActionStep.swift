// ActionStep.swift
// アクションチェーンで実行可能なアクションの種別を定義する。
// 各ケースは UI 表示名・SF Symbols アイコン名を持つ。
// CaseIterable により全ケースを列挙でき、チェーンの表示順序は定義順に従う。
//
// 実行順序（デフォルト）:
//   1. screenSaver  — スクリーンセーバーを起動してロック画面へ遷移
//   2. displayOff   — ディスプレイの電源を即時 OFF
//   3. systemSleep  — macOS のシステムスリープを実行

import Foundation

/// アクションチェーンの各ステップを表す列挙型
enum ActionType: String, CaseIterable, Identifiable {
    case screenSaver   // スクリーンセーバー起動（open -a ScreenSaverEngine）
    case displayOff    // ディスプレイOFF（pmset displaysleepnow）
    case systemSleep   // システムスリープ（pmset sleepnow）

    /// ForEach 等で使用する一意識別子（rawValue をそのまま利用）
    var id: String { rawValue }

    /// UI に表示するアクション名
    func displayName(language: AppLanguage) -> String {
        let text: LocalizedText
        switch self {
        case .screenSaver:
            text = LocalizedText(japanese: "スクリーンセーバー起動", english: "Screen saver")
        case .displayOff:
            text = LocalizedText(japanese: "ディスプレイOFF", english: "Display off")
        case .systemSleep:
            text = LocalizedText(japanese: "システムスリープ", english: "System sleep")
        }
        return text.text(language)
    }

    /// SF Symbols のアイコン名（StepCardView で使用）
    var iconName: String {
        switch self {
        case .screenSaver: return "tv.inset.filled"
        case .displayOff: return "display"
        case .systemSleep: return "moon.fill"
        }
    }

}
