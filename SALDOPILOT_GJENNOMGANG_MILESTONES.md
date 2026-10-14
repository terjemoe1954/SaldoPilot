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

Status: Ferdig 14. oktober 2026. Se `Documentation/SALDOPILOT_FUNN.md`. Versjonert backup av transaksjoner, budsjetter og relevante innstillinger er gjenopprettet og feltsammenlignet isolert. Kjøpsstatus og AI-samtykke utelates med vilje. Skjermkontroll er uttrykkelig merket «må testes på enhet». Aktiv database ble ikke brukt.

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
- [x] Kontroller om filtrering på forfallsdato og betalingsdato gir riktige og forståelige resultater. (Syntetisk kryssmånedskontroll bestått; SP-013 rettet omvendt egendefinert periode.)
- [x] Verifiser at betaling av en gjentakende post bevarer den betalte forekomstens beløp og dato når neste forfall beregnes. (Isolert minnelager: forfall 15.10, betalt 03.11, neste ventende forekomst 15.11; ID, beløp og historiske datoer bevart.)
- [x] Test intervallene appen faktisk støtter, spesielt dato 29., 30. og 31. og betaling lenge etter forfall. (SP-011 rettet med stabil serie-ID og opprinnelig månedsdag; 31.01 → 29.02 → 31.03 er verifisert både automatisk og på fysisk iPhone med isolerte testdata. Sen betaling og normalflyt består.)
- [x] Kontroller dobbelttrykk på «Betalt», redigering av betalt post og eventuell angre-funksjon. (Idempotens og redigeringskonsistens rettet; angre finnes ikke og er registrert for senere vurdering.)
- [x] Avklar om manglende eldre betalingshistorikk skyldes dagens modell. Ikke konstruer historikk fra en nåværende forfallsdato. (SP-014: bare lagrede forekomster med faktisk betalingsdato kan vises; ingen historikk ble konstruert.)
- [x] Skriv målrettede tester for feil som rettes og økonomisk logikk med høy konsekvens. (Swift Testing-målet er koblet til hovedskjemaet; 11 av 11 testtilfeller bestod på isolert iPhone 17 Pro-simulator 14. oktober 2026.)

Ferdig når: Kjente P0/P1-feil innen beløp og betaling er rettet, og representative fasiter stemmer mellom liste, oversikt og rapport.

## M3 – lagring, synk og mange poster

