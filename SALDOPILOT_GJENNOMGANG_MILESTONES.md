# SaldoPilot – gjennomgang, forbedringer og utskrift

Opprettet: 14. oktober 2026
Formål: Gjennomgå den eksisterende SwiftUI-appen, finne dokumenterbare feil og synlige mangler, forbedre enkelheten og sikre at brukeren kan skrive ut relevante opplysninger.

## Oppdrag til Codex

Arbeid i det eksisterende SaldoPilot-prosjektet. Les AGENTS.md, eksisterende milepæler og prosjektets dokumentasjon først. Denne planen supplerer tidligere planer. Undersøk den faktiske koden før du konkluderer med at noe mangler. Appen brukes aktivt av eieren og har mye verdifull data. Bevar den kjente arbeidsflyten og gjør små, målrettede endringer.

Start med M0 og M1. Lag deretter en prioritert oversikt over funn før du retter feil i M2. Fullfør én milepæl om gangen, oppdater avkryssingene og rapporter hva som er endret, hva som er testet og hva eieren må prøve på sin iPhone. Fortsett med neste gjennomførbare steg innenfor oppdraget. Spør bare når en uklarhet faktisk påvirker økonomisk betydning, databevaring eller en større endring av brukerens arbeidsflyt.

### Forventet utgangspunkt – må bekreftes i prosjektet

- Oversikt over inntekter, utgifter og saldo for valgt periode.
- Forfalte poster, bilagsliste, kategorier og datofiltre.
- Gjentakende poster hvor registrert betaling kan flytte neste forfallsdato.
- iCloud-synkronisering.
- Innstillinger for norsk, engelsk og thai, lyst/mørkt/system samt versjon og build, dersom disse finnes i prosjektet.

Dette er kontrollpunkter, ikke en beskrivelse av verifisert nåværende funksjonalitet.

## Regler som gjelder gjennom hele arbeidet

1. Ikke slett, nullstill, overskriv eller konverter brukerens aktive database som ledd i testing. Ikke legg testposter inn i produksjonsdata.
2. Bruk en separat lokal testdatabase og syntetiske eller anonymiserte kopier. Hvis faktisk iCloud-synk skal testes, bruk et adskilt testoppsett; samme konto og container kan påvirke ekte data også fra en simulator.
3. Kartlegg backup og gjenoppretting før risikofylte modellendringer. En PDF eller CSV er ikke automatisk en fullstendig backup.
4. Bevar identifikatorer, relasjoner og betalingshistorikk. Gjør nødvendige migreringer eksplisitte og prøv dem på en kopi først.
5. Ikke skriv personlige beløp, navn, kontoinformasjon eller vedlegg inn i logger, skjermbilder, git eller rapporter til andre.
6. Ingen total omskriving, ny server, AI-funksjon eller endring av prismodell som del av denne gjennomgangen.
7. Retting av feil og enkle forbedringer går foran nye funksjoner. Gode eksisterende funksjoner skal beholdes.
8. Ikke oppgi at en kontroll er bestått hvis miljøet ikke kan kjøre den. Merk den som «må testes på enhet» med konkrete steg.

## Status og registrering av funn

Status: Ikke startet / Pågår / Ferdig / Blokkert.

Opprett SALDOPILOT_FUNN.md i prosjektets dokumentasjonsmappe. Hvert funn skal ha ID, skjerm eller fil, reproduksjonssteg, forventet/faktisk resultat, konsekvens, prioritet, foreslått tiltak og testresultat. Skill bekreftede feil fra forbedringsforslag og ubesvarte spørsmål.

| Prioritet | Betydning | Arbeidsrekkefølge |
|---|---|---|
| P0 | Datatap, feil beløp/saldo eller farlig synkfeil | Rett først |
| P1 | Krasj eller sentral funksjon som ikke virker | Rett før utgivelse |
| P2 | Utydelig arbeidsflyt, feil filter eller manglende viktig utskrift | Etter P0/P1 |
| P3 | Kosmetikk og valgfrie forbedringer | Ved dokumentert nytte |

