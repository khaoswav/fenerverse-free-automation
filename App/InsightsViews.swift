import SwiftUI

struct IntelligenceView: View {
    @EnvironmentObject private var store: AppStore
    private var coveredSports: Int { Set(store.articles.map(\.sportSlug)).filter { $0 != "genel" }.count }
    var body: some View {
        NavigationStack {
            ZStack { FVBackground(); ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppTopBar(eyebrow: "Fener Intelligence", title: "Veri zekâsı")
                    Text("Tahmin değil, kanıt. Bu ekran yalnızca bağlanan kaynaklardan gelen verileri özetler.").font(.subheadline).foregroundStyle(FVStyle.muted).lineSpacing(3)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "İçerik kaydı", value: "\(store.articles.count)", detail: "Şu an uygulamada görünen", symbol: "doc.text.magnifyingglass")
                        MetricCard(title: "Haber bulunan branş", value: "\(coveredSports)", detail: "Gerçek içerik kapsamı", symbol: "chart.bar.xaxis")
                        MetricCard(title: "Takvim kaydı", value: "\(store.events.count)", detail: "Bağlı karşılaşma verileri", symbol: "calendar")
                        MetricCard(title: "Kaynak durumu", value: store.hasBackend ? "Bağlı" : "Bekliyor", detail: "Ücretsiz REST bağlantısı", symbol: "network")
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Kapsama görünümü", systemImage: "chart.pie.fill").font(.headline).foregroundStyle(.white)
                            if store.articles.filter({ !$0.isDemo }).isEmpty {
                                EmptyState(symbol: "chart.bar.xaxis", title: "Analiz için gerçek veri gerekiyor", message: "Otomasyon haber topladıkça kapsama ölçümleri burada oluşur. Uydurma skor veya tahmin kullanılmaz.")
                            } else {
                                ForEach(SportCatalog.all.filter { $0.slug != "genel" }) { sport in
                                    let count = store.articles.filter { $0.sportSlug == sport.slug && !$0.isDemo }.count
                                    HStack { Text(sport.name).font(.subheadline).foregroundStyle(.white); Spacer(); Text("\(count)").font(.caption.monospacedDigit()).foregroundStyle(FVStyle.gold) }
                                    GeometryReader { geo in ZStack(alignment: .leading) { Capsule().fill(.white.opacity(0.07)); Capsule().fill(FVStyle.gold).frame(width: geo.size.width * min(CGFloat(count) / CGFloat(max(store.articles.count, 1)), 1)) } }.frame(height: 5)
                                }
                            }
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Analiz ilkeleri", systemImage: "checkmark.shield.fill").font(.headline).foregroundStyle(.white)
                            bullet("Kaynağı ve zamanı olmayan veri skor olarak gösterilmez.")
                            bullet("Haber sayısı sportif başarı puanı gibi yorumlanmaz.")
                            bullet("Geleceğe yönelik tahminler, veri yeterli değilse gösterilmez.")
                        }
                    }
                }.padding(18)
            }}.toolbar(.hidden, for: .navigationBar)
        }
    }
    private func bullet(_ text: String) -> some View { HStack(alignment: .top, spacing: 8) { Image(systemName: "checkmark.circle.fill").foregroundStyle(FVStyle.gold); Text(text).font(.subheadline).foregroundStyle(FVStyle.muted) } }
}

struct PulseView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            ZStack { FVBackground(); ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    AppTopBar(eyebrow: "Fener Pulse", title: "Senin gündemin")
                    Text("Favori branşlarına göre süzülen haberler. Tercihlerini Bugün ekranından yönetebilirsin.").font(.subheadline).foregroundStyle(FVStyle.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip("Tümü", slug: "hepsi")
                            ForEach(SportCatalog.all) { sport in filterChip(sport.name, slug: sport.slug) }
                        }
                    }
                    if store.visibleArticles.isEmpty {
                        EmptyState(symbol: "dot.radiowaves.left.and.right", title: "Bu filtrede içerik yok", message: "Başka bir branş seç veya kaynakların senkronize olmasını bekle.")
                    } else {
                        ForEach(store.visibleArticles) { article in ArticleCard(article: article) }
                    }
                }.padding(18)
            }}.toolbar(.hidden, for: .navigationBar)
        }
    }
    private func filterChip(_ label: String, slug: String) -> some View {
        Button { store.selectedSport = slug } label: {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(store.selectedSport == slug ? FVStyle.navy : .white)
                .padding(.horizontal, 13).padding(.vertical, 9)
                .background(store.selectedSport == slug ? FVStyle.gold : FVStyle.panel, in: Capsule())
        }.buttonStyle(.plain)
    }
}

struct ImpactView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        NavigationStack {
            ZStack { FVBackground(); ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppTopBar(eyebrow: "Kulüp hafızası", title: "Etki Haritası")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            SmallTag(title: "Canlı gelişen arşiv")
                            Text("Her haber, doğru kaynağı ve branşıyla hafızaya eklenir.").font(.title3.bold()).foregroundStyle(.white)
                            Text("Bu ilk sürüm kaynaklı haber zaman çizelgesini oluşturur. Tarihî kupalar, sporcu profilleri ve branşlar arası bağlantılar yalnızca güvenilir veri eklenince gösterilecektir.").font(.subheadline).foregroundStyle(FVStyle.muted).lineSpacing(4)
                        }
                    }
                    SectionHeader(title: "Son kayıtlar", subtitle: "Kaynağı bilinen içerikler")
                    if store.articles.filter({ !$0.isDemo }).isEmpty {
                        EmptyState(symbol: "point.3.connected.trianglepath.dotted", title: "Hafıza henüz boş", message: "Gerçek haber verisi geldikçe her kayıt zaman çizelgesine eklenir. Tarih veya başarı uydurulmaz.")
                    } else {
                        ForEach(store.articles.filter { !$0.isDemo }) { item in
                            HStack(alignment: .top, spacing: 12) {
                                VStack(spacing: 0) { Circle().fill(FVStyle.gold).frame(width: 10, height: 10); Rectangle().fill(FVStyle.gold.opacity(0.25)).frame(width: 2, height: 66) }
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(SportCatalog.name(for: item.sportSlug).uppercased()).font(.system(size: 9, weight: .heavy)).tracking(1.1).foregroundStyle(FVStyle.gold)
                                    Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                                    Text("\(item.sourceName) · \(item.publishedAt?.fvRelative ?? "Tarih yok")").font(.caption).foregroundStyle(FVStyle.muted)
                                }
                            }
                        }
                    }
                }.padding(18)
            }}.toolbar(.hidden, for: .navigationBar)
        }
    }
}
