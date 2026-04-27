import Foundation

/// アプリ内で扱う表示言語。
/// Localizable.strings は使わず、小規模なUI文言をコード上で明示的に管理する。
enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese
    case english

    var id: String { rawValue }

    /// macOS の地域設定から初期表示言語を決める。
    /// 日本地域のみ日本語、それ以外は英語にして、判定できない環境でも英語へ倒す。
    static var defaultForCurrentLocale: AppLanguage {
        Locale.current.region?.identifier == "JP" ? .japanese : .english
    }

    /// デバッグUIの言語切替に表示する固定ラベル。
    /// このラベル自体は現在の言語に依存させず、選択肢として常に読める表記にする。
    var label: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }
}

/// 1つの文言に日本語・英語を持たせる軽量な入れ物。
/// 呼び出し側は AppLanguage だけ渡せば表示文字列を取得できる。
struct LocalizedText {
    let japanese: String
    let english: String

    func text(_ language: AppLanguage) -> String {
        switch language {
        case .japanese: return japanese
        case .english: return english
        }
    }
}

/// アプリ共通の表示文言を集約する。
/// 文言の追加・修正箇所をここに寄せ、各Viewに直書き文字列が増えないようにする。
enum AppText {
    static let monitoringActive = LocalizedText(japanese: "自動スリープ待機中", english: "Auto sleep is on")
    static let stopped = LocalizedText(japanese: "停止中", english: "Stopped")
    static let debugLog = LocalizedText(japanese: "デバッグログ", english: "Debug log")
    static let displayLanguage = LocalizedText(japanese: "表示言語", english: "Language")
    static let adminWarning = LocalizedText(japanese: "管理者権限がないため一部動作しない場合があります", english: "Some actions may not work without admin privileges")
    static let launchAtLogin = LocalizedText(japanese: "ログイン時に起動", english: "Launch at login")
    static let launchAtLoginDescription = LocalizedText(japanese: "Macの起動時に自動で開始します", english: "Starts automatically when you log in")
    static let autoSleepStopped = LocalizedText(japanese: "自動スリープは停止中です", english: "Auto sleep is off")
    static let noActionSelected = LocalizedText(japanese: "アクションが選択されていません", english: "No steps selected")
    static let afterIdle = LocalizedText(japanese: "アイドル後", english: "After idle")
    static let afterPreviousStep = LocalizedText(japanese: "前ステップから", english: "After previous step")
    static let aboutApp = LocalizedText(japanese: "このアプリについて", english: "About this app")
    static let quit = LocalizedText(japanese: "終了", english: "Quit")
    static let welcomeTitle = LocalizedText(japanese: "Halcyon へようこそ", english: "Welcome to Halcyon")
    static let welcomeMenuBarTitle = LocalizedText(japanese: "メニューバーに常駐", english: "Lives in the menu bar")
    static let welcomeMenuBarDescription = LocalizedText(japanese: "Halcyon はメニューバーに常駐します。\n画面右上のアイコンをクリックして設定画面を開けます。", english: "Halcyon stays in the menu bar.\nClick the icon in the top-right to open settings.")
    static let welcomeStepsTitle = LocalizedText(japanese: "ステップごとに設定", english: "Configure each step")
    static let welcomeStepsDescription = LocalizedText(japanese: "スクリーンセーバー→ディスプレイOFF→スリープの各ステップを設定できます。", english: "Set each step: screen saver, display off, then sleep.")
    static let welcomeSettingsTitle = LocalizedText(japanese: "設定を確認してください", english: "Check this setting")
    static let welcomeSettingsDescription = LocalizedText(japanese: "スクリーンセーバー起動ステップを使う場合、macOS側の設定変更が必要です。", english: "If you use the screen saver step, you need to change one macOS setting.")
    static let learnMore = LocalizedText(japanese: "詳しくはこちら", english: "Learn more")
    static let close = LocalizedText(japanese: "閉じる", english: "Close")
    static let welcomeFooter = LocalizedText(japanese: "初回起動時のみ表示されます。アプリ下部「このアプリについて」からいつでも確認できます", english: "Shown only on first launch. You can reopen it from About this app at the bottom of the app.")
    static let updateAvailable = LocalizedText(japanese: "新しいバージョンがあります", english: "A new version is available")
    static let download = LocalizedText(japanese: "ダウンロード", english: "Download")
    static let skipThisVersion = LocalizedText(japanese: "このバージョンをスキップ", english: "Skip this version")
    static let later = LocalizedText(japanese: "後で", english: "Later")

    /// アクション名と合計待機時間を、言語ごとの自然な語順で組み立てる。
    static func totalUntil(actionName: String, minutes: Int, language: AppLanguage) -> String {
        switch language {
        case .japanese:
            return "\(actionName)まで合計 \(minutes)分"
        case .english:
            return "\(minutes) min until \(actionName)"
        }
    }

    /// 分数表示は複数箇所で使うため、単位表記をここで統一する。
    static func minuteCount(_ minutes: Int, language: AppLanguage) -> String {
        switch language {
        case .japanese:
            return "\(minutes)分"
        case .english:
            return "\(minutes) min"
        }
    }

    /// 更新通知はバージョン番号を埋め込むため、固定文言ではなく関数で生成する。
    static func updateDescription(version: String, language: AppLanguage) -> String {
        switch language {
        case .japanese:
            return "\(version) がリリースされています。ダウンロードページを開きますか？"
        case .english:
            return "\(version) is available. Open the download page?"
        }
    }
}
