# SaldoPilot - neste steg

Dato: 14. september 2026

## Status akkurat nå

Appen har nå hovedfunksjonene for en tidlig TestFlight-kandidat:

- Oversikt
- Poster
- Statistikk
- Innstillinger
- Kategorier
- Betalt- og mottattdato
- Gjentakende poster med automatisk ny post
- Import og eksport til JSON/CSV
- iCloud/CloudKit-synk
- Språkvalg
- Sletting med bekreftelse
- Slett alle poster for testing

Du har også tatt backup til JSON og CSV og lagret filene i iCloud Drive.

## Viktig før du sletter data

Slettefunksjonen i Settings sletter registrerte poster fra appens SwiftData-lager.

Siden appen bruker iCloud/CloudKit, kan sletting synkes til iCloud. Det er derfor riktig at du tok backup først.

## Steg 1 - Test sletting av data

1. Åpne SaldoPilot.
2. Gå til Settings.
3. Gå til Manage.
4. Trykk Delete all transactions.
5. Bekreft sletting.
6. Gå til Overview og Transactions.
7. Kontroller at listene er tomme.
8. Vent litt dersom iCloud synk bruker noen sekunder.

## Steg 2 - Test import fra backup

1. Gå til Settings.
2. Gå til Import data.
3. Velg JSON-backupen du lagret i iCloud Drive.
4. Velg Merge hvis appen er tom.
5. Kontroller at postene kommer tilbake.
6. Kontroller kategorier, datoer, status og gjentakelse.

## Steg 3 - Test CSV-reserve

1. Slett postene igjen hvis du vil teste helt rent.
2. Gå til Import data.
3. Velg CSV-filen fra iCloud Drive.
4. Importer.
5. Kontroller at de viktigste feltene er riktige:
   - tittel
   - beløp
   - type
   - forfallsdato
   - betalt/mottattdato
   - status
   - kategori
   - gjentakelse

## Steg 4 - Test normal bruk

1. Opprett en inntekt.
2. Opprett en utgift.
3. Sett kategori på begge.
4. Registrer betalt dato på utgiften.
5. Registrer mottatt dato på inntekten.
6. Kontroller at status blir Betalt eller Mottatt.
7. Lag en gjentakende post.
8. Marker den som betalt.
9. Kontroller at neste post blir opprettet med ny dato.

## Steg 5 - Test forsiden

1. Se at Oversikt viser riktig inntekt, utgifter og netto.
2. Trykk på Forfalt hvis det finnes forfalte poster.
3. Trykk på Neste forfall hvis det finnes kommende poster.
4. Kontroller at Poster åpnes med riktig filter.
5. Test egendefinert periode fra/til.

## Steg 6 - Test Poster

1. Test filter:
   - Alle
   - Forfalt
   - Neste forfall
   - Kommende
   - Betalt
   - Til gode
2. Åpne filterarket.
3. Test periode/intervall.
4. Test sortering etter dato, beløp, tittel, kategori og status.
5. Swipe en post og test:
   - Marker betalt
   - Rediger
   - Dupliser
   - Slett med bekreftelse

## Steg 7 - Test språk

1. Gå til Settings.
2. Bytt språk til Norsk.
3. Gå gjennom de viktigste skjermene.
4. Bytt til English.
5. Bytt til Thai.
6. Noter tekster som fortsatt står på feil språk.

## Steg 8 - Test på iPhone og iPad

1. Test på iPhone-simulator.
2. Test på iPad-simulator eller fysisk iPad.
3. Kontroller at faner/meny fungerer.
4. Kontroller at plussknappen ikke dekker tabbaren.
5. Kontroller mørk modus.

## Steg 9 - Før TestFlight

1. Commit nåværende kode.
2. Lag screenshots.
3. Gå gjennom AppStore-mappen:
   - PrivacyPolicy.md
   - Support.md
   - AppStoreMetadata.md
   - AppPrivacyQuestionnaire.md
   - TestPlan.md
4. Opprett App Store Connect-record.
5. Sett versjon, for eksempel 0.1.
6. Arkiver og last opp build.
7. Start intern TestFlight.

## Anbefalt commit-melding

SaldoPilot pre-TestFlight cleanup and reset data tool

