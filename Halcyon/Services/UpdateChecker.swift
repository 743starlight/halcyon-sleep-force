// UpdateChecker.swift
// アプリ起動時に GitHub Releases API で最新バージョンを確認し、
// 新しいバージョンがある場合にアラートを表示する。
// オフラインや API エラー時はサイレントに無視する。

import AppKit
import Foundation

enum UpdateChecker {
    private static let releasesAPIURL = "https://api.github.com/repos/743starlight/halcyon-sleep-force/releases/latest"
    private static let releasesPageURL = "https://github.com/743starlight/halcyon-sleep-force/releases/latest"

    /// アプリ起動時に呼び出す。最新バージョンを非同期で確認する。
    static func checkOnLaunch() {
        Task.detached(priority: .utility) {
            await check()
        }
    }

    // MARK: - Private

    private struct GitHubRelease: Decodable {
        let tag_name: String
    }

    private static func check() async {
        guard let url = URL(string: releasesAPIURL) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latest = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if compareVersions(latest, isNewerThan: current) {
                await showUpdateAlert(version: release.tag_name)
            }
        } catch {
            Log.debug("Update check failed: \(error.localizedDescription)")
        }
    }

    /// セマンティックバージョニングで比較する
    private static func compareVersions(_ latest: String, isNewerThan current: String) -> Bool {
        let latestParts = latest.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(latestParts.count, currentParts.count) {
            let l = i < latestParts.count ? latestParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }

    @MainActor
    private static func showUpdateAlert(version: String) {
        let alert = NSAlert()
        alert.messageText = "新しいバージョンがあります"
        alert.informativeText = "\(version) がリリースされています。ダウンロードページを開きますか？"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "ダウンロード")
        alert.addButton(withTitle: "後で")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: releasesPageURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }

}
