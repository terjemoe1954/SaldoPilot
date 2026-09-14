# SaldoPilot - anbefalte testdata

Dato: 14. september 2026

Bruk disse testdataene etter at du har slettet alle poster, eller i en ren simulator. Målet er å dekke de viktigste flytene før TestFlight.

## Før du starter

1. Ta backup hvis du har ekte data.
2. Gå til Settings.
3. Velg Delete all transactions.
4. Bekreft sletting.
5. Opprett postene nedenfor manuelt.

## Grunnoppsett

Bruk gjerne inneværende måned som testmåned.

Hvis dagens dato er langt ute i måneden, juster datoene slik:

- Forfalt: en dato før i dag.
- Kommende: en dato etter i dag.
- Neste forfall: den tidligste kommende datoen.
- Betalt/mottatt: sett dato til dagens dato eller en dato tidligere i måneden.

## Testposter

| Tittel | Type | Beløp | Kategori | Forfallsdato | Status | Gjentakelse | Notat |
|---|---:|---:|---|---|---|---|---|
| Lønn | Inntekt | 42000 | Income | 25. denne måned | Pending | Monthly | Fast månedslønn |
| Husleie | Utgift | 14500 | Home | 1. denne måned | Pending | Monthly | Skal bli forfalt hvis datoen er passert |
| Strøm | Utgift | 1249 | Home | i morgen | Pending | Monthly | Test neste forfall |
| Matbutikk | Utgift | 875 | Groceries | i dag | Pending | None | Dagligvaretest |
| Netflix | Utgift | 129 | Subscriptions | om 5 dager | Pending | Monthly | Abonnement |
| Telefon | Utgift | 399 | Communication | om 7 dager | Pending | Monthly | Mobil |
| Forsikring | Utgift | 699 | Insurance | om 10 dager | Pending | Monthly | Forsikring |
| Busskort | Utgift | 897 | Transport | om 12 dager | Pending | Monthly | Transport |
| Gave til bursdag | Utgift | 600 | Gifts | om 3 dager | Pending | None | Tester Gaver |
| Påleggstrekk skatt | Utgift | 2500 | Payroll deduction | 15. denne måned | Pending | Monthly | Tester Påleggstrekk |
| Refusjon jobb | Inntekt | 1200 | Income | om 2 dager | Pending | None | Tester til gode |
| Sparekonto | Utgift | 2000 | Savings | om 20 dager | Pending | Monthly | Sparing |
| Lege | Utgift | 375 | Health | for 3 dager siden | Pending | None | Skal vises som forfalt |
| Kino | Utgift | 220 | Entertainment | i dag | Paid | None | Sett betalt dato |
| App-utvikling | Inntekt | 3500 | Developer | for 2 dager siden | Received | None | Sett mottatt dato |

## Viktige tester med disse dataene

### Oversikt

Kontroller at:

- Inntekter viser Lønn, Refusjon jobb og App-utvikling når perioden dekker datoene.
- Utgifter viser alle utgifter i perioden.
- Netto regnes riktig.
- Forfalt viser Husleie og Lege hvis datoene er før i dag.
- Neste forfall peker på den tidligste kommende posten.

### Poster

Test filtrene:

- All
- Overdue
- Next due
- Upcoming
- Paid
- Receivable

Test sortering:

- Due date ascending
- Due date descending
- Amount descending
- Title ascending
- Category ascending
- Status ascending

### Betalt og mottatt

1. Åpne Strøm.
2. Velg Register paid date.
3. Sett dato til i dag.
4. Kontroller at status blir Paid/Betalt.
5. Kontroller at ny Strøm-post opprettes en måned frem i tid.

1. Åpne Refusjon jobb.
2. Velg Register received date.
3. Sett dato til i dag.
4. Kontroller at status blir Received/Mottatt.

### Gjentakelse

Marker disse som betalt/mottatt og kontroller at neste forekomst opprettes:

- Lønn: neste måned.
- Husleie: neste måned.
- Netflix: neste måned.
- Påleggstrekk skatt: neste måned.
- Sparekonto: neste måned.

Poster uten gjentakelse skal ikke lage ny post.

### Kategorier

Kontroller at kategorilisten er alfabetisk sortert, og at disse finnes:

- Gifts / Gaver / ของขวัญ
- Payroll deduction / Påleggstrekk / การหักเงินเดือนตามคำสั่ง

### Språk

Bytt språk i Settings:

- Norsk
- English
- Thai

Kontroller spesielt:

- Register paid date
- Register received date
- Delete all transactions
- Sorting
- Gifts
- Payroll deduction

## Etter test

1. Eksporter JSON.
2. Eksporter CSV.
3. Slett alle poster.
4. Importer JSON.
5. Kontroller at dataene kommer tilbake.
6. Slett alle poster igjen.
7. Importer CSV.
8. Kontroller at CSV-importen får med de viktigste feltene.

## Forslag til minimum før TestFlight

Appen bør klare dette uten feil:

- Opprette alle testpostene.
- Filtrere og sortere listen.
- Registrere betalt/mottatt dato.
- Opprette neste gjentakende post.
- Slette enkeltpost med bekreftelse.
- Slette alle poster med bekreftelse.
- Eksportere JSON og CSV.
- Importere JSON tilbake.
- Vise appen på norsk uten engelske nøkkeltekster i hovedflytene.

