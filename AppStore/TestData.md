# SaldoPilot - testdata og skjermbilder til App Store Connect

**Dato:** 18. oktober 2026
**Formål:** Lage pene og realistiske data for TestFlight/App Store-skjermbilder.

Bruk dette datasettet i TestFlight/Production hvis du vil se ekte iCloud-sync mellom enheter. Ta JSON-backup før du sletter eller importerer data.

## Anbefalt oppsett

| Punkt | Anbefaling |
|---|---|
| Språk | Norsk for første skjermbildesett. Ta eventuelt egne sett på engelsk og thai senere. |
| Valuta | NOK / norske beløp. |
| Dato | Datasettet er laget for oktober 2026. Ved senere opptak flyttes datoene samlet slik at statusene fortsatt er riktige. |
| Datamengde | 15-18 poster er nok. Det gir liv i oversikt, statistikk og filtre uten at appen ser rotete ut. |
| Ekte data | Ikke bruk egne bankdetaljer, ekte kundenavn eller private notater i skjermbilder. |

## Før du legger inn data

| Ferdig | Handling |
|---|---|
| [ ] | Ta JSON-backup hvis du har eksisterende data. |
| [ ] | Bruk TestFlight på en testkonto eller en trygg testdatabase. |
| [ ] | Gå til Innstillinger og slett alle poster hvis du vil ha helt rene skjermbilder. |
| [ ] | Sett språk til Norsk. |
| [ ] | Legg inn postene under manuelt, eller importer fra en egen testfil hvis du lager en. |

## Testdata for skjermbilder

Bruk disse postene for å få gode tall i Oversikt, Budsjett, Poster, Statistikk og Dagens innsikt.

| Tittel | Type | Beløp | Kategori | Forfallsdato | Status | Gjentakelse | Notat |
|---|---:|---:|---|---|---|---|---|
| Lønn oktober | Inntekt | 42000 | Lønn & Inntekt | 25.10.2026 | Venter | Månedlig | Fast månedslønn |
| App-design | Inntekt | 8500 | Hobby & Utvikling | 18.10.2026 | Mottatt | Ingen | Prosjektbetaling |
| Bidrag husleie og strøm | Inntekt | 7500 | Refusjon | 15.10.2026 | Mottatt | Månedlig | Samboers andel |
| Husleie | Utgift | 14500 | Bolig & strøm | 01.10.2026 | Betalt | Månedlig | Leilighet |
| Strøm | Utgift | 1249 | Bolig & strøm | 17.10.2026 | Betalt | Månedlig | Strømregning |
| Ukeshandel | Utgift | 875 | Dagligvarer | 16.10.2026 | Betalt | Ingen | Mat og husholdning |
| Busskort | Utgift | 897 | Transport | 20.10.2026 | Venter | Månedlig | Månedskort |
| Utviklerprogram | Utgift | 1290 | Hobby & Utvikling | 21.10.2026 | Venter | Årlig | Utviklerkonto |
| Strømmetjeneste | Utgift | 129 | Abonnementer | 21.10.2026 | Venter | Månedlig | Film og serier |
| Mobil og internett | Utgift | 799 | Telefon & internett | 22.10.2026 | Venter | Månedlig | Mobil- og internettpakke |
| Innboforsikring | Utgift | 699 | Forsikring | 24.10.2026 | Venter | Månedlig | Forsikring |
| Jakke og sko | Utgift | 1290 | Klær & sko | 23.10.2026 | Venter | Ingen | Høstklær |
| Overføring til sparekonto | Utgift | 2500 | Sparing | 28.10.2026 | Venter | Månedlig | Mellom egne kontoer |
| Brilleabonnement | Utgift | 375 | Helse | 13.10.2026 | Betalt | Månedlig | Syn og briller |
| Kino | Utgift | 220 | Fritid & ferie | 15.10.2026 | Betalt | Ingen | Helgetur |
| Middag ute | Utgift | 685 | Spise ute | 16.10.2026 | Betalt | Ingen | Restaurant |
| Restskatt | Utgift | 1600 | Skatt & avgifter | 30.10.2026 | Venter | Ingen | Restskatt |
| Bursdagsgave | Utgift | 600 | Gaver | 27.10.2026 | Venter | Ingen | Gave |

## Budsjett for skjermbilder

| Kategori | Månedsbudsjett |
|---|---:|
| Bolig & strøm | 17000 |
| Dagligvarer | 5000 |
| Transport | 1500 |
| Spise ute | 1800 |
| Fritid & ferie | 2500 |
| Lønn & Inntekt | 42000 |

## Forventet uttrykk i appen

