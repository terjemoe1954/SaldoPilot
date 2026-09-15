# SaldoPilot - testdata og testprosedyre

**Dato:** 15. september 2026  
**Formål:** Siste manuelle test før TestFlight og App Store Connect.

Bruk dette dokumentet etter at du har slettet alle poster, eller i en ren simulator. Testdataene dekker oversikt, poster, sortering, betalt/mottatt, gjentakelse, import/eksport og norsk språk.

## 1. Klargjøring

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Ta backup hvis du har ekte data. |
| [ ] | Gå til `Settings > Manage > Delete all transactions`. |
| [ ] | Bekreft sletting. |
| [ ] | Kontroller at `Oversikt` og `Poster` er tomme. |
| [ ] | Opprett testpostene i tabellen nedenfor manuelt. |

## 2. Dato-regel for test

| Situasjon | Bruk denne datoen |
|---|---|
| Forfalt | En dato før i dag |
| Kommende | En dato etter i dag |
| Neste forfall | Den tidligste kommende datoen |
| Betalt/mottatt | Dagens dato eller en dato tidligere i måneden |

## 3. Testposter

| Tittel | Type | Beløp | Kategori | Forfallsdato | Status | Gjentakelse | Notat |
|---|---:|---:|---|---|---|---|---|
| Lønn | Inntekt | 42000 | Income | 25. denne måned | Pending | Monthly | Fast månedslønn |
| Husleie | Utgift | 14500 | Home | 1. denne måned | Pending | Monthly | Skal bli forfalt hvis datoen er passert |
| Strøm | Utgift | 1249 | Home | I morgen | Pending | Monthly | Test neste forfall |
| Matbutikk | Utgift | 875 | Groceries | I dag | Pending | None | Dagligvaretest |
| Netflix | Utgift | 129 | Subscriptions | Om 5 dager | Pending | Monthly | Abonnement |
| Telefon | Utgift | 399 | Communication | Om 7 dager | Pending | Monthly | Mobil |
| Forsikring | Utgift | 699 | Insurance | Om 10 dager | Pending | Monthly | Forsikring |
| Busskort | Utgift | 897 | Transport | Om 12 dager | Pending | Monthly | Transport |
| Gave til bursdag | Utgift | 600 | Gifts / Gaver | Om 3 dager | Pending | None | Tester Gaver |
| Påleggstrekk skatt | Utgift | 2500 | Payroll deduction / Påleggstrekk | 15. denne måned | Pending | Monthly | Tester Påleggstrekk |
| Refusjon jobb | Inntekt | 1200 | Income | Om 2 dager | Pending | None | Tester til gode |
| Sparekonto | Utgift | 2000 | Savings | Om 20 dager | Pending | Monthly | Sparing |
| Lege | Utgift | 375 | Health | For 3 dager siden | Pending | None | Skal vises som forfalt |
| Kino | Utgift | 220 | Entertainment | I dag | Paid | None | Sett betalt dato |
| App-utvikling | Inntekt | 3500 | Developer | For 2 dager siden | Received | None | Sett mottatt dato |

## 4. Oversikt

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Inntekter viser `Lønn`, `Refusjon jobb` og `App-utvikling` når perioden dekker datoene. |
| [ ] | Utgifter viser alle utgifter i perioden. |
| [ ] | Netto regnes riktig. |
| [ ] | Forfalt viser `Husleie` og `Lege` hvis datoene er før i dag. |
| [ ] | Neste forfall peker på den tidligste kommende posten. |
| [ ] | Trykk på `Forfalt` og kontroller at `Poster` åpnes med riktig filter. |
| [ ] | Trykk på `Neste forfall` og kontroller at `Poster` åpnes med riktig filter. |

## 5. Poster

### Filtre

| Ferdig | Filter |
|---|---|
| [ ] | All |
| [ ] | Overdue |
| [ ] | Next due |
| [ ] | Upcoming |
| [ ] | Paid |
| [ ] | Receivable |

### Sortering

| Ferdig | Sortering |
|---|---|
| [ ] | Due date ascending |
| [ ] | Due date descending |
| [ ] | Amount descending |
| [ ] | Title ascending |
| [ ] | Category ascending |
| [ ] | Status ascending |

### Swipe-handlinger

| Ferdig | Handling |
|---|---|
| [ ] | Marker betalt. |
| [ ] | Rediger. |
| [ ] | Dupliser. |
| [ ] | Slett med bekreftelse. |

## 6. Betalt, mottatt og gjentakelse

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Åpne `Strøm` og velg `Register paid date`. |
| [ ] | Sett dato til i dag. |
| [ ] | Kontroller at status blir `Betalt` / `Paid`. |
| [ ] | Kontroller at ny `Strøm`-post opprettes en måned frem i tid. |
| [ ] | Åpne `Refusjon jobb` og velg `Register received date`. |
| [ ] | Sett dato til i dag. |
| [ ] | Kontroller at status blir `Mottatt` / `Received`. |

### Poster som skal lage neste forekomst

| Ferdig | Post | Forventning |
|---|---|---|
| [ ] | Lønn | Neste måned |
| [ ] | Husleie | Neste måned |
| [ ] | Netflix | Neste måned |
| [ ] | Påleggstrekk skatt | Neste måned |
| [ ] | Sparekonto | Neste måned |

Poster uten gjentakelse skal ikke lage ny post.

## 7. Kategorier

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Kategorilisten er alfabetisk sortert. |
| [ ] | `Gifts / Gaver` finnes. |
| [ ] | `Payroll deduction / Påleggstrekk` finnes. |
| [ ] | Automatisk kategoriforslag treffer på gave/gaver. |
| [ ] | Automatisk kategoriforslag treffer på påleggstrekk. |

## 8. Språk

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Bytt til `Norsk` og sjekk hovedflytene. |
| [ ] | Bytt til `English` og sjekk hovedflytene. |
| [ ] | Kontroller at `Register paid date` er oversatt. |
| [ ] | Kontroller at `Register received date` er oversatt. |
| [ ] | Kontroller at `Delete all transactions` er oversatt. |
| [ ] | Kontroller at sortering, `Gifts` og `Payroll deduction` vises riktig. |

## 9. Import og eksport

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Eksporter JSON. |
| [ ] | Eksporter CSV. |
| [ ] | Slett alle poster. |
| [ ] | Importer JSON og kontroller at dataene kommer tilbake. |
| [ ] | Slett alle poster igjen. |
| [ ] | Importer CSV og kontroller de viktigste feltene. |

## 10. Minimum før TestFlight

Appen bør klare dette uten feil:

| Ferdig | Krav |
|---|---|
| [ ] | Opprette alle testpostene. |
| [ ] | Filtrere og sortere listen. |
| [ ] | Registrere betalt/mottatt dato. |
| [ ] | Opprette neste gjentakende post. |
| [ ] | Slette enkeltpost med bekreftelse. |
| [ ] | Slette alle poster med bekreftelse. |
| [ ] | Eksportere JSON og CSV. |
| [ ] | Importere JSON tilbake. |
| [ ] | Vise appen på norsk uten engelske nøkkeltekster i hovedflytene. |