- [x] Kontroller at oppretting og redigering bevares etter avslutning og omstart. (Automatisk gjenåpningstest bestått, og bruker bekreftet på fysisk iPhone at én inntekt og én utgift fortsatt var lagret etter full omstart i separat lokalt testlager uten CloudKit.)
- [x] Test offlinebruk og overgang tilbake til nett. (Bruker verifiserte på fysisk iPhone med separat lokalt testlager: inntekt og utgift kunne opprettes i flymodus, redigering og betaling ble bevart gjennom full omstart, og ingen poster forsvant eller ble duplisert etter at nettet ble slått på igjen.)
- [x] Test iCloud-synk i adskilt oppsett: nye poster, endringer, sletting og samtidige endringer på to enheter. (Egen container `iCloud.com.terjemoe.SaldoPilot.Test` er aktivert med separat lokal cache og tydelig testbanner. Oppretting, endring og sletting er bekreftet mellom iPhone og iPad. Manglende bakgrunnsmodus for CloudKit-varsler og manglende eksplisitt lagring ble funnet og rettet. En frakoblet konflikt med tittelendring på iPhone og beløpsendring på iPad konvergerte til én post med samme tittel og beløp på begge enhetene.)
- [x] Kontroller duplikater og at dobbel betaling ikke oppstår ved gjentatte synkforsøk. (Samme månedlige post ble markert betalt på iPhone og iPad mens begge var i flymodus. Etter ny tilkobling konvergerte begge til én betalt opprinnelig post og én ventende neste forekomst; ingen ekstra kopi ble opprettet.)
- [x] Kontroller feiltilstander og tydelig informasjon ved manglende iCloud eller nett; unngå å vise falsk synkbekreftelse. (Manglende nett er verifisert: rødt offline-banner vises, posten lagres lokalt gjennom full manuell omstart og synkroniseres automatisk når nettet kommer tilbake. Testmodus huskes ved manuell oppstart, slik at produksjonslageret ikke åpnes ved offline-test. Manglende iCloud-konto ble trygt simulert uten utlogging: et eget rødt banner forklarte at iCloud var utilgjengelig og at endringer lagres på enheten. Begge tilstandene unngår falsk «synkronisert»-bekreftelse.)
- [x] Test søk, scrolling, filtrering og rapport med mange syntetiske poster, eksempelvis 1 000 og 10 000 hvis relevant. (Både 1 000 og 10 000 merkede poster bestått på fysisk iPhone i isolert lokalt testlager. Søk, scrolling, statusfiltre, postdetaljer, oversikt, statistikk, rapport og full omstart fungerte uten duplikater. Manglende søk ble funnet og rettet under 10 000-testen.)
- [x] Mål merkbare forsinkelser før optimalisering; unngå tung rapportgenerering som låser grensesnittet. (Isolert måling med 10 000 poster: oppretting/lagring 1,038 s, uthenting 0,153 s, saldo 0,080 s, søk 0,032 s, PDF 1,200 s og CSV 4,336 s. Brukertesten på iPhone opplevdes som fungerende; synkron eksport på hovedaktøren er registrert som SP-015.)
- [x] Hvis modellendring er nødvendig: prøv oppgradering fra gammel database på kopi og sammenlign antall, summer og relasjoner. (SwiftData-skjema V1 og V2 er fastlåst, og nye gjentakelsesfelt ligger i V3. En syntetisk lokal V2-database ble oppgradert til V3: 2 av 2 poster, begge ID-er, samlet postbeløp 623,45 kr og 1 budsjett på 9 000 kr var uendret. Nye valgfrie felt var tomme som forventet. Alle 12 tester bestod 14. oktober 2026; ingen iCloud-database eller brukerbackup ble åpnet.)

Ferdig når: Data lagres og synkes som forventet i testoppsettet, og begrensninger eller konflikter er dokumentert.

## M4 – enklere og mer oversiktlig

