# SON SEFER — Güncelleme Notları

## 2026-07-07 (11) — SEKANS SİSTEMİ: asansör inişi, vardiya başlatma prosedürü, günlük, sesler

### Sekans 1 — İniş (asansör)
- Oyun artık **animasyonlu asansör kabininde** başlıyor (`simple_elevator.glb`, kendi kayar
  kapı animasyonuyla). Servis koridoru + camlı OFİS kapısıyla ofise bağlanıyor.
- **Kulaklık önerisi kartı** + HİSAR-7 açılış kartı; iniş hızlandırıldı, varış "clank" sesi
  kaldırıldı, kapı sesi kısıldı.
- Telsiz **çalar** (sol altta telsiz ikonu + [Q] göstergesi), oyuncu **Q** ile cevaplar;
  ilk temastan sonra hat açık kalır (Merkez çağrı yapmadan direkt konuşur).

### Sekans 2 — Ofis: Vardiya Başlatma Prosedürü
- Ofis **karanlık** başlar, çelik kapı **kapalı**. Adım adım, tek görev akışı:
  **ana pano (şalter) → giriş defteri (imza) → sistem senkron → kameraları devreye al →
  bölge taraması → ekipman kuşan**.
- **Kameralar tek tek açılıyor** (BOŞLUK); her kamera için Merkez konuşuyor, 6. (alt peron)
  ölü/karlı kalıyor. Replik bitmeden sonraki kameraya geçilemiyor.
- **Ekipman** zimmet masasında: terminal, fener (cılız → dolaptan/masadan pil ile güçlenir),
  kart + yedek sigorta. Konsol yalnız sistem/kamera; terminalle karışmıyor.
- Ana pano artık **gerçek elektrik panosu modeli** (yapay kutu/LED değil).

### Görev Günlüğü (yeni)
- CCTV masasındaki not defteri **E** ile alınıyor → **J** tuşuyla açılan görev günlüğü.
- Aktif görevler listeleniyor; **tamamlananların üstü çizili** ✓. Görevler akışın kilit
  noktalarında otomatik ekleniyor/tamamlanıyor.

### Yeni sistemler ve cila
- **Obje inceleme** (E): model ekran ortasına gelir, arka plan buğulu, fare ile döndürülür
  (vardiya çizelgesi, bakım defteri, termos, gazete kupürü, takvim).
- **Foto modu** (P / F12): menüsüz anlık ekran görüntüsü → `~/Desktop/Peronomaly_shots/`.
- **Poster shader**: peron/hol afişleri prosedürel vintage metro afişi.
- **Profesyonel etkileşim göstergesi**: çerçeveli tuş kutusu [E] + eylem metni.
- **Yeni ESC menüsü** (oyun fontları, bölümlü ayarlar).
- **Gerçek ses kayıtları**: telsiz çalma/squelch, asansör motoru, tersten işlenmiş telsiz
  konuşma dokusu; Master limiter ile ses dengesi (kulaklıkta patlama önlendi).

### Diyaloglar
- **En son diyaloglar (`DIYALOGLAR.md`) güncellendi — bir sonraki sürümde etkinleştirilecek.**
  Oyundaki metinler o zaman bu belgeye göre yenilenecek.

---

## 2026-07-06 (10) — KONTROL ODASI yeniden: CCTV sistemi, alınabilir terminal+fener; 3 görsel bug

### Görsel bug düzeltmeleri (kullanıcı ekran görüntüleri)
- **Koridor ağzı lentosu titremesi**: merdiven tavanı ile lento aynı düzlemi paylaşıyordu
  (y=5.75 çakışık yüzey) → tavan lentodan önce bitiyor, lento alt yüzü 3 cm aşağı alındı
- **Peron köşesinde model bozulması**: köşe pilastırı duvar yüzeyleriyle eş düzlemdeydi
  → pilastır her yönden 3-5 cm taşkın yapıldı, çakışan yüzey kalmadı
