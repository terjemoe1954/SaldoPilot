# SaldoPilot Release Checklist

Sist oppdatert: 2026-09-24

Dette dokumentet brukes for siste sjekk før release og for å samle observasjoner etter lansering.

## Før Release

### App Store Connect

- [x] App status er godkjent
- [x] Riktig build er valgt for release
- [x] Versjon og buildnummer er riktig
- [x] App-navn er riktig
- [x] Undertittel er riktig
- [x] Beskrivelse er riktig
- [x] Keywords er lagt inn
- [x] Support URL fungerer
- [x] Privacy Policy URL fungerer
- [x] Screenshots er riktige for iPhone
- [x] Screenshots er riktige for iPad
- [x] Aldersgrense er riktig
- [x] App Review Notes er oppdatert

### Funksjonstest

- [x] Opprette ny utgift
- [x] Opprette ny inntekt
- [x] Registrere utgift som betalt
- [x] Registrere inntekt som mottatt
- [x] Gjentakende utgift oppretter neste post
- [x] Gjentakende inntekt oppretter neste post
- [x] Betalte/mottatte poster kan skjules og vises
- [x] Filter for forfalt fungerer
- [x] Filter for neste forfall fungerer
- [x] Filter for betalt/mottatt fungerer
- [x] Sortering i Poster fungerer
- [x] Tilgjengelig beløp vises riktig
- [x] Statistikk viser riktig språk og kategori
- [x] AI-oppsummering bruker valgt språk
- [x] Backup JSON fungerer
- [x] Backup CSV fungerer
- [x] Import JSON fungerer
- [x] Varsel for forfall i dag fungerer
- [x] Varselinnstillinger kan slås av og på

### Enhetstest

- [x] iPhone liten skjerm
- [x] iPhone stor skjerm
- [x] iPad
- [x] Lys modus
- [x] Mørk modus
- [x] Norsk språk
- [x] Engelsk språk
- [x] Thai språk

### Data Og Sync

- [x] App installert på nytt viser forventet iCloud-data
- [x] Endringer synker mellom iPhone og iPad
- [x] Backup er tatt før større testing
- [x] Slett alle poster krever bekreftelse

## Etter Release

Noter observasjoner her:

- Dato: 2026-09-18
- Versjon/build: App Store-versjon
- Enhet: iPad og iPhone
- Hva skjedde: Full test utført på iPad med testdata. App Store-installasjon på iPhone mottok iCloud-data etter sync.
- Hvor alvorlig: Ingen feil etter sync.
- Mulig løsning: Ved treg sync: kontroller samme Apple ID, iCloud for SaldoPilot og vent til CloudKit har synkronisert.

- Dato: 2026-09-19
- Versjon/build: App Store-versjon
- Enhet: iPad og iPhone
- Hva skjedde: App Store-versjonen er testet OK. iCloud-sync fungerer. Prosjektet går videre til Milestone 16 - Pro-Grunnlag.
- Hvor alvorlig: Ingen release-blokkerende feil.
- Mulig løsning: Ikke relevant.

- Dato: 2026-09-18
- Versjon/build: App Store Connect
- Enhet: Web
- Hva skjedde: Paid Apps/Agreements ble håndtert. Bankinformasjon ble lagt inn, og tax-dokumenter ble godkjent/fullført.
- Hvor alvorlig: Viktig Pro-forberedelse fullført.
- Mulig løsning: Neste steg er å kontrollere at appen er gratis, og opprette SaldoPilot Pro som non-consumable in-app purchase til 39 kr.

- Dato: 2026-09-24
- Versjon/build: 1.0.3 build 1
- Enhet: App Store
- Hva skjedde: Versjon 1.0.3 build 1 ble godkjent og ligger på App Store.
- Hvor alvorlig: Stabilitets- og forbedringsversjon fullført.
- Mulig løsning: Neste steg er Pro-test av kjøp/restore og planlegging av Milestone 17.

- Dato: 2026-09-24
- Versjon/build: 1.0.3 build 1
- Enhet: App Store/TestFlight-miljø
- Hva skjedde: SaldoPilot Pro-kjøp fungerte, status endret seg til Pro, status holdt etter restart, og restore fungerte.
- Hvor alvorlig: Pro-grunnlag bekreftet.
- Mulig løsning: Eksisterende basisfunksjoner forblir gratis. Første Pro-verdi blir nye planleggingsfunksjoner i Milestone 17.

- Dato: 2026-09-24
- Versjon/build: Xcode-build med budsjettgrunnlag
- Enhet: iPhone med eksisterende iCloud-data
- Hva skjedde: Etter installasjon direkte fra Xcode viste iPhone midlertidig doble beløp, mens iPad fortsatt viste riktige tall. Etter sletting av Xcode-build, restart og reinstall fra App Store ble tallene riktige igjen. SaldoPilot Pro-status vises riktig som Pro.
- Hvor alvorlig: Viktig testobservasjon for SwiftData/iCloud-migrering.
- Mulig løsning: Ikke test ny SwiftData-migrering videre på hoved-iPhone direkte fra Xcode. Bruk TestFlight, simulator eller separat testenhet før App Store-release.

