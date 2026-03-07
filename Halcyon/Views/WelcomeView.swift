// WelcomeView.swift
// 初回起動時に表示するウェルカムウインドウ。
// メニューバー常駐であること、基本的な使い方を案内する。

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // ── ヘッダー ──
            VStack(spacing: 4) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .padding(.bottom, 4)

                Text("Halcyon")
                    .font(.custom("Syne-Bold", size: 22))

                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
                let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
                Text("v\(version) (\(build))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 32)
            .padding(.bottom, 24)

            Divider().padding(.horizontal, 24)

            // ── 使い方 ──
            VStack(alignment: .leading, spacing: 14) {
                WelcomeRow(
                    icon: "menubar.arrow.up.rectangle",
                    title: "メニューバーに常駐",
                    description: "Halcyon はメニューバーに常駐します。\n画面右上のアイコンをクリックして設定画面を開けます。"
                )
                WelcomeRow(
                    icon: "slider.horizontal.3",
                    title: "ステップごとに設定",
                    description: "スクリーンセーバー → ディスプレイOFF → スリープの\n各ステップを個別に設定できます。"
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider().padding(.horizontal, 24)

            // ── スクリーンセーバー設定の案内 ──
            WelcomeRow(
                icon: "exclamationmark.triangle",
                title: "設定を確認してください",
                description: "スクリーンセーバー起動ステップを使う場合、macOS側の設定変更が必要です。",
                iconColor: .orange
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 4)

            // ── ボタン ──
            VStack(spacing: 10) {
                Button {
                    if let url = URL(string: "https://halcyon-sleep-force.vercel.app/setup") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("詳しくはこちら")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)

                Button {
                    dismiss()
                } label: {
                    Text("はじめる")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Text("この画面は初回起動時のみ表示されます。アプリ下部「このアプリについて」からいつでも確認できます。")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(width: 380)
    }
}

// MARK: - 説明行

private struct WelcomeRow: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color = .accentColor

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(description)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
