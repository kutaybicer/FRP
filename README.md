# FRP Harita Ustası (Godot 4.3+)

FRP kampanyaları için iç içe harita tasarlama aracı. Dünya haritası çiz, krallıkları boya, şehir sembolü koy. Sembole tıklayınca o şehrin haritası açılır, oradan meyhaneye, meyhaneden mahzene girebilirsin.

## Çalıştırma
1. Godot 4.3 veya daha yenisini aç, **Import** ile bu klasördeki `project.godot` dosyasını seç.
2. F5 ile çalıştır. Harici resim veya eklenti gerekmez, tüm semboller kodla çizilir.

## Dosya yapısı
| Dosya | Görevi |
|---|---|
| `scripts/defs.gd` | (Autoload `Defs`) Arazi tipleri, semboller, yol tipleri, harita türleri, isim üreteci |
| `scripts/map_data.gd` | Tek bir haritanın verisi (arazi/bölge/sis katmanları + semboller, yollar, yazılar) |
| `scripts/campaign.gd` | Haritalar ağacı, kaydet/yükle (`.frp`) |
| `scripts/map_view.gd` | Haritayı çizer, tüm araçlar, geri al/yinele |
| `scripts/map_generator.gd` | Rastgele kıta, nehir üretimi ve yeni alt haritaların başlangıç düzeni |
| `scripts/symbol_painter.gd` | 45'ten fazla sembolün vektör çizimi |
| `scripts/camera_rig.gd` | Kaydırma ve yakınlaştırma |
| `scripts/main.gd` | Arayüz, gezinme, dosya işlemleri |
| `scripts/lore.gd` | (Autoload `Lore`) Irklar, sınıflar, yönelimler, boyutlar ve bestiyer (yaratık kataloğu) |
| `scripts/portrait_painter.gd` | Karakter ve yaratık portrelerinin vektör çizimi |
| `scripts/portrait_cache.gd` | (Autoload `Portraits`) Portreleri shader ile bir kez çizip doku olarak saklar |
| `scripts/character_editor.gd` | Karakter kartı penceresi |
| `scripts/bestiary_window.gd` | Bestiyer penceresi |
| `scripts/inventory_panel.gd`, `item_slot.gd`, `item_painter.gd` | Envanter, sürükle-bırak yuvalar, eşya ikonları |
| `scripts/dice.gd`, `dice_overlay.gd`, `die_button.gd` | Zar ifadeleri, zar tepsisi ve atma animasyonu |

## Sıfırdan harita / büyük haritalar
- **Yeni** düğmesi bir pencere açar. Başlangıç tipini seç: *Rastgele kıta*, *Boş okyanus (anakarayı ben çizeceğim)*, *Boş kara* ya da *Boş parşömen*. Boyutu da buradan seçersin: Küçük 120×80'den Dev Kıta 900×620'ye kadar hazır boyutlar var, istersen en fazla 1000×1000 hücrelik özel boyut girebilirsin. Ölçek de ayarlanabilir (1 hücre = ? km).
- Boş okyanusla başlayınca Arazi aracı (B) Çayır seçili açılır; anakarayı fırçayla çizersin. Fırça boyutu 40'a kadar çıkar ( `[` ve `]` tuşları). Kova Dolgu (G) kapalı alanları tek tıkla doldurur.
- Var olan haritayı sıfırlamak için: sağ panel → **Haritayı Tamamen Temizle** (boş deniz) veya **Tümünü Seçili Araziyle Doldur**.
- Haritayı sonradan büyütmek için: sağ panel → Boyut → **Uygula**. "Ortadan genişlet" seçiliyse harita her yönden eşit büyür ve semboller, yollar ve jetonlar yerinde kalır.

