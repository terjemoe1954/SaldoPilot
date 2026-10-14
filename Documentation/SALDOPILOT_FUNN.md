# SaldoPilot – funn og gjennomgang

Oppdatert: 14. oktober 2026  
Gjennomgått versjon: 1.2 (build 7), iOS/iPadOS 27.0  
Status: M0 ferdig, M1 ferdig ved statisk gjennomgang. Enhetstester er særskilt merket.

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

Dette er likevel ikke en fullstendig appbackup: `Budget`, appinnstillinger, kjøpsstatus og varselinnstillinger er ikke med. Kontrollen brukte bare syntetiske data og berørte ikke aktiv lokal database eller iCloud. Før en risikofylt modellendring må en fullstendig backupstrategi være på plass; dagens transaksjonsbackup alene beskytter ikke hele appens tilstand.

## Prioritert funnliste

### SP-001 – Betalingsdato kan overskrives på en allerede betalt post

- Type: Bekreftet feil
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
- Faktisk: Bare kategoridefinisjoner og transaksjoner eksporteres.
- Konsekvens: Brukeren kan tro at hele appen kan gjenopprettes.
- Prioritet: P1
- Foreslått tiltak: Endre forklaring straks; vurder senere versjonert fullbackup som inkluderer budsjetter og relevante innstillinger.
- Testresultat: Begrensningen er bekreftet ved kodegjennomgang. Transaksjonsdelen er gjenopprettet og feltsammenlignet i to isolerte minnelagre 14. oktober 2026; budsjetter og innstillinger er fortsatt ikke dekket.

### SP-005 – Import med «erstatt» er ikke transaksjonell

- Type: Bekreftet risiko
- Skjerm/fil: Import, `ImportService.swift`
- Reproduksjon: Velg erstatning med en gyldig fil og fremprovoser lagringsfeil etter at eksisterende objekter er markert for sletting.
- Forventet: Enten fullføres hele erstatningen, eller opprinnelige data beholdes.
- Faktisk: Eksisterende transaksjoner slettes i konteksten før nye settes inn; eksplisitt rollback/atomisk validering finnes ikke.
- Konsekvens: Potensielt datatap dersom lagring feiler eller delvis state lagres.
- Prioritet: P1
- Foreslått tiltak: Valider alt først, bruk isolert kontekst/atomisk strategi, lagre eksplisitt og håndter rollback.
- Testresultat: Risiko bekreftet ved kodegjennomgang; skal ikke prøves mot produksjonsdata.

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
- Faktisk: Fremtidige forekomster finnes ved likhet på flere redigerbare felt; ingen serie-ID lagres.
- Konsekvens: Serieoppdatering/sletting kan slutte å finne tilhørende poster, eller i sjeldne tilfeller treffe separate, identiske poster.
- Prioritet: P2 nå, men P1 før større serieendringer
- Foreslått tiltak: Ikke migrer produksjonsmodellen uten backupprøve; vurder stabil serie-ID i en eksplisitt, testet migrering.
- Testresultat: Bekreftet ved kodegjennomgang; ingen modellendring utført.

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
- Faktisk: Resultatet blir 31.01 → 29.02 → 29.03. Tilsvarende kan dato 30 drive etter februar.
- Konsekvens: Fremtidige forfallsdatoer kan bli tidligere enn den avtalte datoen etter februar.
- Prioritet: P1
- Foreslått tiltak: Lagre en stabil opprinnelig månedsdag/serieidentitet og bruk den ved beregning. Dette krever eksplisitt SwiftData-/CloudKit-migrering og skal først prøves på en gjenopprettet kopi.
- Testresultat: Bekreftet med ren kalenderkjøring uten datalager 14. oktober 2026. Ingen modellendring utført.

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

## M1 – gjennomgåtte hovedflyter

- Førstegangsbruk/tom database: Hovedfanene og opprettingshandlinger finnes; onboarding finnes ikke. Tomtilstand bør skilles tydeligere fra filtrert nullresultat.
- Mange poster: Lister bruker SwiftUI `List`, men filtrering og summering skjer over hele `@Query`-resultatet i minnet. Ytelse ved 1 000/10 000 poster er ikke målt.
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
- Et Swift Testing-mål med fire testgrupper er opprettet for beløpsinput, tilgjengelig saldo og gjentakelsesdatoer. Testmålet bygger og Xcode finner alle fire testene. Automatisk kjøring er foreløpig blokkert av testskjemaets vertskonfigurasjon; de samme beregningene er kjørt som isolerte kodesnutter. Dette regnes ikke som bestått automatisert testkjøring før Xcode kan kjøre testplanen.
