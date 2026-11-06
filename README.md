# temizle.sh — Plesk yedek ve log temizliği

Plesk sunucularında disk dolduğunda, **en son tam site yedeği hariç** eski yedekleri ve
Apache / nginx / Plesk servis loglarını güvenli şekilde temizlemek için bir Bash scripti.

## Ne yapar

1. **Plesk yedekleri** (`/var/lib/psa/dumps`): En son tam yedek setini (`.tzst` veri dosyası
   olan en yeni anahtar) korur, diğer `backup_*` dosyalarını siler. Yalnızca `.xml` bilgi
   dosyası olan bir seti "son yedek" olarak seçmez.
2. **Servis logları** (Apache, nginx, Plesk, sw-cp-server, PHP-FPM):
   - Döndürülmüş / sıkıştırılmış eski logları (`.gz`, `.1`, `.old` …) siler.
   - Aktif `*.log` dosyalarını **silmez, sıfırlar**. Servis dosyayı açık tuttuğu için
     bu, servisi bozmadan yer açar.

## Kullanım

```bash
sudo ./temizle.sh          # sadece listeler, hiçbir şey silmez (önerilen ilk adım)
sudo ./temizle.sh --run    # gerçekten siler / boşaltır
```

Root olarak çalışmalıdır. Sonunda Apache, nginx, sw-cp-server ve MariaDB durumunu gösterir.

## Uyarılar

- Çalıştırmadan önce mutlaka `--run` olmadan listeleme yapın ve çıktıyı inceleyin.
- Silinen Plesk yedekleri geri gelmez. Önemli yedeklerin sunucu dışında kopyası olmalı.
- Bu script yalnızca loglar ve yedek dosyaları için tasarlanmıştır; veritabanı veya site
  dosyalarına dokunmaz.
- Kendi sunucunuzda, sorumluluk size aittir. Kullanmadan önce kodu okuyun.

---

## Donate

If you find this project useful, consider supporting its development:

| Network | Address |
|---------|---------|
| **USDT (TRC20)** | `TYCK6ZyMS6UDt787foPH2QwFuvkdqMw1Jv` |
| **USDT (BSC20 / BEP20)** | `0x15aac92a1945ddbe5c79304bfa388d6be99b26a3` |

---

<p align="center">Created by <strong>TAPSIN</strong></p>
