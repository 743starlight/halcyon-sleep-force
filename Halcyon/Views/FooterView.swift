// FooterView.swift
// popover 下部のフッター領域。
// 「このアプリについて」リンクと「終了」ボタンを左右に配置する。
//
// レイアウト:
//   左側: info アイコン + 「このアプリについて」 — タップでウェルカムウインドウを表示
//   右側: 「終了」ボタン — アプリを完全に終了する（NSApplication.terminate）

import SwiftUI

struct FooterView: View {
    var body: some View {
        HStack {
            // ウェルカムウインドウ（このアプリについて）を表示する
            Button {
                AppDelegate.showWelcomeWindow()
            } label: {
                Text("このアプリについて")
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            // アプリを完全に終了する（メニューバーからも消える）
            Button("終了") {
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
