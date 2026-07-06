# CLAUDE.md — SON SEFER

> **Çalışma Başlığı:** SON SEFER (alternatifler: *Hat Dışı*, *Karahat*, *Aşağıdaki*)
> **Tür:** First-person psychological horror / anomali-teşhis (walking-sim-plus)
> **Motor:** Godot 4.x (3D, forward+)
> **Hedef Platform:** Steam (PC), tek oyunculu
> **Referanslar:** The Exit 8, Observation, Stories Untold, Papers Please, Signalis, The Exit 8'in "yorumla ve karar ver" damarı + Observation'ın "makine gözünden" gerilimi
> **Tahmini Oyun Süresi:** 2.5–3 saat (bir "true ending" run'ı), tekrar oynanabilirlik: farklı sonlar + kaçırılan lore
> **Ton:** Soğuk, endüstriyel, yavaş yanan gerilim. Jump-scare minimum; "yanlış olan bir şey var" hissi maksimum.

---

## 0. TEK CÜMLELİK PITCH

Kapalı bir yeraltı metro istasyonunda gece vardiyasına çağrılan bir bakım teknisyenisin; telsizden sana görev veren "Merkez" ile elindeki teşhis terminali zamanla birbirini yalanlamaya başlar ve sen istasyonu tamir mi ettiğini, yoksa aşağıda bir şeyi serbest mi bıraktığını çözmeye çalışırken kime güveneceğine karar vermek zorunda kalırsın.

**Çekirdek gerilim (oyunun tamamı bunun üzerine kurulu):**
> Sana yol gösteren SES (telsis) ile sana gerçeği gösteren VERİ (terminal) çelişince, kime inanacaksın?

Bu tek soru; anomalileri, seçimleri, kaynak yönetimini ve üç sonu birbirine bağlayan omurgadır. Bir mekanik veya sahne bu soruya hizmet etmiyorsa **kesilir** (bkz. Scope Lock).

---

## 1. TASARIM PRENSİPLERİ (ihlal edilemez)

1. **Düşman yok, tehdit her yerde.** Oyuncuyu kovalayan bir yaratık, bir savaş, bir "koş" anı yok. Tehdit; belirsizlik, sosyal baskı (Merkez'in sesi) ve "fark edilme" korkusudur.
2. **İki güvenilmez otorite — DENGEDE.** Ne telsize ne terminale %100 güvenilir; **hiçbiri baskın çıpa değildir.** Ama denge *statik 50/50 gürültü* değildir (o gerilim değil, sinir bozukluğu üretir). Denge şöyle çalışır: her ikisi de güvenilmez ama **aynı anda değil, öğrenilebilir "tell"lerle** (bkz. §4.8). Oyuncunun güvenebileceği tek gerçek çıpa üçüncü şeydir: **kendi gözlemi.** Oyunun öğrettiği ders budur.
3. **Checklist değil, sezgi.** Anomali tespiti asla "şu 5 şeyi kontrol et" değildir. Olasılıksal, bağlamsal, öğrenilen bir histir. (Detay: §5)
4. **Her seçimin bir bedeli var.** "Güvenli" seçim çoğu zaman daha az bilgi verir; "riskli" seçim daha çok gerçek ama daha çok Dikkat. Push-your-luck ruhu (senin imzan).
5. **Diegetic her şey.** UI, ses, ölüm, menü — hepsi kurgunun içinde. Terminal ekranı = oyuncu HUD'u. Telsis parazidi = müzik. Sanity düşüşü = UI'ın kendisinin bozulması.
6. **Sessizlik en güçlü ses.** Telsis kesildiğinde, müzik durduğunda oyuncu en çok gerilir. Sessizliği bir kaynak gibi kullan.
7. **Tekrar değil, derinleşme.** Oyun bir döngü anlatısı ama oyuncuyu aynı koridorda 5 kez yürütmez. Aynı mekân **her inişte anlam değiştirir.**

---

## 2. SENARYO — TAM METİN (spoiler dahil, oyuncuya asla böyle anlatılmaz)

### 2.1 Kurgusal evren / "gerçek"

**Karahat'ın en derin istasyonu** olan **Hisar-7** (halk arasında "Kuyu"), yıllar önce bir "iş kazası" gerekçesiyle kapatıldı. Resmî kayıtlarda: zemin oturması, su baskını, tahliye. Gerçekte: istasyonun en alt peronunun altında bir **Yarık** açıldı — ne olduğu asla tam açıklanmayan, mekânı ve zamanı "yanlışlaştıran" bir şey. İçinden gelen etkiye içerideki personel **"Aşağıdaki"** adını verdi.

Yarık yok edilemedi; sadece **bastırıldı**. Bastırma bir cihazla değil, bir **ritüelle** yapılıyor: istasyonun elektromekanik sistemleri (sinyalizasyon, havalandırma, sigorta panoları) belirli bir düzende "akort edilirse" Yarık'ın etkisi yüzeye çıkmıyor. Ama akort kendi kendine bozuluyor. Ve akordu koruyan bir şey daha gerekiyor: **aşağıda kalan bir insan.** Bir bekçi.

Bekçi ölmez, gitmez — **istasyonun bir parçası** olur. Sesi telsize karışır. Zamanla yeni gelenlere "Merkez" olarak seslenir. Çünkü bekçinin tek kaçış yolu vardır: **yerine birini geçirmek.**

### 2.2 Döngü

Her birkaç yılda bir, "acil bakım" bahanesiyle bir teknisyen çağrılır. Telsizdeki ses ("Merkez") ona rutin bir vardiya gibi görevler verir: şalteri sıfırla, havalandırmayı dengele, alt perondaki panoyu ayarla. Teknisyen bunları yaptıkça **ritüeli yeniden akort eder.** Vardiyanın sonunda, farkında olmadan **kendini bekçi olarak bağlar** — ve bir önceki bekçi (yani telsizdeki ses) serbest kalır, "yukarı çıkar", gider.

Telsizdeki ses bu yüzden **yalan söylemek zorundadır.** Sana yardım ediyormuş gibi yapar ama asıl derdi kurtulmaktır. Sen ne kadar itaat edersen, o kadar özgürlüğe yaklaşır. Ne kadar sorgularsan, o kadar paniklersin — ve o kadar tehlikeli olursun (Aşağıdaki'nin dikkatini çekersin).

### 2.3 Oyuncu kim?

Oyuncu: **kod adı belirtilmeyen bir gece vardiyası teknisyeni.** Adı hiç söylenmez (oyuncu boşluğu doldurur). Ama oyun ilerledikçe ipuçları verir: oyuncunun buraya gelmesi tesadüf değil. **Sen zaten bir kez buradaydın.** Küçük detaylar (önceki bekçinin eşyaları arasında SENİN el yazın, terminalinde SENİN eski log'ların) döngünün oyuncuya özgü olmadığını, oyuncunun da döngüde olduğunu ima eder. Bu, ikinci playthrough'da yeniden okununca anlam kazanan bir katmandır.

### 2.4 Karakterler

**MERKEZ (telsizdeki ses).**
- Başta: sıcak, biraz yorgun, tecrübeli bir amir. "Kolay gelsin evladım." Rehber, güven veren.
- Ortada: talepkâr, aceleci. Sen sorgulamaya başlayınca savunmaya geçer. "Boşver onu, işine bak."
- Sonda: yalvaran, sonra tehdit eden, sonra çaresiz. Gerçek adı geç açıklanır: **Cavit.** 11 yıl önce çağrılan bir teknisyen. O da yerine birini geçirmeye çalışıyor. Onun trajedisi: seni kurtaramaz çünkü tek kurtuluşu sensin.
- **Merkez asla açıkça kötü değildir.** Oyuncu ona kızabilmeli ama acıyabilmeli de. En iyi horror, düşmanının haklı olabileceğidir.

**EDA (kayıtlardaki ses / gerçek yol).**
- Cavit'ten önceki döngüde bir **dispatcher stajyeri.** Ritüelin farkına vardı, döngüyü kırmaya çalıştı, başaramadı ama **bir iz bıraktı**: istasyonun içine saklanmış ses kayıtları, notlar, işaretler.
- Oyuncuya "üçüncü yolu" veren tek kaynak Eda'dır. Sesi sakin, kararlı, biraz kırık. Merkez'in aksine sana **görev vermez**, sadece **gerçeği fısıldar.**
- Eda'nın izini takip etmek push-your-luck gerektirir: kayıtlar riskli yerlerde, ana yoldan sapmayı ister. (True ending'in anahtarı budur.)

**YOLCULAR (anomali figürleri).**
- Peronlarda beliren, orijinal kazada ölenlerin ekoları. Düşman değil. Sana saldırmazlar. Sadece **oradalar** — nefes almadan otururlar, yanlış yöne bakarlar, sen baktığında dururlar.
- Onlara nasıl davrandığın (raporla / yok say / yaklaş) hem Dikkat'i hem lore'u hem de bazı seçim dallarını etkiler.

**AŞAĞIDAKİ (Yarık).**
- Asla tam gösterilmez. Bir yüz, bir yaratık değil. Bir **basınç**, bir **ses altı titreşim**, ışıkların "yanlış" davranması, terminalin okuyamadığı bir değer. Dikkat metresi dolunca "uyanır" ve vardiya kâbusa döner.
- Kural: **Aşağıdaki'yi göstermek onu zayıflatır.** Ne kadar az görürsen o kadar korkutucu. Sadece imalar, gölgeler, veri glitch'leri.

---

## 3. YAPI — 5 BÖLÜM (BİR GECE, GİDEREK DERİNLEŞEN İNİŞ)

Oyun **tek bir gece** boyunca geçer ve **giderek aşağı iner.** Her bölüm bir kat aşağıdır; her kat daha "yanlıştır". Döngü teması, tekrar eden koridorlarla değil, **aynı mekânın anlam değiştirmesiyle** ve backstory ile anlatılır.

| Bölüm | Mekân | Süre | İşlev |
|-------|-------|------|-------|
| **0 — İniş** | Servis asansörü, üst hol | ~10 dk | Tutorial, "normal"i kur |
| **1 — Üst Peron** | Ana peron, turnikeler | ~30 dk | İlk anomaliler, güven tam |
| **2 — Ara Kat** | Teknik koridorlar, pano odaları | ~40 dk | Telsis ≠ Terminal ayrışması başlar |
| **3 — Alt Peron** | Terk edilmiş derin peron | ~40 dk | Gerçek açığa çıkar, Merkez maskesi düşer |
| **4 — Yarık** | Mühür odası / son | ~30 dk | Üç son burada ayrışır |

Toplam: ~2.5 saat "düz" oynanış; keşif + lore ile 3 saat+.

### 3.1 RİTİM HARİTASI — "Nefes Alan" Yapı (KİLİTLİ)
> Karar: 2.5-3 saat, sürekli tavan gerilim DEĞİL — **peak/valley** ritmi. Kesintisiz gerilim körelir; asıl korku, güvenli andan sonra gelen düşüştedir. Her tepe bir vadiden sonra daha sert vurur.

**Ritim eğrisi (her bölümde tepe-vadi dönüşümlü):**
- **Tepe (tension):** anomali kümesi, telsis-terminal çelişkisi, dead zone sessizliği, ana seçim.
- **Vadi (breath):** ışıklı **güvenli oda** (bekçi kulübesi, şarj istasyonu, mola noktası), Merkez'le sakin diyalog, lore okuma/kayıt dinleme, terminal bakımı. Burada Dikkat düşer, oyuncu "toparlanır".
- **Kritik kural:** Her büyük tepe sahnesinden **hemen önce** kısa bir vadi olmalı ki oyuncu rahatlamışken vurulsun. En büyük korku, "güvendeyim sanırken"dir.
- **Yanıltıcı sükunet (Bölüm 2 sonu / 3 başı):** Uzunca bir sakin an — oyuncu "en kötüsü bitti mi?" der. Değildir. Bu, 2.5 saatlik yapının duygusal bel kemiği.

**Süre dağılımı (yaklaşık):** her bölümde ~%60 keşif/vadi + %40 tepe. Bu, "nefes alan" his verirken toplam süreyi 2.5-3 saatte tutar. Boşluk = ölü zaman değil, **gerilim için yay germe.**

**Pacing tuzağı (kaçın):** Vadiler "yürüyüş dolgusu" olmamalı. Her vadi ya lore verir, ya kaynak yönetimi sunar, ya da bir sonraki tepeyi kurar. Amaçsız uzun koridor = kes.

---

### BÖLÜM 0 — İNİŞ (Prologue / Tutorial)

**Amaç:** Kontrolleri, terminali, telsizi öğret. "Normal" bir referans yarat ki sonra bozulunca hissedilsin.

**Akış:**
1. Oyun servis asansöründe başlar. Kapı kapalı. Telsis cızırdar, **Merkez** konuşur: kendini tanıtır, oyuncuya "yeni misin, sorun değil, ben yönlendiririm" der. **(Tutorial telsisten diegetic veriliyor.)**
2. Terminal eline verilir (envanterde otomatik). Merkez terminali açtırır: `Basınç`, `Sıcaklık`, `Hat Gürültüsü` okumalarını gösterir. Hepsi yeşil/normal.
3. Asansör iner (uzun, sesli, gerilimli iniş — burada oyuncuya "aşağı gidiyoruz" hissi ekilir). Kapı açılır.
4. Üst hole çık. Merkez ilk görevi verir: "Turnikelerin yanındaki sigorta panosunu aç, A hattı şalterini kaldır." **Tek düğme etkileşimi tutorial'ı.**
5. Şalteri kaldırınca ışıklar yanar. Merkez: "Aferin. Görüyorsun, kolay." — güven inşası.
6. **İlk mikro-anomali (zararsız):** Holdeki bir yönlendirme tabelası bir an "ÇIKIŞ" yerine başka bir şey gösterir, sonra düzelir. Merkez bir şey demez. Oyuncu görürse görür, görmezse görmez. **Bu, "dikkat et" öğretisidir** — ama zorla değil.

**Öğretilen mekanikler:** hareket, etkileşim (E), terminal aç/kapa (Tab), telsize cevap (Q ile diyalog), basit obje kullanımı.

**Bölüm sonu kancası:** Merkez "Şimdi peron katına in, orada asıl işimiz var" der. Merdiven/asansör → Bölüm 1.

---

### BÖLÜM 1 — ÜST PERON (Güven Dönemi)

**Amaç:** Çekirdek döngüyü tam öğret (görev al → yap → anomali fark et → tepki ver). Farkındalık metresini tanıt. İlk gerçek seçim. Merkez hâlâ güvenilir görünür.

**Ortam:** İşleyen ama bomboş bir metro peronu. Işıklar çalışıyor. Arada bir "hayalet tren" anonsları. Duvarda eski afişler, bozuk saat panosu.

**Görevler (Merkez verir):**
1. **Turnike sıfırlama:** 3 turnikeden sinyal alınamıyor, terminalle her birini "doğrula" (verify), sıfırla.
2. **Anons sistemi kontrolü:** Peron hoparlöründen test anonsu çal. → Anons çalınca **yanlış istasyon adını** söyler ("Bir sonraki durak: Hisar-7... Hisar-7... Hisar-7"). Merkez: "Ee, kayıt eski, aldırma."
3. **Peron sonundaki kamerayı yeniden başlat.**

**İlk gerçek anomaliler (Bölüm 1'de 2-3 tane, hafif):**
- **Bir Yolcu:** Bankta oturan bir figür. Yaklaşınca nefes almadığı fark edilir. Terminalle taranırsa: `Sıcaklık: —` (okuma yok). Kaybolmaz, sadece orada.
- **Yanlış tabela:** B hattı tabelası boş tünele işaret ediyor.
- **Ters yansıma:** Cam bir yüzeyde oyuncunun yansıması bir saniye gecikmeli hareket eder (opsiyonel, dikkatli oyuncu için).

**İLK SEÇİM (küçük ama dallanmayı başlatır):**
Bankta oturan Yolcu'yu terminalle tararsın. Merkez telsizden: "O bir eski manken, aldırma, işine bak."
- **A) Merkez'e uy, geç git.** → Dikkat +0. Ama Yolcu, sen sırtını dönünce **yer değiştirir** (arkanda başka bankta). Küçük tedirginlik.
- **B) Yaklaş ve incele.** → Dikkat +1. Yolcu'nun elinde eski bir personel kartı: **"E. — Dispatcher Stajyeri"** (Eda'nın ilk izi). Lore kazanılır. `flag: eda_iz_1 = true`
- **C) Merkez'e itiraz et** ("Bu manken değil, tarama boş dönüyor"). → Merkez bir an susar. "...Sen işine bak." Diyalog: Merkez'e olan `güven` sayacı -1. İlk çatlak.

