<div align="center">

# ⚡ OtoKapat

**Windows İçin Akıllı Otomatik Kapatıcı & İndirme Takipçisi**  
*Gelişmiş WPF XAML Arayüzü | Saf PowerShell 5.1+ | Kurulum Gerektirmez*

[![Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?logo=windows&logoColor=white)](https://github.com/hcorc/OtoKapat)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE?logo=powershell&logoColor=white)](https://github.com/hcorc/OtoKapat)
[![License: MIT](https://img.shields.io/badge/License-MIT-emerald.svg)](LICENSE)
[![Portable](https://img.shields.io/badge/Kurulum-Gerektirmez%20(Taşınabilir)-10B981)](#)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](#)

</div>

---

## 📖 Genel Bakış

**OtoKapat**, bilgisayar başında olmadığınızda indirmeleriniz bittiğinde veya belirlediğiniz senaryolarda sistemi güvenle kapatmak için geliştirilmiş modern, şık ve güçlü bir görev yöneticisidir.

Geleneksel karmaşık kapatma programlarının aksine **hiçbir kurulum gerektirmez**, harici bağımlılığı yoktur ve Windows'un yerel `.NET / WPF` altyapısı üzerinde saf PowerShell ile son derece kararlı çalışır.

---

## ✨ Öne Çıkan Özellikler

### 🎯 5 Akıllı Kapatma Modu

1. **⏱ Geri Sayım Zamanlayıcısı:**
   - Belirlediğiniz süre (saat, dakika, saniye) bittiğinde sistemi otomatik kapatır.
   - Hızlı çiplerle tek tıkla süre ekleme: `+15 Dk`, `+30 Dk`, `+45 Dk`, `+1 Saat`, `+2 Saat`, `+3 Saat`.
   - Hedef kapanış saatini anlık canlı gösterir (*Örn: "Bugün saat 23:45:00"*).

2. **🕒 Belirli Saatte Kapatma:**
   - Günün dilediğiniz saat ve dakikasını seçin (`00:00` - `23:59`).
   - Hızlı saat butonları (`00:00`, `01:00`, `02:00`, `+1 Saat`, `+2 Saat`).
   - Hedefe kalan süreyi dinamik olarak hesaplar.

3. **🌐 Ağ & İndirme Takibi (Steam, Epic, Torrent, IDM, Tarayıcı):**
   - Ağ trafiğini ve anlık indirme hızını canlı olarak ölçer.
   - İndirme hızı belirlediğiniz eşiğin (Örn: `100 KB/s`) altına düştüğünde ve doğrulama süresi (1, 2, 3, 5, 10 dk) boyunca sessiz kaldığında sistemi otomatik kapatır.
   - *Steam ve Epic Games'in disk yazma aralıklarında erken kapanmayı önleyen akıllı koruma süresi içerir.*

4. **📁 Klasör & İndirme İzleme:**
   - **Geçici Dosya Takibi:** `.crdownload`, `.part`, `.downloading`, `.!ut`, `.opdownload`, `.aria2`, `.tmp` gibi indirme uzantıları bittiğinde sistemi kapatır.
   - **Hareketsizlik Takibi:** Klasörde son 3 dakika içinde yeni veri yazımı olmadığında kapanma sürecini başlatır.

5. **⚡ Program / İşlem (Process & PID) İzleyicisi:**
   - Seçtiğiniz uygulama (`Steam`, `Epic Games`, `qBittorrent`, `uTorrent`, `IDM`, `FDM` vb.) kapandığında sistemi kapatır.
   - Aktif çalışan programlar listesinden tek tıkla seçilebilir.
   - *Hatalı girişlerde ve program henüz açık değilken kazara kapanmayı önleyen güvenlik doğrulaması içerir.*

---

### 🛡️ Güvenlik ve Sistem Entegrasyonu

* **🚨 60 Saniye Güvenlik Uyarısı (Overlay):**
  - Kapanma anı geldiğinde ekranın ortasında kırmızı acil durum geri sayım penceresi belirir ve sesli uyarı verir.
  - **"KAPATMAYI İPTAL ET"** butonuyla istediğiniz zaman tek tıkla vazgeçebilirsiniz.
* **🔔 Resmi Windows Bildirim Entegrasyonu:**
  - Zamanlama başladığında ve iptal edildiğinde Windows'un resmi sistem bildirimleri ("Oturumunuz kapatılmak üzere / İptal edildi") ekrana gelir.
  - Üst bardaki **"🔔 Bildirim Testi"** butonuyla hemen test edebilirsiniz.
* **⚙️ 4 Farklı Eylem Seçeneği:**
  - 🔴 Bilgisayarı Kapat (`shutdown /s`)
  - 🔄 Yeniden Başlat (`shutdown /r`)
  - 🌙 Uyku Modu (`SetSuspendState`)
  - ❄️ Hazırda Beklet (`shutdown /h`)
  - İsteğe bağlı **"Zorla Kapat (/f)"** seçeneği.
* **🔒 Tekil Çalışma Koruması (Mutex):**
  - Program açıkken tekrar tıklandığında birden fazla pencere açmaz, çakışmaları engeller.

---

## 🚀 Kurulum ve Çalıştırma

Kurulum gerekmez! Dosyaları indirip doğrudan kullanabilirsiniz.

1. Depoyu indirin veya ZIP olarak çıkartın.
2. Klasördeki **`Baslat.bat`** dosyasına çift tıklayın.
3. Modern koyu temalı arayüz doğrudan açılacaktır.

```powershell
# Dilerseniz doğrudan PowerShell üzerinden de çalıştırabilirsiniz:
powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File ".\OtoKapat.ps1"
```

---

## 📁 Proje Dosya Yapısı

```text
OtoKapat/
├── Baslat.bat                 # Tek tıkla sessiz başlatıcı (STA & Gizli Konsol)
├── OtoKapat.ps1               # Ana WPF XAML motoru ve tüm mantık kodları
├── LICENSE                    # MIT Açık Kaynak Lisansı
├── README.md                  # Proje dokümantasyonu
└── .gitignore                 # Git yoksayma kuralları
```

---

## 💻 Sistem Gereksinimleri

* **İşletim Sistemi:** Windows 10 veya Windows 11 (Tüm sürümler)
* **PowerShell:** PowerShell 5.1 veya üzeri (Windows ile yerleşik gelir)
* **.NET:** .NET Framework 4.5+ (Windows ile yerleşik gelir)

---

## 📜 Lisans

Bu proje **MIT Lisansı** altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına göz atabilirsiniz.

Geliştirici: **hcorc (OtoKapat Project)**