| Område | Hva datasettet skal vise |
|---|---|
| Oversikt | Inntekter, utgifter, netto og til gode får tydelige beløp. |
| Forfalt | Ingen betalt post skal vises som forfalt. Flytt én ventende testpost bak dagens dato hvis bildet skal vise forfalt-status. |
| Neste forfall | Busskort eller Utviklerprogram skal være neste kommende utgift, avhengig av opptaksdato. |
| Inntekter | Lønn, prosjektbetaling og refusjon gir en tydelig inntektsvisning. |
| Budsjett | Inntektsmålet og flere utgiftskategorier viser forventet mot oppnådd. |
| Statistikk | Flere kategorier gir varierte grafer. Bolig & strøm er størst uten å stå alene. |
| Innsikt | Vanlige utgifter telles med; sparing mellom egne kontoer og saldojusteringer holdes utenfor. |

## Skjermbilder du bør ta

Ta skjermbilder etter at alle data er lagt inn. Bruk gjerne samme iPhone-størrelse for alle bilder.

| Nr. | Skjerm | Hva som bør være synlig | Hvorfor dette bildet er nyttig |
|---:|---|---|---|
| 1 | Oversikt | Kort for inntekter, utgifter, netto, til gode, forfalt og neste forfall. | Viser hovedverdien i appen med en gang. |
| 2 | Budsjett | Budsjettlinjer for inntekt og utgifter med forventet og oppnådd. | Viser planlegging og fremdrift. |
| 3 | Ny post | Beskrivelse, kategoriforslag, beløp, dato og status. | Viser rask og hjelpsom registrering. |
| 4 | Poster | Liste med flere poster, typeikoner, status og filterlinje. | Viser praktisk kontroll over regninger og inntekter. |
| 5 | Statistikk | Kategorigraf og månedlig utvikling. | Viser innsikt og visuell oversikt. |
| 6 | Innstillinger | Personvern, backup, språk og varsler. | Viser trygghet og kontroll. |

## Anbefalt App Store-rekkefølge

| Rekkefølge | Skjermbilde | Kort budskap |
|---:|---|---|
| 1 | Oversikt | Se hva som kommer, hva som er betalt og hva du har til gode. |
| 2 | Budsjett | Se forventet og oppnådd på ett sted. |
| 3 | Ny post | Få kategoriforslag mens du skriver. |
| 4 | Poster | Hold orden på regninger, lønn og refusjoner. |
| 5 | Statistikk | Forstå hvor pengene går med tydelige grafer. |
| 6 | Innstillinger | Personvern, backup, språk og varsler. |

## Tekstforslag til skjermbilder

Hvis du legger tekst på skjermbildene i App Store Connect-verktøy eller annet designverktøy, bruk korte tekster.

| Skjerm | Norsk tekst |
|---|---|
| Oversikt | Se hva du faktisk har igjen |
| Budsjett | Få kontroll på månedens budsjett |
| Ny post | Registrer raskt med kategoriforslag |
| Poster | Følg regninger, lønn og refusjoner |
| Statistikk | Forstå hvor pengene går |
| Innstillinger | Dine data. Din private iCloud. |

## Kontroll før skjermbilder

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Ingen ekte persondata eller private kontonavn vises. |
| [ ] | Alle poster har ryddige titler og kategorier. |
| [ ] | Kategorifargene i statistikk er ulike nok. |
| [ ] | Refusjon vises som inntekt, men ikke som vanlig forbruk. |
| [ ] | Sparing mellom egne kontoer holdes utenfor vanlig forbruk og inntekt. |
| [ ] | Kommende betalinger viser bare utgifter. |
| [ ] | Ingen tomme grafer eller rare nullverdier vises. |
| [ ] | Norsk språk er aktivt for norske skjermbilder. |
| [ ] | Klokken/batteri/statuslinje ser ryddig ut i simulator eller på enhet. |

## Tips for penere skjermbilder

| Tips | Hvorfor |
|---|---|
| Bruk færre, tydelige poster i listen. | En ryddig liste selger appen bedre enn en full testdatabase. |
| Unngå veldig store eller rare beløp. | Realistiske tall bygger tillit. |
| Ha minst én forfalt post og flere kommende poster. | Appen får vist de viktigste statusene. |
| Ha både mottatte og ventende inntekter. | Inntektsmål og fremdrift blir tydelige. |
| Ha minst seks utgiftskategorier. | Statistikkgrafen blir mer interessant. |
| Ta skjermbilder samme dag som dataene passer. | Datoavhengige felter som forfalt og neste forfall blir riktige. |
