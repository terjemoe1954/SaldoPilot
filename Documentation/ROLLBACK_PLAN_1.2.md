# SaldoPilot 1.2 – tilbakeføringsplan

## Før opplasting

- Behold en urørt JSON-backup laget med gjeldende app.
- Arkiver kildekoden og Xcode-arkivet som lastes opp, med versjon 1.2 og buildnummer.
- Noter datamodell, backupformat og CloudKit-container. Denne utgaven bruker SwiftData-skjema V3 og JSON-backupformat 4.
- Ikke slett eller endre produksjonscontaineren som del av en tilbakeføring.

## Hvis en TestFlight-build har en alvorlig feil

1. Stopp nye testere eller fjern den aktuelle builden fra testing i App Store Connect.
2. Be testerne slutte å bruke builden, men ikke slette appen, importere backup eller rydde iCloud-data.
3. Samle anonymisert feilinformasjonsdata: build, enhet, iOS-versjon, tidspunkt og handling.
4. Lag en korrigerende build med høyere buildnummer.
5. Behold samme eller nyere SwiftData-skjema, og migrer data framover ved behov.
6. Kjør isolerte migrerings-, backup-, synk- og regresjonstester før ny distribusjon.

## Hvorfor en eldre build ikke er standard tilbakeføring

En eldre appbuild kan mangle SwiftData-skjemaet eller migreringskoden som allerede har skrevet dataene. Den kan derfor feile ved åpning eller tolke data feil. Installer ikke automatisk en eldre build over et lager som er åpnet av 1.2.

Den tryggeste tilbakeføringen er en ny build basert på kjent god kode, men med gjeldende datamodell og nødvendige rettelser. Dette er en framoverrettet retting, ikke en nedgradering av data.

## Hvis data må gjenopprettes

1. Bevar originalen og ta en ny kopi/backup hvis appen fortsatt kan eksportere.
2. Reproduser mot en kopi eller isolert testcontainer, aldri direkte mot aktiv iCloud-database.
3. Kontroller backupens formatversjon før import.
4. Gjenopprett først i et separat testlager og sammenlign postantall, ID-er, historikk, budsjetter og summer.
5. Gjør ingen produksjonsimport uten uttrykkelig beslutning og en ny backup av dagens tilstand.

## Kode

- Tilbakefør bare de konkrete kodeendringene som forårsaket feilen; behold migrerings- og kompatibilitetskode.
- Ikke bruk destruktive Git-kommandoer på en arbeidskopi med ulagrede endringer.
- Bygg, kjør alle tester og gjennomfør eiertesten før et nytt arkiv lastes opp.

## CloudKit

- Slett aldri produksjonsskjema, poster eller container for å rulle tilbake en appbuild.
- Test synkendringer i `iCloud.com.terjemoe.SaldoPilot.Test`.
- En CloudKit-skjemaendring må behandles som framoverkompatibel og kan kreve en ny korrigerende build fremfor nedgradering.
