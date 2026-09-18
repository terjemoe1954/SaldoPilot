# SaldoPilot Release Checklist

Sist oppdatert: 2026-09-18

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

## Kjente Punkter

- Appen bruker iCloud privat database når tilgjengelig. Derfor kan data komme tilbake etter reinstall dersom iCloud-sync er aktiv.
- Varsler krever at iOS har gitt SaldoPilot tillatelse under Settings > Notifications.
- Ekstern AI bør holdes valgfri og forklares tydelig i personverntekst.

## Neste Planlagte Arbeid

1. Fullføre Milestone 15.
2. Bestemme gratis/Pro-grense.
3. Starte Milestone 16 når første release er stabil.
