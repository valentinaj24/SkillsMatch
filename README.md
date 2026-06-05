# 🎓 SkillsMatch

> Mobilna aplikacija za povezovanje mentorjev in učencev ter spodbujanje medgeneracijskega prenosa znanja.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![Firebase](https://img.shields.io/badge/Firebase-Backend-orange)
![Firestore](https://img.shields.io/badge/Firestore-NoSQL-yellow)
![LiveKit](https://img.shields.io/badge/LiveKit-Video%20Calls-green)
![Cloudinary](https://img.shields.io/badge/Cloudinary-Images-blueviolet)

---

## 📖 O projektu

SkillsMatch je mobilna aplikacija, razvita v okviru projektnega dela skupine **SkillBridge**, katere namen je povezovanje uporabnikov različnih generacij z namenom izmenjave znanja, izkušenj in veščin.

V sodobni družbi imajo starejše generacije bogate življenjske in strokovne izkušnje, medtem ko imajo mlajše generacije dostop do sodobnih tehnologij in velike količine informacij. Kljub temu pogosto prihaja do pomanjkanja neposrednega sodelovanja med generacijami.

Aplikacija SkillsMatch omogoča ustvarjanje skupnosti, kjer lahko uporabniki:

- delijo svoje znanje,
- poiščejo mentorja,
- poiščejo učenca,
- vzpostavijo sodelovanje,
- komunicirajo preko sporočil,
- izvajajo avdio in video klice,
- ocenjujejo sodelovanja,
- gradijo zaupanja vredno skupnost.

---

## ✨ Ključne funkcionalnosti

### 👤 Upravljanje uporabnikov

- Registracija uporabnikov
- Prijava uporabnikov
- Urejanje uporabniškega profila
- Nastavitve zasebnosti
- Nalaganje profilnih slik

### 🤝 Sistem ujemanja

- Iskanje uporabnikov glede na veščine
- Prikaz stopnje ujemanja
- Priporočanje ustreznih mentorjev in učencev
- Pregled skupnosti uporabnikov

### 📨 Povabila in sodelovanja

- Pošiljanje povabil
- Sprejem ali zavrnitev povabil
- Upravljanje sodelovanj
- Spremljanje aktivnih sodelovanj

### 💬 Komunikacija

- Besedilna sporočila
- Avdio klici
- Video klici
- Obvestila v realnem času

### ⭐ Sistem zaupanja

- Ocenjevanje uporabnikov
- Verifikacija mentorjev
- Pregled zgodovine sodelovanj

### ♿ Dostopnost

- Temni način
- Večja velikost pisave
- Enostaven uporabniški vmesnik
- Prilagojen prikaz za starejše uporabnike

---

# 🏗️ Arhitektura sistema

Sistem temelji na arhitekturi odjemalec–strežnik.

```text
Flutter App
     │
     ├── Firebase Authentication
     ├── Cloud Firestore
     ├── Firebase Cloud Messaging
     ├── Cloudinary
     └── LiveKit
```
### Arhitekturne odločitve

Pri razvoju aplikacije smo sprejeli več arhitekturnih odločitev, ki omogočajo dobro uporabniško izkušnjo, enostavno vzdrževanje sistema in razširljivost rešitve.

| Komponenta | Razlog za izbiro |
|------------|------------------|
| Flutter | Razvoj za Android in iOS iz ene same kode ter hitrejši razvoj uporabniškega vmesnika. |
| Firebase Authentication | Varna registracija in prijava uporabnikov brez razvoja lastnega sistema za avtentikacijo. |
| Cloud Firestore | Shranjevanje podatkov v realnem času ter enostavna integracija s Flutter aplikacijo. |
| Firebase Cloud Messaging | Pošiljanje obvestil o novih sporočilih, povabilih in klicih v realnem času. |
| Cloudinary | Shranjevanje in optimizacija profilnih slik ter zmanjšanje obremenitve podatkovne baze. |
| LiveKit | Stabilna implementacija avdio in video klicev z nizko zakasnitvijo. |

### Uporabljene tehnologije

| Tehnologija | Namen |
|------------|---------|
| Flutter | Razvoj mobilne aplikacije |
| Dart | Programski jezik |
| Firebase Authentication | Registracija in prijava |
| Cloud Firestore | Shranjevanje podatkov |
| Firebase Cloud Messaging | Push obvestila |
| Cloudinary | Profilne slike |
| LiveKit | Avdio in video komunikacija |

---

# 📊 UML Diagrami

## Use Case Diagram

![Use Case Diagram](docs/usecase.jpg)

---

## Sequence Diagram

![Sequence Diagram](docs/sequence.jpg)

---

## Activity Diagram

![Activity Diagram](docs/activity.jpg)

---

## Deployment Diagram

![Deployment Diagram](docs/deployment.jpg)

---

## ER Diagram

![ER Diagram](docs/er.jpeg)

---

# 📂 Struktura projekta

```text
lib/
├── accessibility/
├── models/
├── screens/
├── services/
├── theme/
├── widgets/
├── firebase_options.dart
└── main.dart
```

### Glavni zasloni

- Login Screen
- Register Screen
- Profile Screen
- User Profile Screen
- Users List Screen
- Chat Screen
- Call Screen
- Incoming Call Screen
- Collaboration Screen
- Activity Analytics Screen

### Storitve

- Authentication Service
- Notification Service
- Call Notification Service
- Cloudinary Service
- Encryption Service
- Call Service

---

# 🚀 Namestitev

## Kloniranje repozitorija

```bash
git clone https://github.com/valentinaj24/SkillsMatch.git
```

## Namestitev odvisnosti

```bash
flutter pub get
```

## Zagon aplikacije

```bash
flutter run
```

---

# 🔐 Varnost

Aplikacija uporablja več mehanizmov za zagotavljanje varnosti:

- Firebase Authentication
- Firestore Security Rules
- HTTPS komunikacija
- Nadzor dostopa do podatkov
- Sistem ocen in verifikacij
- Upravljanje nastavitev zasebnosti

---

# 📱 Dostopnost

Pri razvoju smo posebno pozornost namenili dostopnosti, saj je aplikacija namenjena uporabnikom različnih starostnih skupin.

Implementirane funkcionalnosti:

- Temni način
- Večja velikost pisave
- Pregledna navigacija
- Veliki interaktivni elementi
- Enostaven uporabniški vmesnik

---

# 🔮 Nadaljnji razvoj

V prihodnosti načrtujemo:

- naprednejši sistem priporočanja uporabnikov,
- skupinska mentorstva,
- integracijo koledarja,
- spremljanje napredka pri učenju,
- sistem značk in dosežkov,
- večjezično podporo.

---

# 📋 Projektno vodenje

Pri razvoju projekta smo uporabljali GitHub Projects in Kanban metodologijo za organizacijo dela, spremljanje napredka.

Naloge so bile razdeljene v kategorije:

- Todo
- In Progress
- Done

Takšen pristop nam je omogočil pregled nad razvojem projekta, spremljanje napredka posameznih funkcionalnosti ter učinkovito sodelovanje med člani ekipe.

## Kanban tabla

![Kanban Board](docs/kanban.png)

# 👨‍💻 Projektna skupina

Projekt je bil razvit v okviru skupine **SkillBridge**.

### Člani ekipe

- Teodora Krunić
- Valentina Jovanović
- Mateja Djurić

---

# 📄 Licenca

Projekt je razvit izključno za izobraževalne in študijske namene.