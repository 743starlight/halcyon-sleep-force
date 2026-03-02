// AppState.swift
// アプリ全体の状態を一元管理する ViewModel。
// 各ステップの有効/無効・待機時間、監視の ON/OFF、ログイン時起動の設定を保持する。
// @AppStorage によりすべての設定値が UserDefaults に自動永続化される。
//
// 責務:
//   - 各アクションステップの設定値の読み書き（有効/無効、待機分数）
//   - IdleMonitor の起動・停止制御
//   - 管理者ユーザー判定（pmset displaysleepnow の実行可否に影響）
//   - SMAppService によるログイン時自動起動の登録・解除

import SwiftUI
import ServiceManagement

@MainActor
final class AppState: ObservableObject {

    /// デバッグログの出力切替（Option キー押下時のみ UI に表示される）
    /// @AppStorage で永続化し、アプリ再起動後も設定を保持する
    @AppStorage("debugLogging") var debugLogging = false

    // MARK: - UserDefaults 永続化される設定値

    /// 監視全体の ON/OFF（トグルで切替、OFF にすると IdleMonitor を停止）
    @AppStorage("isMonitoringEnabled") var isMonitoringEnabled = true
    /// スクリーンセーバー起動ステップの有効/無効
    @AppStorage("step_screensaver_enabled") var screenSaverEnabled = true
    /// スクリーンセーバー起動までのアイドル待機時間（分）
    @AppStorage("step_screensaver_minutes") var screenSaverMinutes = 20
    /// ディスプレイOFF ステップの有効/無効
    @AppStorage("step_display_off_enabled") var displayOffEnabled = true
    /// ディスプレイOFF までの待機時間（分、前ステップからの経過）
    @AppStorage("step_display_off_minutes") var displayOffMinutes = 10
    /// システムスリープ ステップの有効/無効
    @AppStorage("step_sleep_enabled") var sleepEnabled = true
    /// システムスリープまでの待機時間（分、前ステップからの経過）
    @AppStorage("step_sleep_minutes") var sleepMinutes = 10

    // MARK: - サービス・判定

    /// アイドル監視サービス（ポーリングとチェーン実行を担当）
    let idleMonitor = IdleMonitor()

    /// 現在のユーザーが管理者グループに属しているか判定する
    /// POSIX API (getgrnam + getgroups) を使用し、プロセス起動なしで判定
    /// pmset displaysleepnow は管理者でないと失敗する場合がある
    let isAdminUser: Bool = {
        guard let grp = getgrnam("admin") else { return false }
        let adminGid = grp.pointee.gr_gid
        // プロセスの補助グループ ID 一覧を取得し、admin グループの GID が含まれるか判定
        var groups = [gid_t](repeating: 0, count: 64)
        let count = getgroups(64, &groups)
        guard count > 0 else { return false }
        return groups.prefix(Int(count)).contains(adminGid)
    }()

    /// ログイン時にアプリを自動起動するかどうか
    /// SMAppService を通じて macOS のログイン項目に登録・解除する
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Log.debug("SMAppService error: \(error)")
            }
            // SwiftUI に変更を通知して UI を更新する
            objectWillChange.send()
        }
    }

    // MARK: - 初期化

    init() {
        // IdleMonitor に有効ステップ一覧を返すクロージャを注入
        // IdleMonitor が AppState を直接参照しないよう、クロージャで疎結合にしている
        idleMonitor.stepsProvider = { [weak self] in
            self?.enabledSteps ?? []
        }
        // 永続化されたデバッグログ設定を Log ユーティリティに同期
        Log.isEnabled = debugLogging
        syncMonitoring()
    }

    /// isMonitoringEnabled の値に応じて IdleMonitor を起動または停止する
    /// ContentView の onChange から呼ばれる
    func syncMonitoring() {
        if isMonitoringEnabled {
            idleMonitor.start()
        } else {
            idleMonitor.stop()
        }
        Log.debug("monitoring=\(isMonitoringEnabled)")
    }

    // MARK: - ステップ一覧の算出

    /// 現在有効なステップを定義順に返す（IdleMonitor のチェーン実行で使用）
    var enabledSteps: [(ActionType, Int)] {
        var steps: [(ActionType, Int)] = []
        if screenSaverEnabled {
            steps.append((.screenSaver, screenSaverMinutes))
        }
        if displayOffEnabled {
            steps.append((.displayOff, displayOffMinutes))
        }
        if sleepEnabled {
            steps.append((.systemSleep, sleepMinutes))
        }
        return steps
    }

    /// 有効な全ステップの待機時間の合計（分）
    var totalMinutes: Int {
        enabledSteps.reduce(0) { $0 + $1.1 }
    }

    // MARK: - ActionType 経由のアクセサ（View から使用）

    /// 指定アクションが有効かどうかを返す
    func isEnabled(_ action: ActionType) -> Bool {
        switch action {
        case .screenSaver: return screenSaverEnabled
        case .displayOff: return displayOffEnabled
        case .systemSleep: return sleepEnabled
        }
    }

    /// 指定アクションの有効/無効を設定する
    func setEnabled(_ action: ActionType, _ value: Bool) {
        switch action {
        case .screenSaver: screenSaverEnabled = value
        case .displayOff: displayOffEnabled = value
        case .systemSleep: sleepEnabled = value
        }
    }

    /// 指定アクションの待機時間（分）を返す
    func minutes(for action: ActionType) -> Int {
        switch action {
        case .screenSaver: return screenSaverMinutes
        case .displayOff: return displayOffMinutes
        case .systemSleep: return sleepMinutes
        }
    }

    /// 指定アクションの待機時間（分）を設定する（1〜120 の範囲にクランプ）
    func setMinutes(_ action: ActionType, _ value: Int) {
        let clamped = max(1, min(120, value))
        switch action {
        case .screenSaver: screenSaverMinutes = clamped
        case .displayOff: displayOffMinutes = clamped
        case .systemSleep: sleepMinutes = clamped
        }
    }

    /// 指定アクションが有効ステップの先頭かどうか（「アイドル後」表示の判定に使用）
    func isFirstEnabled(_ action: ActionType) -> Bool {
        enabledSteps.first?.0 == action
    }

}
