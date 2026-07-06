# SON SEFER — Güncelleme Notları

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