- **"Kuyu gibi" merdiven düzlüğü**: üst düzlük siyah parlak taştı → hol ile aynı açık
  fayansa çevrildi + merdiven ağzına sarı ikaz bandı

### Kontrol odası büyüdü ve yeniden düzenlendi (5.2 × 5.0 m)
- **Duvarlar**: "sulu/yağlı" görünen boya yerine düz mat sıva
- **CCTV masası (batı duvarı)**: retro bilgisayar (kullanıcının modeli, yeşil fosfor ekran) —
  **E ile GÜVENLİK KAMERALARI açılır**; koltuk masaya dönük
- **Zimmet masası (güney duvarı)**: **el terminali ve el feneri masada duruyor, E ile alınıyor**
  — alınana kadar TAB ve F çalışmaz (vintage_flashlight modeli eklendi, Poly Haven CC0)
  MERKEZ açılışta "Masandaki terminali ve feneri üstüne al" diyor; alınca teyit veriyor
- Telsiz cihazı, kol lambası (artık masanın ÜSTÜNE dönük), notlar, klipbord düzenli yerleşti
- Kitaplık + çekmeceli dolap kuzey duvarına ferah yerleşim; çaydanlık dolabın üstünde
- **Kapı eklendi**: aralık duran çelik kapı + hol tarafında **STAFF ONLY** plakası
  ("PERSONEL HARİCİ GİRİLMEZ" alt yazısıyla)
- Mantar pano duvarın içine gömülme hatası düzeltildi (notlar artık görünür)

### GÜVENLİK KAMERASI SİSTEMİ (yeni: scripts/cctv.gd)
- Bilgisayara E → tam ekran monokrom CCTV: **4 kanal** (K-1 PERON BATI, K-2 PERON DOĞU,
  K-3 ÜST HOL, K-4 MERDİVEN), 1-4 ile geçiş, E/ESC ile çıkış; oyuncu ekrandayken kilitli
