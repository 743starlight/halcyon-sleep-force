// FooterView.swift
// popover 下部のフッター領域。
// 「設定について」リンクと「終了」ボタンを左右に配置する。
//
// レイアウト:
//   左側: 歯車アイコン + 「設定について」 — タップでセットアップガイドをブラウザで開く
//   右側: 「終了」ボタン — アプリを完全に終了する（NSApplication.terminate）

import SwiftUI

struct FooterView: View {
    var body: some View {
        HStack {
            // 設定の詳細説明ページ（セットアップガイド）をブラウザで開くリンク
            Button {
                if let url = URL(string: "https://halcyon-sleep-force.vercel.app/setup") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                        .font(.caption)
                    Text("設定について")
                }
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
        .padding(.vertical, 8)
    }
}
