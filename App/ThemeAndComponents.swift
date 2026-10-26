import SwiftUI

enum FVStyle {
    static let navy = Color(red: 0.035, green: 0.075, blue: 0.16)
    static let panel = Color(red: 0.075, green: 0.12, blue: 0.22)
    static let gold = Color(red: 0.94, green: 0.77, blue: 0.28)
    static let muted = Color(red: 0.65, green: 0.70, blue: 0.78)
    static let line = Color.white.opacity(0.09)
}

struct FVBackground: View {
    var body: some View {
        ZStack {
            FVStyle.navy.ignoresSafeArea()
            LinearGradient(colors: [Color(red: 0.08, green: 0.16, blue: 0.29).opacity(0.8), FVStyle.navy, .black.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        }
    }
}

struct BrandMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(FVStyle.gold)
            Image(systemName: "sparkles").font(.system(size: 21, weight: .black)).foregroundStyle(FVStyle.navy)
        }.frame(width: 44, height: 44)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(.white)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(FVStyle.muted) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GlassPanel<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(padding).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(FVStyle.panel.opacity(0.86)))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(FVStyle.line, lineWidth: 1))
    }
}

struct SmallTag: View {
    let title: String
    var color: Color = FVStyle.gold
    var body: some View {
        Text(title.uppercased()).font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(1)
            .foregroundStyle(color).padding(.horizontal, 8).padding(.vertical, 5)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let detail: String
    let symbol: String
    var body: some View {
        GlassPanel(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol).font(.system(size: 18, weight: .semibold)).foregroundStyle(FVStyle.gold)
                Text(value).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(.white).minimumScaleFactor(0.7).lineLimit(1)
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text(detail).font(.caption).foregroundStyle(FVStyle.muted).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ArticleCard: View {
    let article: NewsArticle
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                SmallTag(title: SportCatalog.name(for: article.sportSlug))
                if article.isDemo { SmallTag(title: "Örnek veri", color: .orange) }
                Spacer(minLength: 0)
                if let date = article.publishedAt { Text(date.fvRelative).font(.caption2).foregroundStyle(FVStyle.muted) }
            }
            Text(article.title).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
            Text(article.summary).font(.subheadline).foregroundStyle(FVStyle.muted).lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Image(systemName: "link").font(.caption2)
                Text(article.sourceName).font(.caption.weight(.medium))
                Spacer()
                if let url = URL(string: article.canonicalURL), !article.canonicalURL.isEmpty {
                    Link(destination: url) { HStack(spacing: 4) { Text("Kaynağı aç"); Image(systemName: "arrow.up.right") }.font(.caption.weight(.semibold)).foregroundStyle(FVStyle.gold) }
                }
            }.foregroundStyle(FVStyle.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FVStyle.panel.opacity(0.75), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(FVStyle.line, lineWidth: 1))
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 30, weight: .light)).foregroundStyle(FVStyle.gold)
            Text(title).font(.headline).foregroundStyle(.white)
            Text(message).font(.subheadline).foregroundStyle(FVStyle.muted).multilineTextAlignment(.center).lineSpacing(3)
        }.frame(maxWidth: .infinity).padding(.vertical, 28).padding(.horizontal, 16)
    }
}
