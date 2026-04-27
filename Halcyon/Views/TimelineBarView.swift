// TimelineBarView.swift
// アクションチェーンの合計待機時間をサマリーテキストとして表示するビュー。
// 監視状態や有効ステップの有無に応じて表示内容が切り替わる。
//
// 表示パターン:
//   - 監視 OFF       → 「自動スリープは停止中です」
//   - 有効ステップなし → 「アクションが選択されていません」
//   - 通常           → 「{最後のステップ名}まで合計 N分」

import SwiftUI

struct TimelineBarView: View {
    @ObservedObject var appState: AppState

    /// 現在有効なステップ一覧
    private var steps: [(ActionType, Int)] {
        appState.enabledSteps
    }

    /// 有効ステップの待機時間合計（分）
    private var total: Int {
        appState.totalMinutes
    }

    var body: some View {
        Group {
            if !appState.isMonitoringEnabled {
                // 監視が OFF の場合
                Text(AppText.autoSleepStopped.text(appState.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if steps.isEmpty {
                // 全ステップが無効の場合
                Text(AppText.noActionSelected.text(appState.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // 最後の有効ステップ名と合計時間を表示
                Text(AppText.totalUntil(actionName: steps.last!.0.displayName(language: appState.language), minutes: total, language: appState.language))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
}