- [x] Gjør periode, aktive filtre og hva summeringen omfatter lett synlig. (Postlisten viser nå aktiv periode og øvrige filtre som brikker, antall synlige av alle aktive poster, og forklarer at «Tilgjengelig» beregnes fra startsaldo og oppgjorte poster uavhengig av listefiltrene. Brukeren bekreftet at antallet endres ved filtrering mens tilgjengelig beløp forblir uendret.)
- [x] Vurder tydelig «Nullstill filtre» og enkel veksling mellom forfalt, kommende og betalt hvis det passer dagens modell. (Hurtigfiltrene Alle, Forfalt, Neste forfall, Kommende, Betalt og Til gode er horisontalt rullbare med full tekst, tydelig valgt tilstand og minst 44 punkters trykkhøyde. Avanserte filtre vises som brikker med synlig «Tilbakestill», også inne i filterarket. Brukeren godkjente flyten på fysisk iPhone.)
- [x] Gjør primære handlinger lette å finne og gi tydelig bekreftelse når data lagres eller betaling registreres. (Ny post og filtre ligger synlig i topplinjen. Postdetaljene har en navngitt handling for mottak/betaling. Registrering fra detaljvisningen lagres nå eksplisitt, rulles tilbake med feilmelding ved lagringsfeil og viser «Betaling registrert» eller «Inntekt registrert» etter vellykket lagring. Brukeren godkjente flyten på fysisk iPhone, og alle 12 tester bestod.)
- [x] Gjør sletting forståelig og gi bekreftelse eller angremulighet der det er hensiktsmessig. (Sletting krever bekreftelse med forklaring om permanent sletting. Gjentakende poster gir egne valg for bare denne eller denne og framtidige poster. Lagringsfeil gjenoppretter endringen og viser feil. Brukeren bekreftet på fysisk iPhone at Avbryt bevarer posten, mens bekreftet sletting fjernes og synkroniseres mellom testenhetene.)
- [x] Kontroller kontrast, store tekststørrelser, VoiceOver, trykkflater og at status ikke uttrykkes bare med farge. (Postlisten består kodekontroll for VoiceOver, dynamisk tekst og kontrast. Avkorting og nedskalering av posttekst ble fjernet, lyse statusfarger brukes ikke lenger som tekstfarge, tilgjengelig-beløpet fikk kontrasterende svart tekst, og hurtigfiltrene har minst 44 punkters trykkhøyde samt valgt-trait. Status formidles med tekst og symbol i tillegg til farge. Brukeren bekreftet største tilgjengelighetstekst på fysisk iPhone.)
- [x] Kontroller liten/stor iPhone, tastatur og eventuelle iPad-visninger som prosjektet allerede støtter. (Brukeren kontrollerte postliste og registreringsskjema på iPhone og iPad, inkludert tastatur, rulling, avbryt uten lagring, vannrette hurtigfiltre og iPad i stående og liggende retning. Ingen testdata måtte opprettes.)
- [x] Kontroller lyst, mørkt og systemutseende. (Brukeren kontrollerte Oversikt, Poster og registreringsskjema i lyst og mørkt utseende, samt at System følger enhetens valgte utseende. Ingen uleselig tekst, forsvinnende status eller kontrastfeil ble rapportert.)
- [x] Kontroller norsk, engelsk og thai, inkludert lange tekster, datoer, tall og rapporter. (Strengkatalogen har ingen uoversatte strenger på norsk eller thai. Brukeren kontrollerte Oversikt, Poster, postdetaljer, Innstillinger og rapportvisningen på norsk, engelsk og thai, inkludert tekstflyt, datoer, tall og knapper, og byttet deretter tilbake til ønsket språk.)
- [x] Vurder en kort hjelpetekst om periode, gjentakelse og betaling der brukeren trenger den. (Den eksisterende Brukermanualen dekker periode, oppretting, gjentakelse, betaling/mottak og rapporter på norsk, engelsk og thai. Forklaringen av «Tilgjengelig beløp» ble oppdatert med startsaldo, startdato, oppgjorte poster, filteruavhengighet og anbefaling om å beholde betaling uten dekning som ventende. Brukeren bekreftet at teksten vises fullt.)

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

