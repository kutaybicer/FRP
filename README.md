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

## Görüntü kalitesi
- **HD Görünüm** (üst çubuk, varsayılan açık): Arazi GPU'da shader ile çizilir (`shaders/`). Organik kıyılar, mürekkep kıyı çizgisi, kıyı dalgaları, sığ su geçişi, arazi dokuları (orman, dağ gölgesi, kum tepeleri, kaldırım taşı, ahşap tahta, taş duvar, lav çatlakları) ve yumuşak krallık sınırları burada. Kapatınca klasik kare hücre görünümüne döner. Zindan ve bina haritalarında duvarlar düz kalsın diye kıyı bükmesi kapalıdır.
- **Parşömen**: Sepya tonlu eski kağıt harita görünümü.
- **Fontlar**: Cinzel (bölge isimleri, başlıklar) ve EB Garamond (sembol isimleri). İkisi de MSDF olarak yüklenir, yakınlaştırınca bulanıklaşmaz. Lisans: SIL OFL, bkz. `fonts/`.
- **PNG dışa aktarma** ekran çözünürlüğünden bağımsızdır, haritayı 3 kat çözünürlükte (120×80 dünya için 5760×3840) kaydeder.
- Daha fazla detay için haritanın hücre sayısını artırın (Özellikler > Boyut). Örneğin dünya haritasını 200×130 yapabilirsiniz.

## Kısayollar
| Tuş | İş |
|---|---|
| V B G R P S T F M E Q | Seç, Arazi, Kova, Krallık, Nehir/Yol, Sembol, Yazı, Sis, Ölç, Silgi, Grup |
| Tab | Düzenleme ↔ Masa modu |
| Çift tık (sembol) | Alt haritaya gir; yoksa oluşturur |
| Backspace | Üst haritaya dön |
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
