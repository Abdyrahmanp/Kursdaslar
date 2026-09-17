# Alwaysdata Hosting Sazlamalary Gollanmasy (Step-by-Step)

Bu gollanma **Topar-115 (Kursdaşlar)** internet duýduryş API serwerini [Alwaysdata.com](https://www.alwaysdata.com) platformasynda mugt açmak üçin taýýarlandy.

---

## 🚀 1. Alwaysdata-da Hasap Açmak (2 Minut)

1. [alwaysdata.com](https://www.alwaysdata.com) sahypasyna giriň we **Sign up for free** (Mugt hasap aç) düwmesine basyň.
2. Hasap adyňyzy saýlaň (mysal üçin: `topar115`).
   - Siziň mugt domeniňiz: `https://topar115.alwaysdata.net` bolar.
3. E-poçtaňyzy we parolyňyzy girizip, hasaby tassyklaň.

---

## 🛠 2. Ýerleşdirmegiň Iki Usuly:

### 🌟 1-nji Usul: PHP Arkaly (Iň aňsat we 1 minutda taýýar bolýan wariant)

Alwaysdata-da PHP awtomatiki taýýar ýagdaýda işleýär. Hiç zat gurmak gerek däl!

1. Alwaysdata dolandyryş panelinde çep menýudan **Web** -> **Sites** bölümine geçiň.
2. Eýýäm bar bolan esasy sahypaňyzyň (`topar115.alwaysdata.net`) sazlamasyna giriň.
3. Adaty görnüşde ol `PHP` we Document root: `/home/topar115/www/` bolar.
4. Çep menýudan **Files** (Faýllar) bölümine giriň:
   - `/home/topar115/www/` bukjanyň içine giriň.
   - Taslamamyzdaky `backend/php/index.php` faýlyny göçürip, Alwaysdata-daky `www/` içine ýükläň (Upload).
   *(Eger `www/api/` bukjasy açyp, şonuň içine `index.php` goýsaňyz, salgyňyz: `https://topar115.alwaysdata.net/api` bolar).*
5. **Barlap görüň:**
   Brauzerde `https://topar115.alwaysdata.net` (ýa-da `/api`) açyp görüň. Duýduryşlaryň JSON sanawyny görersiňiz!

---

### 🐍 2-nji Usul: Python (Flask) Arkaly

Eger Python ulanmak isleseňiz:

1. Alwaysdata dolandyryş panelinde **Web** -> **Sites** bölümine giriň -> **Add a site** basyň.
2. **Type:** `Python WSGI` saýlaň.
3. **Application path:** `app:app` ýazyň.
4. **Working directory:** `/home/topar115/backend/` edip belläň.
5. **Python version:** `3.11` ýa-da `3.12` saýlaň.
6. **Files** arkaly `backend/app.py`, `backend/wsgi.py` we `backend/requirements.txt` faýllaryny şol bukjanyň içine ýükläň.
7. **SSH** ýa-da Alwaysdata terminaly arkaly baglanyp, kitaphana gurnap bilersiňiz:
   ```bash
   pip install -r requirements.txt
   ```
8. Sahypany täzeläň (Restart site).

---

## 📱 3. Flutter Goşundysyna Öz Serwer Salgyňyzy Goşmak

Serweri Alwaysdata-da açanyňyzdan soň, taslamamyzdaky:
`lib/core/constants/app_constants.dart` faýlyna giriň we öz domeniňizi ýazyň:

```dart
static const String apiBaseUrl = 'https://topar115.alwaysdata.net/api';
// ýa-da PHP ulanýan bolsaňyz:
// static const String apiBaseUrl = 'https://topar115.alwaysdata.net';
```

Şu sazlama bilen goşundyňyz dünýäniň islendik ýerindäki talyplara internet arkaly duýduryş ugradyp we kabul edip biler!
