// StepCardView.swift
// アクションチェーンの1ステップ分を表示するカードビュー。
// 左側にタイムラインドット＋コネクター線、右側にアクション情報と設定UIを配置する。
//
// レイアウト:
//   [ドット] [アイコン] [アクション名]           [ON/OFFトグル]
//   [線  ]  [「アイドル後」or「前ステップから」] [-] [N分] [+]
//   [線  ]  [スライダー 1〜120分]
//
// タイムラインドット:
//   - 有効時: ActionType の定義順に応じた色（purple → blue → indigo）で塗りつぶし
//   - 無効時: 枠線のみ（中空）で半透明の secondary カラー
//
// コネクター線:
//   showConnector = true の場合、ドットの下から次のカードまで縦線を描画
//
// 待機時間の設定:
//   - ±ボタンで1分刻みの増減
//   - スライダーで1〜120分の範囲を直感的に設定
//   - 先頭ステップは「アイドル後」、2番目以降は「前ステップから」と表示

import SwiftUI

struct StepCardView: View {
    @ObservedObject var appState: AppState
    /// 表示するアクション種別
    let action: ActionType
    /// このカードの下にタイムラインのコネクター線を表示するか
    var showConnector: Bool = false

    /// このアクションが有効かどうか
    private var isEnabled: Bool {
        appState.isEnabled(action)
    }

    /// このアクションが有効ステップの先頭かどうか（「アイドル後」表示の判定）
    private var isFirst: Bool {
        appState.isFirstEnabled(action)
    }

    /// 待機時間（分）の双方向バインディング（±ボタン用、Int 型）
    private var minutes: Binding<Int> {
        Binding(
            get: { appState.minutes(for: action) },
            set: { appState.setMinutes(action, $0) }
        )
    }

    /// 待機時間（分）の双方向バインディング（Slider 用、Double 型）
    private var sliderMinutes: Binding<Double> {
        Binding(
            get: { Double(appState.minutes(for: action)) },
            set: { appState.setMinutes(action, Int($0.rounded())) }
        )
    }

    /// 有効/無効の双方向バインディング（トグル用）
    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { appState.isEnabled(action) },
            set: { appState.setEnabled(action, $0) }
        )
    }

    /// タイムラインドットの色（ステップ順に purple → blue → indigo）
    private var dotColor: Color {
        let colors: [Color] = [.purple, .blue, .indigo]
        let index = ActionType.allCases.firstIndex(of: action) ?? 0
        return colors[index % colors.count]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // タイムラインのドットとコネクター線
            VStack(spacing: 0) {
                // ドット: 有効時は塗りつぶし、無効時は枠線のみ
                Circle()
                    .fill(isEnabled ? dotColor : Color.clear)
                    .overlay(
                        Circle()
                            .stroke(isEnabled ? dotColor : Color.secondary.opacity(0.5), lineWidth: 1.5)
                    )
                    .frame(width: 8, height: 8)
                    .padding(.top, 11)
                
                // コネクター線: 次のステップへの接続を示す縦線
                if showConnector {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 1.5)
                }
            }
            .frame(width: 8)
            
            // アクション情報と設定UI
            VStack(spacing: 8) {
                // アイコン・アクション名・ON/OFF トグル
                HStack(spacing: 4) {
                    Image(systemName: action.iconName)
                        .font(.system(size: 14))
                        .foregroundStyle(isEnabled ? .primary : .secondary)

                    Text(action.displayName(language: appState.language))
                        .font(.subheadline)
                        .foregroundStyle(isEnabled ? .primary : .secondary)

                    Spacer()

                    Toggle("", isOn: enabledBinding)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }

                // 有効時のみ表示: 待機時間の設定UI
                if isEnabled {
                    VStack(spacing: 0) {
                        HStack {
                            // 先頭ステップは「アイドル後」、それ以降は「前ステップから」
                            Text((isFirst ? AppText.afterIdle : AppText.afterPreviousStep).text(appState.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            // ±ボタンと分数表示
                            HStack(spacing: 6) {
                                Button {
                                    minutes.wrappedValue -= 1
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)

                                Text(AppText.minuteCount(appState.minutes(for: action), language: appState.language))
                                    .font(.caption.monospacedDigit())
                                    .frame(minWidth: 42)

                                Button {
                                    minutes.wrappedValue += 1
                                } label: {
                                    Image(systemName: "plus.circle")
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // 1〜120分のスライダー
                        Slider(value: sliderMinutes, in: 1...120)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}