**Eda'nın ilk kaydı (opsiyonel keşif):** Peron sonundaki kilitli olmayan bir personel dolabında bir eski ses kayıt cihazı. Çalınırsa Eda'nın sesi: *"...eğer bunu dinliyorsan, sana verdikleri görev listesini olduğu gibi yapma. Sırasına dikkat et. Sıra önemli..."* → `flag: eda_iz_1 = true` (kartla aynı flag'i de tetikleyebilir, ya da ayrı sayaç).

**Farkındalık (Dikkat) metresi tanıtımı:** Terminalin köşesinde ince bir çubuk. Anomaliye uzun bakınca, izinsiz kapı açınca, fazla tarayınca dolar. Bu bölümde asla tehlikeli seviyeye ulaşmaz (öğretici). Merkez bir yerde açıklar: "O çubuk mu? Hatın gürültüsü. Yükselirse bir mola ver, kendine gel." (Yalan/eksik açıklama — aslında Aşağıdaki'nin dikkati.)

**Bölüm sonu:** Merkez son görevi verir: "Alt katlara inmemiz lazım, ama önce ara kattaki ana panoyu ayarlaman gerek." → Ara Kata iniş.

---

### BÖLÜM 2 — ARA KAT (Ayrışma Dönemi)

**Amaç:** Çekirdek gerilimi devreye sok — **telsis ile terminal çelişmeye başlar.** İlk büyük dallanan seçim. Önceki teknisyenin (Cavit'in) izleri. Sessizlik/parazit gerilimi.

**Ortam:** Dar teknik koridorlar, kablo yatakları, pano odaları, havalandırma şaftları. Işıklar titrek, floresan uğultusu. Telsis burada **ilk kez kesilmeye** başlar ("dead zone"lar).

**Ana görev (Merkez):** "Ara kattaki üç panoyu belli bir sırayla aç ki alt katın gücü gelsin." Merkez bir sıra verir: **1-3-2.**

**ÇEKİRDEK ÇATIŞMA BURADA BAŞLAR:**
- Terminalle panoları taradığında, ekranda bir uyarı: `SIRA UYUMSUZ — önerilen: 2-1-3`.
- Eda'nın kaydı (bulunduysa) da "sıra önemli" demişti.
- **Merkez 1-3-2 diyor. Terminal (ve Eda) 2-1-3 diyor.**

**İKİNCİ BÜYÜK SEÇİM (branching'in gerçek başlangıcı):**
- **A) Merkez'in sırasını uygula (1-3-2).** → Alt kata "temiz" güç gelir ama bir havalandırma kapısı **kapanır** (Merkez'in istediği). Ritüel akordu ilerler. `flag: ritual_ilerleme +1`. Merkez memnun. Dikkat düşük kalır. → **Ending A'ya (Devir) doğru ağırlık.**
- **B) Terminalin sırasını uygula (2-1-3).** → Güç gelir ama "yanlış" bir kapı **açık kalır**; oradan soğuk bir hava ve uzak bir ses gelir. Merkez sinirlenir: "Ne yaptın sen? O kapıyı kim açtı?" Dikkat +2. Ama yeni bir alan açılır: içeride Cavit'in eşyaları + Eda'nın 2. kaydı. `flag: gercek_yolu +1`, `guven(Merkez) -2`. → **Ending C'ye (Kapanış) doğru ağırlık.**
- **C) Merkez'e sırayı sor / sorgula** ("Terminal başka sıra diyor, neden?"). → Merkez savunmaya geçer, ikna etmeye çalışır. Diyalog ağacı: ısrar edersen B'ye yakınsar, kabul edersen A'ya. Karakter derinliği.