- Kanal başlığı + akan **03:47 zaman damgası** + yanıp sönen REC + kanal geçiş paraziti
- **Anomali beslemeleri**: kanal açıkken %40 ihtimalle birkaç saniye sonra o kameranın
  gördüğü bir noktada **duran siyah figür** belirir, parazitle kaybolur (Aşağıdaki asla
  net gösterilmez — CLAUDE.md Kilit 2'ye uygun: sadece uzak, kısa, bozuk görüntü)

## 2026-07-06 (9) — TEKNİSYEN OFİSİ (yeni başlangıç), hol cilası, yeni font, doğal diyalog

### Yeni mekân: Teknisyen Ofisi — oyun artık burada başlıyor
- Holün batısında, kapısı hole açılan **3.8×3.6 m sıcak ışıklı oda** (CLAUDE.md "vadi/güvenli oda")
- Kapı üstünde "TEKNİK SERVİS"; içeride koyu süpürgelik, boyalı sıva duvarlar, sıcak floresan
- **Poly Haven CC0 mobilya** (hepsi doğal ölçekte, 1k doku): metal ofis masası, yeşil kumaş koltuk,
  eskimiş kitaplık, çekmeceli dolap, plastik yedek sandalye
- **Masa üstü**: bağa telsiz cihazı (vintage radio transceiver — MERKEZ'in sesi buradan
  gelir hissi), akrobat kol lambası (sıcak nokta ışığı), not defterleri, klipbord, bakır çaydanlık
- **Mantar pano** + raptiyeli notlar: "VARDİYA 23:00–06:00 / tek kişi", kırmızı kalemle
  "A panosu ARIZALI — dokunma. C." (Cavit'in ilk izi)
- Duvar saati **03:47'de durmuş** — açılış kartıyla aynı an (zaman anomalisinin ilk tohumu)
- Oyuncu masaya dönük uyanır; MERKEZ ilk konuşmasını burada yapar ("Ofisten çık, hole geç...")

### Üst hol cilası ("üst taraf hâlâ çok kötü" geri bildirimi)
- **Gerçek CAM bariyerler**: şeffaf cam panolar (SSR yansımalı) + paslanmaz dikme,
  boru küpeşte ve alt ray — önceki "cam gibi olmayan" plakalar gitti
- **4 fayanslı kolon** (peronla aynı görsel dil, koyu fayans tabanlı)
- **Süpürgelik** tüm duvar diplerinde; tavanda hol boyunca **iki boru hattı** + dikey inişler
- Aydınlatma 3 → 6 armatür (dördü sağlam, biri titrek, biri ölü) — hol artık okunuyor ama loş
- Kepenk üstünde büyük **"H İ S A R — 7"** istasyon harfleri
- Koridor ağzında asılı çift yüzlü **"▼ PERON"** yönlendirme tabelası
- Kepenk yanlarına iki poster (HAT PLANI / SON SEFER 00:40), doğu duvarına yangın tüpü
- Bilet makineleri doğu duvarına taşındı (batı duvarı artık ofisin)

### Altyazı ve yazı tipi
- **Barlow** (OFL) ailesi eklendi: altyazılar Barlow-Medium 34pt, açılış kartı
  BarlowCondensed-SemiBold — jenerik sistem fontu gitti

### Diyaloglar doğallaştırıldı ("konuşmalar gerçekçi hissettirmiyor")
- Tüm MERKEZ replikleri kısa, telsiz-usulü cümlelere bölündü: çağrı tekrarı
  ("Hisar-yedi, Hisar-yedi"), teyit ("...Tamam, sinyalin geldi"), duraksamalar,
  yarım cümleler ("Dur— ...o mu?")
- Yalan anlarında CLAUDE.md §4.8 tell'leri: acele ettirme, konu kapatma ("Kayda geçme."),
  aşırı güven verme ("Manken o, manken.")

## 2026-07-06 (8) — Tempo yeniden yazıldı: her şey artık İLERLEMEYE bağlı; bug düzeltmeleri

### Tempo / oyun hissi (kullanıcı geri bildirimi: "her şey çok hızlı, zamana bağlı")
- **Açılış kartı**: siyah ekranda "HİSAR-7 — gece vardiyası 03:47" yavaşça belirir,
  ~10 sn'de sahneye açılır; MERKEZ ilk kez **14. sn'de** konuşur ("Acele yok, etrafı tanı"),
  ilk görevi **38. sn'de** verir
- **Zamanla tetiklenen her şey kaldırıldı** — yeni zincir tamamen ilerlemeye bağlı:
  şalter → turnike taraması → T-3 UYUMSUZ → anons + Yolcu → Yolcu kaybolur →
  MERKEZ sol uca yollar (B panosu bahanesi) → **karartma** → 15-20 sn sonra **telefon** →
  25 sn sonra **gölge figür silahlanır**
- Fısıltılar artık ancak anons olayından sonra başlar; ilk tren 110-170. sn'de geçer
- **Gölge figür** (CAUTION tarafındaki): TEST kalıntısı 10 sn'lik cooldown 300 sn yapıldı,
  koşulsuz tetikleyen T tuşu kaldırıldı, `enabled` bayrağı eklendi — telefon olayından önce hiç çıkmaz

### Karartma düzeltmesi ("ışıklar tek tek sönmüyordu")
- Sönme aralığı 0.34 → **0.55 sn**; her lamba sönerken **kendi konumundan röle "çat" sesi**
  geliyor (sentez; uzaktan yaklaşarak gelen tak... tak... tak hissi)
- Dalganın sonunda çukur/tünel/kafes lambaları da sönüyor → **gerçek zifiri karanlık**;
  ışıklar dönünce hepsi geri geliyor
- Karartma artık ancak görev 4'te (MERKEZ sol uca yolladığında) tetiklenebilir

### Tarama bug'ı düzeltildi ("turnikelerin hepsi NORMAL diyordu")
- Turnike kollarının görünmez çarpışma kutuları ışını yutuyordu → engellere `scan_ignore`
  işareti kondu, tarama ışını bunları atlayıp gerçek hedefe geçiyor
- Grup kontrolü artık üst düğümlerde de arıyor (GLB sahnelerinde collider çocukta kalıyor)

### Üst hol yeniden tasarımı (kullanıcı: "yanları boş, mantıken geçilir")
- **Gerçek turnike modeli**: subway_turnstile.glb, 5 ünite doğal ölçekte (T-1…T-5, T-3 anomali)
- **Yan bariyerler**: turnike sırasının iki yanı duvara kadar fırçalı çelik pano + küpeşte +
  dikmelerle kapatıldı — artık holün öbür yarısına sadece turnikelerden geçilebilir (kilitli)
- **Bilet makineleri**: japanese_parking_machine.glb ×2, batı duvarına yaslı

## 2026-07-06 (7) — BÜYÜK GENİŞLEME: üst hol, görev zinciri, yeni korku olayları

### Yeni mekân: Turnikeli Üst Hol (CLAUDE.md Bölüm 0/1 mekanı)
- Merdivenin üstündeki kör duvar açıldı → **17 × 12 m turnikeli hol** (z −10.6 … −22.5)
- **5 turnike** (T-1…T-5), geçiş kolları kilitli; **T-3 "anomaly" grubunda** — terminalle taranınca `UYUMSUZ` verir
- Kuzey duvarda **indirilmiş çelik kepenk** + üzerinde "ÇIKIŞ — İSTASYON KAPALI" yazısı + kırmızı acil lambası
  (çıkış görünür ama ulaşılamaz — oyuncuya "hapis" hissi)
- Loş aydınlatma: 3 tavan floresanı (biri ölü), yan duvarlarda tabelalar

### Görev zinciri (quest state machine, `_quest` 0→3)
1. **Şalter görevi** (mevcut) → MERKEZ artık **1.8 sn gecikmeyle** tepki verir ("yapıldığını fark etme" hissi)
2. MERKEZ yeni görev verir: *"Üst holdeki turnikeleri terminalle doğrula"*
3. **T-3 taraması** → MERKEZ'İN İLK YALANI: "Boşver onu, eski arıza." (CLAUDE.md §4.8 tell: acele ettirme)
4. 9 sn sonra **bozuk anons olayı**: hoparlörlerden pes perdeden fısıltı + "[ANONS] Bir sonraki tren: Hisar-yedi..." ×3
5. Anons sonrası **Yolcu belirir**: sol bankta oturan, nefes almayan siyah figür (wraith shader, solidity 0.86)
   - Taranırsa `OKUNAMIYOR` (kırmızı) + MERKEZ'in "manken" yalanı
   - 1.8 m'den fazla yaklaşınca **fısıltı patlamasıyla kaybolur**, MERKEZ inkâr eder ("Orada kimse yoktu.")

### Yeni korku olayları
- **Karartma (blackout)**: peronun sol ucuna gidince uzak uçtan **Close Door.wav** kapı çarpması,
  ardından peron lambaları **uzaktan yakına tek tek söner** (0.34 sn arayla), 3.5 sn zifiri karanlık,
  MERKEZ panikle döner, ışıklar geri gelir (120 sn bekleme süreli, tekrarlanabilir)
- **Telefon çalması**: 150–260 sn arasında ankesörlü telefon **kendi kendine çalar** (sentez 425 Hz zil);
  MERKEZ: "O hat on bir yıldır kesik."
- Fısıltılar ilk kez 35–80 sn içinde başlıyor (önceden 60–140)

### Altyazı sistemi yenilendi (kullanıcı geri bildirimi)
- Oyun tarzı **yarı saydam siyah panel** üzerinde 36 pt beyaz yazı, ekranın alt-ortasında
- Her replikte sentezlenmiş **anlaşılmaz telsiz mırıltısı** çalar (hece zarflı, bant sıkıştırmalı; [ANONS] için pes perde)

### Terminal
- Tarama sonuçlarına `OKUNAMIYOR` (unreadable) ve `UYUMSUZ` (anomaly) durumları + quest_mgr geri bildirimleri
- GÖREV sekmesi kaydırmalı log listesine dönüştü (`add_log`, son 7 satır)

## 2026-07-06 (6) — Oynanış başlangıcı: telsis + ilk görev; model düzeltmeleri

### Oynanış / hikâye (M0 dikey dilime doğru)
- **`scripts/radio.gd` — telsis sistemi**: MERKEZ'in replikleri ekran altında altyazıyla akar,
  her replik öncesi sentezlenmiş parazit çızırtısı; `say(speaker, text, dur)` kuyruk API'si (VO sonradan eklenebilir)
- **Açılış sekansı**: vardiya başlangıcında MERKEZ konuşur, ilk görevi verir ("A panosunun şalterini kaldır")
- **E-etkileşim sistemi**: `player.gd` ışın taramasıyla "interactable" grubunu bulur; ekranda "[E] ..." ipucu belirir
- **İlk görev**: PANO A kapağındaki kırmızı şalter — E ile kalkar, MERKEZ tepki verir,
  terminalin GÖREV sekmesine kayıt düşer (`terminal.add_log`) → görev döngüsünün ilk halkası çalışıyor
- Ses yerleşimleri: fısıltılar rastgele aralıklarla oyuncunun yakınından (60–140 sn), gerçek tren kaydı ray çukurundan geçiyor,
  Breath Swell gölge figüre bağlı

### Model düzeltmeleri (kullanıcı geri bildirimi)
- **ÇIKIŞ tabelası** → way_out.glb (ışıklı koşan-adam lightbox; yaw 180 ile ön yüz perona döndürüldü)
- **Saat** ters bakıyordu → yaw −90 (kadran perona döndü)
- **Posterler** "ters tablo" gibiydi → kâğıt + görsel alan + okunur başlık eklendi (SEFER SAATLERİ, GÜVENLİK HERKESİN İŞİDİR, ...)

### Sonraki hedefler
- Mekân genişletme (turnikeli üst hol → ara kat koridorları) — kullanıcı talebi
- Turnike görevi + ilk anomaliler (banktaki Yolcu), Dikkat metresinin oyuna bağlanması

## 2026-07-06 (6) — Siyah bulut figür, gerçek sesler, rigli saat

### Gölge figürü: siyah bulut + merdiven çıkışı
- Wraith shader'a **solidity** parametresi: gövde parçaları kesif simsiyah kütle (0.5–0.6), mavi kenar parıltısı figürde kısıldı
- Rota artık **merdivenden yukarı**: peron → merdiven dibi → 1. kol boyunca tırmanış → sahanlık karanlığında duraksayıp erime
- `_audio` düğümünün her karede yeniden yaratılmasına yol açan yerleşim hatası düzeltildi (dış düzenlemede `_update_puffs` içine kaymıştı)

### Kullanıcının ses paketleri entegre edildi
- **breath_swell.mp3** (Breath Swell 2): figür belirdiğinde çalan nefes kabarması (−7 dB, doğal pitch)
- **whispers.mp3** (gossip whispers): rastgele aralıklarla (60–140 sn) oyuncunun yakınında rastgele bir yönden, kayıttan rastgele bir dilim fısıltı çalar, 5–8 sn sonra sönerek kaybolur
- **train_real.mp3** (Train, 40 sn): sentezlenmiş hayalet trenin yerine gerçek kayıt; ray çukurunda yavaş süzülerek 3D pan yapar (sentez artık sadece dosya yoksa yedek)

### Saat + duvar temizliği
- Prosedürel bozuk saat yerine **basic_clock_rigged.glb**; ibreler kemik pozuyla **04:17'de donduruldu** (`_set_clock_time`)
- Karşı duvardaki **HİSAR-7 bantları/yazıları kaldırıldı**

## 2026-07-06 (5) — El terminali (TAB) + rigli el + gerçek cihaz modeli

### El terminali — CLAUDE.md §4.1 diegetic HUD (M0 dikey dilimin ilk parçası)
- **TAB**: kaldır/indir (yumuşak animasyon); kalkıkken **1-4** sekme değiştirir, **sol tık** tarama yapar
- 4 sekme: **OKUMA** (Basınç/Sıcaklık/Hat Gürültüsü — gürültülü, süzülen değerler; Hat Gürültüsü gerilim müziğinin enerjisiyle yükselir), **TARAMA** (ışın taraması: NORMAL / UYUMSUZ ("anomaly" grubu) / HEDEF YOK; batarya −%4, Dikkat +), **GÖREV** (vardiya log'u), **HAT** (telsis sinyali — üst koridor = ölü bölge)
- Ekran `SubViewport` (640×343) → cihaz mesh'ine salt-emissive doku; yeşil fosfor + CRT tarama çizgisi shader'ı
- Terminalin alt kenarında ince **Dikkat çubuğu** (taramayla dolar, zamanla söner; AwarenessManager öncüsü)
- Batarya: tarama başına −%4 + çok yavaş pasif tükenme; %25 altında amber uyarı

### Kullanıcı modelleri entegre edildi
- **handheld_terminal-thingy.glb** → cihaz gövdesi (askeri el terminali; ön yüz +Z, ~28 cm, doğal ölçek). Üst paneline SubViewport ekranı bindirildi; tuş takımı/LED şeridi baked halde kaldı
- **hand.glb** → Blender'da **3 kemikli rig** eklendi (forearm→palm→fingers, otomatik ağırlık) → `hand_rigged.glb`; `set_finger_curl()` ile kavrama çalışma zamanında ayarlanabilir
- ⚠️ **hand.glb SOL eldir** — sağ el görünümü için `hand_mirror` (X'te negatif ölçek) kullanılıyor; poz `hand_pos/hand_rot/hand_scale` değişkenleriyle ayarlanır
- Cihazın önünden taşan **işaret + orta parmak Blender'da mesh'ten silindi** (x 0.28–0.565, z<−0.45 vertex bölgesi + ayrı tırnak mesh'i); güdük kısımlar cihaz gövdesinin arkasında kalıyor

### Viewmodel cilası (kullanıcı geri bildirimi)
- Terminal indirikken artık **tamamen gizli** (TAB'a basmadan görünmüyor)
- Cihaz %15 küçültüldü ve ön yüzü kameraya çevrildi (−13° yaw — ekran artık sağa açılı değil)
- El cihazı **arkadan kavrıyor, parmaklar ön yüzde** (10 cm sola alındı); kol aşağı açılı (bilek kesiği görünmüyor)
- El + cihaz **gölge düşürmüyor** (viewmodel gölgesi kapatıldı)
- **İdle animasyonu**: nefes salınımı + organik mikro titreşim + kamera dönüşüne gecikmeli takip (sway)

### Gölge figürü insansılaştırıldı (kullanıcı geri bildirimi)
- Kapsül duman yerine **insansı silüet**: kafa + gövde + iki kol + iki bacak + dış duman örtüsü (hepsi wraith shader, boy ~2.1 m)
- Koşarken artık kaybolmuyor; yeni **duraksama + erime** evresi: merdiven ağzında ~0.9 sn durur (sanki bakar), sonra 1.5 sn'de yavaşça erir
- 2. tur geri bildirim: dış sis örtüsü şeffaflaştırıldı, koşu hızlandı,
  arkasında **duman izi** bırakıyor (0.07 sn'de bir doğan, büyüyüp yukarı süzülerek 0.9 sn'de sönen yarı-saydam kapsüller)
- 3. tur: **siyah bulut gövde** (wraith shader'a `solidity` parametresi — gövde parçaları kesif simsiyah, mavi kenar parıltısı kısıldı)
  ve rota artık **merdivenden yukarı**: peron → merdiven dibi → 1. kol → sahanlık karanlığı; duraksama+erime sahanlıkta
- Figür sesi: **Breath Swell 2** (kullanıcının dosyası, `assets/audio/breath_swell.mp3`) — 10 sn nefes kabarması,
  figür kaybolduktan sonra da duyulmaya devam eder
- Terminal indirme "pop" düzeltmesi: POS_DOWN ekranın iyice altına taşındı, gizlenme eşiği 0.015'e düşürüldü — önce tamamen ekrandan çıkıyor, sonra gizleniyor

## 2026-07-06 (4) — Gerilim kararması + telefon & otomat + hayalet tren

### Ses-reaktif ekran kararması
- Gerilim müziği (tension.mp3) artık kendi **"Tension" ses bus'ında**; spektrum analizörü anlık enerjisini ölçer
- Müzik yoğunlaştıkça **ekran kenarları yavaşça kararır** (`post_grade.gdshader` yeni `tension_dark` uniform'u), ses kesilince biraz daha hızlı açılır
- Kalibrasyon gerçek ölçümle yapıldı: bant 30–2600 Hz, eşikler −46/−37 dB (sakin drone'da ~0, tepe/kesilme anlarında tam kararma)

### Yeni modeller (kullanıcının indirdikleri)
- **korean_payphone.glb** — sol duvarda (x=−12.55), gerçek ölçek (74 cm), duvara monte
- **realistic_vending_machine__3d_model.glb** — poster ile bank arasında (x=6.8), sırtı duvara sıfır;
  AABB derinliği gerçekçi makine derinliğine z-sıkıştırıldı (%72), çarpışma kutusu + soğuk iç aydınlatma eklendi

### Uzak hayalet tren
- Kod içinde sentezlenir (`_make_train`): kahverengi gürültü rumble + ~1.3 Hz ray klakları, 22 sn gel-geç zarfı
- Arka plan iş parçacığında üretilir (açılışta takılma yok); ilk geçiş 25–60 sn içinde, sonra 70–160 sn rastgele aralıklarla
- `AudioStreamPlayer3D` ray çukurunda bir uçtan diğerine hareket eder — gerçek 3D pan ile yaklaşıp uzaklaşır; tren asla görünmez

## 2026-07-06 (3) — ESC duraklatma menüsü

- **`scripts/pause_menu.gd`**: ESC ile açılan duraklatma menüsü (oyun `get_tree().paused` ile durur, fare serbest kalır)
- Ayarlar: **Tam ekran**, **VSync**, **Fare hassasiyeti** (%20–%300), **Görüş alanı / FOV** (60–90°), **Ana ses** (%0–%100)
- Butonlar: Devam Et / Varsayılanlara Dön / Oyundan Çık
- Ayarlar anında uygulanır ve **`user://settings.cfg`**'ye kaydedilir; açılışta otomatik geri yüklenir
- `player.gd`: `sens_mult` + `base_fov` değişkenleri eklendi (menü kontrol eder); ESC işleme oyuncudan menüye taşındı
- Görsel dil: koyu endüstriyel panel + fosfor yeşili vurgu (terminal estetiğiyle uyumlu)

## 2026-07-06 (2) — Uyarı tabelaları (ambientCG, CC0)

- **4 fotorealistik uyarı tabelası** eklendi (`assets/models/signs/`): ambientCG'nin
  CC0 PBR doku setleri (Color+Opacity birleşik RGBA PNG + NormalGL + Roughness).
  Geometri `main.gd::_wall_sign()` içinde alfa-kesmeli (alpha scissor) quad olarak kurulur.
- Yerleşimler:
  - **Sign009 — yüksek gerilim**: PANO A (box-01) kapağında, DANGER çıkartmasının solunda
  - **Sign005 — kaygan zemin**: merdiven ağzının sağındaki duvarda (ıslak zemin temasını destekler)
  - **Sign002 — genel tehlike**: peron uçlarında, tünel ağızlarına yakın (x = ±14.3)
  - **Sign021 — paslı kırmızı ünlem**: karşı duvarda, tünel ağzına doğru (yasak bölge hissi)
- Not: tabela malzemesi mat (metallic 0) — parlak emaye, duvar lambalarının
  spekülerinde beyaz patlıyordu.

## 2026-07-06 — İlk sürüm: Hisar-7 Üst Peron ortamı

### Ortam
- **Metro peronu** (30 m): ray çukuru, raylar + traversler, iki uçta karanlık tünel ağızları, fayanslı kolonlar, sarı peron kenar bandı + beyaz çizgi
- **Merdiven kovası**: 8 basamaklı alt kol → düzlük → 12 basamaklı üst kol (karanlığa çıkar); köşe pilasterleri, duvara ankrajlı çift metal korkuluklar, düz-ferah iki kademeli tavan
- Karşı duvarda **HİSAR-7** istasyon tabelaları, "SARI ÇİZGİYİ GEÇMEYİNİZ" yazısı, ÇIKIŞ tabelası
- Tamamı **prosedürel malzeme**: triplanar fayans (karo başına mikro eğim/varyasyon), püskürtme sıva, granit basamak, kabartmalı sarı bant; düz malzemelerde prosedürel normal map detayı

### Modeller
- **Poly Haven (CC0)**: modüler sokak oturağı (bank), ıslak zemin uyarı tabelası, varil, karton koliler, paslı teneke, kafesli endüstriyel lamba
- **electrical_boxes.glb** (Sketchfab kiti): modular-box-01 ana sigorta panosu (PANO A — oyunun ilk görev nesnesi), buat + orta kutu servis kümesi
- **pipe_set.glb** (Sketchfab kiti): tavan boruları — segmentler uniform ölçekle uç uca döşenir (esnetme yok), vanalı parçalar serpiştirilmiş
- **weathered_fluorescent_lightlamp.glb**: tüm floresan armatürler

### Işık / Görüntü
- SDFGI + SSR + SSAO + SSIL + volumetrik sis, AgX tonemap, soğuk teal grade
- 7'li peron floresan sırası: biri ölü, biri titrek; sahanlık lambası bozuk (flicker + dropout sistemi)
- Post-process: film grain (gölge ağırlıklı), vinyet, kromatik aberasyon, dönüşe bağlı yönlü motion blur

### Ses
- Ana gerilim: **"Unseen Horrors" — Kevin MacLeod (incompetech.com), CC-BY 4.0**
- Bölge tetikli sting: **"Horror Ambient" — Vinrax (opengameart.org), CC-BY 3.0**
- Tünel uğultusu: **"Dark Ambience Loop" — Iwan Gabovitch (opengameart.org), CC-BY 3.0**
- Floresan cızırtısı kodda sentezlenir (100 Hz şebeke + çıtırtı), konumsal; ışıkla birlikte bozulur
- Tetik bölgeleri: üst merdiven karanlığı, tünel ağızları, düzlük

### Oynanış
- FPS kontrol: WASD + fare, Shift koşu, **F el feneri** (gecikmeli takip), **sağ tık dijital zoom** (1.6x, temiz)
- Hafif baş sallanması (koşuda artar) + hafif kamera yatışı
- **Siluet korkutmacası**: peron ucunda arkanı dönünce merdivene süzülen dumansı karaltı (wraith shader — fresnel kenar erimesi, yırtık duman dokusu); T tuşu test tetikleyicisi (yayında kaldırılacak), soğutma 10 sn (yayında 300)

### Bilinen eksikler / sonraki adımlar
- Siluet için Sketchfab'den gerçek hayalet modeli entegre edilecek (shader karaltı beğenilmedi)
- El terminali (Tab), turnikeli üst hol, ıslak zemin yansımaları planlı

### Lisans / Atıf (yayında credits'e girecek)
- "Unseen Horrors" Kevin MacLeod (incompetech.com) — CC BY 4.0
- "Horror Ambient" — Vinrax — CC BY 3.0
- "Dark Ambience Loop" — Iwan Gabovitch (qubodup) — CC BY 3.0
- Poly Haven modelleri — CC0
- Sketchfab kitleri (electrical_boxes, pipe_set) — indirildiği sayfalardaki CC lisans şartlarına tabi
