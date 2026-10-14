# SaldoPilot – funn og gjennomgang

Oppdatert: 14. oktober 2026  
Gjennomgått versjon: 1.3 (build 8), iOS/iPadOS 27.0.1  
Status: M0–M8 ferdig. TestFlight 1.3 (8) er validert, lastet opp og kontrollert på iPhone og iPad.

## Sikker testavgrensning

- Produksjonsstart bruker privat CloudKit-database `iCloud.com.terjemoe.SaldoPilot` og faller tilbake til lokal SwiftData-lagring dersom CloudKit-containeren ikke kan opprettes.
- Ingen appkjøring, simulatorstart, import, sletting eller skriving til produksjonslageret ble utført under M0/M1.
- For isolert testing skal miljøvariabelen `SALDOPILOT_USE_TEST_STORE=1` eller launch-argumentet `-SaldoPilotUseTestStore` brukes. Det velger en minnebasert SwiftData-konfigurasjon med `cloudKitDatabase: .none`. Et oransje «ISOLATED TEST DATA»-banner må være synlig. Data forsvinner når testprosessen avsluttes og kan ikke synkroniseres til iCloud. Varselsynkronisering er deaktivert i testmodusen.
- Aktiv iCloud-synk skal bare testes senere med separat konto/container og et eksplisitt testoppsett.

## Kartlagt nåsituasjon

| Område | Faktisk implementasjon |
|---|---|
| Lagring | SwiftData, skjema V2, privat CloudKit med lokal reserve |
| Modeller | `Transaction` og `Budget`; kategorier er en fast enum, ikke egne lagrede objekter |
| Beløp | `Decimal`; inntekt og utgift lagres som positive beløp og fortegn anvendes i summering |
| Betalingshistorikk | Hver betalt/mottatt forekomst er en `Transaction` med status, `paidDate` og `isCompleted`; det finnes ingen egen betalings- eller serie-ID |
| Gjentakelse | Ved første fullføring opprettes neste forekomst fra den betalte postens opprinnelige forfallsdato |
| Hovedflyt | Oversikt, poster, statistikk, budsjetter og innstillinger i fem faner |
| Filtre | Hurtigfilter samt periode, datotype, status, type, kategori, beløpsgrenser og sortering |
| Eksport | JSON-backup av transaksjoner og CSV-eksport |
| Import | JSON/CSV, sammenslåing eller erstatning av transaksjoner |
| Rapport | Månedlig A4-PDF, deling og systemets utskriftsdialog |
| Språk/utseende | System, engelsk, norsk og thai; system, lys og mørk |

## Backup og gjenoppretting

JSON-eksporten bevarer alle felt på `Transaction`, inkludert UUID, datoer, status, gjentakelse og arkivstatus. Import kan lese formatet og bevare transaksjons-ID-er. En syntetisk JSON-backup ble 14. oktober 2026 gjenopprettet mellom to separate, minnebaserte SwiftData-containere uten CloudKit. Antall, UUID-er, eksakte `Decimal`-beløp, statuser, forfalls- og betalingsdatoer, gjentakelse og fullførtstatus var identiske etter gjenoppretting.

Backupformat versjon 3 inkluderer også `Budget` med UUID, kategori, måned, eksakt beløp samt opprettet-/endret-dato, og relevante appinnstillinger: utseende, språk, navn/visningsvalg, standardperiode/datotype, varselvalg og startsaldo med dato. Budsjettet og innstillingene ble gjenopprettet og feltsammenlignet mellom separate minnelagre og egne `UserDefaults`-suiter. «Erstatt» fjerner og gjenoppretter budsjetter bare når filen faktisk inneholder `budgets`; en eldre transaksjonsbackup uten dette feltet lar eksisterende budsjetter stå urørt.

Kjøpsstatus og samtykke til ekstern AI er med vilje ikke med og overskrives aldri ved import. Operativsystemets varseltillatelse kan ikke sikkerhetskopieres; bare appens varselvalg bevares. Kontrollen brukte bare syntetiske data og berørte ikke aktiv lokal database, standardinnstillinger eller iCloud.

## Prioritert funnliste

### SP-001 – Betalingsdato kan overskrives på en allerede betalt post

- Type: Rettet
- Skjerm/fil: Poster, `TransactionsView.swift` (`markCompleted`)
- Reproduksjon: Åpne listen med en betalt/mottatt post, sveip fra venstre og velg «Marker betalt» på nytt.
- Forventet: Handlingen er ikke tilgjengelig, eller eksisterende betalingsdato bevares.
- Faktisk: `paidDate` settes til nåtid også når posten allerede er fullført.
- Konsekvens: Historisk betaling kan flyttes til en annen måned og endre rapporter og saldo basert på betalingsdato.
- Prioritet: P0
- Foreslått tiltak: Skjul/deaktiver handlingen for ferdige poster og gjør fullføringsfunksjonen idempotent.
- Testresultat: Rettet 14. oktober 2026. Sveipehandlingen skjules for ferdige poster, og funksjonen avbryter uten endring dersom den likevel kalles. Prosjektet bygger; interaksjonen må verifiseres på iPhone med isolert lager.

### SP-002 – Redigering kan lagre «betalt» uten betalingsdato

