// ActionChainView.swift
// アクションチェーンの3ステップを縦に並べるコンテナビュー。
// ActionType.allCases の定義順に StepCardView を表示する。
// 各カード間にはタイムラインのコネクター線が描画される（最後のカードを除く）。
//
// 表示仕様:
//   - 監視 ON 時: 通常の不透明度で表示
//   - 監視 OFF 時: 半透明（opacity 0.5）で表示し、操作不可であることを視覚的に示す
//   - 無効なステップも常に表示する（トグルで ON/OFF を切り替えられるようにするため）

import SwiftUI

struct ActionChainView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // ActionType.allCases の定義順（screenSaver → displayOff → systemSleep）で表示
            ForEach(ActionType.allCases) { action in
                StepCardView(
                    appState: appState,
                    action: action,
                    // 最後のステップ以外はタイムラインのコネクター線を表示
                    showConnector: action != ActionType.allCases.last
                )
            }
        }
        .padding(.horizontal, 16)
        // 監視 OFF 時は半透明にして無効状態を視覚的に表現
        .opacity(appState.isMonitoringEnabled ? 1.0 : 0.5)
    }
}
