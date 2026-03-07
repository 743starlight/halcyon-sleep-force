// HeaderView.swift
// popover 上部のヘッダー領域。
// アプリ名・バージョン/ビルド番号・監視状態インジケーター・監視 ON/OFF トグルを表示する。
//
// レイアウト:
//   左側: アプリ名 "Halcyon" + バージョン "vX.Y.Z (build)" + 状態ドット + ステータステキスト
//   右側: 監視 ON/OFF のスイッチトグル
//
// バージョン表示:
//   Info.plist の CFBundleShortVersionString をそのまま表示
//   CFBundleVersion をビルド番号として括弧内に表示

import SwiftUI

struct HeaderView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                // アプリ名とバージョン/ビルド番号
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Halcyon")
                        .font(.custom("Syne-Bold", size: 14))
                    // CFBundleShortVersionString（例: "1.0.1"）を取得
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
                    // CFBundleVersion はビルドごとに変わる5桁の数値（Unix時間の下5桁）
                    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
                    Text("v\(version) (\(build))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                // 監視状態のインジケーター（緑ドット=待機中、灰色ドット=停止中）
                HStack(spacing: 4) {
                    Circle()
                        .fill(appState.isMonitoringEnabled ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(appState.isMonitoringEnabled ? "自動スリープ待機中" : "停止中")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 監視の ON/OFF を切り替えるメインスイッチ
            Toggle("", isOn: $appState.isMonitoringEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
