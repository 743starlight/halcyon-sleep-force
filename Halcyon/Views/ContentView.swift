// ContentView.swift
// popover ウィンドウのルートビュー。
// 各セクション（ヘッダー、アクションチェーン、タイムライン、設定、フッター）を
// 垂直に配置し、幅 320pt の固定サイズで表示する。
//
// レイアウト構成（上から順）:
//   HeaderView       — アプリ名・バージョン・監視状態トグル
//   Divider
//   ActionChainView  — 3ステップのカード一覧（タイムラインドット付き）
//   TimelineBarView  — 合計待機時間のサマリーテキスト
//   Divider
//   SettingsView     — ログイン時起動の設定
//   デバッグログ切替   — Option キー押下時のみ表示
//   管理者権限警告     — 非管理者ユーザーの場合のみ表示
//   FooterView       — 設定リンク・終了ボタン

import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    /// Option キー押下で popover を開いた場合にデバッグセクションを表示する
    @State private var showDebug = false

    var body: some View {
        VStack(spacing: 0) {
            // アプリ名・バージョン・監視 ON/OFF トグル
            HeaderView(appState: appState)

            Divider()
                .padding(.horizontal, 16)

            // アクションチェーンの3ステップ（スクリーンセーバー → ディスプレイOFF → スリープ）
            ActionChainView(appState: appState)
                .padding(.top, 12)
                .padding(.leading, 6)
                .padding(.bottom, 8)

            // 有効ステップの合計待機時間を表示
            TimelineBarView(appState: appState)
                .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            // ログイン時に起動の ON/OFF
            SettingsView(appState: appState)
                .padding(.top, 8)

            // デバッグログ切替（Option キーを押しながら popover を開いた場合のみ表示）
            if showDebug {
                HStack {
                    Text("デバッグログ")
                        .font(.subheadline)
                    Spacer()
                    Toggle("", isOn: $appState.debugLogging)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
            }

            // 非管理者ユーザーへの警告（pmset displaysleepnow が失敗する可能性がある）
            if !appState.isAdminUser {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("管理者権限がないため一部動作しない場合があります")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            // 設定リンク・アプリ終了ボタン
            FooterView()
            .padding(.bottom, 2)
        }
        .frame(width: 320)
        .onAppear {
            // popover 表示時に Option キーが押されていればデバッグ UI を表示
            showDebug = NSEvent.modifierFlags.contains(.option)
        }
        .onChange(of: appState.isMonitoringEnabled) { _, _ in
            // 監視トグル変更時に IdleMonitor の起動/停止を同期
            appState.syncMonitoring()
        }
        .onChange(of: appState.debugLogging) { _, newValue in
            // デバッグトグル変更時に Log ユーティリティの出力フラグを同期
            Log.isEnabled = newValue
        }
    }
}
