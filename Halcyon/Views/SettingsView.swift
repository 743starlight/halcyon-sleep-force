// SettingsView.swift
// ログイン時にアプリを自動起動するかの設定ビュー。
// SMAppService を通じて macOS のログイン項目に登録・解除を行う。
//
// レイアウト:
//   [ログイン時に起動]                     [ON/OFFトグル]
//   [Macの起動時に自動で開始します]  ← ON 時のみ表示
//
// 注意:
//   @AppStorage ではなく SMAppService.mainApp.status で直接状態を取得するため、
//   Binding を手動で構築して get/set を AppState.launchAtLogin に委譲している。

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(AppText.launchAtLogin.text(appState.language))
                    .font(.subheadline)
                Spacer()
                // SMAppService の登録状態を直接参照するため手動 Binding
                Toggle("", isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.launchAtLogin = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
            }

            // 自動起動が有効な場合に補足テキストを表示
            if appState.launchAtLogin {
                Text(AppText.launchAtLoginDescription.text(appState.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }
}
