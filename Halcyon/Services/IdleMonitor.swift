// IdleMonitor.swift
// HID（キーボード・マウス等）イベントのアイドル時間を監視し、
// 閾値を超えたらアクションチェーンを順次実行するサービス。
//
// 動作フロー:
//   1. start() でポーリングタイマー（5秒間隔）を開始
//   2. checkIdle() で最後の HID イベントからの経過秒数を取得
//   3. 最初のステップの閾値を超えたら beginChain() でチェーンを開始
//   4. 各ステップ実行後、次ステップの待機時間だけ遅延してから
//      再度アイドル秒数を確認し、待機時間以上アイドルなら次ステップへ進む
//   5. 待機中にユーザー操作があった場合（idleSeconds < delay）はチェーン全体をキャンセル
//   6. キャンセル後、再びアイドル閾値を超えたらステップ1から再開
//
// チェーン完了後の再発火防止:
//   CGEventSource のアイドル秒数はチェーン完了後もリセットされないため、
//   chainStartedAt を記録し、アイドル期間がチェーン開始前から継続している場合はスキップする。
//
// App Nap 対策 + macOS システム設定の抑制:
//   ProcessInfo.beginActivity で App Nap を無効化し、
//   バックグラウンドでもタイマーが確実に発火するようにしている。
//   .userInitiated + .idleDisplaySleepDisabled を使用し、
//   macOS のアイドルシステムスリープ・ディスプレイスリープを抑制する。
//   これにより、システム設定の内容に関わらず Halcyon がスリープの流れを一元管理する。
//   注: macOS のスクリーンセーバータイマーはこの API では抑制できない。
//
// RunLoop モード:
//   タイマーは .common モードで登録し、popover 操作中もタイマーが動作する。

import Foundation
import CoreGraphics

@MainActor
final class IdleMonitor {

    /// チェーンが実行中かどうか（checkIdle の多重起動防止に使用）
    private var isChainRunning = false

    /// アイドル検知用の定期ポーリングタイマー
    private var pollingTimer: Timer?
    /// ステップ間の待機用ワンショットタイマー
    private var stepTimer: Timer?
    /// 現在のチェーンで実行するステップ一覧（ActionType と待機秒数のペア）
    private var activeSteps: [(ActionType, TimeInterval)] = []
    /// チェーン内の現在のステップ位置
    private var chainStepIndex = 0
    /// チェーン開始時刻（再発火防止の判定に使用）
    private var chainStartedAt: Date?

    /// ポーリング間隔（秒）
    private let pollingInterval: TimeInterval = 5
    /// App Nap 抑制用のアクティビティトークン
    private var activity: NSObjectProtocol?

    /// 有効なステップ一覧を返すクロージャ（AppState から注入される）
    var stepsProvider: (() -> [(ActionType, Int)])?

    // MARK: - 公開API