- [x] Brukeren velger rapport, periode og enten «gjeldende filtre» eller «alle poster». Vis hva valget omfatter. (Rapportsiden tilbyr Periodeoversikt, Postliste, Forfalt og kommende samt Betalingshistorikk. Brukeren velger måned og Gjeldende utvalg eller Alle poster i perioden. Gjeldende utvalg viser arkiv-/kanselleringsvalg; Alle poster inkluderer begge med forklaring. Forfalt/kommende bruker forfallsdato og betalingshistorikk betalingsdato. Brukeren godkjente valgene og at forhåndsvisningens antall/summer oppdateres.)
- [x] Vis antall poster, periode, datotype og aktive filtre i forhåndsvisning og rapporthode. (Forhåndsvisningen viser rapporttype, måned, datotype, omfang, arkiv-/kanselleringsvalg, antall og summer. PDF-hodet viser rapporttype, periode, antall, sortering/datotype samt samme omfang og filtervalg. Brukeren sammenlignet forhåndsvisning og PDF på fysisk iPhone og bekreftet samsvar.)
- [x] Bruk samme filtrerings- og beregningsgrunnlag i app og rapport; unngå parallelle regler som gir avvik. (Forhåndsvisning, PDF-rader og rapportoppretting bruker samme beregnede `reportTransactions`-utvalg. Brukeren sammenlignet antall og summer for Postliste og Betalingshistorikk på fysisk iPhone uten avvik.)
- [x] Generer en konsistent kopi av utvalget slik at pågående synk ikke endrer summer halvveis i rapporten. (`createReport()` kopierer hele det valgte utvalget til verditypen `ReportTransaction` før PDF-renderingen starter. PDF-tjenesten sorterer og summerer bare denne kopien, ikke den levende SwiftData-spørringen.)
- [x] Rapporten har SaldoPilot, rapporttittel, genereringsdato, tydelige kolonner og sidenummer. (PDF-en viser en rapporttypespesifikk SaldoPilot-tittel, lokalisert genereringstid, dato/tittel/beløp/status/kategori som kolonner og «SaldoPilot · Side n» i bunnteksten. Sidehodet og sidenummeret tegnes på hver side. Brukeren kontrollerte PDF-en på fysisk iPhone.)
- [x] Bruk utskriftsvennlig A4, lyse flater, lesbar skrift og tilstrekkelige marger; bred tabell kan bruke liggende format. (Rapporten bruker stående A4 på 595 × 842 punkter, hvit bakgrunn, mørk tekst, 28 punkters marg og høyrejusterte beløp. Brukeren kontrollerte PDF-en i mørkt og lyst apputseende og bekreftet at kolonnene holder seg innenfor siden.)
- [x] Gjenta kolonneoverskrifter på nye sider og håndter lange notater uten avklipping eller overlapp. (Tabellhodet tegnes på hver side. Rapportpostene kopierer nå notater, bruker dynamisk radhøyde og deler svært lang tittel-/notattekst i fortsettelsesrader som kan gå over flere sider. Brukeren kontrollerte lang tittel, langt notat, sideskift og gjentatte kolonneoverskrifter uten avklipping eller overlapp.)
- [x] Bruk norsk/valgt språk, korrekt valutaformat og tydelige datoer. (Rapportens tekst, datoer og tall følger valgt språk. Valutaen er låst til NOK slik at norsk økonomidata ikke feilmerkes som USD eller THB ved språkbytte. Alle 12 automatiske tester besto, og brukeren godkjente kontrollen på enhet.)
- [x] Totaler skal tydelig gjelde hele rapportutvalget. Skill planlagte beløp fra faktiske betalinger. (Forfallsdato viser planlagte inntekter, utgifter og netto for hele utvalget. Betalingsdato viser mottatte inntekter, betalte utgifter og oppgjort netto. Brukeren bekreftet at forhåndsvisning og PDF har samme tall.)
- [x] Vis en forståelig tom rapport eller melding når utvalget ikke har data. (Brukeren kontrollerte et utvalg med 0 transaksjoner: forhåndsvisning og PDF vises forståelig med nullsummer, uten feil eller tom svart side.)
- [x] Tilby forhåndsvisning, «Skriv ut» og «Del / lagre PDF». Brukeren velger mottaker i systemets delingsark. (Brukeren bekreftet forhåndsvisning, at systemets utskriftsdialog åpnes, og at en delt/lagret PDF kan åpnes komplett fra Filer.)
- [x] Vedlegg: Hvis appen lagrer kvitteringer eller andre dokumenter, la brukeren åpne og skrive ut støttede vedlegg, eller velge å inkludere dem. Dokumenter formater som ikke kan skrives ut. (Ikke aktuelt i dagens datamodell: SaldoPilot lagrer ingen kvitteringer eller dokumentvedlegg. Rapporten har derfor ingen vedleggskontroll eller udokumenterte filformater.)
- [x] Håndter avbryt, manglende skriver og genereringsfeil uten å endre økonomiske data. (Brukeren avbrøt både delingsark og utskriftsdialog uten valgt skriver og bekreftet normal retur til appen uten endringer i poster, statuser, beløp eller saldo. Genereringsfeil vises som feil og rapportarbeidet muterer ikke økonomimodellen.)