- Type: Bekreftet feil
- Skjerm/fil: Ny/rediger post, `TransactionFormView.swift`
- Reproduksjon: Rediger en betalt post, slå av «Betalt eller mottatt», og lagre uten å endre statusfeltet.
- Forventet: Status og dato holdes konsistente, eller brukeren får tydelig validering.
- Faktisk: `paidDate` blir `nil`, mens status og `isCompleted` fortsatt kan være betalt/fullført.
- Konsekvens: Posten telles som betalt enkelte steder, men mangler fra rapport/filter på betalingsdato.
- Prioritet: P1
- Foreslått tiltak: Avslå inkonsistent kombinasjon eller sett status til ventende når betalingsdato fjernes.
- Testresultat: Rettet 14. oktober 2026. Når betalingsdato fjernes, endres betalt/mottatt status til ventende, og lagring normaliserer samme kombinasjon. Prosjektet bygger; skjemaflyten må verifiseres på iPhone med isolert lager.

### SP-003 – Duplisering kopierer betalingsstatus og betalingsdato

- Type: Bekreftet feil
- Skjerm/fil: Poster, `TransactionsView.swift` (`duplicate`)
- Reproduksjon: Dupliser en betalt eller mottatt post.
- Forventet: Ny post gjenbruker innhold, men starter som ventende uten betalingshistorikk.
- Faktisk: Kopien får samme status, `paidDate`, `isCompleted`, gjentakelse og arkivstatus.
- Konsekvens: Summer og betalingshistorikk kan dobbelttelles umiddelbart.
- Prioritet: P1
- Foreslått tiltak: Dupliser som ny, aktiv og ventende forekomst uten betalingsdato.
- Testresultat: Rettet og verifisert på iPhone med isolert testlager 14. oktober 2026. En betalt gjentakende utgift ble duplisert som aktiv post uten betalingsdato eller fullførtstatus. Kopien vises korrekt som forfalt fordi den beholdt en tidligere forfallsdato.

### SP-004 – JSON-backup omfatter ikke budsjetter eller innstillinger

- Type: Bekreftet begrensning
- Skjerm/fil: Backup og eksport, `ExportService.swift`
- Reproduksjon: Opprett budsjett og endre innstillinger; inspiser JSON-eksportens felter.
- Forventet: «Backup» forklarer nøyaktig hva som kan gjenopprettes.
- Faktisk før retting: Bare kategoridefinisjoner og transaksjoner ble eksportert. Backupformat versjon 3 inkluderer nå også budsjetter og relevante innstillinger.
- Konsekvens: Brukeren kan tro at hele appen kan gjenopprettes.
- Prioritet: P1
- Foreslått tiltak: Utført. Behold formatet versjonert og utelat kjøpsrettigheter og AI-samtykke.
- Testresultat: Rettet 14. oktober 2026. Transaksjoner, budsjetter og relevante innstillinger er gjenopprettet og feltsammenlignet isolert. Ny backup kunne erstatte eksisterende budsjett korrekt, mens en eldre backup uten budsjettfelt bevarte eksisterende budsjett. Pro-status og AI-samtykke forble uendret.

### SP-005 – Import med «erstatt» er ikke transaksjonell

- Type: Bekreftet risiko
- Skjerm/fil: Import, `ImportService.swift`
- Reproduksjon: Velg erstatning med en gyldig fil og fremprovoser lagringsfeil etter at eksisterende objekter er markert for sletting.
- Forventet: Enten fullføres hele erstatningen, eller opprinnelige data beholdes.
- Faktisk før retting: Eksisterende transaksjoner ble slettet i konteksten før nye ble satt inn; eksplisitt lagring og rollback fantes ikke.
- Konsekvens: Potensielt datatap dersom lagring feiler eller delvis state lagres.
- Prioritet: P1
- Foreslått tiltak: Valider alt først, lagre samlet og rull konteksten tilbake ved lagringsfeil.
- Testresultat: Rettet 14. oktober 2026. Hele filen klargjøres før eksisterende objekter endres, transaksjoner og eventuelle budsjetter lagres samlet, og konteksten rulles tilbake dersom `save()` feiler. Innstillinger anvendes først etter vellykket datalagring. Kontrollert bare i isolerte minnelagre.

### SP-006 – Tom database og «ingen treff» har samme hovedtittel

- Type: Forbedringsforslag
- Skjerm/fil: Poster, `TransactionEmptyState`
- Reproduksjon: Sammenlign helt tom database med et filter som gir null treff.
- Forventet: Ny bruker ser forskjell på ingen registrerte poster og ingen treff i aktive filtre.
- Faktisk: Begge viser hovedtittelen «Ingen poster», selv om forklaringsteksten varierer.
- Konsekvens: Filtre kan oppfattes som datatap.
- Prioritet: P2
- Foreslått tiltak: Bruk «Ingen poster ennå» og «Ingen treff» med tydelig nullstilling av filtre.
- Testresultat: Bekreftet ved kodegjennomgang; visuell kontroll på iPhone gjenstår.

### SP-007 – «Tilgjengelig» var ikke en faktisk kontosaldo

