// WelcomeView.swift
// 初回起動時に表示するウェルカムウインドウ。
// メニューバー常駐であること、基本的な使い方を案内する。

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    let language: AppLanguage

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
                    title: AppText.welcomeMenuBarTitle.text(language),
                    description: AppText.welcomeMenuBarDescription.text(language)
                )
                WelcomeRow(
                    icon: "slider.horizontal.3",
                    title: AppText.welcomeStepsTitle.text(language),
                    description: AppText.welcomeStepsDescription.text(language)
                )
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            Divider().padding(.horizontal, 24)

            // ── スクリーンセーバー設定の案内 ──
            WelcomeRow(
                icon: "exclamationmark.triangle",
                title: AppText.welcomeSettingsTitle.text(language),
                description: AppText.welcomeSettingsDescription.text(language),
                iconColor: .orange
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // ── ボタン ──
            VStack(spacing: 6) {
                Button {
                    if let url = URL(string: "https://halcyon-sleep-force.vercel.app/setup") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text(AppText.learnMore.text(language))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)

                Button {
                    dismiss()
                } label: {
                    Text(AppText.close.text(language))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 6)

            Text(AppText.welcomeFooter.text(language))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(width: 320)
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