### Testkrav for utskrift

- [x] Test 0, 1, 50 og minst 1 000 poster samt lange navn/notater og store beløp. (En isolert automatisk grensetest genererer og åpner PDF-er med 0, 1, 50 og 1 000 syntetiske poster, inkludert lang tittel, langt notat og stort beløp. Testen bruker bare minne og midlertidige filer, aldri SwiftData eller iCloud. Brukeren godkjente i tillegg belastningsrapporten visuelt på enhet.)
- [x] Sammenlign antall, utvalg og totaler med manuelt kontrollert testdatasett. (Brukeren summerte et oversiktlig testutvalg manuelt og bekreftet samme antall, inntekt, utgift og netto i forhåndsvisning og PDF.)
- [x] Kontroller PDF visuelt: første side, sideskift, totalside og vedlegg hvis støttet. (Brukeren kontrollerte første side, et sideskift og siste side med totaler i belastningsrapporten. Vedlegg støttes ikke av dagens datamodell.)
- [x] Kontroller at hele listen eksporteres og at skjulte filtre ikke fjerner poster fra «alle poster». (Brukeren aktiverte et Poster-filter og bekreftet at «Alle transaksjoner i perioden» fortsatt ga samme komplette rapportutvalg.)
- [x] Test deling og PDF-lagring på enhet. (Brukeren delte/lagret rapporten via systemarket og åpnet den komplette PDF-en fra Filer.)
- [x] Test faktisk AirPrint på iPhone når skriver er tilgjengelig; PDF-generering alene bekrefter ikke fysisk utskrift. (Brukeren godkjente fysisk AirPrint-kontroll på iPhone, inkludert marger, sideskift, kolonner og siste side.)
- [x] Kontroller at brukeren selv velger å dele sensitive økonomiske opplysninger. (Brukeren bekreftet at appen bare åpner Apples delingsark, uten forhåndsvalgt mottaker eller automatisk sending, og at delingen kan avbrytes.)

Ferdig når: Relevante rapporter kan forhåndsvises, lagres som PDF og sendes til utskrift med riktige data. Ikke tilgjengelige kontroller er eksplisitt dokumentert.

## M6 – forbedringspotensial uten å gjøre appen tung

Vurder hvert forslag ut fra brukerbehov, eksisterende funksjonalitet, kompleksitet og risiko. Implementer bare små forbedringer med klar nytte innenfor dette oppdraget. Registrer større ideer i en egen senere-liste.