## M0 – trygg oppstart og kartlegging

- [x] Les prosjektreglene og noter aktiv versjon/build, plattformkrav og datalagring.
- [x] Kartlegg modeller, summeringslogikk, gjentakelse, betalingshistorikk, iCloud, eksport og eventuell backup.
- [x] Kontroller git-status og bevar brukerens uferdige endringer.
- [x] Bygg dagens prosjekt og noter eksisterende feil og relevante advarsler.
- [x] Etabler separat testdatasett og skriv ned hvordan det holdes adskilt fra ekte data.
- [x] Dokumenter tilgjengelig backup, hva den inkluderer og om gjenoppretting er verifisert på en kopi.
- [x] Lag oversikt over skjermbilder og hovedflyt uten å endre funksjoner.

Status: Ferdig 14. oktober 2026. Se `Documentation/SALDOPILOT_FUNN.md`. Transaksjonsbackup er gjenopprettet og feltsammenlignet mellom to isolerte minnelagre; full appbackup finnes fortsatt ikke. Skjermkontroll er uttrykkelig merket «må testes på enhet». Aktiv database ble ikke brukt.

Ferdig når: Dagens tilstand er dokumentert og videre testing kan utføres uten å endre brukerens aktive data.

## M1 – gjennomgang med en ny brukers øyne

- [x] Gå gjennom førstegangsbruk, tom database og bruk med mange poster.
- [x] Undersøk om en ny bruker forstår inntekt, utgift, saldo, forfall og betalt uten forklaring.
- [x] Kontroller opprette, redigere, slette, registrere betaling, finne historikk og filtrere.
- [x] Undersøk om aktive filtre, periode og valgt datotype er synlige i resultatet.
- [x] Kontroller tydelige titler, konsekvente begreper og forskjellen mellom «ingen poster» og «ingen treff».
- [x] Vurder om kategorier er konsekvent navngitt; ikke bytt interne modellnavn bare for å endre en visningstekst.
- [x] Kontroller om tilbakeknapp, avbryt og lagre oppfører seg forventet, også med ulagrede endringer.
- [x] Registrer funn med prioritet og skill subjektive ønsker fra reproduserbare feil.

Status: Ferdig ved statisk gjennomgang 14. oktober 2026. Visuell kontroll, stor datamengde og gestbasert avbryt må testes på iPhone med isolert lager.

Ferdig når: Alle hovedskjermer og brukerflyter er gjennomgått, og funnlisten viser de viktigste tiltakene først.

## M2 – beløp, datoer og betaling må være riktige

- [x] Verifiser fortegn, inntekt/utgift, avrunding og summering mot manuelt beregnede fasiter. (Syntetisk oktoberfasit: 10 000,10 − 1 234,55 = 8 765,55; annullerte, arkiverte og neste periodes poster utelatt.)
- [x] Undersøk desimalhåndtering og unngå at binær flyttallsavrunding gir feil økonomiske resultater. (`Decimal`/`NSDecimalNumber` brukes nå gjennom parsing og valutavisning.)
- [x] Kontroller desimalkomma, desimalpunkt, limte beløp, null og store beløp. Definert gyldig postbeløp: positivt, maksimalt to desimaler; vanlige norske/engelske skilletegn og valgfritt NOK/kr godtas.
- [x] Kontroller periodegrenser, inkludert første/siste dag, månedsskifte, årsskifte og skuddår. (SP-012 rettet: sluttpunktet er nå eksklusivt.)
- [x] Kontroller datoer rundt tidssoner og sommertid slik at poster ikke flytter kalenderdag utilsiktet. (Halvåpen periode kontrollert i `Europe/Oslo`, inkludert den 25 timer lange 25.10.2026.)
- [x] Avklar og dokumenter hva saldo betyr: «Tilgjengelig» er startsaldo + mottatte inntekter − betalte utgifter fra valgt startsaldodato. «Netto» er perioderesultat for planlagte poster.
- [ ] Kontroller om filtrering på forfallsdato og betalingsdato gir riktige og forståelige resultater.
- [ ] Verifiser at betaling av en gjentakende post bevarer den betalte forekomstens beløp og dato når neste forfall beregnes.
- [ ] Test intervallene appen faktisk støtter, spesielt dato 29., 30. og 31. og betaling lenge etter forfall. (Delvis: P1-datodrift etter februar bekreftet som SP-011; sen betaling gjenstår.)
- [x] Kontroller dobbelttrykk på «Betalt», redigering av betalt post og eventuell angre-funksjon. (Idempotens og redigeringskonsistens rettet; angre finnes ikke og er registrert for senere vurdering.)
- [ ] Avklar om manglende eldre betalingshistorikk skyldes dagens modell. Ikke konstruer historikk fra en nåværende forfallsdato.
- [ ] Skriv målrettede tester for feil som rettes og økonomisk logikk med høy konsekvens.

