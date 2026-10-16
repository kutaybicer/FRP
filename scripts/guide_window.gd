class_name GuideWindow
extends Window
## Oyun içi rehber (Info düğmesi / F1). Solda konular ve arama, sağda anlatım.

const GOLD := "#e0b85c"
const KEY := "#8fd1ff"

var _list: ItemList
var _text: RichTextLabel
var _search: LineEdit
var _shown: Array = []

# [başlık, içerik (BBCode)] — [k]...[/k] kısayol, [g]...[/g] düğme/menü adı olarak renklenir
var topics: Array = [
	["Başlarken", """[h]FRP Harita Ustası'na hoş geldin![/h]
Bu uygulamayla oyun dünyanı çizebilir; şehirler, zindanlar ve iç içe haritalar oluşturabilir, karakterlerini ve yaratıklarını yönetebilir, oyun sırasında zar atabilirsin.

[b]Ekranın bölümleri[/b]
• [g]Üst çubuk[/g]: Yeni, Aç, Kaydet, PNG Dışa Aktar, Geri Al / Yinele, görünüm seçenekleri, [g]Zarlar[/g], [g]Info[/g] ve mod düğmesi.
• [g]Konum çubuğu[/g] (üstte ikinci satır): Hangi haritada olduğunu gösterir (Dünya › Başkent › Meyhane). Bir isme tıklayınca o haritaya dönersin.
• [g]Sol panel[/g]: Araçlar ve seçili aracın ayarları (fırça boyutu, arazi tipi, semboller...).
• [g]Sağ panel[/g]: [g]Özellikler[/g] (seçili nesne ya da harita), [g]Karakterler[/g] ve [g]Harita Ağacı[/g] sekmeleri.
• [g]Alt çubuk[/g]: Farenin altındaki hücre, arazi ve bölge bilgisi; seçili aracın ipucu.

[b]Kaydetme[/b]
• [k]Ctrl+S[/k] veya [g]Kaydet[/g]: Kampanyayı tek bir [b].frp[/b] dosyasına kaydeder (tüm haritalar ve karakterler bu dosyanın içindedir).
• [k]Ctrl+O[/k] veya [g]Aç[/g]: Kayıtlı bir kampanyayı açar.
• Uygulama 90 saniyede bir ve kapanırken [b]otomatik kaydeder[/b]; bir sonraki açılışta kaldığın yerden devam eder. Temiz başlamak için [g]Yeni[/g]'ye bas.

[b]Kamera[/b]
• [k]Sağ tık sürükle[/k] veya [k]orta tuş sürükle[/k]: haritayı kaydır. Seç aracında boş bir yeri [k]sol tıkla sürüklemek[/k] de kaydırır.
• [k]Fare tekerleği[/k]: imlecin olduğu yere yakınlaş / uzaklaş.
• [k]Home[/k] veya [g]Sığdır[/g]: haritanın tamamını ekrana sığdır.

[b]Geri alma[/b]
• [k]Ctrl+Z[/k] geri al, [k]Ctrl+Y[/k] (ya da [k]Ctrl+Shift+Z[/k]) yinele. Her haritanın kendi geri alma geçmişi vardır."""],

	["Yeni Harita ve Anakara Çizmek", """[h]Sıfırdan bir dünya oluşturmak[/h]
1. Üst çubukta [g]Yeni[/g]'ye tıkla.
2. [g]Nasıl başlayalım?[/g] listesinden birini seç:
   • [b]Rastgele kıta[/b]: dağları, ormanları, nehirleri hazır bir kıta üretir.
   • [b]Boş okyanus — anakarayı ben çizeceğim[/b]: her yer deniz; kıtanı sen çizersin.
   • [b]Boş kara[/b]: her yer çayır (bölge veya şehir haritası için ideal).
   • [b]Boş parşömen[/b]: eskiz kağıdı.
3. [g]Harita boyutu[/g]: Küçük (120×80) → Dev Kıta (900×620) arası hazır boyutlardan seç ya da Genişlik/Yükseklik'e kendi değerini yaz (en fazla 1000×1000 hücre).
4. [g]Ölçek[/g]: 1 hücrenin kaç km olduğu. Pencerenin altında dünyanın toplam genişliği yazar.
5. [g]Oluştur[/g]'a bas.

[b]Anakarayı çizmek (Boş okyanus seçtiysen)[/b]
• Harita açılınca [g]Arazi[/g] aracı ([k]B[/k]) ve [b]Çayır[/b] seçili gelir. Sol tıkla basılı tutup sürükleyerek karayı çiz.
• Fırçayı büyütmek / küçültmek: [k][rb][/k] ve [k][lb][/k] tuşları ya da sol paneldeki [g]Fırça boyutu[/g] kaydırıcısı (1–40).
• Kıyı şeritleri HD görünümde kendiliğinden kıvrımlı ve dalgalı olur, kumsal kendiliğinden belirir.
• İç kısımları hızlı doldurmak için [g]Kova Dolgu[/g] ([k]G[/k]): bir arazi tipi seç, kapalı alana tıkla.
• Göl veya iç deniz eklemek: Arazi fırçasında [b]Sığ Su / Göl[/b] veya [b]Deniz[/b] seç ve karaya boya.
• Sonra [b]Orman, Dağlık, Tepelik, Çöl, Bataklık, Kar[/b]... ile bölgeleri şekillendir.

[b]Var olan haritayı değiştirmek[/b]
• Sağ panel → [g]Özellikler[/g] (hiçbir şey seçili değilken harita özellikleri görünür):
   • [g]Haritayı Tamamen Temizle[/g]: her şeyi silip boş deniz yapar.
   • [g]Tümünü Seçili Araziyle Doldur[/g]: bütün haritayı fırçada seçili araziyle doldurur.
   • [g]Rastgele Arazi Üret[/g]: tohum sayısı, kıta/ada, nehir ve sembol seçenekleriyle yeni arazi üretir (sembollerin ve yazıların korunur).
   • [g]Boyut[/g] → [g]Uygula[/g]: haritayı büyütür ya da küçültür. [g]Ortadan genişlet[/g] işaretliyse her yönden eşit büyür, sembol ve jetonlar yerinde kalır."""],

	["Arazi Boyama", """[h]Arazi aracı ([k]B[/k])[/h]
• Sol panelden arazi tipini seç, haritada sol tıkla basılı tutup boya.
• Fırça boyutu: [k][lb][/k] / [k][rb][/k] veya kaydırıcı.
• Fırçayı bırakmak için [k]Esc[/k] (Seç aracına döner). Başka bir haritaya geçince ya da yeni harita oluşturunca da fırça kendiliğinden bırakılır.
• Arazi tipleri: Derin Deniz, Deniz, Sığ Su/Göl, Kumsal, Çayır, Ova, Orman, Bataklık, Çöl, Tepelik, Dağlık, Kar, Lav; şehir ve zindan için Toprak Yol, Kaldırım, Taş Zemin, Ahşap Zemin, Duvar, Boşluk/Kaya ve Parşömen.

[h]Kova Dolgu ([k]G[/k])[/h]
• Tıkladığın yerdeki aynı tip araziyle bitişik tüm alanı seçili araziyle doldurur. Örneğin bir adanın içini tek tıkla ormana çevirebilirsin.

[b]Su eklemek[/b]
• Deniz / göl: Arazi fırçasında [b]Deniz[/b] ya da [b]Sığ Su / Göl[/b] seçip boya.
• Nehir ve dere: [g]Nehir / Yol[/g] aracını kullan (bkz. "Nehirler, Yollar, Surlar").

[b]İpuçları[/b]
• Önce kaba şekli büyük fırçayla, ayrıntıları küçük fırçayla çiz.
• Yanlış boyadıysan [k]Ctrl+Z[/k].
• [g]Izgara[/g] ([k]H[/k]) açıkken hücreleri görebilirsin."""],

	["Krallıklar ve Bölgeler", """[h]Krallık / Bölge aracı ([k]R[/k])[/h]
1. Sol panelde [g]+ Yeni Krallık / Bölge[/g]'ye tıkla. Rastgele bir isim ve renk atanır.
2. [g]Seçili Bölge[/g] bölümünden [b]Ad[/b] (ör. "Arendil Krallığı"), [b]Renk[/b] ve [b]Notlar[/b] (yönetici, din, ordu...) değiştirilebilir.
3. Haritada sürükleyerek o krallığın topraklarını boya. Bölge rengi yarı saydam olarak araziyi örter, sınır çizgileri ve büyük krallık adı kendiliğinden çizilir.

• [k]Shift + tık[/k]: tıkladığın alanı tek seferde o krallıkla doldurur.
• [g]Sadece karaya boya[/g] işaretliyse denize taşmaz.
• Toprağı silmek: listeden [g](Bölgeyi Sil)[/g] seçip boya.
• Krallığı tamamen silmek: krallığı seç → [g]Bu Bölgeyi Sil[/g].

[b]Başkent ekleme[/b]
• [g]Sembol[/g] aracıyla ([k]S[/k]) [b]Başkent[/b] sembolünü koy, sağ panelden adını yaz."""],

	["Nehirler, Yollar, Surlar", """[h]Nehir / Yol aracı ([k]P[/k])[/h]
• Sol panelden çizgi tipini seç: [b]Nehir, Dere, Yol, Patika, Sur/Duvar, Sınır Çizgisi[/b].
• Sol tıkla basılı tutup sürükle; bıraktığında çizgi yumuşatılır.
• [k]Shift[/k] basılı tutarsan düz çizgi çizer (surlar, köprüler, düz yollar için).

[b]Çizgiyi düzenlemek[/b]
• [g]Seç[/g] aracı ([k]V[/k]) ile çizgiye tıkla. Sağ panelden [b]ad[/b] (ör. "Gümüş Nehir"), [b]tip[/b] ve [b]kalınlık[/b] değiştirilir.
• Sürükleyerek tüm çizgiyi taşıyabilirsin. [k]Delete[/k] siler."""],

	["Semboller ve İç İçe Haritalar", """[h]Sembol aracı ([k]S[/k])[/h]
• Sol panelden bir sembol seç (Yerleşim, Doğa, Özel Yerler, Şehir, Zindan / İç Mekan, Mobilya), haritaya tıkla.
• [g]Sembol boyutu[/g] kaydırıcısı yeni sembollerin büyüklüğünü belirler.
• [g]Yerleşimlere rastgele isim ver[/g] işaretliyse yeni köy ve şehirler otomatik isim alır.
• Koyduğun sembol seçili gelir: sağ panelde [b]ad[/b], [b]tip[/b], [b]boyut[/b] ve [b]notlar[/b] düzenlenir. [g]Zar[/g] düğmesi rastgele fantastik isim verir.
• Bina içlerinde [g]Mobilya[/g] kategorisi en üstte gelir: masa, sandalye, yatak, fıçı, tezgâh, ocak, raf, halı, taht, sancak, kazan, silah rafı...

[h]Bir yerin içine girmek[/h]
• Düzenleme modunda sembole [k]çift tıkla[/k]. Masa modunda tek tık yeterli.
• İçi daha önce oluşturulmuşsa doğrudan girersin.
• İçi henüz yoksa harita kendiliğinden üretilmez: sembol seçilir ve [b]sağ panelde[/b] iki seçenek çıkar:
   – [g]Kendim Çizeceğim (boş harita)[/g]: türüne uygun boş zemin açılır (binada duvarlı boş oda, ormanda orman zemini...), içini sen çizersin.
   – [g]Otomatik Oluştur[/g]: türüne uygun, mantıklı bir iç harita hazırlanır.
• Alt haritası olan sembollerin köşesinde küçük altın bir ok işareti görünür.

[h]Neyin içine girilebilir? (katman kuralı)[/h]
• [b]Dünya / Bölge haritasında:[/b] başkent, şehir, kasaba, köy, liman → [b]şehir haritası[/b]; kale, karakol, kule, tapınak → [b]yapı içi[/b]; orman, çam ormanı, dağ, tepeler, yanardağ → [b]yerel alan[/b]; zindan, mağara, harabe → [b]zindan[/b].
• [b]Şehir haritasında:[/b] sadece binalar (ev, konak, meyhane, han, dükkan, demirci, muhafız, tapınak, kule, kale) → [b]bina içi[/b]; kuyu ve zindan → yeraltı.
• [b]Bina içi, zindan ve yerel alan (orman, dağ...) son katmandır:[/b] içlerindeki sembollere girilmez. Ormanın içinde yeni bir orman, dağın içinde yeni bir dağ açılmaz.
• Yani çok katmanlı giriş sadece yerleşimlerde: [b]Dünya → Şehir → Meyhane[/b].

[h]Otomatik oluşturma ne üretir?[/h]
• [b]Başkent / şehir / kasaba:[/b] ana caddeler ve yan sokaklar, kiremit ve arduvaz çatılı evler, çarşı meydanı, kuyu, heykel, surlar, 4 kapı ve kuleler; isimli meyhaneler, hanlar, dükkanlar, demirci, tapınak, konak ve muhafız karakolu. Başkentte saray bölgesi, dışarıda tarlalar ve ağaçlar.
• [b]Köy:[/b] toprak yollar, dağınık evler, köy kuyusu, meyhane ve demirci, çevrede geniş tarlalar. [b]Liman:[/b] kıyı, iskeleler, deniz feneri.
• [b]Meyhane:[/b] bar tezgâhı ve meyhaneci, fıçılar, masalar ve sandalyeler, şömine, kiler, mutfak, üst kata merdiven. [b]Han:[/b] numaralı konuk odaları, yemek salonu, hancı.
• [b]Ev, dükkan, demirci, tapınak, konak, muhafız, kale, kule, karakol:[/b] her biri kendine özgü odalar ve eşyalar (ocak ve örs, sunak ve sıralar, taht salonu, koğuş ve hücreler...).
• [b]Orman:[/b] açıklıklar, patika, dere, göl, köprü, avcı kampı, druid sunağı, kurt ini. [b]Dağ:[/b] karlı zirveler, geçit patikası, mağara ağzı, konaklama yeri. [b]Tepeler:[/b] dikili taşlar, çoban kampı. [b]Yanardağ:[/b] krater, lav akıntıları.
• [b]Zindan:[/b] odalar, koridorlar, kapılar, tuzaklar, sandıklar, canavarlar, hazine. [b]Mağara:[/b] doğal tüneller ve yeraltı gölleri. [b]Harabe:[/b] yıkık duvarlar, kırık heykel, yeraltı girişi.
• Beğenmezsen: o haritaya gir → sağ panel (boş yere tıkla) → [g]Yeniden Oluştur[/g]. [k]Ctrl+Z[/k] ile geri alınır.
• Sağ panelden ayrıca [g]Bağlantıyı Kaldır[/g] ya da [g]var olan bir haritaya bağla[/g] (ör. iki kapı aynı zindana çıksın) seçenekleri var.

[b]Geri dönmek[/b]
• [k]Backspace[/k] veya konum çubuğundaki [g]< Üst Harita[/g].
• Konum çubuğundaki herhangi bir isme tıklayarak oraya atlayabilirsin.
• Sağ panel → [g]Harita Ağacı[/g]: tüm haritaların listesi; tıklayınca o haritaya gider. Buradan sembolsüz (boş) alt harita da eklenebilir.

[b]Harita silmek[/b]
• Silmek istediğin haritaya gir → sağ panel → [g]Bu Haritayı Sil[/g] (alt haritalarıyla birlikte silinir)."""],

	["Yazılar ve İsimler", """[h]Yazı aracı ([k]T[/k])[/h]
• Haritaya tıkla, yeni bir yazı oluşur ve seçili gelir. Sağ panelden [b]metin[/b], [b]boyut[/b], [b]yazı tipi[/b] (Başlık: Cinzel / Metin: Garamond) ve [b]renk[/b] ayarlanır.
• Deniz, okyanus, dağ sırası, çöl isimleri için idealdir.
• [g]Seç[/g] aracıyla sürükleyip taşıyabilirsin.

[b]İsimleri gizlemek[/b]
• Üst çubukta [g]İsimler[/g] düğmesi sembol, yol ve jeton isimlerini açar / kapatır."""],

	["Görünüm ve Dışa Aktarma", """[h]Üst çubuktaki görünüm seçenekleri[/h]
• [g]Izgara[/g] ([k]H[/k]): hücre ızgarası.
• [g]İsimler[/g]: sembol, yol ve jeton isimleri.
• [g]HD Görünüm[/g]: organik kıyılar, dalgalar, arazi dokuları ve yumuşak sınırlar. Kapatınca klasik kare hücre görünümü.
• [g]Parşömen[/g]: sepya tonlu eski kağıt harita görünümü.
• [g]Sığdır[/g] ([k]Home[/k]): haritayı ekrana sığdır.

[h]PNG olarak kaydetmek[/h]
• [g]PNG Dışa Aktar[/g]: haritanın tamamını ekrandan bağımsız, yüksek çözünürlükte (3 kata kadar) resim olarak kaydeder. Baskı veya oyunculara göndermek için.
• Masa modundayken dışa aktarırsan savaş sisi de resme dahil olur."""],

	["Karakter Oluşturmak", """[h]Yeni karakter[/h]
• Sağ panel → [g]Karakterler[/g] sekmesi → [g]+ Kahraman[/g] (oyuncu karakteri) veya [g]+ NPC[/g].
• Karakter kartı açılır. Kartı sonra tekrar açmak için listedeki karakter ismine tıkla.

[h]Karakter kartının sekmeleri[/h]
[b]Kimlik[/b]
• Ad ([g]Zar[/g] ırka uygun rastgele isim verir), Rol (Kahraman / NPC), Oyuncu adı.
• [b]Irk[/b]: 26 ırk (İnsan, Elfler, Cüce, Buçukluk, Gnom, Ork, Goblin, Şeytansoyu, Ejderdoğan, Kedi/Kuş/Kertenkele/Tavşan Halkı, Minotor, Sentor...). Irkı değiştirince yüz, kulak, boynuz, ten ve istatistik bonusları değişir.
• [b]Sınıf[/b]: Savaşçı, Barbar, Paladin, Korucu, Hırsız, Büyücü, Sihirbaz, Ahitli, Rahip, Druid, Ozan, Keşiş, Mucit; NPC sınıfları Köylü, Tüccar, Soylu, Muhafız. Sınıf kıyafeti, silahı ve başlangıç ekipmanını belirler.
• Seviye, Yönelim, [b]Taraf[/b] (Dost / Tarafsız / Düşman: jetonun halka rengi), Boyut, Geçmiş.

[b]Görünüm[/b]
• Kafa, Yüz, Kulak, Saç, Sakal, Boynuz, İşaretler (dövme, yara izi...), Başlık (kapüşon, miğfer, taç...), Kıyafet, Eşya/Silah, Kanat.
• Azı dişleri, parlayan gözler, hale, hayaletimsi seçenekleri; yapı, kafa boyu ve kaş kaydırıcıları.
• Ten, saç, göz, kıyafet, süsleme, arka plan, dövme ve boynuz renkleri.
• Portrenin altındaki [g]Rastgele Görünüm[/g], [g]Rastgele İsim[/g], [g]Her Şeyi Rastgele[/g] düğmeleri.

[b]İstatistikler[/b]
• 6 yetenek (Güç, Çeviklik, Dayanıklılık, Zeka, Bilgelik, Karizma); ırk bonusu ve değiştirici otomatik hesaplanır.
• [g]4d6 At[/g] (zarla), [g]Standart Dizi[/g] (15,14,13,12,10,8) ya da elle gir.
• [g]Can / ZS Yeniden Hesapla[/g]: sınıf, seviye ve Dayanıklılığa göre can ve zırh sınıfı.
• Her yeteneğin yanındaki [g]d20 At[/g]: yetenek kontrolü atar. [g]İnisiyatif At[/g] düğmesi de buradadır.

[b]Envanter[/b] — bkz. "Envanter ve Eşyalar".
[b]Notlar[/b] — kişilik, sırlar, DM notları.

[b]Alt düğmeler[/b]: [g]Haritaya Yerleştir[/g], [g]Kopyasını Oluştur[/g], [g]Sil[/g] (karakteri ve tüm jetonlarını siler)."""],

	["Bestiyer ve Yaratıklar", """[h]Yaratık eklemek[/h]
• Sağ panel → [g]Karakterler[/g] → [g]+ Yaratık[/g] (ya da Karakter aracında [g]+ Yaratık[/g]).
• Bestiyer penceresi açılır: üstten kategori seç (Hayvanlar, Kuşlar, Deniz Canlıları, Böcekler ve Sürüngenler, Ejderhalar, Fantastik Yaratıklar, Canavarlar, Ölümsüzler, Elementaller ve Yapılar, İnsansılar) veya ara (ör. "kurt", "ejder").
• Bir kartın üzerine gelince can, zırh, tehlike derecesi ve saldırılar görünür.
• Karta tıkla: yaratık kampanyana eklenir ve fareye yapışır. Haritaya her tıklayışında [b]yeni bir kopya[/b] koyarsın (Kurt 1, Kurt 2...). Her kopyanın kendi canı vardır.
• Bitince [k]sağ tık[/k] veya [k]Esc[/k].

• Yaratığın kartında görünüm renkleri, can, zırh, saldırılar ve notlar düzenlenebilir."""],

	["Jetonlar (Haritada Karakterler)", """[h]Karakteri haritaya koymak[/h]
• [g]Karakterler[/g] sekmesinde karakterin yanındaki [g]Koy[/g]'a bas, ya da [g]Karakter[/g] aracını ([k]C[/k]) seçip sol paneldeki portreye tıkla.
• Karakter fareye yapışır: [k]sol tık[/k] koyar, [k]sağ tık[/k] veya [k]Esc[/k] iptal eder.
• Kahraman ve NPC'ler aynı anda tek yerde bulunur; başka yere koyunca taşınır (başka haritadan da).

[h]Jetonla oynamak[/h]
• Jetonu [k]sürükleyerek[/k] taşı (düzenleme ve masa modunda).
• Jetona tıkla: sağ panelde portre, [b]Can[/b], [g]Hasar[/g] / [g]İyileştir[/g] / [g]Tam[/g], zırh, hız, yetenekler, silahlar, [g]d20 At[/g], [g]İnisiyatif[/g], taraf seçimi ve [g]Karakter Kartını Aç[/g].
• Halka rengi: [color=#4caf50]yeşil dost[/color], [color=#e0b85c]sarı tarafsız[/color], [color=#d84a3a]kırmızı düşman[/color]. Altta can çubuğu; can 0'a inince jetonun üstünde kırmızı çarpı çıkar.
• Fareyi jetonun üstünde tutunca ad, can ve zırh yazar.

[h]Jetonu kaldırmak[/h]
• [g]Karakterler[/g] listesinde [g]Kaldır[/g] (karakter silinmez, sadece haritadan kalkar).
• Ya da jetonu seçip [k]Delete[/k] / [g]Jetonu Haritadan Kaldır[/g].
• Listede [g]Konum[/g] satırı karakterin hangi haritada olduğunu gösterir; filtreden [g]Bu haritada[/g] seçerek sadece buradakileri listeleyebilirsin."""],

	["Envanter ve Eşyalar", """[h]Envanteri açmak[/h]
• Karakter kartı → [g]Envanter[/g] sekmesi.

[b]Yuvalar[/b]
• [b]Silah 1, Silah 2, Kask, Omuzluk, Gövde Zırhı, Eldiven, Bacak Zırhı, Ayakkabı[/b]. Altında [b]Altın[/b] miktarı.
• Sağda sınırsız [b]Çanta[/b]: yedek eşyalar, iksirler, parşömenler...

[b]Eşya eklemek[/b]
• [g]+ Eşya Ekle[/g] → şablonlardan birine tıkla. Eşya çantaya gelir ve seçili olur.
• Silahlar: Büyücü Asası, Değnek, Büyü Küresi, Büyük/Uzun/Kısa Kılıç, Hançer, El Baltası, Savaş Baltası, Savaş Çekici, Gürz, Mızrak, Teber, Tırpan, Kamçı, Yay, Arbalet, Sapan, Kalkan.
• Zırhlar: her yuva için bir tane. Diğer: İksir, Parşömen, Kitap, Yüzük, Kolye, Mücevher, Para Kesesi, Anahtar, Erzak, Meşale, Halat, Ok Demeti, Alet Takımı, Müzik Aleti, Harita/Not, Taş/Malzeme.
• [b]Özel Eşya[/b]: içine ne yazarsan o. Örneğin karakter yerden taş aldıysa: Özel Eşya ekle → Ad: "Taş" → Özellikler: "Yerden alınmış sıradan bir taş" → İkon: Taş / Malzeme.

[b]Eşyayı düzenlemek[/b]
• Eşyaya tıkla; sağ tarafta: [b]Ad, Tür (şablon), İkon, Nadirlik[/b] (Sıradan → Efsanevi, çerçeve rengi), [b]Adet, Renk[/b] ve serbest [b]Özellikler[/b] metni (hasar, büyü, açıklama... ne yazarsan).
• Fareyi bir eşyanın üstünde tutunca adı ve özellikleri görünür.

[b]Taşımak ve kuşanmak[/b]
• [k]Sürükle-bırak[/k]: çantadan yuvaya, yuvadan çantaya, çanta içinde sıralama.
• [k]Çift tık[/k] veya [k]sağ tık[/k]: eşyayı kuşanır ya da çıkarır.
• Yuvalar sadece uygun eşyayı kabul eder (kaska kılıç takılmaz). Kalkan ve büyü odakları silah yuvasına takılır.
• [g]Kopyala[/g], [g]Sil[/g] ve [g]Başka karaktere ver[/g] (ganimet paylaşımı) düğmeleri detay panelindedir."""],

	["Zarlar", """[h]Zar atmak[/h]
• Üst çubukta [g]Zarlar (D)[/g] ya da [k]D[/k] tuşu zar tepsisini açar / kapatır.
• Zar düğmesine tıkla: [b]d4, d6, d8, d10, d12, d20, d%[/b] (d100).
• [g]Adet[/g]: kaç zar atılacağı (ör. 3 ve d6 = 3d6). [g]Bonus[/g]: eklenecek / çıkarılacak sayı.
• [g]Avantaj[/g] / [g]Dezavantaj[/g]: tek d20 atışında iki zar atılır, yüksek / düşük olan sayılır; diğeri çizili görünür.
• [g]Atan[/g]: zarı kimin attığı (sonuçta adı yazar).
• Serbest ifade kutusu: [b]2d6+3[/b], [b]1d8+1d6-1[/b], [b]4d6[/b], [b]d%[/b] yazıp [k]Enter[/k] ya da [g]At[/g].

[b]Sonuç[/b]
• Zarlar ekrana yuvarlanır, sonra toplam ve döküm gösterilir. [color=#ffd700]Doğal 20 = KRİTİK BAŞARI[/color], [color=#ff5a4a]doğal 1 = KRİTİK BAŞARISIZLIK[/color].
• Son atışlar tepside saatiyle listelenir, alt çubukta da kısa sonuç yazar.

[b]Kısa yollar[/b]
• Karakter kartı → İstatistikler: her yeteneğin yanında [g]d20 At[/g] (değiştirici otomatik eklenir) ve [g]İnisiyatif At[/g].
• Jetona tıklayınca sağ panelde [g]d20 At[/g] ve [g]İnisiyatif[/g]."""],

	["Masa Modu, Sis ve Grup", """[h]Masa modu (oyun sırasında)[/h]
• Sağ üstteki mod düğmesi ya da [k]Tab[/k]: [g]Düzenleme Modu[/g] ↔ [g]Masa Modu[/g].
• Masa modunda: sembole [k]tek tık[/k] o yerin haritasına girer, jetonlar sürüklenir, boş yeri sürükleyince harita kayar, savaş sisi tamamen kapalıdır. Düzenleme araçları gizlenir.

[h]Savaş sisi ([k]F[/k])[/h]
• Sis aracında [g]Bu haritada savaş sisi açık[/g] kutusunu işaretle (ya da sağ panelde [g]Savaş sisi[/g]).
• [g]Sisi Aç[/g] / [g]Sisi Kapat[/g] seçip fırçayla boya. [g]Tüm Haritayı Aç / Kapat[/g] düğmeleri de var.
• Düzenleme modunda sis yarı saydam (sen görürsün), masa modunda tamamen kapalıdır (oyuncular görmez). Sisin altındaki düşman jetonları da gizli kalır.
• [b]Kahraman jetonları[/b] ve grup jetonu ilerledikçe çevrelerindeki sis kendiliğinden açılır.

[h]Grup jetonu ([k]Q[/k])[/h]
• Haritaya tıkla: oyuncu grubunu temsil eden bayraklı jeton. Masa modunda sürüklenir. Sol panelden kaldırılır."""],

	["Ölçüm ve Mesafe", """[h]Ölç aracı ([k]M[/k])[/h]
• Haritada iki nokta arasını sürükle; mesafe yazar.
• Harita ölçeği km ise yaya ve atlı yolculuk süresi (gün), m veya ft ise savaş turu sayısı da gösterilir.
• Herhangi bir araçtayken [k]Shift + sürükle[/k] de ölçer (Bölge ve Yol araçları hariç).
• Ölçeği değiştirmek: sağ panel → harita özellikleri → [g]Ölçek: 1 hücre =[/g]."""],

	["Kısayollar", """[h]Klavye kısayolları[/h]
[table=2]
[cell][k]V[/k]  [/cell][cell]Seç / Taşı[/cell]
[cell][k]B[/k][/cell][cell]Arazi fırçası[/cell]
[cell][k]G[/k][/cell][cell]Kova dolgu[/cell]
[cell][k]R[/k][/cell][cell]Krallık / Bölge[/cell]
[cell][k]P[/k][/cell][cell]Nehir / Yol[/cell]
[cell][k]S[/k][/cell][cell]Sembol[/cell]
[cell][k]T[/k][/cell][cell]Yazı[/cell]
[cell][k]F[/k][/cell][cell]Savaş sisi[/cell]
[cell][k]M[/k][/cell][cell]Ölç[/cell]
[cell][k]E[/k][/cell][cell]Silgi[/cell]
[cell][k]Q[/k][/cell][cell]Grup jetonu[/cell]
[cell][k]C[/k][/cell][cell]Karakter (jeton) aracı[/cell]
[cell][k]D[/k][/cell][cell]Zar tepsisi[/cell]
[cell][k]F1[/k][/cell][cell]Bu rehber[/cell]
[cell][k][lb][/k] / [k][rb][/k][/cell][cell]Fırçayı küçült / büyüt[/cell]
[cell][k]H[/k][/cell][cell]Izgara aç / kapa[/cell]
[cell][k]Home[/k][/cell][cell]Haritayı ekrana sığdır[/cell]
[cell][k]Tab[/k][/cell][cell]Düzenleme ↔ Masa modu[/cell]
[cell][k]Delete[/k][/cell][cell]Seçili nesneyi sil[/cell]
[cell][k]Backspace[/k][/cell][cell]Üst haritaya dön[/cell]
[cell][k]Esc[/k][/cell][cell]Yerleştirmeyi iptal et / elindeki aracı (fırça vb.) bırak / seçimi kaldır[/cell]
[cell][k]Ctrl+Z[/k] / [k]Ctrl+Y[/k][/cell][cell]Geri al / Yinele[/cell]
[cell][k]Ctrl+S[/k] / [k]Ctrl+O[/k][/cell][cell]Kaydet / Aç[/cell]
[/table]

[h]Fare[/h]
[table=2]
[cell][k]Sol tık[/k]  [/cell][cell]Aracı kullan / seç / yerleştir[/cell]
[cell][k]Çift tık[/k] (sembol)[/cell][cell]İçine gir (alt harita)[/cell]
[cell][k]Sağ tık sürükle[/k][/cell][cell]Haritayı kaydır[/cell]
[cell][k]Sağ tık[/k] (yerleştirirken)[/cell][cell]Yerleştirmeyi iptal et[/cell]
[cell][k]Tekerlek[/k][/cell][cell]Yakınlaş / uzaklaş[/cell]
[cell][k]Shift + sürükle[/k][/cell][cell]Mesafe ölç[/cell]
[cell][k]Shift + tık[/k] (Bölge)[/cell][cell]Alanı krallıkla doldur[/cell]
[cell][k]Shift[/k] (Nehir/Yol)[/cell][cell]Düz çizgi[/cell]
[/table]"""],

	["İpuçları ve Sık Sorulanlar", """[b]Kayıtlarım nerede?[/b]
• [g]Kaydet[/g] ile seçtiğin yerde (varsayılan Belgeler). Otomatik kayıt: Windows'ta [b]%APPDATA%\\Godot\\app_userdata\\FRP Harita Ustasi\\autosave.frp[/b].

[b]Haritam çok büyük, yavaşladı[/b]
• Semboller parçalara bölünerek çizilir; ekranda görünmeyenler çizilmez. Çok uzaklaşınca küçük dağ / orman sembolleri gizlenir (arazi rengi zaten görünür).
• Hâlâ yavaşsa HD görünümü kapatmayı dene. Çok büyük haritalarda geri alma geçmişi kısalır (bellek için).

[b]Bir şeyi yanlışlıkla sildim[/b]
• [k]Ctrl+Z[/k]. Karakter silme geri alınamaz; dikkat!

[b]Şehir haritası boş geliyor[/b]
• Yeni şehir haritaları sur, dört kapı ve çarşıyla gelir. [g]Haritayı Tamamen Temizle[/g] ile sıfırlayıp kendin çizebilirsin.

[b]Aynı zindana iki kapıdan girmek[/b]
• İkinci kapı sembolünü seç → sağ panel → [g]var olan bir haritaya bağla[/g].

[b]Oyuncu ekranı[/b]
• Masa modunda sis tamamen kapalıdır; ikinci bir ekranda oyunculara gösterebilir ya da [g]PNG Dışa Aktar[/g] ile resmini paylaşabilirsin."""],
]