- [x] Kommende 7/30 dager: Vil dette gjøre regninger enklere å planlegge, og finnes det allerede? (Det eksisterende «Kommende»-filteret viste alle framtidige poster. Periodefilteret har derfor fått små, lokaliserte valg for «Neste 7 dager» og «Neste 30 dager», med i dag inkludert og eksklusiv øvre datogrense. Brukeren godkjente begge på enhet; 13 av 13 tester besto.)
- [x] Søk etter navn, kategori og notat: Er det lett å finne igjen eldre poster? (Eksisterende fritekstsøk dekket tittel og notat. Det er utvidet til kategoriens lokaliserte navn ved å bruke SwiftUI-miljøets språk. Brukeren godkjente alle tre søketypene på enhet; 13 av 13 tester besto.)
- [x] Gjenbruk av tidligere post: Kan registrering gjøres enklere uten å kopiere betalingsstatus og historikk feil? (Eksisterende «Dupliser» kopierer relevante registreringsfelt til en ny unik post, men nullstiller status til Venter og kopierer ikke betalingsdato, fullførtstatus, arkivstatus eller synkhistorikk. Brukeren godkjente kopien og bekreftet at originalen var uendret.)
- [x] Kategorisummer: Finnes en enkel vei fra kategoriens sum til postene bak den? (Statistikk har allerede trykkbare kategorirader under Kategoribalanse. De åpner en transaksjonsliste med postene bak summen. Brukeren bekreftet riktig måned, kategori og antall på enhet; ingen kodeendring var nødvendig.)
- [x] Påminnelser: Hvis appen har dem, kontroller tillatelse, endrede datoer og duplikater. (Varsler ber om systemtillatelse, og endringer i dato, status eller innstillinger utløser full omplanlegging med stabile identifikatorer. SP-021 rettet et tilfelle der et ennå ikke levert varsel kunne forsvinne ved ny synkronisering. Bygg og 13 av 13 tester besto. Faktisk levering er ikke testet mot produksjonsdata fordi varsler med hensikt er deaktivert i isolert testmodus.)
- [x] CSV-eksport: Vurder som tillegg for regneark; kontroller tegnsett, skilletegn og sikker behandling av tekst som regneark kan tolke som formler. (CSV fantes allerede med komma og siterte felt. SP-022 sikrer formellignende tekst som ren tekst og legger til UTF-8-signatur for norsk/thai. Automatisk test og brukerens regnearkkontroll besto; JSON er fortsatt full backup.)
- [x] Backup/gjenoppretting: Versjon 3 omfatter transaksjoner, budsjetter og relevante innstillinger, er bakoverkompatibel og er kontrollert isolert. Kjøpsstatus og AI-samtykke overskrives ikke.
- [x] Kort brukerveiledning: Forklar de viktigste oppgavene med samme begreper som appen. (Eksisterende brukermanual dekker hovedoppgavene. Tekstene for søk, 7/30-dagersfilter og rapportvalg er oppdatert på norsk, engelsk og thai med samme begreper som grensesnittet. Brukeren godkjente visningen på enhet.)

Ferdig når: De mest verdifulle forslagene er rangert, med tydelig skille mellom implementert og utsatt.

## M7 – samlet regresjon og eierens test

- [x] Bygg prosjektet og kjør relevante automatiserte tester for berørte funksjoner. (Samlet prosjekt bygget for testing uten feil etter M6. Hele testsuiten besto med 14 av 14 tester, inkludert migrering, lokal persistens, økonomiberegning, gjentakelse, PDF-grenser og CSV-sikkerhet.)
- [x] Test hovedflyt fra ny post til betaling, neste forfall, filtrering og utskrift. (Brukeren gjennomførte hele flyten i isolert testlager: månedlig utgift, søk/30-dagersfilter, betaling, ny ventende forekomst med riktig dato, statusfiltre og PDF-rapport.)
- [x] Test redigering og sletting, omstart, offlinebruk og synk i sikkert testoppsett. (Brukeren redigerte på iPhone, kontrollerte endringen på iPad, redigerte og omstartet offline, synkroniserte tilbake og slettet fra iPad. Endringen/slettingen konvergerte mellom enhetene i `iCloud.com.terjemoe.SaldoPilot.Test`, og produksjonsposter var aldri synlige.)
- [x] Test tom database og stor database, alle språk og utseender som appen støtter. (Tidligere fysisk kontroll i samme gjennomgang dekker tomt isolert lager, 1 000 og 10 000 syntetiske poster, norsk/engelsk/thai og lyst/mørkt/system. Senere regresjonsbygg og 14 automatiske tester besto; testen gjentas ikke destruktivt.)
- [x] Sammenlign et fast testdatasett før/etter: postantall, historikk og økonomiske summer. (Brukeren noterte antall poster, inntekter, utgifter, netto og oppgjorte poster for en fast måned. Etter full omstart på begge testenhetene var tallene identiske i Oversikt og rapportforhåndsvisningen.)
- [x] Lag en kort sjekkliste som eieren kan prøve med sine kjente poster, uten destruktive testhandlinger. (`Documentation/SALDOPILOT_EIERTEST.md` dekker sikker oppstart, kjente summer/poster, søk, filtre, detaljer uten lagring, statistikk, rapport, synk og stoppregel uten sletting/import/statusendring.)
- [x] La eieren kontrollere at appen fremdeles føles enkel og gjenkjennelig. (Brukeren gjennomførte den subjektive eierkontrollen og godkjente Oversikt, navigasjon, nye filtre/rapportvalg og sentrale begreper som enkel og gjenkjennelig.)
- [x] Registrer faktisk testmiljø, build og resultat. Ikke merk eiertest eller fysisk utskrift bestått før det er gjort. (`Documentation/SALDOPILOT_FUNN.md` registrerer 14. oktober 2026, SaldoPilot 1.3 build 8, iPhone 15 Pro/iPad 10 på iOS 27.0.1, isolert CloudKit-testcontainer, 14 av 14 tester, gjennomført eiertest, fysisk AirPrint og skrivebeskyttet produksjonskontroll av TestFlight-bygget. Ingen uavklarte P0/P1-funn.)