## Karakterler ve yaratıklar
- **Kahramanlar ve NPC'ler** 26 ırk ve 17 sınıftan oluşturulabilir. İnsan, Yüksek/Orman/Kara Elf, Yarı-Elf, Cüce, Buçukluk, Gnom, Yarı-Ork, Ork, Goblin, Hobgoblin, Kobold, Şeytansoyu, Ejderdoğan, Göksoylu, Dağ Devi Soyu, Kedi/Kertenkele/Kuş/Tavşan Halkı, Minotor, Sentor, Orman Devi Soyu, Elementsoyu ve Deniz Halkı var. Savaşçı, Barbar, Paladin, Korucu, Hırsız, Büyücü, Sihirbaz, Ahitli, Rahip, Druid, Ozan, Keşiş ve Mucit sınıflarına ek olarak Köylü, Tüccar, Soylu ve Muhafız NPC sınıfları da var.
- **Bestiyer**: 150'den fazla hayvan, kuş, deniz canlısı, böcek, ejderha, fantastik yaratık, canavar, ölümsüz, elemental ve insansı düşman. Her birinin can, zırh sınıfı, tehlike derecesi ve saldırıları hazır gelir.
- **Karakter kartı**: kimlik, görünüm (kafa, kulak, saç, sakal, boynuz, işaret, başlık, kıyafet, silah, kanat ve tüm renkler), yetenek puanları (4d6 zar ya da standart dizi, ırk bonusları, değiştiriciler), can, zırh sınıfı, hız, XP, altın ve notlar.
- **Portreler** tamamen kodla çizilir. Shader ile boya dokusu, ışık ve gölge eklenir. Portreler bir kez çizilip önbelleğe alındığı için harita jetonları hızlıdır ve her yakınlaştırmada pürüzsüz görünür.
- **Jetonlar** (Karakter aracı, C): Kahramanlar ve NPC'ler aynı anda tek bir haritada bulunur, yeniden yerleştirince taşınırlar. Yaratıklardan istediğin kadar koyabilirsin (Kurt 1, Kurt 2...); her jetonun kendi canı vardır. Jeton halkasının rengi tarafını gösterir (dost, tarafsız, düşman). Can çubuğu ve ölü işareti de var. Kahramanlar ilerledikçe savaş sisi açılır.
- **Koy**'a basınca karakter fareye yapışır; sol tık yerleştirir, **sağ tık veya Esc iptal eder**. Listedeki **Kaldır** düğmesi jetonu haritadan kaldırır (karakter silinmez).
- Jetona tıklayınca sağ panelde hasar/iyileştirme düğmeleri ve hızlı istatistikler görünür. **Karakterler** sekmesi bütün kadroyu ve her karakterin hangi haritada olduğunu listeler.

## Envanter
- Karakter kartındaki **Envanter** sekmesinde 8 kuşanma yuvası var: Silah 1, Silah 2, Kask, Omuzluk, Gövde Zırhı, Eldiven, Bacak Zırhı, Ayakkabı. Ayrıca sınırsız bir **çanta** var (yedek eşyalar, iksirler, parşömenler...).
- Bütün eşyalar **tek tiptir** ve her şeyi düzenlenebilir: ad, tür (şablon), ikon, nadirlik (Sıradan → Efsanevi), adet, renk ve serbest **özellik metni** (hasar, büyü, açıklama... ne yazarsan).
- **Şablonlar** (her türden bir tane): Büyücü Asası, Değnek, Büyü Küresi, Büyük Kılıç, Uzun Kılıç, Kısa Kılıç, Hançer, El Baltası, Savaş Baltası, Savaş Çekici, Gürz, Mızrak, Teber, Tırpan, Kamçı, Yay, Arbalet, Sapan, Kalkan; Kask, Omuzluk, Gövde Zırhı, Eldiven, Bacak Zırhı, Ayakkabı; İksir, Parşömen, Kitap, Yüzük, Kolye, Mücevher, Para Kesesi, Anahtar, Erzak, Meşale, Halat, Ok Demeti, Alet Takımı, Müzik Aleti, Harita/Not, Taş/Malzeme ve **Özel Eşya** (içine ne yazarsan o).
- Sürükle-bırak ile taşı. Çift tık veya sağ tık eşyayı kuşanır ya da çıkarır. Yuvalar sadece uygun eşyayı kabul eder (kaska kılıç takılmaz).
- Eşyalar başka bir karaktere verilebilir (ganimet paylaşımı). Yeni karakterler sınıflarına göre başlangıç ekipmanıyla gelir.