func _init() -> void:
	title = "Rehber — Bilmen Gerekenler"
	size = Vector2i(1080, 720)
	min_size = Vector2i(760, 480)
	transient = true
	visible = false
	close_requested.connect(hide)


func _ready() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.085)
	sb.set_content_margin_all(10)
	bg.add_theme_stylebox_override("panel", sb)
	add_child(bg)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	bg.add_child(h)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 270
	h.add_child(left)
	_search = LineEdit.new()
	_search.placeholder_text = "Ara: fırça, su, envanter, zar..."
	_search.clear_button_enabled = true
	_search.text_changed.connect(func(_t: String) -> void: _fill_list())
	left.add_child(_search)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_show)
	left.add_child(_list)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.selection_enabled = true
	_text.add_theme_font_size_override("normal_font_size", 16)
	_text.add_theme_font_size_override("bold_font_size", 16)
	_text.add_theme_color_override("default_color", Color("e8dfcc"))
	h.add_child(_text)
	_fill_list()


func open() -> void:
	popup_centered()
	_search.grab_focus()


func _fill_list() -> void:
	var q := _search.text.strip_edges().to_lower() if _search else ""
	_list.clear()
	_shown.clear()
	for i in topics.size():
		if q == "" or str(topics[i][0]).to_lower().find(q) >= 0 or str(topics[i][1]).to_lower().find(q) >= 0:
			_list.add_item(topics[i][0])
			_shown.append(i)
	if not _shown.is_empty():
		_list.select(0)
		_show(0)
	else:
		_text.text = "Aramana uygun konu bulunamadı."


func _show(idx: int) -> void:
	if idx < 0 or idx >= _shown.size():
		return
	var t: Array = topics[_shown[idx]]
	var body: String = t[1]
	body = body.replace("[h]", "[font_size=22][color=%s]" % GOLD).replace("[/h]", "[/color][/font_size]\n")
	body = body.replace("[k]", "[color=%s][b]" % KEY).replace("[/k]", "[/b][/color]")
	body = body.replace("[g]", "[color=%s]" % GOLD).replace("[/g]", "[/color]")
	body = body.replace("[/cell][cell]", "\u2003\u2003\u2003[/cell][cell]")
	_text.text = "[font_size=28][color=%s]%s[/color][/font_size]\n\n%s" % [GOLD, t[0], body]
	_text.scroll_to_line(0)