    /// アイドル監視を開始する
    /// 既存の監視があれば停止してから再開する
    func start() {
        stop()
        // App Nap を無効化してバックグラウンドでもタイマーを確実に発火させる
        // .userInitiated: App Nap 抑止 + macOS のアイドルシステムスリープを抑制
        // .idleDisplaySleepDisabled: macOS のアイドルディスプレイスリープを抑制
        // Halcyon がスリープまでの流れを一元管理するため、システム側のタイマーを抑制する
        // 注: macOS のスクリーンセーバータイマーはこの API では抑制できない
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleDisplaySleepDisabled, .suddenTerminationDisabled],
            reason: "Halcyon idle monitoring"
        )
        // 起動直後に1回チェックし、その後は定期ポーリング
        checkIdle()
        let timer = Timer(timeInterval: pollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdle()
            }
        }
        // .common モードで登録し、popover 操作中もタイマーが動作するようにする
        RunLoop.main.add(timer, forMode: .common)
        pollingTimer = timer
    }

    /// アイドル監視を停止する
    /// 実行中のチェーンもキャンセルされる
    func stop() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        if let activity { ProcessInfo.processInfo.endActivity(activity) }
        activity = nil
        cancelChain()
    }

    // MARK: - アイドル検知

    /// HID イベントのアイドル秒数を取得し、閾値と比較する
    /// チェーン実行中は何もしない（多重起動防止）
    private func checkIdle() {
        guard !isChainRunning else { return }

        // 全 HID イベント種別の最終イベントからの経過秒数を取得
        guard let idleSeconds = queryIdleSeconds() else { return }

        guard let steps = stepsProvider?(), !steps.isEmpty else { return }
        // 最初のステップの待機時間がチェーン発動の閾値となる
        let firstThreshold = TimeInterval(steps[0].1 * 60)

        Log.debug("idle=\(Int(idleSeconds))s threshold=\(Int(firstThreshold))s")

        if idleSeconds >= firstThreshold {
            // チェーン完了後の再発火防止:
            // アイドル秒数がチェーン開始からの経過時間以上 = チェーン前から続くアイドル
            // → 同じアイドル期間で再度チェーンを起動しない
            if let startedAt = chainStartedAt,
               idleSeconds >= -startedAt.timeIntervalSinceNow {
                Log.debug("skip: idle predates last chain start")
                return
            }
            beginChain(steps: steps)
        }
    }

    // MARK: - チェーン実行

    /// アクションチェーンを開始する
    /// 有効なステップ一覧を受け取り、秒数に変換して保持する
    private func beginChain(steps: [(ActionType, Int)]) {
        activeSteps = steps.map { ($0.0, TimeInterval($0.1 * 60)) }
        chainStepIndex = 0
        chainStartedAt = Date()
        isChainRunning = true
        executeCurrentStep()
    }

    /// 現在のステップを実行し、次ステップがあれば待機タイマーを設定する
    private func executeCurrentStep() {
        guard chainStepIndex < activeSteps.count else {
            cancelChain()
            return
        }

        let (action, _) = activeSteps[chainStepIndex]
        Log.debug("executing step \(chainStepIndex): \(action.displayName)")
        ActionExecutor.execute(action)

        let nextIndex = chainStepIndex + 1
        if nextIndex < activeSteps.count {
            // 次ステップの待機時間（秒）後にアイドル状態を再確認
            let delay = activeSteps[nextIndex].1
            let executedAction = action
            let t = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    guard let idleSeconds = self.queryIdleSeconds() else {
                        self.cancelChain()
                        return
                    }
                    // idleSeconds < delay = 待機中にユーザー操作があった
                    // → チェーン全体をキャンセルし、次回のアイドル検知を待つ
                    if idleSeconds < delay {
                        self.cancelChain()
                        return
                    }
                    // ステップ遷移時に設定を再取得し、変更を反映する
                    // 実行済みアクションの次から継続する
                    if let freshSteps = self.stepsProvider?(), !freshSteps.isEmpty {
                        let freshActive = freshSteps.map { ($0.0, TimeInterval($0.1 * 60)) }
                        // 実行済みアクションの位置を新しいリストで検索
                        if let currentIdx = freshActive.firstIndex(where: { $0.0 == executedAction }),
                           currentIdx + 1 < freshActive.count {
                            self.activeSteps = freshActive
                            self.chainStepIndex = currentIdx + 1
                            self.executeCurrentStep()
                        } else {
                            // 実行済みアクションが無効化されたか、次がない
                            self.cancelChain()
                        }
                    } else {
                        self.cancelChain()
                    }
                }
            }
            RunLoop.main.add(t, forMode: .common)
            stepTimer = t
        } else {
            // 最後のステップ完了後、2秒後にチェーン状態をリセット
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.cancelChain()
            }
        }
    }

    // MARK: - ユーティリティ

    /// HID イベントのアイドル秒数を取得する
    /// CGEventType の初期化に失敗した場合は nil を返す
    private func queryIdleSeconds() -> TimeInterval? {
        guard let allEvents = CGEventType(rawValue: ~0) else {
            Log.debug("CGEventType init failed")
            return nil
        }
        return CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: allEvents)
    }

    /// チェーンをキャンセルし、タイマーと状態をリセットする
    /// chainStartedAt は再発火防止のためリセットしない
    private func cancelChain() {
        stepTimer?.invalidate()
        stepTimer = nil
        isChainRunning = false
        chainStepIndex = 0
    }
}
