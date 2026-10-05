# SaldoPilot Roadmap

Sist oppdatert: 2026-09-24

Dette dokumentet brukes som felles arbeidsplan når prosjektet flyttes mellom Mac hjemme og Mac på jobb. Før videre arbeid: sync siste endringer fra GitHub, åpne dette dokumentet, og fortsett fra aktiv milepæl.

## Status

- App Store review: Approved
- Nåværende App Store-versjon: 1.0.3 build 1
- Nåværende fokus: Milestone 17 - Budsjett og prognose
- Anbefalt betalingsretning: gratis basisapp med engangskjøp for SaldoPilot Pro

## Milestone 15 - Launch & Stabilitet

Mål: få første App Store-versjon rolig ut og samle erfaring uten å introdusere store nye endringer.

Oppgaver:

- [x] Publiser appen eller planlegg release-dato i App Store Connect
- [x] Sjekk at App Store metadata, skjermbilder og support/privacy-lenker er korrekte
- [x] Test installasjon fra App Store/TestFlight på iPhone
- [x] Test installasjon fra App Store/TestFlight på iPad
- [x] Test iCloud-sync mellom enheter
- [x] Test backup til JSON og CSV
- [x] Test import fra JSON
- [x] Test varsler for forfall i dag
- [x] Test betalt/mottatt flyt for gjentakende poster
- [x] Noter feil, spørsmål eller brukerfeedback i ReleaseChecklist.md

Kriterier for ferdig:

- Første offentlige versjon er ute eller klar til manuell release
- Ingen kritiske feil i betaling/mottak, gjentakelser, backup eller varsler
- Kjente mindre feil er notert for senere versjon

## Milestone 16 - Pro-Grunnlag

Mål: klargjøre appen for betalt funksjonalitet uten å låse produktet for tidlig.

Anbefalt modell:

- Gratis basisapp
- Engangskjøp: SaldoPilot Pro
- Anbefalt lav fast pris: 39 kr

Mulige Pro-funksjoner:

- AI-oppsummering og spørsmål
- Budsjett per kategori
- Prognose for månedsslutt
- Smarte forslag til kategori og gjentakelse
- Avanserte varsler
- Avansert eksport

Beslutning 2026-09-24:

- Eksisterende basisfunksjoner skal forbli gratis.
- Første Pro-verdi skal være nye planleggingsfunksjoner i Milestone 17.
- Budsjett per kategori og prognose markeres som første Pro-kandidater.
- Pro-låsing innføres først når de nye funksjonene er nyttige og testet.

Oppgaver:

- [x] App Store Connect: Agreements, Tax, and Banking
  - [x] Gå til Agreements
  - [x] Finn Paid Apps / Betalte apper
  - [x] Klikk Set Up eller View and Agree
  - [x] Godkjenn Paid Apps-avtalen
  - [x] Legg inn bankinformasjon: IBAN og BIC/SWIFT fra nettbank
  - [x] Fyll ut Tax Forms hvis Apple ber om det
  - [x] For Norge: normalt W-8BEN/egenerklæring om bosted og skatteplikt
  - [x] Ikke lagre IBAN, BIC/SWIFT eller skatteinformasjon i repoet
- [x] App Store Connect: Gratis app og Pro-produkt
  - [x] Kontroller at selve appen fortsatt er Free under Pricing and Availability
  - [x] Opprett In-App Purchase for SaldoPilot Pro
  - [x] Velg type Non-Consumable
  - [x] Sett Pro-pris til 39 kr
  - [x] Lagre endringer i App Store Connect
- [x] Bestem betalingsmodell endelig
- [x] Definer gratis vs Pro-funksjoner
- [x] Lage enkel Pro-statusmodell i appen
- [x] Lage skjerm for Pro-informasjon
- [x] Vurdere StoreKit 2-oppsett
- [x] Legge inn StoreKit 2-grunnlag i appen
- [x] Teste kjøp og gjenoppretting i Sandbox/TestFlight/App Store-miljø
- [x] Ikke aktivere kjøp før funksjonsgrensen er tydelig

Notat:

