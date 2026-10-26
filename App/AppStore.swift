import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var articles: [NewsArticle] = []
    @Published private(set) var events: [MatchEvent] = []
    @Published var isRefreshing = false
    @Published var lastRefreshAt: Date?
    @Published var statusMessage: String?
    @Published var favoriteSports: Set<String> = []
    @Published var selectedSport = "hepsi"

    @Published var projectURL: String { didSet { UserDefaults.standard.set(projectURL, forKey: "fv.projectURL") } }
    @Published var anonKey: String { didSet { UserDefaults.standard.set(anonKey, forKey: "fv.anonKey") } }

    var hasBackend: Bool {
        URL(string: projectURL.trimmingCharacters(in: .whitespacesAndNewlines)) != nil && !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var isDemoMode: Bool { articles.allSatisfy(\.isDemo) }
    var visibleArticles: [NewsArticle] {
        let favoriteOnly = articles.filter { article in
            favoriteSports.isEmpty || favoriteSports.contains(article.sportSlug) || article.sportSlug == "genel"
        }
        if selectedSport == "hepsi" { return favoriteOnly }
        return favoriteOnly.filter { $0.sportSlug == selectedSport }
    }

    init() {
        projectURL = UserDefaults.standard.string(forKey: "fv.projectURL") ?? ""
        anonKey = UserDefaults.standard.string(forKey: "fv.anonKey") ?? ""
        favoriteSports = Set(UserDefaults.standard.stringArray(forKey: "fv.favoriteSports") ?? ["futbol", "basketbol", "voleybol"])
        loadLocalSamples()
        Task { await refresh(silent: true) }
    }

    func toggleFavorite(_ slug: String) {
        if favoriteSports.contains(slug) { favoriteSports.remove(slug) } else { favoriteSports.insert(slug) }
        UserDefaults.standard.set(Array(favoriteSports), forKey: "fv.favoriteSports")
    }

    func loadLocalSamples() {
        let now = Date()
        articles = [
            NewsArticle(id: "welcome", title: "FenerVerse hazır: kulübün tüm branşları tek merkezde", summary: "Bu, arayüzün nasıl çalıştığını göstermek için telefonda tutulan örnek içeriktir. Gerçek haber değildir. Gerçek kaynak bağlandığında bu kart kaybolur.", sportSlug: "genel", sourceName: "Yerel örnek", canonicalURL: "", publishedAt: now.addingTimeInterval(-600), isDemo: true),
            NewsArticle(id: "data", title: "Veri motorunu bağla", summary: "Ayarlar bölümüne Supabase Project URL ve anon/public anahtarını eklediğinde, otomasyonun topladığı kayıtlar burada görüntülenir.", sportSlug: "genel", sourceName: "Kurulum notu", canonicalURL: "", publishedAt: now.addingTimeInterval(-1200), isDemo: true),
            NewsArticle(id: "all-sports", title: "Branşlar arası takip", summary: "Futbol, basketbol, voleybol ve diğer branşların haberlerini filtreleyebilir, favorilerini seçebilir ve kaynak bilgilerini görebilirsin.", sportSlug: "genel", sourceName: "Kurulum notu", canonicalURL: "", publishedAt: now.addingTimeInterval(-2400), isDemo: true)
        ]
        events = []
    }

    func refresh(silent: Bool = false) async {
        guard hasBackend else {
            if !silent { statusMessage = "Yerel örnek modundasın. Gerçek veri için Ayarlar bölümünden Supabase bağla." }
            return
        }
        guard let base = URL(string: projectURL.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))) else {
            statusMessage = "Project URL geçerli değil."
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            async let loadedArticles = request(path: "/rest/v1/articles?select=id,title,summary,sport_slug,source_name,canonical_url,published_at&order=published_at.desc&limit=100", base: base, type: [NewsArticle].self)
            async let loadedEvents = request(path: "/rest/v1/events?select=id,title,sport_slug,home_team,away_team,starts_at,status,home_score,away_score&order=starts_at.asc&limit=100", base: base, type: [MatchEvent].self)
            let (newArticles, newEvents) = try await (loadedArticles, loadedEvents)
            if !newArticles.isEmpty { articles = newArticles }
            else { articles = [] }
            events = newEvents
            lastRefreshAt = Date()
            statusMessage = "Veriler güncellendi."
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "fv.lastRefresh")
        } catch {
            statusMessage = "Veri alınamadı. Bağlantı, anon key ve SQL kurulumunu kontrol et."
            if articles.isEmpty { loadLocalSamples() }
        }
    }

    private func request<T: Decodable>(path: String, base: URL, type: T.Type) async throws -> T {
        let url = URL(string: path, relativeTo: base)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(anonKey.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
