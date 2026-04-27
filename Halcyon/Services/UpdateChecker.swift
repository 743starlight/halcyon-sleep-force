// UpdateChecker.swift
// アプリ起動時に GitHub Releases API で最新バージョンを確認し、
// 新しいバージョンがある場合にアラートを表示する。
// オフラインや API エラー時はサイレントに無視する。

import AppKit
import Foundation

enum UpdateChecker {
    // GitHub の latest API は tag_name だけ取得できればよいので、専用URLを固定で持つ
    private static let releasesAPIURL = "https://api.github.com/repos/743starlight/halcyon-sleep-force/releases/latest"
    // ユーザーが「ダウンロード」を選んだときにブラウザで開くページ
    private static let releasesPageURL = "https://github.com/743starlight/halcyon-sleep-force/releases/latest"

    /// アプリ起動時に呼び出す。最新バージョンを非同期で確認する。
    static func checkOnLaunch() {
        // 起動処理やUI表示をブロックしないよう、低優先度のバックグラウンドタスクで実行する
        Task.detached(priority: .utility) {
            await check()
        }
    }

    // MARK: - Private

    private struct GitHubRelease: Decodable {
        let tag_name: String
    }

    private static func check() async {
        // URL文字列が壊れている場合は更新確認自体を行わない
        guard let url = URL(string: releasesAPIURL) else { return }

        var request = URLRequest(url: url)
        // GitHub API の推奨Acceptヘッダーを付け、レスポンス形式を安定させる
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        // ネットワーク不調時に起動後の処理を長く引きずらないよう短めに打ち切る
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // API制限や一時障害などは通知せず、通常起動を優先する
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }

            // latest リリースのタグ名から v / V プレフィックスを除き、アプリ内バージョンと比較する
            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latest = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

            if compareVersions(latest, isNewerThan: current) {
                // ユーザーがスキップした同一タグは再通知しない
                let skipped = UserDefaults.standard.string(forKey: "skippedVersion")
                guard release.tag_name != skipped else { return }
                await showUpdateAlert(version: release.tag_name)
            }
        } catch {
            // 更新確認の失敗はアプリ本体の利用を妨げないため、デバッグログだけに留める
            Log.debug("Update check failed: \(error.localizedDescription)")
        }
    }

    /// セマンティックバージョニングで比較する
    private static func compareVersions(_ latest: String, isNewerThan current: String) -> Bool {
        // "1.2.3" を [1, 2, 3] として扱い、欠けた桁は 0 扱いで比較する
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
        // 更新通知はデバッグUIの一時切替ではなく、起動時点の地域設定に合わせる
        let language = AppLanguage.defaultForCurrentLocale
        // メニューバーアプリでもアラートが背面に隠れないよう、表示前にアプリを前面化する
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = AppText.updateAvailable.text(language)
        alert.informativeText = AppText.updateDescription(version: version, language: language)
        alert.alertStyle = .informational
        alert.addButton(withTitle: AppText.download.text(language))
        alert.addButton(withTitle: AppText.skipThisVersion.text(language))
        alert.addButton(withTitle: AppText.later.text(language))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // 「ダウンロード」選択時は GitHub Releases の latest ページを開く
            if let url = URL(string: releasesPageURL) {
                NSWorkspace.shared.open(url)
            }
        } else if response == .alertSecondButtonReturn {
            // 「このバージョンをスキップ」はタグ名を保存し、同じリリースだけ再通知しない
            UserDefaults.standard.set(version, forKey: "skippedVersion")
        }
    }

}
