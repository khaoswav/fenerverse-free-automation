# FenerVerse · Ücretsiz iOS başlangıç paketi

**Fenerbahçe'nin branşlarını tek uygulamada toplayan bağımsız taraftar projesi.** Paket; çalışan SwiftUI iPhone arayüzü, yerel örnek içerik, Supabase veritabanı şeması, RSS haber senkronizasyon betiği, GitHub Actions zamanlayıcısı ve otomatik kurulum yardımcısını içerir.

> **Şeffaflık:** Kod ve geliştirme araçları ücretsizdir. Bu ZIP kendi başına senin Apple/Supabase/GitHub hesaplarını açamaz veya bu hesaplarda senin adına proje oluşturamaz. Gerçek bulut senkronizasyonu için ücretsiz Supabase hesabında bir proje oluşturup `Backend/SETUP.sql` dosyasını bir kez çalıştırman, ardından ZIP içindeki kurulum yardımcısını çalıştırman gerekir. App Store dağıtımı ücretsiz Apple kişisel imzasıyla yapılamaz; bu paket kendi iPhone'unda ücretsiz Xcode testi için hazırlanmıştır.

## Pakette neler var?

- `FenerVerse.xcodeproj`: Xcode ile açılabilen iOS projesi (iOS 17+, SwiftUI, haricî Swift paketi yok).
- `App/`: Bugün, Intelligence, Pulse, Etki Haritası ve Ayarlar ekranları; favori branşlar; kaynak bağlama alanı; demo verisini gerçek haber gibi göstermeyen etiketler.
- `Backend/SETUP.sql`: branşlar, takımlar, sporcular, karşılaşmalar, haberler ve otomasyon kayıtları için veritabanı + okuma politikaları.
- `automation/sync_feeds.py`: ücretsiz RSS kaynaklarını okur, tekrarları engeller ve yapılandırılan Supabase tablosuna başlık/kısa açıklama/kaynak bağlantısı yazar.
- `.github/workflows/sync-feeds.yml`: GitHub Actions ile 30 dakikada bir otomatik senkronizasyon ve elle çalıştırma.
- `automation/test_sync_feeds.py`: çevrimdışı testler.
- `Kurulum.command`: Mac'te kurulum kontrol listesi ve kolaylaştırıcıyı açar.
- `automation/publish_free_automation.command`: GitHub CLI kurulu ve oturum açılmışsa otomasyon deposu oluşturur ve sırları güvenli GitHub Secrets'a kaydeder.

## 1. iPhone uygulamasını aç

1. ZIP dosyasını Mac'te tamamen aç (Xcode projesini ZIP içinden açma).
2. Önce `FenerVerse.xcworkspace` dosyasına çift tıkla. Olmazsa `FenerVerse.xcodeproj` dosyasına sağ tık > Birlikte Aç > Xcode seç.
3. Xcode içinden `FenerVerse` şemasını seç.

**Xcode proje penceresi hiç açılmıyorsa:** Terminal'i aç, açtığın klasöre git ve `open -a Xcode FenerVerse.xcworkspace` komutunu çalıştır. `Xcode is not installed` veya `application not found` hatası gelirse Mac'te tam Xcode uygulaması kurulu değildir ya da Xcode ilk açılış kurulumu tamamlanmamıştır.

