# SaldoPilot 1.3 – tilbakeføringsplan

## Bevaring

- Behold en urørt JSON-backup laget med gjeldende app.
- Behold kildekoden og Xcode-arkivet for versjon 1.3 build 8.
- Denne utgaven bruker SwiftData-skjema V3 og JSON-backupformat 4.
- Ikke slett eller endre produksjonscontaineren som del av en tilbakeføring.

## Hvis TestFlight-bygget har en alvorlig feil

1. Fjern build 1.3 (8) fra aktuelle testgrupper eller stopp nye testere.
2. Be testerne slutte å bruke bygget, men ikke slette appen, importere backup eller rydde iCloud-data.
3. Samle anonymisert feilinformasjon: build, enhet, iOS-versjon, tidspunkt og handling.
4. Lag en korrigerende build med høyere buildnummer.
5. Behold samme eller nyere SwiftData-skjema og migrer framover ved behov.
6. Kjør isolerte migrerings-, backup-, synk- og regresjonstester før ny distribusjon.

En eldre appbuild kan mangle skjemaet eller migreringskoden som allerede har skrevet dataene. Standard tilbakeføring er derfor en framoverrettet korrigerende build, ikke automatisk nedgradering.

## Data og CloudKit

- Reproduser og gjenopprett først i et separat testlager eller `iCloud.com.terjemoe.SaldoPilot.Test`.
- Gjør ingen produksjonsimport uten uttrykkelig beslutning og en ny backup av dagens tilstand.
- Slett aldri produksjonsskjema, poster eller container for å rulle tilbake en appbuild.