Ferdig når: Kjente P0/P1-feil innen beløp og betaling er rettet, og representative fasiter stemmer mellom liste, oversikt og rapport.

## M3 – lagring, synk og mange poster

- [ ] Kontroller at oppretting og redigering bevares etter avslutning og omstart.
- [ ] Test offlinebruk og overgang tilbake til nett.
- [ ] Test iCloud-synk i adskilt oppsett: nye poster, endringer, sletting og samtidige endringer på to enheter.
- [ ] Kontroller duplikater og at dobbel betaling ikke oppstår ved gjentatte synkforsøk.
- [ ] Kontroller feiltilstander og tydelig informasjon ved manglende iCloud eller nett; unngå å vise falsk synkbekreftelse.
- [ ] Test søk, scrolling, filtrering og rapport med mange syntetiske poster, eksempelvis 1 000 og 10 000 hvis relevant.
- [ ] Mål merkbare forsinkelser før optimalisering; unngå tung rapportgenerering som låser grensesnittet.
- [ ] Hvis modellendring er nødvendig: prøv oppgradering fra gammel database på kopi og sammenlign antall, summer og relasjoner.

Ferdig når: Data lagres og synkes som forventet i testoppsettet, og begrensninger eller konflikter er dokumentert.

## M4 – enklere og mer oversiktlig

- [ ] Gjør periode, aktive filtre og hva summeringen omfatter lett synlig.
- [ ] Vurder tydelig «Nullstill filtre» og enkel veksling mellom forfalt, kommende og betalt hvis det passer dagens modell.
- [ ] Gjør primære handlinger lette å finne og gi tydelig bekreftelse når data lagres eller betaling registreres.
- [ ] Gjør sletting forståelig og gi bekreftelse eller angremulighet der det er hensiktsmessig.
- [ ] Kontroller kontrast, store tekststørrelser, VoiceOver, trykkflater og at status ikke uttrykkes bare med farge.
- [ ] Kontroller liten/stor iPhone, tastatur og eventuelle iPad-visninger som prosjektet allerede støtter.
- [ ] Kontroller lyst, mørkt og systemutseende.
- [ ] Kontroller norsk, engelsk og thai, inkludert lange tekster, datoer, tall og rapporter.
- [ ] Vurder en kort hjelpetekst om periode, gjentakelse og betaling der brukeren trenger den.

Ferdig når: Hovedoppgavene kan utføres uten skjulte filtervalg, avklippede tekster eller unødvendige steg.

## M5 – komplett og forståelig utskrift

Kartlegg eksisterende utskrift først. Lag deretter én konsekvent rapportflyt som kan nås fra oversikten, bilagslisten og detaljvisningen der det er naturlig. Bruk systemets utskriftsdialog på iOS og en delbar PDF. Ingen utskrift skal kreve skjermbilder.

### Rapporter som skal kunne lages