- App Store-versjonen er testet OK på iPad og iPhone.
- iCloud-sync fungerer mellom enheter.
- Agreements, bankinformasjon og tax-dokumenter ble fullført i App Store Connect 2026-09-18.
- Betalingsmodell valgt: gratis basisapp med SaldoPilot Pro som Non-Consumable In-App Purchase til 39 kr.
- App Store Connect Pro-produkt er opprettet som non-consumable in-app purchase.
- Planlagt StoreKit product ID: `com.terjemoe.SaldoPilot.pro`.
- Før StoreKit-kode legges inn bør avtaler, bank, skatt og pris være ryddet i App Store Connect.
- Pro-grunnlag i appen har enkel statusmodell, Pro-side i Innstillinger og StoreKit-kjøp/restore. Ingen funksjoner er låst ennå.
- StoreKit 2-grunnlag er lagt inn: produktlasting, kjøp, restore og entitlement-sjekk.
- Kjøp, restore og status etter restart/enhetsbytte er testet OK 2026-09-24.
- Testplan for kjøp og restore ligger i `AppStore/ProTesting.md`.

## Milestone 17 - Budsjett Og Prognose

Mål: gjøre appen mer nyttig for planlegging.

Pro-retning:

- Gratis: dagens oversikt, poster, statistikk, backup/import og grunnleggende gjentakelser.
- Pro: budsjett per kategori, varsel/nivå for budsjett, og prognose for månedsslutt.
- Første versjon bør være enkel: månedlig budsjett per kategori og en oversikt som viser brukt, igjen og forventet månedsslutt.

Første budsjettgrunnlag:

- [x] SwiftData-modell for månedlig kategoribudsjett
- [x] Budsjett-tab i appen
- [x] Pro-gate for budsjettvisning
- [x] Sett/endre budsjettbeløp per kategori for inneværende måned
- [x] Vis totalbudsjett, brukt og igjen
- [ ] Test migrering/iCloud med eksisterende App Store-data på enhet før release
- [ ] Test Pro-gate med gratis og Pro-status
- [ ] Legg til prognose for månedsslutt

Før Milestone 17:

- [x] Poster/filter: beløpsbanneret følger filtrerte poster
- [x] Statistikk: kategorioversikt viser netto per kategori for inneværende måned
- [x] Gjentakende poster: bruker kan velge bare denne posten eller denne og fremtidige poster ved endring/sletting
- [x] Test 1.0.3-endringene på iPhone
- [x] Test 1.0.3-endringene på iPad
- [x] Bygg og arkiver ny App Store Connect-build når test er OK
- [x] 1.0.3 build 1 er godkjent og ligger på App Store

Mulige funksjoner:

- Månedlig budsjett per kategori
- Varsel når en kategori nærmer seg budsjett
- Forventet saldo ved slutten av måneden
- Vis om kommende inntekter dekker kommende utgifter
- Bedre visning av faste poster

## Milestone 18 - AI-Assistent

Mål: AI som gir praktisk økonomihjelp uten å bli uklar eller invaderende.

Mulige spørsmål:

- Hva bør jeg betale først?
- Har jeg nok penger til resten av måneden?
- Hvorfor er denne måneden dyrere enn vanlig?
- Oppsummer de neste 14 dagene.
- Finn uvanlige utgifter.
- Foreslå budsjett basert på historikk.

Viktig:

- AI må følge valgt app-språk
- Ekstern AI må være valgfritt
- Personvern må forklares tydelig

## Milestone 19 - Smart Registrering

Mål: gjøre registrering raskere og enklere.

Mulige funksjoner:

- Forslag til kategori basert på tittel
- Forslag til gjentakelse når lignende post finnes
- Maler for vanlige poster
- Kopier poster fra forrige måned
- Hurtigregistrering for lønn og regninger

## Milestone 20 - App Store Polish

Mål: gjøre appen mer salgbar og lettere å forstå for nye brukere.

Mulige oppgaver:

- Bedre screenshots
- App preview-video
- Førstegangsveiledning
- Demo-/eksempeldata
- Brukermanual med bilder
- Forbedret App Store-tekst basert på feedback