- Type: Bekreftet feil, økonomisk betydning avklart med eier
- Skjerm/fil: Poster og oversikt
- Reproduksjon: Vis listen med filtre; les banneret «Tilgjengelig».
- Forventet: Tilgjengelig beløp er startsaldo pluss mottatte inntekter minus betalte utgifter fra startsaldodatoen. Ventende poster påvirker ikke beløpet.
- Faktisk før retting: Beløpet var netto av ferdige poster i det filtrerte listeutvalget, ikke kontosaldo. Oversikten viser fortsatt «Netto» av alle planlagte poster i valgt forfallsperiode.
- Konsekvens: To økonomiske tall kan tolkes som samme saldo selv om de har ulikt grunnlag.
- Prioritet: P2
- Tiltak: Én startsaldo og dato kan angis under Innstillinger. Listefiltre påvirker ikke beregningen. Ved utilstrekkelig registrert dekning foreslår appen å beholde posten som ventende, med eksplisitt overstyring fordi SaldoPilot ikke kjenner bankens faktiske saldo.
- Testresultat: Ren syntetisk kontroll med startsaldo 1 000, mottatt inntekt 500, betalt utgift 200, ventende utgift 900 og annullert utgift 400 ga korrekt tilgjengelig beløp 1 300. Prosjektet bygger. iPhone-flyt gjenstår.
- Lagring: Startsaldoinnstillingen er foreløpig lokal og har separat nøkkel i isolert testmodus. Den er ikke del av JSON-backup eller iCloud-synk før løsningen er ferdig validert.

### SP-008 – Ulagrede skjem Endringer forkastes uten varsel

- Type: Forbedringsforslag
- Skjerm/fil: Ny/rediger post, `TransactionFormView.swift`
- Reproduksjon: Endre et felt og trykk «Avbryt».
- Forventet: Ved redigering av eksisterende data varsles brukeren før endringer forkastes.
- Faktisk: Skjemaet lukkes direkte.
- Konsekvens: Manuelt arbeid kan gå tapt, men lagrede økonomiske data endres ikke.
- Prioritet: P2
- Foreslått tiltak: Spor om skjemaet er endret og be om bekreftelse ved avbryt/interaktiv lukking.
- Testresultat: Bekreftet ved kodegjennomgang; gestbasert lukking må testes på iPhone.

### SP-009 – Betalingshistorikk har ingen eksplisitt serierelasjon

- Type: Bekreftet modellbegrensning
- Skjerm/fil: `Transaction.swift`, `RecurrenceService.swift`
- Reproduksjon: Rediger tittel, beløp, kategori eller notat i én forekomst og forsøk deretter «denne og fremtidige» på en annen forekomst.
- Forventet: Forekomster i samme serie identifiseres stabilt.
- Faktisk før retting: Fremtidige forekomster ble funnet ved likhet på flere redigerbare felt; ingen serie-ID ble lagret.
- Konsekvens: Serieoppdatering/sletting kan slutte å finne tilhørende poster, eller i sjeldne tilfeller treffe separate, identiske poster.
- Prioritet: P2 nå, men P1 før større serieendringer
- Utført tiltak: Stabil, valgfri serie-ID lagres i skjemaversjon V3. Historiske V1/V2-modeller er fastlåst, og V2→V3 bruker en eksplisitt lettvektsmigrering.
- Testresultat: En syntetisk lokal V2-database ble oppgradert til V3 uten endring i antall poster og budsjetter, ID-er eller beløpssummer. Alle 12 isolerte tester bestod 14. oktober 2026. Produksjonslageret, iCloud og brukerens backupfiler ble ikke åpnet.

### SP-010 – Rapportfunksjonen dekker bare én månedsrapport

- Type: Bekreftet funksjonsgap
- Skjerm/fil: Rapporter, `ReportsView.swift` og `ReportPDFService.swift`
- Reproduksjon: Åpne Rapporter og se tilgjengelige valg.
- Forventet etter M5: Periodeoversikt, filtrert liste, forfalte/kommende, betalingshistorikk, kategorier, enkeltpost og full dataliste.
- Faktisk: Måned, datotype, arkivert/annullert og én PDF-rapport tilbys.
- Konsekvens: Viktige utskriftsbehov kan ikke dekkes uten manuell omvei.
- Prioritet: P2
- Foreslått tiltak: Behold eksisterende rapport og utvid én felles rapportflyt i M5.
- Testresultat: Bekreftet ved kodegjennomgang; fysisk AirPrint må testes på enhet.

### SP-011 – Månedlig dato driver etter en kort måned

- Type: Bekreftet feil
- Skjerm/fil: Gjentakende poster, `RecurrenceService.swift`
- Reproduksjon: Start en månedlig post 31.01.2024, beregn neste forekomst 29.02.2024 og beregn deretter enda en forekomst fra denne.
- Forventet: Den opprinnelige månedsdagen bevares; 31.01 → 29.02 → 31.03.
- Faktisk før retting: Resultatet ble 31.01 → 29.02 → 29.03. Tilsvarende kunne dato 30 drive etter februar.
- Konsekvens: Fremtidige forfallsdatoer kan bli tidligere enn den avtalte datoen etter februar.
- Prioritet: P1
- Utført tiltak: Transaction lagrer nå valgfri stabil serie-ID og opprinnelig månedsdag. Nye forekomster arver begge feltene. Eldre serier får metadata fra samsvarende historiske forekomster når neste forekomst opprettes, slik at en tidligere 31. kan gjenfinnes etter februar. Backupformat 4 bevarer feltene; eldre backupfiler er fortsatt lesbare.
- Testresultat: Bygg bestått og 10 av 10 isolerte Swift Testing-tilfeller bestod 14. oktober 2026, inkludert 31.01 → 29.02 → 31.03. Deretter verifiserte brukeren samme flyt på fysisk iPhone med «ISOLERTE TESTDATA». Ingen CloudKit-database ble brukt.

