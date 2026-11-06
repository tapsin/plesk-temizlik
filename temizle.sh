#!/bin/bash
# temizleyeni.sh
# 1) Plesk site yedeklerinden en son TAM yedek seti haricindekileri siler.
# 2) Apache, nginx ve Plesk servis loglarını temizler:
#    - Döndürülmüş/sıkıştırılmış eski logları (.gz, .1, .old ...) siler.
#    - Aktif *.log dosyalarını SIFIRLAR (silmez). Servisler dosyayı açık tuttuğu
#      için silmek yerine boşaltmak servisi bozmadan yer açar.
#
# Kullanım:
#   ./temizleyeni.sh          -> sadece ne silineceğini listeler (güvenli, hiçbir şey silmez)
#   ./temizleyeni.sh --run    -> gerçekten siler/boşaltır

set -u

if [ "$(id -u)" -ne 0 ]; then
    echo "Bu script root olarak çalıştırılmalı." >&2
    exit 1
fi

RUN=0
[ "${1:-}" = "--run" ] && RUN=1

if [ $RUN -eq 1 ]; then MOD="SİLME (gerçek)"; else MOD="KURU ÇALIŞTIRMA (listeleme)"; fi
echo "=== temizleyeni.sh | Mod: $MOD | $(date '+%F %T') ==="
echo "Önce disk: $(df -h / | tail -1)"
echo

# ---------------------------------------------------------------
# 1) PLESK YEDEKLERİ
# ---------------------------------------------------------------
DUMPS=/var/lib/psa/dumps

# En yeni TAM yedek (veri dosyası .tzst) bulunur. XML bilgi dosyası tek başına
# kullanılmaz, çünkü veri dosyası silinmiş olabilir.
NEWEST_TZST=$(find "$DUMPS" -type f -name 'backup_*.tzst' -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$NEWEST_TZST" ]; then
    echo "[Yedek] Hiç .tzst yedek bulunamadı; yedek temizliği ATLANDI (güvenlik)."
else
    # Dosya adından anahtarı çıkar: _NNNNNNNNNN_NNNNNNNNNN veya _NNNNNNNNNN
    KEY=$(basename "$NEWEST_TZST" | grep -oE '_[0-9]{10}(_[0-9]{10})?' | tail -1)
    if [ -z "$KEY" ]; then
        echo "[Yedek] Anahtar okunamadı ($NEWEST_TZST); yedek temizliği ATLANDI."
    else
        echo "[Yedek] Korunacak son tam yedek seti: $KEY"
        echo "[Yedek] (Örnek korunan dosya: $(basename "$NEWEST_TZST"))"

        # Silinecekler: backup_* dosyaları, anahtarı korunan sette olmayanlar
        LIST=$(find "$DUMPS" -type f -name 'backup_*' ! -name "*${KEY}.*" 2>/dev/null)
        COUNT=$(printf '%s\n' "$LIST" | grep -c . || true)
        SIZE=$(printf '%s\n' "$LIST" | grep . | xargs -r du -ch 2>/dev/null | tail -1 | cut -f1)
        echo "[Yedek] Silinecek dosya sayısı: $COUNT (toplam: ${SIZE:-0})"

        if [ $RUN -eq 1 ] && [ "$COUNT" -gt 0 ]; then
            printf '%s\n' "$LIST" | grep . | xargs -r rm -f
            echo "[Yedek] Silindi."
        elif [ $RUN -eq 0 ]; then
            printf '%s\n' "$LIST" | grep . | head -5 | sed 's/^/   örnek: /'
        fi
    fi
fi
echo

# ---------------------------------------------------------------
# 2) SERVİS LOGLARI (Apache, nginx, Plesk)
# ---------------------------------------------------------------
LOGDIRS=(
    /var/log/apache2
    /var/log/nginx
    /var/log/plesk
    /var/log/sw-cp-server
    /var/log/plesk-php*-fpm
    /var/www/vhosts/system
)

for D in "${LOGDIRS[@]}"; do
    # glob desteği için döngü
    for DIR in $D; do
        [ -d "$DIR" ] || continue

        # a) Döndürülmüş / sıkıştırılmış eski loglar -> sil
        OLD=$(find "$DIR" -type f \( -name '*.gz' -o -name '*.[0-9]' -o -name '*.[0-9].gz' -o -name '*.old' \) 2>/dev/null)
        OLDN=$(printf '%s\n' "$OLD" | grep -c . || true)

        # b) Aktif *.log dosyaları -> boşalt (silme!)
        ACT=$(find "$DIR" -type f -name '*.log' 2>/dev/null)
        ACTN=$(printf '%s\n' "$ACT" | grep -c . || true)

        echo "[Log] $DIR : eski döndürülmüş=$OLDN, boşaltılacak aktif=$ACTN"

        if [ $RUN -eq 1 ]; then
            printf '%s\n' "$OLD" | grep . | xargs -r rm -f
            printf '%s\n' "$ACT" | grep . | while read -r F; do : > "$F"; done
        fi
    done
done
echo

if [ $RUN -eq 1 ]; then
    echo "Sonra disk: $(df -h / | tail -1)"
    echo "Servis durumu:"
    for S in apache2 nginx sw-cp-server mariadb; do
        printf '  %-14s %s\n' "$S" "$(systemctl is-active "$S" 2>/dev/null)"
    done
else
    echo "Hiçbir şey silinmedi. Gerçekten çalıştırmak için: ./temizleyeni.sh --run"
fi