**Cavit'in odası (B seçilirse veya keşifle ulaşılırsa):**
- Bir bekçi kulübesi/dinlenme odası. Eski bir yatak, duvarda çetele (kaç gün? çok fazla). Bir defter — **Cavit'in notları**, giderek bozulan el yazısıyla: ilk sayfalar profesyonel, son sayfalar "yerime biri gelmeli, gelmeli, gelmeli."
- **Kritik detay:** Defterin bir sayfasında **oyuncunun kendi el yazısı** vardır (aynı fontla, "ben de aynısını yazmıştım" hissi). İnce, açıklanmayan bir ipucu → oyuncunun döngüde olduğu ima. `flag: sen_de_dongudesin_ipucu = true` (2. playthrough payoff).

**Anomaliler (Bölüm 2, orta yoğunluk):**
- Koridor kendini tekrar eder (aynı koridoru iki kez yürürsün, ikincisinde küçük bir fark — bir kapı numarası değişmiş).
- Terminal bazen **sana yalan söyler** (ilk kez): normal bir şeyi "anomali" gösterir ya da tersi. Bu, "terminale de körü körüne güvenme" öğretisidir. **Her iki otorite de artık şüpheli.**
- Havalandırmadan gelen ses: uzak bir insan sesi mi, metal mi? (belirsiz bırak)