### SP-012 – Første midnatt i neste periode ble telt i begge perioder

- Type: Bekreftet feil
- Skjerm/fil: Oversikt, poster, statistikk, kategorier, budsjetter, rapporter og lokale oppsummeringer
- Reproduksjon: Lag en periode som slutter 29.02.2024 og kontroller en post datert 01.03.2024 kl. 00:00, eller avslutt 25.10.2026 og kontroller 26.10.2026 kl. 00:00.
- Forventet: Sluttgrensen er eksklusiv; posten tilhører bare neste periode.
- Faktisk før retting: `DateInterval.contains` godtok også intervallets sluttpunkt, slik at nøyaktig midnatt kunne bli telt i begge perioder.
- Konsekvens: Sjeldent avvik i antall og summer ved månedsskifte, årsskifte eller egendefinert periode.
- Prioritet: P1
- Tiltak: Alle kalenderbaserte periodesjekker bruker nå en felles halvåpen kontroll: dato ≥ start og dato < slutt.
- Testresultat: Rettet 14. oktober 2026. Syntetiske fasiter bekreftet første/siste dag i skuddårsmåneden, eksklusjon av 01.03 kl. 00:00, hele den 25 timer lange overgangen til vintertid i Oslo og eksklusjon av neste midnatt. Prosjektet bygger uten feil.

### SP-013 – Omvendt egendefinert periode mistet den tidligste dagen

- Type: Bekreftet feil
- Skjerm/fil: Avanserte filtre i Poster, `TransactionsView.swift`
- Reproduksjon: Velg 31.10.2026 som startdato og 01.10.2026 som sluttdato, og filtrer en post datert 01.10.
- Forventet: Appen normaliserer rekkefølgen og inkluderer hele perioden 01.–31. oktober.
- Faktisk før retting: Sluttdatoen ble utvidet med én dag før datoene ble sortert. Dermed startet intervallet 02.10., og 01.10. falt ut.
- Konsekvens: Poster og summer fra den tidligste dagen kunne mangle når datoene var valgt i omvendt rekkefølge.
- Prioritet: P1
- Tiltak: Normaliser først tidligste og seneste kalenderdag, og legg deretter én dag til den seneste som eksklusiv sluttgrense.
- Testresultat: Rettet 14. oktober 2026. Syntetisk kontroll inkluderte 01.10 og 31.10, ekskluderte 01.11 og bekreftet samtidig at forfallsdato- og betalingsdatofilter velger ulike, riktige poster. Prosjektet bygger uten feil.

### SP-014 – Eldre betalingshistorikk finnes bare når hver forekomst er lagret

- Type: Bekreftet modellbegrensning
- Skjerm/fil: Poster, rapporter, `Transaction.swift` og `ImportService.swift`
- Reproduksjon: Opprett eller importer bare dagens gjentakende forekomst og forsøk å vise betalinger fra før denne ble registrert. Alternativt importer status «Betalt» uten betalingsdato og filtrer rapporten på betalingsdato.
- Forventet: Appen viser bare dokumenterte betalinger og gjør det tydelig når historiske opplysninger mangler.
- Faktisk: En registrert betaling bevares som en egen `Transaction` med `paidDate`. Modellen har ingen separat betalingshistorikk eller serie-ID og kan ikke utlede eldre betalinger fra dagens forfallsdato. Import gjetter ikke manglende betalingsdato; en betalt/mottatt importpost uten dato kan derfor ikke inngå i betalingsdatorapporten.
- Konsekvens: Historikk før brukeren begynte å registrere hver forekomst, slettede forekomster og importer uten betalingsdato kan ikke rekonstrueres. En samlet seriehistorikk kan heller ikke vises sikkert.
- Prioritet: P2, men P1 før en funksjon som lover full seriehistorikk
- Foreslått tiltak: Ikke konstruer historikk. Forklar begrensningen i rapport/hjelp, og krev eller varsle om manglende betalingsdato ved import. En fremtidig serie-ID eller egen betalingsmodell krever sikker migrering.
- Testresultat: Bekreftet ved modell-, import-, detalj- og rapportgjennomgang 14. oktober 2026. Ingen data eller datamodell ble endret.

### SP-015 – Stor eksport utføres synkront på hovedaktøren

- Type: Bekreftet ytelsesrisiko
- Skjerm/fil: Backup, CSV og rapport, `ExportService.swift` og `ReportPDFService.swift`
- Reproduksjon: Generer eksport eller PDF med 10 000 syntetiske poster.
- Forventet: Grensesnittet forblir responsivt mens filen bygges, med fremdriftsvisning ved merkbar ventetid.
- Faktisk: Begge tjenestene er markert `@MainActor` og utfører hele genereringen synkront. Isolert måling tok 4,336 sekunder for CSV og 1,200 sekunder for PDF med 10 000 rader.
- Konsekvens: Store eksporter kan midlertidig låse grensesnittet selv om vanlig navigasjon, søk og rapport fungerte i brukerens fysiske 10 000-test.
- Prioritet: P2
- Foreslått tiltak: Flytt ren serialisering og PDF-generering ut av hovedaktøren, behold bare UI-tilstandsoppdatering på hovedaktøren, og vis fremdrift.
- Testresultat: Målt i isolert minnelager uten CloudKit 14. oktober 2026.

