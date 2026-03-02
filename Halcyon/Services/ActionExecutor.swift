// ActionExecutor.swift
// ActionType に対応するシステムコマンドを実行するユーティリティ。
// 各アクションは外部プロセス（Process）経由で macOS の標準コマンドを呼び出す。
// App Sandbox が無効のため、Process による外部コマンド実行が可能。
//
// 実行コマンド一覧:
//   screenSaver  → /usr/bin/open -a ScreenSaverEngine （権限不要）
//   displayOff   → /usr/bin/pmset displaysleepnow    （管理者ユーザー推奨）
//   systemSleep  → /usr/bin/pmset sleepnow            （権限不要）

import Foundation

/// アクション種別に応じたシステムコマンドを実行する
/// インスタンス不要のため enum（ケースなし）で定義
enum ActionExecutor {

    /// IdleMonitor から呼ばれるエントリポイント
    static func execute(_ action: ActionType) {
        switch action {
        case .screenSaver:
            startScreenSaver()
        case .displayOff:
            turnOffDisplay()
        case .systemSleep:
            systemSleep()
        }
    }

    /// スクリーンセーバーを起動する（ロック画面への遷移を兼ねる）
    private static func startScreenSaver() {
        run("/usr/bin/open", arguments: ["-a", "ScreenSaverEngine"])
    }

    /// ディスプレイの電源を即時 OFF にする
    /// 非管理者ユーザーでは失敗する場合がある
    private static func turnOffDisplay() {
        run("/usr/bin/pmset", arguments: ["displaysleepnow"])
    }

    /// macOS のシステムスリープを即時実行する
    private static func systemSleep() {
        run("/usr/bin/pmset", arguments: ["sleepnow"])
    }

    /// 外部コマンドを非同期で実行する共通ヘルパー
    /// プロセスの終了を待たず、terminationHandler で異常終了時のみログ出力する
    /// stderr をキャプチャし、失敗時にエラーメッセージをログへ記録する
    private static func run(_ path: String, arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        // stderr をキャプチャしてエラー内容を取得する
        let errPipe = Pipe()
        process.standardError = errPipe
        // terminationHandler は run() より前に設定する
        // （run() 直後にプロセスが終了するとハンドラが呼ばれないレースを防止）
        process.terminationHandler = { proc in
            guard proc.terminationStatus != 0 else { return }
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            Log.debug("command failed: \(path) \(arguments.joined(separator: " ")) exit=\(proc.terminationStatus) stderr=\(errMsg)")
        }
        do {
            try process.run()
        } catch {
            Log.debug("command error: \(path) \(error.localizedDescription)")
        }
    }
}
