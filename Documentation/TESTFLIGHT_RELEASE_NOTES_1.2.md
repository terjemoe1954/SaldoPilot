# SaldoPilot 1.2 – TestFlight-endringsnotater

## Hva er nytt

- Sikrere registrering av betalte regninger og mottatte inntekter, med tydelig betalingsdato og kontroll når kontoen ikke har dekning.
- Mer pålitelig månedlig gjentakelse, også rundt korte måneder og månedsslutt.
- Bedre søk og filtrering i Poster, inkludert kategori og kommende 7 eller 30 dager.
- Forbedrede rapporter med valg av rapporttype, omfang, måned og dato, samt tydelige planlagte og faktiske summer.
- PDF-rapporter håndterer lange navn/notater, mange sider, norsk/engelsk/thai, lagring, deling og AirPrint.
- JSON-backup omfatter transaksjoner, budsjetter og relevante innstillinger. CSV-eksport har tryggere tekstbehandling og bedre UTF-8-støtte.
- Mer pålitelig iCloud-synk, offlineinformasjon og omplanlegging av påminnelser.
- Oppdatert brukermanual med de samme begrepene som appen.

## Testfokus

Prøv særlig betaling og mottak, neste forekomst av gjentakende poster, søk/filtre, synk mellom enheter og PDF-rapport. Ta JSON-backup før testing med viktige data.

## Verifisert

Testet i separate lokale lagre og isolert iCloud-testcontainer på iPhone og iPad. Prosjektet bygger uten feil, og 14 av 14 automatiske tester består.