### SP-016 – CloudKit-endringer ble ikke hentet pålitelig mellom enheter

- Type: Bekreftet konfigurasjonsfeil
- Skjerm/fil: iCloud-synk, appens bakgrunnsmoduser
- Reproduksjon: Opprett eller slett en post på iPad og vent på at endringen skal vises på iPhone.
- Forventet: Den andre enheten henter endringen uten at brukeren må installere eller starte appen på nytt.
- Faktisk før retting: Oppretting og sletting kunne bli liggende bare på avsenderen. CloudKit-loggen rapporterte at pushvarsler krevde bakgrunnsmodusen `remote-notification`.
- Konsekvens: Enhetene kunne midlertidig vise forskjellige poster og saldoer.
- Prioritet: P1
- Utført tiltak: Bakgrunnsmodusene `fetch` og `remote-notification` og Push Notifications-entitlementet er lagt til. Oppretting, redigering, betaling, duplisering og sletting lagres eksplisitt før UI-et regner handlingen som fullført. Den isolerte CloudKit-testmodusen logger fullførte oppsett-, import- og eksporthendelser uten å bruke produksjonscontaineren.
- Testresultat: Ny post, endring, sletting, offline-oppretting og samtidig konflikt ble synkronisert mellom iPhone og iPad. En samtidig betaling av samme månedlige post konvergerte til én betalt post og én neste forekomst, uten duplikat. CloudKit-loggen viste fullførte importer og eksporter uten feil. Testet mot `iCloud.com.terjemoe.SaldoPilot.Test` 14. oktober 2026.

### SP-017 – Manuell oppstart mistet testmodus og åpnet produksjonslageret

- Type: Bekreftet sikkerhetsfeil i testoppsettet
- Skjerm/fil: Appstart, `SaldoPilotApp.swift`
- Reproduksjon: Start CloudKit-testmodus fra Xcode, stopp Xcode og åpne deretter appen manuelt fra hjemskjermen.
- Forventet: Enheten fortsetter å bruke den isolerte testcontaineren til testperioden avsluttes eksplisitt.
- Faktisk før retting: Xcodes launch-argumenter og miljøvariabler fulgte ikke med ved manuell oppstart. Appen åpnet derfor produksjonslageret. Ingen produksjonsdata ble endret under funnet.
- Konsekvens: Testeren kunne se og i verste fall endre virkelige data mens en test ble gjennomført.
- Prioritet: P1
- Utført tiltak: Valgt testlagermodus lagres lokalt på enheten. Manuelle omstarter fortsetter i samme lokale eller CloudKit-isolerte testmodus. En eksplisitt produksjonsparameter kan nullstille modusen kontrollert.
- Testresultat: Etter retting viste manuell offline-oppstart både oransje testbanner og rødt offline-banner, og bare de isolerte testpostene. Produksjonsdataene var ikke synlige.

### SP-018 – Offline-endringer manglet synlig synkstatus

- Type: Bekreftet informasjonsmangel
- Skjerm/fil: Global toppstatus, `NetworkStatusMonitor.swift` og `SaldoPilotApp.swift`
- Reproduksjon: Koble enheten helt fra nettet og opprett en post i CloudKit-modus.
- Forventet: Appen forklarer at enheten er offline og at endringer venter på synkronisering.
- Faktisk før retting: Ingen melding eller synkstatus ble vist.
- Konsekvens: Brukeren kunne tro at en lokalt lagret endring allerede var tilgjengelig på andre enheter.
- Prioritet: P1
- Utført tiltak: Et rødt, lokalisert offline-banner viser at endringer synkroniseres når nettet er tilbake. Ved utilgjengelig iCloud vises i stedet at endringene lagres på enheten. Bannerne lover aldri at synkronisering er fullført. Manglende iCloud-konto kan simuleres eksplisitt i det isolerte CloudKit-testoppsettet uten å logge brukeren ut av iCloud.
- Testresultat: På iPad ble en post opprettet offline, bevart gjennom full manuell omstart og automatisk mottatt på en allerede åpen iPhone etter at nettet kom tilbake. Brukeren bekreftet også at både det oransje isolasjonsbanneret og det røde banneret for utilgjengelig iCloud ble vist under trygg simulering. Simuleringen ble deretter deaktivert i standardskjemaet.

### SP-019 – Rapportflyten dekker bare én månedsrapport og avkorter lange felt

