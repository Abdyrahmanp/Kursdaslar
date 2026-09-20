# Fly.io Platformasynda Python (FastAPI) Serwerini Ýerleşdirmek (Ädimme-ädim Gollanma)

Bu gollanma **Topar-115 (Kursdaşlar)** üçin taýýarlanan Python FastAPI serwerini (Duýduryşlar, Real-time Chat we Sapak Temalary) [Fly.io](https://fly.io) bulut platformasynda mugt we hemişelik disk bilen işletmek üçin niýetlenendir.

---

## 🚀 1. Fly CLI Gurmak

Kompýuteriňiziň terminalynda (Linux / macOS) aşakdaky komandany işlediň:

```bash
curl -L https://fly.io/install.sh | sh
```

*Eger Windows ulanýan bolsaňyz (PowerShell):*
```powershell
pwsh -Command "iwr https://fly.io/install.ps1 -useb | iex"
```

Gurlandan soňra terminalyňyzda `fly` komandasynyň elýeterli bolmagy üçin (eger gerek bolsa):
```bash
export FLYCTL_INSTALL="/home/$USER/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"
```

---

## 🔑 2. Fly.io-da Hasap Açmak we Giriş Etmek

Terminalda ýazyň:
```bash
fly auth signup
# ýa-da eýýäm hasabyňyz bar bolsa:
fly auth login
```
Brauzer açylar we Fly.io hasabyňyza birikmegi tassyklarsyňyz.

---

## 📂 3. Serweri Fly.io-da Döretmek (Deploy)

Taslamamyzyň `backend` bukjasynda terminaly açyň:

```bash
cd /home/gelnox/topar_115/backend
```

### Ädim 3.1: Täze programma döretmek
```bash
fly launch --no-deploy
```
- Sizden app adyny sorar (mysal üçin: `topar115` ýa-da `topar-115-app`).
- Region hökmünde `fra` (Frankfurt) ýa-da iň golaý regiony saýlaň.
- Maglumat bazasy sorasa (Postgres/Redis), "No" saýlaň (sebäbi biz ýeňil we çalt işleýän SQLite Persistent Disk ulanýarys).

### Ädim 3.2: Hemişelik Disk (Persistent Volume) Döretmek
Serwer öçüp-ýananda hem maglumatlaryň (duýduryşlar, chat hatlary, sapak temalary) ýitmezligi üçin 1 GB mugt hemişelik disk dörediň:

```bash
fly volumes create topar_data --region fra --size 1
```

### Ädim 3.3: Serweri Ýaýratmak (Deploy)
```bash
fly deploy
```

Birnäçe sekundyň içinde Fly.io Docker konteýnerini gurap, serweri bütin dünýä boýunça ýaýradar!

---

## 🌐 4. Serweri Barlamak (Swagger UI & Test)

Serweriňiz taýýar bolansoň, brauzeriňizde açyň:
```
https://<siziň-app-adyňyz>.fly.dev/docs
```
(Mysal: `https://topar115.fly.dev/docs`)

Açylan Swagger UI sahypasynda:
- Ähli API-leri (Duýduryşlar, Chat, Sapak Temalary) brauzeriň içinden derrew barlap we synag edip bilersiňiz!

---

## 📱 5. Flutter Goşundysyna Täze Salgyny Birikdirmek

Serweriňiziň domenini alan wagtyňyz, taslamamyzdaky:
[lib/core/constants/app_constants.dart](file:///home/gelnox/topar_115/lib/core/constants/app_constants.dart) faýlyny açyň we täze Fly.io salgylaryňyzy goýuň:

```dart
// Alwaysdata deregine Fly.io salgylary:
static const String apiBaseUrl = 'https://topar115.fly.dev/api';
static const String wsChatUrl = 'wss://topar115.fly.dev/ws/chat';
```

Şu sazlama bilen goşundyňyz Fly.io bulut serwerine baglanyp, hem duýduryşlary, hem real-time çaty, hem-de sapak temalaryny doly ýerine ýetirer!