**Sessizlik kancası:** Bir dead zone'da telsis tamamen kesilir. Merkez yok. Müzik yok. Sadece sen ve uğultu. Bu 60-90 saniye, oyunun en gergin anlarından biri olmalı. Merkez geri geldiğinde oyuncu rahatlar — ve bu rahatlama, Merkez'e duygusal bağ kurdurur (manipülasyonun mekaniği).

**Bölüm sonu:** Güç geldi. Merkez: "Artık alt perona inebiliriz. Orası... orada dikkatli ol." İlk kez Merkez **tedirgin** duyulur.

---

### BÖLÜM 3 — ALT PERON (Maske Düşüyor)

**Amaç:** Gerçeği açığa çıkar. Merkez'in ne olduğunu oyuncu (ve karakter) anlar. Aşağıdaki'nin varlığı hissedilir. Ending'i belirleyen ANA seçim burada.

**Ortam:** Terk edilmiş, sular altında kalmış hissi veren derin peron. Elektrik güvenilmez. Yolcular burada daha çok, daha rahatsız edici. Zaman "kayar" (saat panoları çelişir, kendi terminalinin saati atlar).

**Akış:**
1. Merkez rutin görev verir gibi yapar: "Peronun sonundaki ana mühür panosunu ayarla." Ama artık dili değişmiştir — daha aceleci, daha "lütfen".
2. Eda'nın 3. kaydı (bu bölümde ana yol üzerinde ama biraz sapmalı): **Ritüelin ne olduğunu açık açık anlatır.** "Sana yaptırdıkları bakım değil. Mühürü sıkıyorsun. Ve mühürün son parçası... bir insan. Sen. Panoyu ayarlarsan, aşağıda kalırsın. O zaman o çıkar."
3. **Merkez'in gerçek adı açığa çıkar:** Bir eski personel kaydında, terminalde, "Bekçi: CAVİT [tarih, 11 yıl önce]". Oyuncu telsizle konuştuğu sesin Cavit olduğunu anlar. Merkez itiraf eder (oyuncu yüzleştirirse): "Evet. Ben de senin gibi geldim. Bana da böyle söylediler. 11 yıl. 11 yıl buradayım. Lütfen. Sadece bir kere daha panoyu ayarla, hepsi bitecek."

**ANA SEÇİM (Ending trajektörisini kilitler):**
Alt peronun sonunda **Mühür Panosu** var. Yanında Eda'nın bıraktığı **elle yazılmış bir alternatif şema.** Ve telsizde Cavit yalvarıyor.