- Type: Bekreftet funksjons- og utskriftsmangel
- Skjerm/fil: `ReportsView.swift` og `ReportPDFService.swift`
- Reproduksjon: Åpne Rapporter. Brukeren kan bare velge måned og forfalls-/betalingsdato. Opprett en PDF med lang tittel eller notat.
- Forventet: Brukeren velger rapporttype, periode og tydelig omfang. Rapporten viser hele det valgte utvalget og håndterer lange felt uten avklipping.
- Faktisk: Dagens løsning lager én månedlig bilagsrapport. Den kan ikke lage periodeoversikt, forfalt/kommende, kategorioversikt, enkeltpost eller full dataliste, og har ikke valget «gjeldende filtre/alle poster». PDF-rader har fast høyde og bruker haleavkorting; notater og gjentakelse er ikke med.
- Konsekvens: Rapporten kan være korrekt for den ene månedsflyten, men kan ikke beskrives som komplett utskrift av appens økonomiske data. Lange titler kan miste informasjon på papir.
- Prioritet: P1
- Avgrensning: Modellen har ingen egne kvitteringsvedlegg og ingen samlet seriehistorikk utover de lagrede postforekomstene. Manglende data skal dokumenteres, ikke konstrueres.
- Eksisterende styrker: Rapporten bruker en kopiert `ReportTransaction`-liste under generering, A4 med lyse flater, lokalisert dato/valuta, gjentatte sidehoder, sidenummer, tomtilstand, systemdeling og iOS-utskriftsdialog.
- Utført tiltak: Rapporter har fått rapporttype, omfang, måned og relevant datotype. Forhåndsvisning og PDF bruker samme frosne utvalg. Lange titler/notater får dynamisk høyde og fortsettelsesrader over sider, med gjentatte kolonneoverskrifter og tydelige planlagte/faktiske summer.
- Testresultat: Brukeren kontrollerte utvalg, summer, 0/1/50/1 000 poster, lange felt, A4, sideskift, språk/valuta, deling, lagring og AirPrint. Automatisk PDF-grensetest og full regresjon besto.

### SP-020 – Norske beløp kunne merkes med feil valuta i andre regioner

- Type: Bekreftet økonomisk presentasjonsfeil
- Skjerm/fil: Beløpsvisning og PDF, `DecimalFormatting.swift` og `ReportPDFService.swift`
- Reproduksjon: Bruk thai språk/region og vis eller generer en rapport med norske beløp.
- Forventet: SaldoPilot viser NOK, siden appen ikke lagrer valutakode per post og ikke utfører valutakonvertering.
- Faktisk før retting: Formatteringen hentet valuta fra enhetens eller rapportspråkets region. Samme tall kunne derfor merkes som eksempelvis THB uten konvertering.
- Konsekvens: Et korrekt tall kunne få feil valutaetikett og dermed en annen økonomisk betydning.
- Prioritet: P1
- Utført tiltak: Valutakoden er låst til NOK i app- og PDF-formattering. Lokale regler for desimaltegn, tusenskille og plassering av valutakoden beholdes.

### SP-021 – Ventende påminnelse kunne forsvinne ved ny synkronisering

- Type: Bekreftet varslingsfeil
- Skjerm/fil: Påminnelser, `NotificationScheduler.swift`
- Reproduksjon: Planlegg et «forfall i dag»-varsel etter normalt varslingstidspunkt, slik at det legges ett minutt frem. Utløs deretter en ny varslingssynkronisering før varslet leveres.
- Forventet: Det ventende varslet omplanlegges og blir fortsatt levert én gang.
- Faktisk før retting: Synkroniseringen fjernet det ventende varslet, mens en lokal «allerede planlagt»-markør hindret at det ble opprettet på nytt.
- Konsekvens: En påminnelse kunne utebli etter endring av dato, post eller varslingsinnstillinger.
- Prioritet: P1
- Utført tiltak: Når en fortsatt ventende SaldoPilot-påminnelse fjernes for omplanlegging, fjernes også bare dens tilsvarende planleggingsmarkør. Allerede leverte varsler finnes ikke i ventende kø og beholder markøren, slik at de ikke sendes på nytt.
- Testresultat: Prosjektet bygget for testing uten feil og 13 av 13 regresjonstester besto. Faktisk varsellevering er ikke kjørt mot produksjonsdata; påminnelser er med hensikt deaktivert i isolert testmodus.

### SP-022 – CSV-tekst kunne tolkes som regnearkformler

- Type: Bekreftet eksportsikkerhetsfeil
- Skjerm/fil: Backup og eksport, `ExportService.swift`
- Reproduksjon: Eksporter en post der tittel eller notat starter med `=`, `+`, `-` eller `@`, og åpne CSV-filen i et regneark.
- Forventet: Brukerens tekst vises bokstavelig og utføres aldri som en formel.
- Faktisk før retting: Feltene var korrekt CSV-sitert, men regneark kan likevel tolke slike celleverdier som formler.
- Konsekvens: En eksportert fil kunne utføre uønskede regnearkuttrykk når brukeren åpnet den.
- Prioritet: P1
- Utført tiltak: Potensielle formelfelt prefikses som tekst før CSV-sitering. Filen får UTF-8-signatur for mer pålitelig norsk og thai tekst i regneark. JSON beholdes som fullverdig backupformat.
- Testresultat: Automatisk test bekreftet UTF-8-signatur og sikring av tittel/notat. Brukeren åpnet eksporten i regneark og godkjente bokstavelig tekst og tegnsett. 14 av 14 tester besto.

### SP-023 – Release-build kunne arve lagret testmodus