4. Xcode > Settings > Accounts bölümünde Apple hesabınla oturum aç.
5. Proje > Signing & Capabilities bölümünde **Automatically manage signing** açık olsun, Team alanında `Personal Team` seç.
6. iPhone'da Ayarlar > Gizlilik ve Güvenlik > Geliştirici Modu'nu gerekirse aç, telefonu Mac'e bağla ve Xcode'da Run (▶) tuşuna bas.
Ücretsiz kişisel imza profilleri zamanla sona erer (Apple'ın güncel dokümanında 7 gün). Bu, koddan kaynaklanan bir hata değildir; uygulamayı yeniden derleyip yüklemen gerekir. Bkz. https://developer.apple.com/help/account/basics/about-your-developer-account/

## 2. Ücretsiz veri otomasyonunu etkinleştir

### A. Supabase projesi

1. https://supabase.com adresinde ücretsiz hesap/proje oluştur.
2. Dashboard > SQL Editor > New query ekranını aç.
3. `Backend/SETUP.sql` içeriğini tek seferde yapıştırıp çalıştır.
4. Project Settings > API bölümünden Project URL ve **service_role** anahtarını bul. `service_role` anahtarını uygulamaya, kaynak koda veya herkese açık dosyaya koyma.

Supabase ücretsiz planı kotalıdır ve hareketsiz projeleri duraklatabilir. Dolayısıyla bu, ücret garantisi olan bir ticari SLA değildir. Ücretsiz plan detayları: https://supabase.com/pricing

### B. GitHub zamanlayıcısı

1. Mac'te Terminal aç ve GitHub CLI kurulu değilse `brew install gh` çalıştır.
2. `gh auth login` komutuyla GitHub'a giriş yap.
3. Bu paket klasöründe `automation/publish_free_automation.command` dosyasına çift tıkla. macOS güvenlik uyarısı çıkarsa Terminal'den şu komutla çalıştır: `bash automation/publish_free_automation.command`.
4. Script, sana depo adı sorar ve kodu **public GitHub reposuna** gönderir. Public repo seçimi standart GitHub-hosted runner'larda Actions kullanımını ücretsiz tutmak içindir. Kaynak kodun herkese açık olur; Supabase anahtarları ise GitHub Secrets olarak saklanır ve kod dosyalarına yazılmaz.
5. Script Project URL ile service_role anahtarını sorar. Anahtar ekrana yazılırken gizlenir. Bu bilgiler GitHub Secrets'a kaydedilir.
6. GitHub reposunda Actions sekmesinden `FenerVerse Free RSS Sync` iş akışının çalıştığını kontrol et; `Run workflow` ile el ile de başlatabilirsin.

GitHub Actions zamanlaması kesin saniyeli servis garantisi değildir. İşler gecikebilir; iş akışı tekrar çalışacak şekilde tasarlanmıştır.

### C. Uygulamaya Supabase bağlantısı

Uygulama > Ayarlar > Veri bağlantısı alanına Supabase **Project URL** ve **anon/public key** girip Kaydet'e bas. Burada service_role anahtarı kullanılmaz. RLS kuralları haber/branş verilerinin herkese okunabilmesini, yazmanın ise servis tarafıyla sınırlı kalmasını sağlar.

## 3. Test et

Paket klasöründe:

```bash
python3 -m unittest automation/test_sync_feeds.py -v
python3 automation/sync_feeds.py --dry-run
```

`--dry-run` gerçek bir veritabanına yazmaz; RSS kaynaklarına erişim gerektirir. Çevrimdışı bir ortamda çalışmaması normaldir.

## Ücretsiz sürümde bilerek olmayanlar

- Ücretli spor veri API'si veya ücretli yapay zekâ servisi.
- Kaynağı olmayan canlı skorları uydurma.
- Kullanıcı verilerini reklam/izleme amacıyla toplama.
- Apple Developer Program gerektiren App Store dağıtımı ve TestFlight.
- APNs ile güvenilir uzaktan bildirim için gereken ücretli dağıtım hesabı yapılandırması.

İlk sürüm RSS haber akışlarını otomatik toplayabilir. RSS haber akışları bütün branşların canlı skorlarını ve fikstürünü sağlamaz; bu bilgiler için her branşa ait ücretsiz ve yeniden kullanıma izin veren ayrı bir veri kaynağı bulunması gerekir. Kaynak bağlantısı ve atıf korunur. Her sağlayıcının kullanım/yeniden yayın koşullarını yayın öncesi kontrol et.

## Güvenlik

- Supabase `service_role` anahtarı sadece GitHub Secrets içinde tutulur.
- iOS uygulaması yalnızca Supabase `anon/public` anahtarıyla salt-okuma yapar.
- Hiçbir gerçek API anahtarı ZIP'e gömülmemiştir.
- RSS içeriği üçüncü taraf içeriktir: uygulama başlık, kısa açıklama, kaynak ve orijinal bağlantıyı gösterir; makalenin tamamını kopyalamaz.

## Marka ve bağımsızlık

FenerVerse bağımsız bir taraftar projesi konseptidir; Fenerbahçe Spor Kulübü tarafından geliştirilmiş veya onaylanmış resmî uygulama değildir. Resmî kulüp logosu/arması bu pakete eklenmemiştir. Marka ve kaynak kullanım izinlerini yayınlamadan önce incele.
