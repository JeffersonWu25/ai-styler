import Foundation

enum AppConfig {
    /// Simulator: use localhost. Physical device: replace with your Mac's LAN IP (e.g. http://192.168.1.10:8000).
    static let apiBaseURL = URL(string: "http://127.0.0.1:8000")!

    static let defaultOutfitName = "Old Money"
}