## Zarlar
- Üst çubuktaki **Zarlar (D)** düğmesi zar tepsisini açar. d4, d6, d8, d10, d12, d20 ve d% (d100) var.
- Adet, bonus, avantaj/dezavantaj ve "atan karakter" seçilebilir. Serbest ifade de yazılabilir: `2d6+3`, `1d8+1d6-1`, `4d6`, `d%`.
- Zarlar ekrana fırlayıp yuvarlanır, sonra toplam gösterilir. Doğal 20 altın, doğal 1 kırmızı parlar. Son atışlar tepside listelenir.
- Karakter kartında her yetenek için "d20 At" (yetenek kontrolü) ve "İnisiyatif At" düğmeleri var. Jeton panelinde de hızlı d20 ve inisiyatif atışı yapılabilir.

## Görüntü kalitesi
- **HD Görünüm** (üst çubuk, varsayılan açık): Arazi GPU'da shader ile çizilir (`shaders/`). Organik kıyılar, mürekkep kıyı çizgisi, kıyı dalgaları, sığ su geçişi, arazi dokuları (orman, dağ gölgesi, kum tepeleri, kaldırım taşı, ahşap tahta, taş duvar, lav çatlakları) ve yumuşak krallık sınırları burada. Kapatınca klasik kare hücre görünümüne döner. Zindan ve bina haritalarında duvarlar düz kalsın diye kıyı bükmesi kapalıdır.
- **Parşömen**: Sepya tonlu eski kağıt harita görünümü.
- **Fontlar**: Cinzel (bölge isimleri, başlıklar) ve EB Garamond (sembol isimleri). İkisi de MSDF olarak yüklenir, yakınlaştırınca bulanıklaşmaz. Lisans: SIL OFL, bkz. `fonts/`.
- **PNG dışa aktarma** ekran çözünürlüğünden bağımsızdır, haritayı 3 kat çözünürlükte (120×80 dünya için 5760×3840) kaydeder.
- Daha fazla detay için haritanın hücre sayısını artırın (Özellikler > Boyut). Örneğin dünya haritasını 200×130 yapabilirsiniz.

## Kısayollar
| Tuş | İş |
|---|---|
| V B G R P S T F M E Q C | Seç, Arazi, Kova, Krallık, Nehir/Yol, Sembol, Yazı, Sis, Ölç, Silgi, Grup, Karakter |
| Tab | Düzenleme ↔ Masa modu |
| Çift tık (sembol) | Alt haritaya gir; yoksa oluşturur |
| Backspace | Üst haritaya dön |
| D | Zar tepsisi |
| Ctrl+Z / Ctrl+Y | Geri al / Yinele |
| Ctrl+S / Ctrl+O | Kaydet / Aç |
| Delete | Seçiliyi sil |
| [ ] | Fırça boyutu |
| Shift + sürükle | Mesafe ölç |
| Sağ/orta tık sürükle, tekerlek | Kaydır, yakınlaştır |
| H, Home | Izgara, haritaya sığdır |

## Yeni sembol veya arazi eklemek
- Arazi: `defs.gd` içindeki `terrains` listesinin **sonuna** ekle. Kayıtlar bu sıraya bağlı olduğu için araya ekleme.
- Sembol: `defs.gd` içindeki `symbols` sözlüğüne kayıt ekle (`child` alanı, tıklanınca açılacak harita türüdür). Sonra `symbol_painter.gd` içindeki `match` bloğuna bir çizim fonksiyonu ekle. Çizimi olmayan semboller kırmızı iğne olarak görünür.