Ferdig når: Ingen uavklarte P0/P1-feil gjenstår, og nødvendige kontroller på enhet er utført eller tydelig oppført som blokkering for utgivelse.

## M8 – klargjøring til TestFlight og senere App Store

- [x] Skriv korte endringsnotater om faktiske rettelser, enkelhet og utskrift. (`Documentation/TESTFLIGHT_RELEASE_NOTES_1.3.md` beskriver gjennomførte rettelser og TestFlight-sikringen.)
- [x] Kontroller hjelpetekster og personvernbeskrivelse hvis dataflyten er endret. (Brukermanualen er oppdatert på norsk/engelsk/thai. `AppStore/PrivacyPolicy.md` er kontrollert mot kode og oppdatert 14. oktober 2026 med faktisk innhold i JSON/CSV/PDF, lokal filgenerering, systemdeling/-utskrift og at mottaker velges av brukeren. KI forblir lokal; ingen ekstern KI-dataflyt finnes.)
- [x] Oppdater build ved ny opplasting og bruk prosjektets versjonspraksis. (Versjon 1.2 var allerede godkjent og lukket hos Apple. Markedsversjonen ble derfor satt til 1.3, build 8 ble validert og lastet opp.)
- [x] Lag konkrete TestFlight-testinstruksjoner, særlig for betaling, synk og rapporter. (`Documentation/TESTFLIGHT_TESTINSTRUKSJONER_1.3.md` dekker sikker oppstart, backup, betaling/gjentakelse, synk, rapport og feilrapportering.)
- [x] Dokumenter tilbakeføringsplan for kode og eventuelle modellendringer. En eldre appbuild kan ikke antas å åpne en ny datamodell. (`Documentation/ROLLBACK_PLAN_1.3.md` beskriver stopp av distribusjon, framoverrettet korrigerende build, bevaring av V3/backupformat 4 og forbud mot destruktiv behandling av produksjons-CloudKit.)
- [x] Etter godkjent eiertest: vurder norske App Store-bilder som viser forfall, enkel registrering og en ekte rapport med anonymiserte eksempeldata. (`Documentation/APP_STORE_SKJERMBILDEPLAN_NO.md` foreslår seks norske bilder, et konsistent oppdiktet demodatasett og tydelige regler om separat lokalt lager, ingen produksjonsdata/testbanner/private opplysninger og ingen feilaktige løfter om bankbetaling eller ekstern KI.)
- [x] Ikke arkiver, last opp eller publiser automatisk som del av denne milestone-filen; lever prosjektet klart for eierens vanlige utgivelsesløp. (Eieren gjennomførte senere arkivering og opplasting manuelt med trinnvis veiledning. TestFlight 1.3 build 8 er tilgjengelig for intern testing; ingen offentlig App Store-publisering er utført.)

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
