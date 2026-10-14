# SaldoPilot – kort eiertest uten destruktive handlinger

Bruk denne listen med kjente poster. Ikke slett, importer, gjenopprett eller endre betalingsstatus bare for å teste. Ta JSON-backup før en ny appversjon installeres.

## Sikker start

- Bekreft hvilken database appen bruker. Oransje «ISOLERTE ICLOUD-TESTDATA» betyr testcontainer; uten banner kan appen vise produksjonsdata.
- Kontroller at noen kjente poster og forventet tilgjengelig beløp vises før du gjør noe annet.

## Ikke-destruktive kontroller

- Oversikt: Sammenlign inntekter, utgifter, netto, forfalt og neste forfall med kjente poster.
- Poster: Søk etter en kjent tittel, et kjent notat og en kategori.
- Filtre: Prøv Forfalt, Neste forfall, Neste 7 dager og Neste 30 dager. Trykk Tilbakestill etterpå.
- Detaljer: Åpne en kjent post og kontroller tittel, beløp, status, forfallsdato og eventuell betalingsdato. Gå tilbake uten å lagre.
- Statistikk: Velg en kjent måned og åpne en kategorisum for å se postene bak summen.
- Rapport: Lag en PDF for en kjent måned og sammenlign antall og totaler. Avbryt deling eller lagre bare lokalt i Filer.
- Synk: La begge enheter være på nett og kontroller at samme kjente post har samme verdi og status. Ikke fremprovoser konflikt i produksjonsdata.
- Språk/utseende: Kontroller ønsket språk og system/lys/mørk uten å endre økonomiske data.

## Stopp hvis noe avviker

Ikke importer backup eller slett data for å «rette» et avvik. Noter skjerm, tidspunkt, enhet, appversjon og hva som forventes, og behold siste JSON-backup urørt.
