import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var urlDraft = ""
    @State private var keyDraft = ""
    @State private var showKey = false
    @State private var resultMessage: String?

    var body: some View {
        NavigationStack {
            ZStack { FVBackground(); ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AppTopBar(eyebrow: "Kontrol merkezi", title: "Ayarlar")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack { Label("Veri bağlantısı", systemImage: "externaldrive.connected.to.line.below").font(.headline).foregroundStyle(.white); Spacer(); SmallTag(title: store.hasBackend ? "Ayarlı" : "Yerel", color: store.hasBackend ? .green : .orange) }
                            Text("Ücretsiz Supabase projenin URL ve anon/public anahtarını ekle. Bu alana service_role anahtarını yazma.").font(.caption).foregroundStyle(FVStyle.muted).fixedSize(horizontal: false, vertical: true)
                            TextField("https://proje-ref.supabase.co", text: $urlDraft).textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled().textFieldStyle(FVTextFieldStyle())
                            Group {
                                if showKey { TextField("Supabase anon/public key", text: $keyDraft) }
                                else { SecureField("Supabase anon/public key", text: $keyDraft) }
                            }.textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(FVTextFieldStyle())
                            Toggle("Anahtarı görünür göster", isOn: $showKey).font(.caption).tint(FVStyle.gold)
                            Button {
                                store.projectURL = urlDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                store.anonKey = keyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                resultMessage = "Ayarlar bu cihazda kaydedildi. Şimdi bağlantıyı kontrol edebilirsin."
                            } label: { Label("Bağlantıyı kaydet", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity) }.buttonStyle(FVPrimaryButton())
                            Button { Task { await store.refresh(); resultMessage = store.statusMessage } } label: { Label(store.isRefreshing ? "Kontrol ediliyor…" : "Bağlantıyı kontrol et", systemImage: "arrow.triangle.2.circlepath").frame(maxWidth: .infinity) }.buttonStyle(FVSecondaryButton())
                            if let resultMessage { Text(resultMessage).font(.caption).foregroundStyle(FVStyle.gold).fixedSize(horizontal: false, vertical: true) }
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Ücretsiz otomasyon", systemImage: "gearshape.2.fill").font(.headline).foregroundStyle(.white)
                            statusLine("Supabase şeması", detail: "Backend/SETUP.sql", ready: store.hasBackend)
                            statusLine("RSS zamanlayıcısı", detail: "GitHub Actions secrets ayarına bağlı", ready: false)
                            statusLine("Canlı skor sağlayıcısı", detail: "Henüz eklenmedi; ücretli API kullanılmıyor", ready: false)
                            Text("RSS haber otomasyonu ayrı bir GitHub Actions iş akışında çalışır. Bu iPhone ekranı sunucu görevini çalıştırmaz.").font(.caption).foregroundStyle(FVStyle.muted)
                        }
                    }
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 9) {
                            Label("Gizlilik ve marka", systemImage: "hand.raised.fill").font(.headline).foregroundStyle(.white)
                            Text("Favori branşların bu cihazda saklanır. Uygulama bağımsız bir taraftar projesidir; resmî Fenerbahçe uygulaması değildir.").font(.subheadline).foregroundStyle(FVStyle.muted).lineSpacing(3)
                            Button("Örnek veriyi yeniden yükle") { store.loadLocalSamples(); resultMessage = "Yerel örnek içerikler yüklendi." }.buttonStyle(FVSecondaryButton())
                        }
                    }
                    Text("FenerVerse · Ücretsiz iOS paketi · v1.0").font(.caption2).foregroundStyle(FVStyle.muted).frame(maxWidth: .infinity).padding(.bottom, 18)
                }.padding(18)
            }}.toolbar(.hidden, for: .navigationBar)
        }.onAppear { urlDraft = store.projectURL; keyDraft = store.anonKey }
    }
    private func statusLine(_ title: String, detail: String, ready: Bool) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: ready ? "checkmark.circle.fill" : "circle.dashed").foregroundStyle(ready ? .green : FVStyle.muted)
            VStack(alignment: .leading, spacing: 3) { Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.white); Text(detail).font(.caption).foregroundStyle(FVStyle.muted) }
        }
    }
}

struct FVTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.padding(13).background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(FVStyle.line, lineWidth: 1)).foregroundStyle(.white)
    }
}
struct FVPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.subheadline.weight(.bold)).foregroundStyle(FVStyle.navy).padding(13).background(FVStyle.gold.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 14)) }
}
struct FVSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.subheadline.weight(.semibold)).foregroundStyle(.white).padding(13).background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 14)).overlay(RoundedRectangle(cornerRadius: 14).stroke(FVStyle.line, lineWidth: 1)) }
}
