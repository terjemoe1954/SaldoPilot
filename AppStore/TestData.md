# SaldoPilot - testdata og skjermbilder til App Store Connect

**Dato:** 16. september 2026  
**Formål:** Lage pene og realistiske data for TestFlight/App Store-skjermbilder.

Bruk dette datasettet i TestFlight/Production hvis du vil se ekte iCloud-sync mellom enheter. Ta JSON-backup før du sletter eller importerer data.

## Anbefalt oppsett

| Punkt | Anbefaling |
|---|---|
| Språk | Norsk for første skjermbildesett. Ta eventuelt egne sett på engelsk og thai senere. |
| Valuta | NOK / norske beløp. |
| Dato | Datasettet er laget for september 2026. Hvis du tester senere, flytt datoene relativt slik at noen poster er forfalt, noen forfaller snart og noen ligger senere i måneden. |
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

Bruk disse postene for å få gode tall i Oversikt, Poster, Statistikk, Til gode og AI-oppsummering.

| Tittel | Type | Beløp | Kategori | Forfallsdato | Status | Gjentakelse | Notat |
|---|---:|---:|---|---|---|---|---|
| Lønn september | Inntekt | 42000 | Income | 25.09.2026 | Venter | Månedlig | Fast månedslønn |
| Freelance app-design | Inntekt | 8500 | Developer | 18.09.2026 | Venter | Ingen | Prosjektbetaling |
| Refusjon jobb | Inntekt | 1200 | Income | 17.09.2026 | Venter | Ingen | Reiserefusjon |
| Husleie | Utgift | 14500 | Home | 01.09.2026 | Venter | Månedlig | Leilighet |
| Strøm | Utgift | 1249 | Home | 17.09.2026 | Venter | Månedlig | Estimert strømregning |
| Matbutikk | Utgift | 875 | Grocery | 16.09.2026 | Venter | Ingen | Ukeshandel |
| Busskort | Utgift | 897 | Transport | 18.09.2026 | Venter | Månedlig | Månedskort |
| Apple Developer Program | Utgift | 1290 | Developer | 19.09.2026 | Venter | Årlig | Utviklerkonto |
| Netflix | Utgift | 129 | Subscriptions | 21.09.2026 | Venter | Månedlig | Streaming |
| Mobilabonnement | Utgift | 399 | Communication | 22.09.2026 | Venter | Månedlig | Telefon |
| Innboforsikring | Utgift | 699 | Insurance | 24.09.2026 | Venter | Månedlig | Forsikring |
| Klær | Utgift | 1290 | Clothes | 23.09.2026 | Venter | Ingen | Jakke og sko |
| Sparekonto | Utgift | 2500 | Savings | 28.09.2026 | Venter | Månedlig | Automatisk sparing |
| Lege | Utgift | 375 | Health | 13.09.2026 | Venter | Ingen | Egenandel |
| Kino | Utgift | 220 | Entertainment | 15.09.2026 | Betalt | Ingen | Helgetur |
| Bursdagsgave | Utgift | 600 | Gifts | 20.09.2026 | Venter | Ingen | Gave |
| Lotto | Utgift | 120 | Gambling | 16.09.2026 | Betalt | Ingen | Testkategori |
| Kaffe med kunde | Utgift | 185 | Other | 16.09.2026 | Betalt | Ingen | Møte |

## Forventet uttrykk i appen

| Område | Hva datasettet skal vise |
|---|---|
| Oversikt | Inntekter, utgifter, netto og til gode får tydelige beløp. |
| Forfalt | Husleie og Lege skal vises som forfalt hvis dagens dato er etter 13.09.2026. |
| Neste forfall | Strøm eller Busskort bør bli neste kommende utgift, avhengig av dagens dato. |
| Til gode | Lønn september, Freelance app-design og Refusjon jobb gir en fin tilgode-sum. |
| Statistikk | Flere kategorier får ulike farger i grafen. Home blir størst, men ikke alene. |
| AI-oppsummering | Kommende betalinger skal telle bare utgifter, ikke inntekter. |

## Skjermbilder du bør ta

Ta skjermbilder etter at alle data er lagt inn. Bruk gjerne samme iPhone-størrelse for alle bilder.

| Nr. | Skjerm | Hva som bør være synlig | Hvorfor dette bildet er nyttig |
|---:|---|---|---|
| 1 | Oversikt | Kort for inntekter, utgifter, netto, til gode, forfalt og neste forfall. | Viser hovedverdien i appen med en gang. |
| 2 | Oversikt med AI-oppsummering | AI-kort med kommende betalinger og ryddige tall. | Viser at appen hjelper brukeren å forstå økonomien. |
| 3 | Poster | Liste med flere poster, typeikoner, status og filterlinje. | Viser at appen fungerer som en praktisk regningsoversikt. |
| 4 | Poster - filter | Velg Forfalt, Neste forfall eller Til gode. | Viser at brukeren raskt kan finne viktige poster. |
| 5 | Ny/rediger post | Skjema med tittel, beløp, type, kategori, dato og gjentakelse. | Viser hvor enkelt det er å legge inn en post. |
| 6 | Statistikk | Kategori-graf og månedlig utvikling. | Viser innsikt og visuell oversikt. |
| 7 | Statistikk - til gode | Rammen/grafen for tilgodebeløp nederst. | Viser at inntekter som ikke er mottatt håndteres separat. |
| 8 | Innstillinger | Språk, varsler, backup/import/eksport. | Viser trygghet, kontroll og flerspråklighet. |

## Anbefalt App Store-rekkefølge

| Rekkefølge | Skjermbilde | Kort budskap |
|---:|---|---|
| 1 | Oversikt | Se hva som kommer, hva som er betalt og hva du har til gode. |
| 2 | Poster | Hold orden på faste og enkeltstående betalinger. |
| 3 | Ny post | Legg inn beløp, kategori, forfall og gjentakelse raskt. |
| 4 | Statistikk | Forstå hvor pengene går med tydelige grafer. |
| 5 | Til gode / inntekter | Følg med på penger du venter på å motta. |
| 6 | Innstillinger | Backup, import, eksport, språk og varsler. |

## Tekstforslag til skjermbilder

Hvis du legger tekst på skjermbildene i App Store Connect-verktøy eller annet designverktøy, bruk korte tekster.

| Skjerm | Norsk tekst |
|---|---|
| Oversikt | Full kontroll på regninger og inntekter |
| Poster | Se hva som er betalt, forfalt og kommende |
| Ny post | Legg inn faste betalinger på sekunder |
| Statistikk | Se hvor pengene går |
| Til gode | Hold oversikt over penger du venter på |
| Innstillinger | Backup, språk og varsler på ett sted |

## Kontroll før skjermbilder

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Ingen ekte persondata eller private kontonavn vises. |
| [ ] | Alle poster har ryddige titler og kategorier. |
| [ ] | Kategorifargene i statistikk er ulike nok. |
| [ ] | Til gode viser bare inntekter som ikke er mottatt. |
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
| Ha minst tre ventende inntekter. | Til gode-funksjonen blir synlig. |
| Ha minst seks utgiftskategorier. | Statistikkgrafen blir mer interessant. |
| Ta skjermbilder samme dag som dataene passer. | Datoavhengige felter som forfalt og neste forfall blir riktige. |