| Rapport | Minimumsinnhold |
|---|---|
| Periodeoversikt | Periode, filtervalg, inntekt, utgift, saldoens definerte betydning og relevante poster |
| Filtrert bilagsliste | Alle treff, også utenfor synlig skjerm; tittel, kategori, beløp, status og relevante datoer |
| Forfalte og kommende poster | Status, forfallsdato, beløp og totalsum for valgt tidsrom |
| Betalingshistorikk | Faktiske lagrede betalinger med betalingsdato og beløp, filtrert på betalingsdato |
| Kategorioversikt | Inntekt/utgift og summer per kategori for valgt periode |
| Enkeltpost | Lagrede detaljer, notater, gjentakelse og tilhørende historikk hvis tilgjengelig |
| Fullstendig dataliste | Alle lagrede økonomiske poster innen tydelig valgt omfang, uavhengig av skjermens aktive filtre |

Hvis en rapport krever data modellen ikke lagrer, dokumenter dette og foreslå minste nødvendige tiltak. Manglende verdier merkes tydelig; de skal ikke erstattes med gjetninger. Hvis appen støtter flere valutaer, skal summer ikke blandes uten en definert valutakonvertering.

### Valg og utforming

- [ ] Brukeren velger rapport, periode og enten «gjeldende filtre» eller «alle poster». Vis hva valget omfatter.
- [ ] Vis antall poster, periode, datotype og aktive filtre i forhåndsvisning og rapporthode.
- [ ] Bruk samme filtrerings- og beregningsgrunnlag i app og rapport; unngå parallelle regler som gir avvik.
- [ ] Generer en konsistent kopi av utvalget slik at pågående synk ikke endrer summer halvveis i rapporten.
- [ ] Rapporten har SaldoPilot, rapporttittel, genereringsdato, tydelige kolonner og sidenummer.
- [ ] Bruk utskriftsvennlig A4, lyse flater, lesbar skrift og tilstrekkelige marger; bred tabell kan bruke liggende format.
- [ ] Gjenta kolonneoverskrifter på nye sider og håndter lange notater uten avklipping eller overlapp.
- [ ] Bruk norsk/valgt språk, korrekt valutaformat og tydelige datoer.
- [ ] Totaler skal tydelig gjelde hele rapportutvalget. Skill planlagte beløp fra faktiske betalinger.
- [ ] Vis en forståelig tom rapport eller melding når utvalget ikke har data.
- [ ] Tilby forhåndsvisning, «Skriv ut» og «Del / lagre PDF». Brukeren velger mottaker i systemets delingsark.
- [ ] Vedlegg: Hvis appen lagrer kvitteringer eller andre dokumenter, la brukeren åpne og skrive ut støttede vedlegg, eller velge å inkludere dem. Dokumenter formater som ikke kan skrives ut.
- [ ] Håndter avbryt, manglende skriver og genereringsfeil uten å endre økonomiske data.

### Testkrav for utskrift

- [ ] Test 0, 1, 50 og minst 1 000 poster samt lange navn/notater og store beløp.
- [ ] Sammenlign antall, utvalg og totaler med manuelt kontrollert testdatasett.
- [ ] Kontroller PDF visuelt: første side, sideskift, totalside og vedlegg hvis støttet.
- [ ] Kontroller at hele listen eksporteres og at skjulte filtre ikke fjerner poster fra «alle poster».
- [ ] Test deling og PDF-lagring på enhet.
- [ ] Test faktisk AirPrint på iPhone når skriver er tilgjengelig; PDF-generering alene bekrefter ikke fysisk utskrift.
- [ ] Kontroller at brukeren selv velger å dele sensitive økonomiske opplysninger.

Ferdig når: Relevante rapporter kan forhåndsvises, lagres som PDF og sendes til utskrift med riktige data. Ikke tilgjengelige kontroller er eksplisitt dokumentert.

## M6 – forbedringspotensial uten å gjøre appen tung

Vurder hvert forslag ut fra brukerbehov, eksisterende funksjonalitet, kompleksitet og risiko. Implementer bare små forbedringer med klar nytte innenfor dette oppdraget. Registrer større ideer i en egen senere-liste.

