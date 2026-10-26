import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Bugün", systemImage: "sun.max.fill") }
            IntelligenceView().tabItem { Label("Zekâ", systemImage: "chart.xyaxis.line") }
            PulseView().tabItem { Label("Pulse", systemImage: "dot.radiowaves.left.and.right") }
            ImpactView().tabItem { Label("Etki", systemImage: "point.3.connected.trianglepath.dotted") }
            SettingsView().tabItem { Label("Ayarlar", systemImage: "slider.horizontal.3") }
        }
        .tint(FVStyle.gold)
        .background(FVStyle.navy)
    }
}

struct AppTopBar: View {
    let eyebrow: String
    let title: String
    var trailing: AnyView? = nil
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            BrandMark()
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow.uppercased()).font(.system(size: 9, weight: .heavy, design: .rounded)).tracking(2).foregroundStyle(FVStyle.gold)
                Text(title).font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(.white)
            }
            Spacer()
            if let trailing { trailing }
        }.padding(.top, 8)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            ZStack { FVBackground(); ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    AppTopBar(eyebrow: "Her branş · tek evren", title: "FenerVerse", trailing: AnyView(Button { Task { await store.refresh() } } label: { Image(systemName: store.isRefreshing ? "arrow.clockwise" : "arrow.clockwise.circle").font(.title2).foregroundStyle(FVStyle.gold).rotationEffect(.degrees(store.isRefreshing ? 180 : 0)) }))
                    hero
                    VStack(alignment: .leading, spacing: 12) {
                        HStack { SectionHeader(title: "Günün radarı", subtitle: "Tüm branşlardan tek akış"); Spacer(); Text("\(store.articles.count)").font(.headline.monospacedDigit()).foregroundStyle(FVStyle.gold) }
                        if store.articles.isEmpty {
                            EmptyState(symbol: "antenna.radiowaves.left.and.right", title: "Yeni içerik bekleniyor", message: "Kaynak taraması henüz içerik getirmedi. Biraz sonra yeniden dene.")
                        } else {
                            ForEach(Array(store.articles.prefix(3))) { article in ArticleCard(article: article) }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Tüm branşlar", subtitle: "Takip etmek istediklerini seç")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(SportCatalog.all.filter { $0.slug != "genel" }) { sport in
                                SportChip(sport: sport, selected: store.favoriteSports.contains(sport.slug)) { store.toggleFavorite(sport.slug) }
                            }
                        }
                    }
                    footer
                }.padding(.horizontal, 18).padding(.bottom, 28)
            }}.toolbar(.hidden, for: .navigationBar)
        }
    }
    private var hero: some View {
        GlassPanel(padding: 18) {
            VStack(alignment: .leading, spacing: 15) {
                HStack { SmallTag(title: store.hasBackend ? "Bağlantı ayarlı" : "Yerel mod", color: store.hasBackend ? .green : .orange); Spacer(); Image(systemName: "sparkles").font(.title2).foregroundStyle(FVStyle.gold) }
                Text("Sarı lacivert\ngündem, tek merkez.").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                Text(store.hasBackend ? "Kaynak verileriyle senkronize ol. Haberler güncellendikçe bu akış yenilenir." : "Uygulama hazır. Gerçek haberler ve otomasyon için Ayarlar bölümünden ücretsiz veri bağlantını tamamla.").font(.subheadline).foregroundStyle(FVStyle.muted).lineSpacing(3)
                HStack(spacing: 8) { Image(systemName: "shield.lefthalf.filled"); Text("Kaynak ve doğruluk odaklı"); Spacer(); Image(systemName: "arrow.up.right") }.font(.caption.weight(.semibold)).foregroundStyle(FVStyle.gold)
            }
        }
    }
    private var footer: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BAĞIMSIZ TARAFTAR PROJESİ").font(.system(size: 9, weight: .heavy)).tracking(1.5).foregroundStyle(FVStyle.muted)
            Text("FenerVerse resmî kulüp uygulaması değildir. Örnek içerikler gerçek haber veya maç sonucu değildir.").font(.caption2).foregroundStyle(FVStyle.muted).fixedSize(horizontal: false, vertical: true)
            if let last = store.lastRefreshAt { Text("Son güncelleme: \(last.formatted(date: .omitted, time: .shortened))").font(.caption2).foregroundStyle(FVStyle.muted) }
        }.padding(.top, 4)
    }
}

struct SportChip: View {
    let sport: Sport
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: sport.symbol).font(.system(size: 16, weight: .semibold)).foregroundStyle(selected ? FVStyle.navy : FVStyle.gold).frame(width: 30, height: 30).background(selected ? FVStyle.gold : FVStyle.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                Text(sport.name).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "plus.circle").font(.caption).foregroundStyle(selected ? FVStyle.gold : FVStyle.muted)
            }.padding(10).background(FVStyle.panel.opacity(0.8), in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(selected ? FVStyle.gold.opacity(0.35) : FVStyle.line, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