## Kjente Punkter

- Appen bruker iCloud privat database når tilgjengelig. Derfor kan data komme tilbake etter reinstall dersom iCloud-sync er aktiv.
- Varsler krever at iOS har gitt SaldoPilot tillatelse under Settings > Notifications.
- Ekstern AI bør holdes valgfri og forklares tydelig i personverntekst.

## Mulige Endringer Etter Testing

- JSON-import: kategori `Hjem` kommer inn som `Annet` ved restore/import fra JSON. CSV-restore fungerer riktig. Undersøk kategori-mapping for norsk kategorinavn i JSON-import.

## Endringer Etter Testing Som Er Håndtert

- 2026-09-22: Poster/filter: beløpsbanneret i Poster følger nå filtrerte poster i stedet for alle aktive poster.
- 2026-09-22: Statistikk og kategori: kategorivisningen viser nå netto per kategori for måneden, slik at inntekt/gevinster i en utgiftskategori påvirker kategoribalansen.
- 2026-09-22: Gjentakende poster: ved endring eller sletting av en gjentakende post får brukeren valg mellom bare denne posten eller denne og fremtidige poster.

## Neste Planlagte Arbeid

1. Følge med på første budsjettgrunnlag i TestFlight/separat test før App Store-release.
2. Teste Pro-gate for Budsjett med gratis status hvis mulig.
3. Deretter legge til prognose for månedsslutt.

## Testplan For Milestone 17 - Budsjett

- [x] Bygg prosjektet i Xcode uten feil
- [x] Test migrering via TestFlight eller separat testenhet før hoved-iPhone brukes igjen
- [x] Installer på enhet med eksisterende iCloud-data
- [x] Bekreft at gamle poster fortsatt vises etter SwiftData-migrering
- [x] Åpne Budsjett som Pro-bruker
- [x] Sett budsjett på minst to kategorier
- [x] Sjekk at totalbudsjett, brukt og igjen oppdateres
- [x] Registrer ny utgift i en budsjettert kategori og sjekk at brukt/igjen endres
- [ ] Test at Budsjett viser Pro-informasjon når Pro ikke er låst opp
- [ ] Test norsk språk
- [ ] Test engelsk språk
- [ ] Test thai språk

Testplan: `AppStore/ProTesting.md`

## Testplan For 1.0.3

- [x] Bygg prosjektet i Xcode uten feil
- [x] Opprett eller finn en gjentakende post med minst én fremtidig post
- [x] Endre kategori på bare denne posten og sjekk at fremtidige poster ikke endres
- [x] Endre kategori på denne og fremtidige poster og sjekk at fremtidige matchende poster oppdateres
- [x] Slett bare denne posten og sjekk at fremtidige poster blir liggende
- [x] Slett denne og fremtidige poster og sjekk at fremtidige matchende poster slettes
- [x] Endre filter i Poster og sjekk at beløpsbanneret følger filteret
- [x] Registrer både utgift og inntekt på samme kategori og sjekk at Statistikk viser netto kategori
- [x] Test norsk språk
- [x] Test engelsk språk
- [x] Test thai språk
- [x] Test iCloud-sync etter endring av gjentakende poster

## Milestone 16 - Pro-Grunnlag Sjekkliste

### App Store Connect

- [x] Agreements: Paid Apps er åpnet
- [x] Paid Apps-avtalen er godkjent
- [x] Bankinformasjon er lagt inn
- [x] Tax Forms er fullført hvis Apple krever det
- [x] Pricing and Availability er åpnet og appen står som Free
- [x] SaldoPilot Pro er opprettet som non-consumable in-app purchase
- [x] Pro-produktet er satt til 39 kr
- [x] Save er trykket øverst til høyre

### Produktvalg

- [x] Betalingsmodell er endelig bestemt: gratis basisapp med SaldoPilot Pro som non-consumable in-app purchase til 39 kr
- [x] Gratis-funksjoner er definert
- [x] Pro-funksjoner er definert
- [x] StoreKit 2-oppsett er vurdert
- [x] StoreKit 2-grunnlag er lagt inn i appen
- [x] Kjøp fungerer i Sandbox/TestFlight/App Store-miljø
- [x] Restore purchases fungerer i Sandbox/TestFlight/App Store-miljø
- [x] Ingen bank-, skatte- eller personopplysninger er lagret i repoet
- [x] Enkel Pro-statusmodell er lagt inn i appen
- [x] Pro-informasjonsskjerm er lagt inn i Innstillinger
- [x] Eksisterende basisfunksjoner skal forbli gratis
- [x] Første Pro-verdi blir nye budsjett/prognose-funksjoner