- **SEÇİM A — Panoyu Merkez'in dediği gibi ayarla.**
  - Ritüel tamamlanmaya çok yaklaşır. Cavit rahatlar, minnettar olur.
  - `flag: son_A_yolu = true`. → **Ending A (Devir)** kilitlenir (Bölüm 4'te finalize).
- **SEÇİM B — Panoyu tamamen kapat / mühürü kır.**
  - Aşağıdaki'nin basıncı fırlar. Dikkat maksimuma yakın. Cavit panikler.
  - `flag: son_B_yolu = true`. → **Ending B (Yarık)** kilitlenir.
- **SEÇİM C — Eda'nın alternatif şemasını uygula.** (Yalnızca `eda_iz` sayacı ≥ eşik ise seçenek görünür — yani lore topladıysan.)
  - Ne mühürü sıkarsın ne kırarsın; **döngünün başlangıç akordunu geri alırsın.** Cavit ne olduğunu anlamaz, korkar ama... umutlanır.
  - `flag: son_C_yolu = true`. → **Ending C (Kapanış)** kilitlenir.

> **Erişilebilirlik/adalet kuralı:** C seçeneği yalnızca oyuncu yeterince keşif yaptıysa (Eda izleri) açılır. Bu, "true ending"i kazanılmış hissettirir. Ama oyuncu C'yi hiç görmese bile A ve B tatmin edici, kapalı sonlardır — kimse "eksik oyun oynadım" hissetmemeli.

**Bölüm sonu:** Seçime göre istasyon tepki verir (ışıklar, ses, basınç). Merkez'in tonu seçime göre kökten değişir. Son inişe (Yarık odası) geçilir.

---

### BÖLÜM 4 — YARIK (Finale / Üç Son)

**Amaç:** Seçimleri kapat. Duygusal doruk. Her son ayrı bir "his" bırakmalı.

Oyuncu Bölüm 3'teki ana seçime göre farklı bir final sekansı yaşar. Ortak: en dibe, mühür/Yarık odasına iniş. Ama ne gördüğün ve ne yaptığın değişir.

---

#### ENDING A — "DEVİR" (İtaat / Buruk son)
- Oyuncu son ayarlamayı yapar. Işıklar sabitlenir, istasyon "sakinleşir".
- Cavit'in sesi son kez: minnet, özür, veda. "Teşekkür ederim. Gerçekten. Üzgünüm." Telsizde uzaklaşan ayak sesleri, bir asansör, bir kapı — Cavit **yukarı çıkar, özgür.**
- Kamera oyuncuda kalır. Oyuncu artık aşağıdadır. Ekran kararırken telsis cızırdar ve **oyuncunun kendi sesi** yeni gelen birine seslenir: "Alo? Beni duyuyor musun? Merak etme, ben yönlendiririm." **Döngü devam eder. Sen artık Merkez'sin.**
- **His:** Buruk, kaçınılmaz, sessiz trajedi. Kötü son değil — *anlaşılır* bir son.

#### ENDING B — "YARIK" (İsyan / Karanlık son)
- Mühür kırılır. Aşağıdaki serbest kalır — ama **asla tam gösterilmez.** Işıklar teker teker söner, terminal veri veremez hale gelir (`ERROR / ERROR / ERROR`), telsis çığlığa dönüşen bir parazitle biter.
- Cavit: dehşet, sonra sessizlik. "Ne yaptın... ne yaptın sen..."
- Belirsiz bir aydınlanma (beyaz? yeni bir sabah? yoksa Aşağıdaki'nin içi mi?). Oyuncu artık serbest ama istasyonun — belki şehrin — ne olduğu meçhul.
- **His:** Kişisel özgürlük vs. bilinmeyen bedel. Rahatsız edici, açık uçlu.

#### ENDING C — "KAPANIŞ" (Gerçek son / Kazanılmış umut)
- Eda'nın şemasıyla oyuncu döngünün **başlangıç akordunu** geri alır. Bu ne mühürü besler ne kırar — **çağrıyı iptal eder.** İstasyon "artık kimseyi çağırmayacak."
- Aşağıdaki geri çekilir (yok olmaz — geri çekilir; kötülük yenilmez, kapatılır). Cavit'in bağı çözülür: 11 yıllık ses, ilk kez **gerçekten** sakin. "Bu... bu muydu? Bunca zaman... teşekkür ederim." Cavit gider — ama bu sefer sen de gidebilirsin.
- Eda'nın son kaydı: kısa, sakin. Bir teşekkür değil, bir **devir teslim**: "Sıra sende değil artık. Kimsede değil." 
- Oyuncu servis asansörüyle yukarı çıkar. Kapı açılır: gündüz. İstasyon resmî olarak "kapatılıyor" — işçiler, bariyerler, sıradan bir sabah. Kamera oyuncunun elindeki terminale iner: ekran karararak kapanır. **Sessizlik. Gerçek sessizlik.**
- **His:** Kazanılmış huzur. Zor ama hak edilmiş. Oyuncunun topladığı her lore parçası bu ana anlam katar.

#### GİZLİ SON — "FARK EDİLDİN" (Fail-state / Dikkat maksimum)
- Herhangi bir bölümde Dikkat metresi tavan yaparsa: ışıklar söner, terminal `GÖZLEMLENİYORSUN` yazar, ekran bir kare boyunca "yanlış" bir şeyle dolar ve kesilir. → Son checkpoint'ten (bölüm başı) yeniden başlar; ama art arda 3 kez olursa özel bir "kayıp" epilogu (oyuncu istasyonun bir Yolcusu olur — sessiz, kısa, ürkütücü). Nadir, kazara ulaşılmamalı; ceza değil, atmosfer.

---

## 4. MEKANİKLER — DETAYLI

### 4.1 El Terminali (çekirdek araç + HUD)
Diegetic bir el cihazı. Tab ile kaldır/indir. Ekranı = oyuncunun tek HUD'u.

**Modlar/sekmeler:**
- **OKUMA (Readings):** `Basınç`, `Sıcaklık`, `Hat Gürültüsü`. Anomalilerin yakınında bu değerler "yanlışlaşır" (— , NaN, aşırı yüksek). Ama **her zaman güvenilir değil** (Bölüm 2'den sonra terminal de yalan söyleyebilir).
- **DOĞRULAMA (Verify):** Bir objeye/figüre tut, tara. Sonuç: `NORMAL` / `UYUMSUZ` / `OKUNAMIYOR`. **Batarya harcar** (bkz. kaynak). Her taramada Dikkat +minik.
- **GÖREV (Log):** Merkez'in verdiği güncel görev + geçmiş loglar. Burada oyuncu **kendi eski loglarını** bulur (döngü ipucu).
- **HAT (Signal):** Telsis sinyal gücü. Dead zone'larda düşer.

**Tasarım kuralı:** Terminal asla "doğru cevabı" düz vermez. İpucu verir; yorum oyuncuya kalır.

### 4.2 Telsis (Merkez ile diyalog)
- Merkez sürekli konuşur (görev, yorum, baskı). Oyuncu **Q** ile push-to-talk yapıp diyalog seçenekleri seçer.
- Diyalog ağaçları **güven (trust) sayacını** etkiler. Sorgulamak güveni düşürür ama gerçeğe yaklaştırır. İtaat güveni yükseltir ama Ending A'ya iter.
- **Yalan söyleyebilme:** Bazı yerlerde oyuncu Merkez'e yalan söyleyebilir ("Kapıyı kapattım" — kapatmadan). Merkez bunu bazen yakalar, bazen yakalamaz. Küçük ama güçlü ajans hissi.
- **Sessizlik seçeneği:** Cevap vermemek de bir seçim. Merkez sessizliğe tepki verir ("Orada mısın? ...Orada mısın?").

### 4.3 Farkındalık / Dikkat Metresi (push-your-luck governor)
- Görünmeyen değer + terminal köşesinde ince gösterge.
- **Artıran:** anomaliye uzun bakma, izinsiz kapı/dolap açma, fazla tarama, ana yoldan sapma, Yolcu'ya dokunma, Merkez'e sürekli karşı gelme.
- **Azaltan:** hareketsiz durup "nefes alma" (kısa diegetic sakinleşme), ışıklı güvenli alanlara girme, göreve odaklanma.
- **Kademeler:**
  - Düşük: normal.
  - Orta: ışıklar titremeye başlar, uzak sesler, Yolcular çoğalır.
  - Yüksek: terminal glitch'ler, telsis bozulur, "izleniyorsun" hissi.
  - Maksimum: fail-state (Fark Edildin).
- **Push-your-luck ruhu:** Daha çok lore/gerçek istiyorsan daha çok risk. "Bir dolabı daha açayım mı?" gerilimi. Senin imzan olan **risk-ödül** buranın kalbi.

### 4.4 Anomali Tespiti — Checklist DEĞİL
- Anomaliler **sabit bir liste** değildir. Ortam, "olması gereken normal"in ihlalidir. Oyuncu zamanla neyin "normal" olduğunu öğrenir, sonra ihlali sezer.
- **Kategoriler (öğreti için, oyuncuya asla liste olarak sunulmaz):**
  1. **Mekânsal:** yanlış yöne işaret eden tabela, olmaması gereken kapı, tekrar eden koridor.
  2. **Varlıksal:** Yolcular — nefes almayan/yanlış duran/sen bakınca donan figürler.
  3. **Zamansal:** çelişen saatler, gecikmeli yansıma, atlayan terminal saati.
  4. **İşitsel:** yanlış anons, yanlış yönden gelen tren sesi, boş tünelden nefes.
  5. **Veri:** terminalin okuyamadığı/yalan söylediği değerler.
- **Tepki seçenekleri** (bağlama göre): **Raporla** (Merkez'e — güvenli ama Merkez yanlış yönlendirebilir), **Yok say** (risksiz görünür ama anomali "büyüyebilir"), **İncele** (gerçek/lore verir ama Dikkat +).
- **Olasılıksal:** Aynı anomali her zaman aynı sonucu vermez. Bir Yolcu bazen sadece bakar, bazen yer değiştirir. Bu, oyuncunun "kalıbı ezberlemesini" engeller — sezgi zorunlu kalır.

### 4.5 Kaynaklar
- **Terminal bataryası:** Doğrulama taramaları harcar. Belli noktalarda şarj istasyonu. Kıtlık, "her şeyi tarayamazsın, seç" gerilimi yaratır.
- **Sigortalar / yedek parça:** Bazı kapıları/panoları açmak için gerekli, sınırlı. Nereye harcayacağın bir seçim.
- **Telsis sinyali:** Kaynak değil ama "kısıt" — dead zone'lar rehbersiz, gergin.
- **Işık:** El feneri değil (fazla "aksiyon" hissi verir); istasyonun kendi ışıkları. Işığı yönetmek = güvenli/tehlikeli alan yönetimi.

### 4.6 Sanity / Algı Kayması (diegetic)
- Döngü derinleştikçe UI'ın kendisi bozulur: terminal yazıları titrer, Merkez'in altyazıları glitch'lenir, envanter ikonları bir an "yanlış" görünür.
- **Asla oyuncuyu sersemletmek için değil**, "gerçeklik güvenilmez" temasını UI seviyesinde hissettirmek için. Ölçülü.

### 4.8 Dengeli Güvensizlik — "Tell" Sistemi (KİLİTLİ TASARIM KARARI)
> Karar: Merkez ve terminal **tam dengede** güvenilmez. Ama denge işe yarasın diye ikisinin de yakalanabilir kalıbı (tell) vardır. Amaç: oyuncu "hangisi şu an yalan söylüyor?"u **çözebilsin**, yazı-tura atmasın.

**Merkez'in tell'leri (yalan söylediğinde):**
- Konu "aşağı inmek", "mühür", "kapıyı kapat" ile ilgiliyse yalan olasılığı yükselir (çıkarı var).
- Yalan söylerken **acele ettirir**, soru sordurmaz, konuyu değiştirir ("boşver onu", "vakit yok").
- Ses tonu bir tık "fazla sıcak" olur (manipülasyon). İyi kulak bunu yakalar.
- **Doğru olduğu alan:** genel istasyon işleyişi, güvenli rutin, oyuncuyu koruma refleksi (bazen gerçekten korur).

**Terminal'in tell'leri (bozulduğunda):**
- Dikkat metresi yüksekken okumaları glitch'lenir/yalanlar (yani **oyuncunun kendi hatası** terminali bozar — öğrenilebilir).
- Aşağıdaki'ye yakın alanlarda `OKUNAMIYOR` yerine "kendinden emin ama yanlış" değer verir (asıl tehlikeli yalan bu).
- Bir değer **çok temiz/çok yuvarlaksa** şüphe et (gerçek okumalar gürültülüdür).
- **Doğru olduğu alan:** düşük Dikkat'te, yüzeye yakın katlarda, mekanik/elektrik ölçümlerinde.

**Güven Ritmi (dinamik denge — statik 50/50 değil):**
- **Bölüm 1:** Merkez ~%80 doğru, terminal ~%80 doğru. İkisi de güvenilir görünür (rahatlık kur).
- **Bölüm 2:** İlk ayrışma. Merkez çıkarına yalan söylemeye başlar; terminal hâlâ çoğunlukla doğru → oyuncu **terminale güvenmeyi öğrenir.**
- **Bölüm 3:** Ters köşe. Derinlik terminali bozar; Merkez bazı gerçekleri (çaresizce) söyler → oyuncunun yeni edindiği "terminale güven" alışkanlığı **sarsılır.** Denge burada duygusal zirveye çıkar.
- **Sonuç:** Hiçbiri baskın değil ama her an *hangisinin* güvenilir olduğu **bağlamdan okunabilir.** Oyuncu iki otoriteyi de "yönetmeyi" öğrenir. Gerçek güven → kendi gözü.

**Tasarım testi (M0'da doğrula):** Bir test oyuncusu, çelişki anında "şu an Merkez yalan söylüyor çünkü ___" diyebiliyorsa denge çalışıyor. "Bilmiyorum, tahmin ettim" diyorsa denge gürültüye kaymış → tell'leri güçlendir.

### 4.7 Kayıt / Checkpoint
- Bölüm başlarında otomatik checkpoint. Bölüm içinde manuel kayıt yok (gerilimi korur) — ama bölümler ~30-40 dk, adil.
- Seçim flag'leri kalıcı; oyun sonunda "toplanan izler / seçimler" özeti (tekrar oynanabilirlik için hangi lore'u kaçırdığını gösterir).

---

## 5. SEÇİM / DALLANMA HARİTASI (özet)

```
BÖLÜM 1: Yolcu incele? (küçük — güven & eda_iz sayacı)
        └─> Eda izi bulundu mu? (opsiyonel keşif)

BÖLÜM 2: Pano sırası — Merkez(1-3-2) mi Terminal(2-1-3) mi?
        ├─ Merkez'e uy   → ritual_ilerleme+, Ending A ağırlık
        ├─ Terminal'e uy → gercek_yolu+, Cavit odası açılır, Ending C yolu
        └─ Merkez'i sorgula → diyalog, ikisine de gidebilir

BÖLÜM 3: MÜHÜR PANOSU — ANA SEÇİM
        ├─ A) Merkez gibi ayarla        → ENDING A (Devir)
        ├─ B) Mühürü kır                → ENDING B (Yarık)
        └─ C) Eda'nın şeması (eda_iz≥eşik gerekli) → ENDING C (Kapanış)

BÖLÜM 4: Seçilen ending finalize.
        + Her bölümde Dikkat MAX → GİZLİ FAIL (Fark Edildin)
```

**Sayaçlar:**
- `guven(Merkez)`: itaat +, sorgulama −. Ending A'ya yatkınlık + diyalog tonu.
- `eda_iz` (0–5+): keşif/kayıtlar. **C sonu için eşik (örn. ≥3).**
- `ritual_ilerleme`: Merkez'e uyunca artar. A sonunu pekiştirir.
- `dikkat`: push-your-luck; fail-state tetikler.

---

## 6. SES TASARIMI (bu oyunun %50'si sestir)

- **Telsis:** parazit, sıkıştırılmış vokal, arada kesilme. Merkez'in sesi = oyunun ana enstrümanı.
- **Ambiyans:** düşük frekanslı uğultu (havalandırma), su damlaması, uzak metal, ara sıra "hayalet tren" gürültüsü.
- **Dialogue blip / işitsel doku:** Yolcular ve Aşağıdaki için insan-altı, pitch'i "yanlış" sesler. (Elindeki mevcut voiced dialogue audio asset'lerini burada değerlendirebilirsin.)
- **Sessizlik bir enstrüman:** dead zone'larda tam sessizlik → oyuncu kendi ayak seslerini/nefesini duyar.
- **Dikkat yükseldikçe:** ses tasarımı "kirlenir" — ambiyansa ters bir alt-ton eklenir, farkına varılmadan gerginlik artar.
- **Müzik:** neredeyse yok; sadece kritik anlarda tek bir drone/nota. Melodi = tehlike.

---

## 7. GÖRSEL / ART YÖNÜ

- **First-person, 3D.** Elindeki metro koridoru asset'i çekirdek mekân. (Bu proje sıfırdan değil — **mevcut asset'in + Verici konseptinin birleşimi** olarak düşünülmeli.)
- **Palet:** soğuk endüstriyel — beton grisi, floresan yeşili-beyazı, pas, ıslak koyu yüzeyler. Sıcak renk (Merkez'in güveni) çok az; azaldıkça soğur.
- **Işık:** kaynak ışık, sert gölge, titrek floresan. Karanlık = bilinmezlik, ama tam karanlık nadir (görememe frustrasyon yaratır; "az görme" korkutur).
- **Yolcular:** düşük detay, statik/az animasyonlu figürler (senin "az animasyon, çok atmosfer" yaklaşımına uygun). Hareket etmemeleri onları daha ürkütücü yapar.
- **Aşağıdaki:** görsel varlık YOK. Sadece etki (ışık, basınç, veri). "Göstermeme" bir sanat yönü kararıdır.
- **UI:** terminal ekranı retro-endüstriyel (yeşil fosfor / eski LCD hissi), diegetic.

---

## 8. TEKNİK NOTLAR (Godot 4)

- **Sahne mimarisi:** her Bölüm ayrı bir `Level` sahnesi; ortak `GameState` autoload (flag'ler, sayaçlar, Merkez güveni).
- **Anomali sistemi:** `AnomalyManager` — her anomali bir `Node` + `AnomalyResource` (tür, tetik koşulu, tepki tablosu, dikkat maliyeti). Olasılıksal davranış için weighted random.
- **Telsis/diyalog:** basit bir dialogue graph (JSON/resource); `RadioManager` autoload sesi + altyazı + trust etkisi yönetir. Dialogic eklentisi değerlendirilebilir ama diegetic ses senkronu için custom daha temiz olabilir.
- **Dikkat metresi:** `AwarenessManager` autoload; girişleri (bakış süresi, tarama, sapma) toplar, kademe event'leri yayınlar (signal-based → ışık/ses/post-process tepki verir).
- **Terminal:** `Control` tabanlı bir SubViewport'ta render edilip 3D cihaz mesh'ine texture olarak yansıtılır (Observation tarzı diegetic ekran).
- **Ses:** `AudioServer` bus'ları: `Ambience`, `Radio`, `SFX`, `Anomaly`. Dikkat yükselince `Anomaly` bus'ı ve reverb devreye girer.
- **Kayıt:** `GameState.save()` → bölüm başı; JSON.
- **Performans:** dar kapalı mekân → occlusion culling + baked lighting ağırlıklı; gerçek-zaman ışık yalnız titrek/olay ışıklarında.

---

## 9. SCOPE LOCK (kilitli — önce bunu oku)

> Senin örüntün: konseptler güçlü, ama paralel çok fazla fikir açılıp hiçbiri bitmiyor. Bu doküman **onu engellemek için** yazıldı. Aşağıdaki kilitler **pazarlık konusu değil.**

**KİLİT 1 — Önce core loop, sonra içerik.**
İçerik (5 bölüm, tüm anomaliler, tüm diyalog) **YAZILMAZ** — ta ki şu "dikey dilim" eğlenceli/gergin olduğu kanıtlanana kadar:
- **1 koridor + 1 pano görevi + 3 anomali + Merkez'in 1 yalanı + terminal-telsis çelişkisi + 1 seçim.**
- Bu ~5-8 dakikalık dilim gerçekten geriyorsa, oyun vardır. Germiyorsa, hiçbir içerik onu kurtarmaz. **Buraya kadar dur.**

**KİLİT 2 — Aşağıdaki asla gösterilmez.** Bir yaratık modeli, bir "boss", bir jump-scare canavarı yapma isteği gelirse: HAYIR. Göstermeme bu oyunun kimliğidir.

**KİLİT 3 — Combat yok, koşma-kaçma yok.** "Bir de kovalayan bir şey olsa" fikri gelirse: HAYIR. Tehdit sosyal + algısaldır.

**KİLİT 4 — 3 son + 1 gizli. Fazlası değil.** Yeni son fikri geldiğinde mevcut 3'ün birini derinleştir, yenisini ekleme.

**KİLİT 5 — Mevcut asset'lerin üstüne kur.** 3D metro koridoru + Verici konsepti + eldeki ses asset'leri. Yeni büyük asset üretimi minimumda.

---

## 10. MİLESTONE PLANI

**M0 — Dikey Dilim (Vertical Slice) [BLOKE EDİCİ]**
- 1 koridor, terminal (okuma + doğrulama), telsis (Merkez'in 3-4 replik + 1 yalan), 3 anomali, Dikkat metresi, terminal-telsis çelişkisi, 1 seçim.
- **Çıktı kriteri:** Bir test oyuncusu (sen dahil) bu dilimi oynayınca gerçekten gerilmeli. Buradan geçmeden M1 YOK.

**M1 — Çekirdek Sistemler**
- AnomalyManager, RadioManager, AwarenessManager, GameState (flag/sayaç), diegetic terminal ekranı, kayıt sistemi.

**M2 — Bölüm 1 + 2 (tam)**
- Güven dönemi + ayrışma dönemi. İlk gerçek dallanma. Eda ve Cavit izleri.

**M3 — Bölüm 3 + Ana Seçim**
- Gerçeğin açığa çıkışı, mühür panosu, 3 yola ayrılma.

**M4 — Bölüm 4 + 3 Son + Gizli Fail**
- Tüm sonların finalize'ı, epiloglar.

**M5 — Cila (Juice) & Ses**
- Ses tasarımı geçişi (senin güçlü olduğun kısım), UI glitch/sanity efektleri, ışık pass'i, pacing ayarı.

**M6 — Playtest & Steam**
- Dış playtest, Dikkat dengesi, seçim netliği, Steam sayfası, demo (Bölüm 0+1 = harika bir demo).

---

## 11. AÇIK KARARLAR (senin netleştirmen gerekenler)

**✅ KİLİTLENDİ:**
1. **Ana gerilim vurgusu → DENGE.** Merkez ve terminal tam dengede güvenilmez; çıpa oyuncunun kendi gözlemi. Uygulama detayı §4.8 "Tell Sistemi" + Güven Ritmi. *(Statik 50/50 değil; öğrenilebilir, dinamik denge.)*
3. **Uzunluk → 2.5-3 saat, nefes alan.** Peak/valley ritmi, §3.1 Ritim Haritası. Kesintisiz gerilim değil; vadiden sonra tepe.

**Hâlâ netleştirilecek:**
2. **Dil:** Tamamen Türkçe seslendirme mi (atmosfer için çok güçlü — Merkez'in sesi oyunun kalbi), yoksa İngilizce lokalizasyon da hedef mi (Steam erişimi için)? Öneri: **Türkçe VO + İngilizce altyazı** ile başla; TR ses atmosferi, EN altyazı erişimi verir.
4. **Ölüm/fail felsefesi:** Fark Edildin fail'i sadece checkpoint mı, yoksa "her fail döngüyü biraz değiştiren" bir sistem mi? (İkincisi tematik olarak çok güçlü — döngü teması — ama scope riski. Öneri: **M4'e kadar basit checkpoint**, artarsa döngü-varyasyonu stretch goal.)

---

*Not: Bu doküman `SON SEFER`'in tasarım anayasasıdır. Her yeni fikir, §9 Scope Lock'a ve §0'daki tek cümlelik çekirdek gerilime karşı test edilir. Çekirdeğe hizmet etmiyorsa — ne kadar havalı olursa olsun — girmez.*
