# SonarQube analiza za Flutter projekt

Ta dokument opisuje postopek namestitve in uporabe SonarQube za analizo kakovosti kode v Flutter projektu.

## Predpogoji

Pred začetkom se prepričajte, da imate nameščeno:

* Docker Desktop
* Sonar Scanner
* Flutter projekt
* Dostop do interneta za prenos Sonar Flutter vtičnika

---

## 1. Zagon Docker Desktop

Zaženite aplikacijo Docker Desktop in počakajte, da se Docker storitve popolnoma inicializirajo.

---

## 2. Zagon SonarQube okolja

Premaknite se v mapo `sonarqube`:

```bash
cd .\sonarqube\
```

Zaženite SonarQube container:

```bash
docker-compose up -d
```

---

## 3. Namestitev Flutter vtičnika za SonarQube

Prenesite datoteko:

`sonar-flutter-plugin-0.5.2.jar`

z uradne GitHub strani:

https://github.com/insideapp-oss/sonar-flutter/releases

---

## 4. Kopiranje vtičnika v SonarQube container

Kopirajte preneseno JAR datoteko v SonarQube container:

```bash
docker cp sonar-flutter-plugin-0.5.2.jar sonarqube-sonarqube-1:/opt/sonarqube/extensions/plugins/
```

---

## 5. Ponovni zagon SonarQube containerja

Po uspešnem kopiranju vtičnika ponovno zaženite container:

```bash
docker restart sonarqube-sonarqube-1
```

Počakajte nekaj trenutkov, da se SonarQube ponovno zažene.

---

## 6. Dostop do SonarQube

Odprite SonarQube v brskalniku:

```text
http://localhost:9000/
```

---

## 7. Ustvarjanje dostopnega žetona (Token)

V SonarQube uporabniškem vmesniku:

1. Odprite **My Account**
2. Izberite **Security**
3. Ustvarite nov **Token**
4. Shranite ustvarjeni token, saj ga boste potrebovali pri analizi projekta

---

## 8. Zagon analize Flutter projekta

Premaknite se v korensko mapo Flutter aplikacije:

```bash
cd ..\skillsmatch
```

Zaženite analizo:

```bash
sonar-scanner -Dsonar.host.url=http://localhost:9000 -Dsonar.login=VAS_SONARQUBE_TOKEN
```

Namesto `VAS_SONARQUBE_TOKEN` uporabite token, ki ste ga ustvarili v prejšnjem koraku.

Primer:

```bash
sonar-scanner -Dsonar.host.url=http://localhost:9000 -Dsonar.login=sqp_xxxxxxxxxxxxxxxxxxxx
```

---

## 9. Pregled rezultatov

Po uspešno zaključeni analizi so rezultati dostopni na:

```text
http://localhost:9000/dashboard?id=SkillsMatch
```

Na nadzorni plošči lahko pregledate:

* Code Smells
* Bugs
* Vulnerabilities
* Coverage
* Technical Debt
* Quality Gate status

---

## Odpravljanje težav

### SonarQube se ne zažene

Preverite stanje containerjev:

```bash
docker ps
```

Preglejte dnevnike:

```bash
docker logs sonarqube-sonarqube-1
```

### Flutter pravila niso prikazana

Preverite, ali je bil vtičnik uspešno kopiran v container in ali je bil SonarQube po namestitvi ponovno zagnan.

### Napaka pri prijavi

Preverite veljavnost SonarQube tokena in pravilnost parametra:

```bash
-Dsonar.login=VAS_SONARQUBE_TOKEN
```