- Type: Bekreftet utgivelses- og lagringsfeil
- Skjerm/fil: Appstart, `SaldoPilotApp.swift`
- Reproduksjon: Kjør Debug med isolert testlager slik at testmodus lagres. Installer deretter en Release/TestFlight-build over samme bundle uten å slette appdata.
- Forventet: Release/TestFlight bruker alltid produksjonslageret og kan ikke aktiveres med interne testflagg.
- Faktisk før retting: Den lagrede testmodusen kunne leses også av Release, slik at builden åpnet lokalt testlager eller testcontaineren.
- Konsekvens: En TestFlight-bruker på en tidligere testenhet kunne se testdata i stedet for sine ordinære data. Produksjonsdata ble ikke slettet eller endret.
- Prioritet: P0
- Utført tiltak: Isolerte lagre kan nå bare aktiveres når `DEBUG` er kompilert inn. Release tvinger produksjonsmodus og fjerner den lagrede testmodusmarkøren ved oppstart.
- Testresultat: Debug beholder eksisterende isolerte testflyt. Prosjektet bygges og hele testsuiten kjøres etter rettingen. Release-koden har ingen aktiv gren som kan velge testlager.

## M6 – prioritert forbedringsliste

1. Implementert, høy nytte/lav kompleksitet: Neste 7/30 dager, kategorisøk, retting av omplanlagte varsler (SP-021), sikker CSV-tekst og UTF-8 (SP-022), samt oppdatert brukermanual.
2. Beholdt som eksisterende løsning: Trygg duplisering av post, navigasjon fra kategorisum til underliggende poster og versjonert JSON-backup.
3. Utsatt fordi det krever større arbeid eller produksjonsnær kontroll: faktisk levering av lokale varsler (deaktivert i isolert testmodus) og asynkron eksport av svært store datasett (SP-015). Dette må ikke testes mot den aktive iCloud-databasen.

## M7 – registrert testmiljø og resultat

- Dato: 14. oktober 2026
- App: SaldoPilot 1.3 (build 8; full isolert eiertest ble gjennomført før opplasting, etterfulgt av skrivebeskyttet produksjonskontroll av TestFlight-bygget)
- Xcode-skjema: `SaldoPilot`
- Enheter: iPhone 15 Pro og iPad 10, begge iOS 27.0.1
- Automatisert referanse: iPhone 15 Pro som aktivt Xcode-mål; iPhone 17 Pro-simulator med iOS 27.0 ble også brukt tidligere i gjennomgangen
- Data: isolert CloudKit-container `iCloud.com.terjemoe.SaldoPilot.Test` og separate lokale/minnebaserte testlagre
- Resultat: Bygg for testing besto. 14 av 14 automatiske tester besto. Fysisk eiertest dekket hovedflyt, PDF/AirPrint, omstart, offlinebruk og synk mellom iPhone/iPad. TestFlight 1.3 (8) besto validering og viste riktig produksjonslager på begge enhetene uten testbanner.
- Sikkerhet: Aktiv produksjonscontainer `iCloud.com.terjemoe.SaldoPilot` ble ikke brukt til testdata.
- Åpne funn: Ingen uavklarte P0/P1-funn. SP-015 er en dokumentert P2-ytelsesforbedring for svært store eksporter. Faktisk levering av lokale varsler er ikke testet i produksjonsmodus, fordi testmodus med hensikt deaktiverer varsler.

## M1 – gjennomgåtte hovedflyter

- Førstegangsbruk/tom database: Hovedfanene og opprettingshandlinger finnes; onboarding finnes ikke. Tomtilstand bør skilles tydeligere fra filtrert nullresultat.
- Mange poster: Lister bruker SwiftUI `List`, mens filtrering og summering skjer over hele `@Query`-resultatet i minnet. 1 000 og 10 000 poster er verifisert på fysisk iPhone; søk manglet og ble lagt til. Kjerneoperasjoner var raske, mens stor synkron eksport er registrert som SP-015.
- Opprette/redigere/slette: Implementert med skjema, bekreftet sletting og valg for fremtidige gjentakelser. Ulagrede endringer varsles ikke.
- Betaling/historikk: Betaling setter status/dato og oppretter neste forekomst. Detaljer viser den enkelte posten; samlet seriehistorikk finnes ikke.
- Filtrering: Hurtigfilter og avanserte filtre finnes. Aktive avanserte filtre vises som brikker og kan nullstilles; hurtigfilteret er synlig i segmentkontrollen.
- Periode/datotype: Oversikten viser valgt periode. Poster viser periodebrikke, men datotypebrikke vises bare når den avviker fra forfallsdato.
- Navigasjon: Standard NavigationStack, tilbake, avbryt og lagre brukes. Skjemalagring er deaktivert ved tom tittel/ugyldig beløp.
- Kategorier: Interne enum-navn er stabile, og visningstekster finnes for engelsk, norsk og thai. Egne kategorier støttes ikke.
- Utskrift: PDF, deling og systemutskrift finnes via Innstillinger, men ikke fra oversikt, liste eller detalj.

## Må testes på iPhone med isolert lager

1. Legg `SALDOPILOT_USE_TEST_STORE` med verdien `1` til Run > Environment Variables, og bekreft at appen starter tom med et oransje «ISOLATED TEST DATA»-banner.
2. Opprett syntetiske poster uten virkelige navn eller beløp; avslutt og start appen på nytt og bekreft at de er borte.
3. Kontroller tomtilstand, store tekststørrelser, norsk/engelsk/thai og lyst/mørkt/system.
4. Test tilbake, Avbryt, interaktiv nedtrekking av skjema og tastatur på liten og stor iPhone.
5. Ikke aktiver eller verifiser iCloud-synk i dette oppsettet.

## Utførte kontroller

