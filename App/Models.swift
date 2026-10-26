import Foundation

struct Sport: Identifiable, Hashable {
    let slug: String
    let name: String
    let symbol: String
    var id: String { slug }
}

struct NewsArticle: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let summary: String
    let sportSlug: String
    let sourceName: String
    let canonicalURL: String
    let publishedAt: Date?
    let isDemo: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, summary, sportSlug = "sport_slug", sourceName = "source_name"
        case canonicalURL = "canonical_url", publishedAt = "published_at"
    }

    init(id: String, title: String, summary: String, sportSlug: String, sourceName: String, canonicalURL: String, publishedAt: Date?, isDemo: Bool = false) {
        self.id = id
        self.title = title
        self.summary = summary
        self.sportSlug = sportSlug
        self.sourceName = sourceName
        self.canonicalURL = canonicalURL
        self.publishedAt = publishedAt
        self.isDemo = isDemo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? "Başlıksız içerik"
        summary = (try? c.decode(String.self, forKey: .summary)) ?? ""
        sportSlug = (try? c.decode(String.self, forKey: .sportSlug)) ?? "genel"
        sourceName = (try? c.decode(String.self, forKey: .sourceName)) ?? "Kaynak belirtilmemiş"
        canonicalURL = (try? c.decode(String.self, forKey: .canonicalURL)) ?? ""
        let raw = try? c.decode(String.self, forKey: .publishedAt)
        if let raw {
            publishedAt = ISO8601DateFormatter.fv.date(from: raw) ?? ISO8601DateFormatter.fvWithFraction.date(from: raw)
        } else {
            publishedAt = nil
        }
        isDemo = false
    }
}

struct MatchEvent: Identifiable, Decodable, Hashable {
    let id: String
    let title: String
    let sportSlug: String
    let homeTeam: String
    let awayTeam: String
    let startsAt: Date?
    let status: String
    let homeScore: Int?
    let awayScore: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, status, homeScore = "home_score", awayScore = "away_score"
        case sportSlug = "sport_slug", homeTeam = "home_team", awayTeam = "away_team", startsAt = "starts_at"
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? "Karşılaşma"
        sportSlug = (try? c.decode(String.self, forKey: .sportSlug)) ?? "genel"
        homeTeam = (try? c.decode(String.self, forKey: .homeTeam)) ?? "Fenerbahçe"
        awayTeam = (try? c.decode(String.self, forKey: .awayTeam)) ?? "Rakip"
        status = (try? c.decode(String.self, forKey: .status)) ?? "scheduled"
        homeScore = try? c.decode(Int.self, forKey: .homeScore)
        awayScore = try? c.decode(Int.self, forKey: .awayScore)
        let raw = try? c.decode(String.self, forKey: .startsAt)
        startsAt = raw.flatMap { ISO8601DateFormatter.fv.date(from: $0) ?? ISO8601DateFormatter.fvWithFraction.date(from: $0) }
    }
}

extension ISO8601DateFormatter {
    static let fv: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    static let fvWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

struct SportCatalog {
    static let all: [Sport] = [
        .init(slug: "futbol", name: "Futbol", symbol: "soccerball"),
        .init(slug: "kadin-futbol", name: "Kadın Futbolu", symbol: "figure.soccer"),
        .init(slug: "basketbol", name: "Basketbol", symbol: "basketball.fill"),
        .init(slug: "voleybol", name: "Voleybol", symbol: "volleyball.fill"),
        .init(slug: "yuzme", name: "Yüzme", symbol: "figure.pool.swim"),
        .init(slug: "atletizm", name: "Atletizm", symbol: "figure.run"),
        .init(slug: "kures", name: "Kürek", symbol: "figure.rower"),
        .init(slug: "yelken", name: "Yelken", symbol: "sailboat.fill"),
        .init(slug: "boks", name: "Boks", symbol: "figure.boxing"),
        .init(slug: "masa-tenisi", name: "Masa Tenisi", symbol: "figure.table.tennis"),
        .init(slug: "tenis", name: "Tenis", symbol: "figure.tennis"),
        .init(slug: "eskrim", name: "Eskrim", symbol: "figure.fencing"),
        .init(slug: "jimnastik", name: "Jimnastik", symbol: "figure.gymnastics"),
        .init(slug: "gures", name: "Güreş", symbol: "figure.wrestling"),
        .init(slug: "judo", name: "Judo", symbol: "figure.martial.arts"),
        .init(slug: "diger", name: "Diğer Branşlar", symbol: "sparkles"),
        .init(slug: "genel", name: "Genel", symbol: "star.fill")
    ]
    static func name(for slug: String) -> String { all.first(where: { $0.slug == slug })?.name ?? "Genel" }
}

extension Date {
    var fvRelative: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