- [ ] Kommende 7/30 dager: Vil dette gjøre regninger enklere å planlegge, og finnes det allerede?
- [ ] Søk etter navn, kategori og notat: Er det lett å finne igjen eldre poster?
- [ ] Gjenbruk av tidligere post: Kan registrering gjøres enklere uten å kopiere betalingsstatus og historikk feil?
- [ ] Kategorisummer: Finnes en enkel vei fra kategoriens sum til postene bak den?
- [ ] Påminnelser: Hvis appen har dem, kontroller tillatelse, endrede datoer og duplikater.
- [ ] CSV-eksport: Vurder som tillegg for regneark; kontroller tegnsett, skilletegn og sikker behandling av tekst som regneark kan tolke som formler.
- [ ] Backup/gjenoppretting: Vurder behov og løsning ut fra hva M0 fant; hold dette adskilt fra rapportutskrift.
- [ ] Kort brukerveiledning: Forklar de viktigste oppgavene med samme begreper som appen.

Ferdig når: De mest verdifulle forslagene er rangert, med tydelig skille mellom implementert og utsatt.

## M7 – samlet regresjon og eierens test

- [ ] Bygg prosjektet og kjør relevante automatiserte tester for berørte funksjoner.
- [ ] Test hovedflyt fra ny post til betaling, neste forfall, filtrering og utskrift.
- [ ] Test redigering og sletting, omstart, offlinebruk og synk i sikkert testoppsett.
- [ ] Test tom database og stor database, alle språk og utseender som appen støtter.
- [ ] Sammenlign et fast testdatasett før/etter: postantall, historikk og økonomiske summer.
- [ ] Lag en kort sjekkliste som eieren kan prøve med sine kjente poster, uten destruktive testhandlinger.
- [ ] La eieren kontrollere at appen fremdeles føles enkel og gjenkjennelig.
- [ ] Registrer faktisk testmiljø, build og resultat. Ikke merk eiertest eller fysisk utskrift bestått før det er gjort.

Ferdig når: Ingen uavklarte P0/P1-feil gjenstår, og nødvendige kontroller på enhet er utført eller tydelig oppført som blokkering for utgivelse.

## M8 – klargjøring til TestFlight og senere App Store

- [ ] Skriv korte endringsnotater om faktiske rettelser, enkelhet og utskrift.
- [ ] Kontroller hjelpetekster og personvernbeskrivelse hvis dataflyten er endret.
- [ ] Oppdater build ved ny opplasting og bruk prosjektets versjonspraksis.
- [ ] Lag konkrete TestFlight-testinstruksjoner, særlig for betaling, synk og rapporter.
- [ ] Dokumenter tilbakeføringsplan for kode og eventuelle modellendringer. En eldre appbuild kan ikke antas å åpne en ny datamodell.
- [ ] Etter godkjent eiertest: vurder norske App Store-bilder som viser forfall, enkel registrering og en ekte rapport med anonymiserte eksempeldata.
- [ ] Ikke arkiver, last opp eller publiser automatisk som del av denne milestone-filen; lever prosjektet klart for eierens vanlige utgivelsesløp.

Ferdig når: Endringene er dokumentert og klare for testing og utgivelse i eierens miljø.

## Fast sluttrapport etter hver milepæl

1. Fullført arbeid og konkret nytte for brukeren.
2. Filer eller funksjoner som er endret.
3. Bekreftede feil som er rettet og relevante tester med resultat.
4. Kontroller som ikke kunne utføres, med årsak og teststeg.
5. Eventuell påvirkning på datamodell, lagring og synk.
6. Oppdatert funnliste og neste anbefalte milepæl.

## Startkommando til Codex

> Les SALDOPILOT_GJENNOMGANG_MILESTONES.md og prosjektets AGENTS.md og tidligere milepæler. Begynn med M0 og M1: kartlegg eksisterende funksjonalitet og gjennomgå feil, oversiktlighet og utskrift. Bevar mine eksisterende data og betalingshistorikk. Ikke bruk min aktive iCloud-database til testing. Opprett SALDOPILOT_FUNN.md med bekreftede funn og prioriteringer. Gå deretter videre med små, målrettede rettelser etter planen. Oppdater milepælene og forklar hva jeg skal teste på min iPhone.
