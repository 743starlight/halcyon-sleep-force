// FooterView.swift
// popover 下部のフッター領域。
// 「このアプリについて」リンクと「終了」ボタンを左右に配置する。
//
// レイアウト:
//   左側: info アイコン + 「このアプリについて」 — タップでウェルカムウインドウを表示
//   右側: 「終了」ボタン — アプリを完全に終了する（NSApplication.terminate）

import SwiftUI

struct FooterView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack {
            // ウェルカムウインドウ（このアプリについて）を表示する
            Button {
                AppDelegate.showWelcomeWindow(language: appState.language)
            } label: {
                Text(AppText.aboutApp.text(appState.language))
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            // アプリを完全に終了する（メニューバーからも消える）
            Button(AppText.quit.text(appState.language)) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}