- Uendret prosjekt bygget uten feil før endringer.
- Prosjektet bygget uten feil etter M0-isolasjon og første M2-rettelser.
- Xcodes live-diagnostikk rapporterte ingen feil i de endrede transaksjonsfilene.
- Ren kalenderkontroll uten datalager ga: 31.01.2024 → 29.02.2024, 31.01.2023 → 28.02.2023, 29.02.2024 → 29.03.2024 og 31.12.2024 → 31.01.2025.
- Felles, desimalbasert beløpstolkning godtar `1 234,50`, `1,234.50`, `1.234,50`, `1234.50`, `1 234,50 kr` og `NOK 1 234,50` som 1 234,50. Postbeløp avviser null, negative beløp, tekst og mer enn to desimaler. Valutavisning bruker nå `NSDecimalNumber` direkte uten mellomkonvertering til binært `Double`.
- Syntetisk JSON-rundtur mellom to separate SwiftData-minnelagre gjenopprettet 2 av 2 transaksjoner og bevarte ID-er, beløp, statuser, forfallsdatoer, betalingsdatoer, gjentakelse og fullførtstatus. Ingen CloudKit-container eller produksjonsfil ble åpnet.
- Manuell summeringsfasit for aktiv oktoberperiode ga inntekt 10 000,10, utgift 1 234,55 og netto 8 765,55; annullerte, arkiverte og neste måneds poster ble holdt utenfor.
- Periodegrenser bruker nå halvåpne intervaller. Kontrollene inkluderte 29. februar og hele dagen ved overgang til vintertid i `Europe/Oslo`, men ekskluderte nøyaktig midnatt i neste periode.
- Forfallsdatofilter for oktober valgte poster med oktoberforfall, mens betalingsdatofilteret valgte en septemberpost betalt i oktober og utelot en oktoberpost betalt i november. Omvendt egendefinert datovalg dekker nå begge endepunktene korrekt.
- Gjentakende betaling ble kontrollert i et isolert SwiftData-minnelager: en månedlig post med forfall 15.10 og betaling 03.11 beholdt ID, beløp, forfallsdato og betalingsdato. Neste forekomst fikk ny ID, samme beløp, forfall 15.11, ventende status og ingen betalingsdato. Dette bekrefter normalflyten og sen betaling, men løser ikke SP-011 for opprinnelig dag 29.–31.
- Betalingshistorikk er bare de lagrede forekomstene med faktisk `paidDate`. Appen konstruerer ikke eldre betalinger fra en nåværende forfallsdato. Importert «Betalt/Mottatt» uten betalingsdato blir heller ikke gitt en oppdiktet dato og er derfor ikke med i betalingsdatorapporten.
- Backupformat versjon 3 gjenopprettet et syntetisk budsjett med identisk UUID, kategori, måned, `Decimal`-beløp og tidsstempler. «Erstatt» fjernet ett gammelt budsjett og gjenopprettet ett nytt; en eldre backup uten `budgets` erstattet ingen budsjetter og bevarte det eksisterende.
- Backupformat versjon 3 gjenopprettet alle inkluderte appinnstillinger identisk i en separat `UserDefaults`-suite, inkludert startsaldo og dato. En eksisterende Pro-status og eksisterende samtykke til ekstern AI ble ikke overskrevet. Alle AppStorage-nøkler har nå egne testmodusnøkler, slik at testappen ikke endrer produksjonsinnstillinger.
- Swift Testing-målet er koblet til hovedskjemaets Test-handling. Testhandlingen har `SALDOPILOT_USE_TEST_STORE=1`, og 11 av 11 testtilfeller bestod på iPhone 17 Pro-simulator 14. oktober 2026, inkludert lokal lagring og gjenåpning. Brukeren bekreftet deretter på fysisk iPhone at én inntekt og én utgift fortsatt var lagret etter full omstart i det separate lokale testlageret. Ingen CloudKit-database ble brukt; aktivt kjøremål ble satt tilbake til iPhone 15 Pro etter kjøringen.
- Offlineflyten ble deretter verifisert på fysisk iPhone med samme separate lokale testlager: oppretting av inntekt og utgift, redigering, betaling og full omstart fungerte i flymodus. Etter overgang tilbake til nett forsvant eller dupliserte ingen poster. Testlageret hadde fortsatt CloudKit avslått.
- Belastningstest med 1 000 merkede syntetiske poster ble verifisert på fysisk iPhone i det isolerte lokale testlageret. Søk, scrolling, statusfiltre, postdetaljer, oversikt, statistikk, rapport og omstart fungerte uten merkbar feil eller duplisering. Testdata opprettes bare opp til ønsket antall og bruker ikke CloudKit.
- Ved 10 000-testen viste kodegjennomgang og skjermbilder at Poster-visningen manglet søkefunksjon. Søk i tittel og notat ble lagt til med SwiftUIs søkefelt, kombinert med eksisterende periode- og statusfiltre. Norsk «Søk i poster» og thai «ค้นหารายการ» ble lagt inn i String Catalog. Brukeren verifiserte søk etter «Belastningstest #9750» på fysisk iPhone med 10 000 isolerte poster.
- Hele 10 000-testen ble deretter bestått på fysisk iPhone: scrolling, søk, statusfiltre, postdetaljer, oversikt, statistikk, rapportgenerering og full omstart fungerte, og oppstarten opprettet ikke duplikater.
