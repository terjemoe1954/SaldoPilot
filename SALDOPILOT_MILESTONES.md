# SaldoPilot – Produktplan og milepæler

## 1. Prosjektidé

**Arbeidstittel:** SaldoPilot  
**Plattform:** iPhone / iPad  
**Teknologi:** SwiftUI + SwiftData  
**Fase 1:** Lokal lagring, enkel og tydelig økonomistyring  
**Fase 2:** iCloud-synk, AI-funksjoner og eventuell betaling/abonnement  
**Mål:** Lage en moderne, enkel og trygg økonomiapp som gjør det lett å holde kontroll på inntekter, utgifter, forfall, gjentakende poster, kategorier og økonomisk utvikling.

SaldoPilot skal videreføre det som allerede fungerer godt i dagens app, men med enklere navigasjon, tydeligere språk og mindre behov for at brukeren må lære hvordan appen fungerer.

---

# 2. Hovedprinsipper

- Appen skal være forståelig første gang den åpnes.
- Viktigste informasjon skal være synlig på forsiden.
- Vanlige handlinger skal kreve få trykk.
- "Klient" erstattes med **Kategori**.
- Forfalte poster skal være lette å finne.
- Gjentakende poster skal håndteres automatisk og forståelig.
- Brukeren skal aldri være i tvil om en post er:
  - Ventende
  - Forfalt
  - Betalt
  - Mottatt
  - Ferdigbehandlet
- Filtrering skal være enkelt, men kraftig.
- AI skal hjelpe brukeren, ikke gjøre appen vanskeligere.
- Ingen AI skal få endre økonomiske data uten tydelig godkjenning fra brukeren.

---

# 3. Foreslått navigasjon

Bruk en enkel `TabView` med fire hovedområder:

1. **Oversikt**
2. **Poster**
3. **Statistikk**
4. **Innstillinger**

En tydelig `+`-knapp brukes for å opprette ny post.

## Oversikt

Forsiden bør vise:

- Saldo / netto for valgt periode
- Inntekter
- Utgifter
- Til gode
- Antall forfalte poster
- Neste forfall
- Poster som krever oppmerksomhet
- Kort AI-oppsummering når AI aktiveres

Eksempel:

> Denne måneden har du 30 811 kr i inntekter og 21 002 kr i utgifter.  
> Du har 3 forfalte poster og 9 809 kr igjen etter registrerte poster.

---

# 4. Datamodell – foreslått struktur

## Transaction / Post

Felter:

- id
- title
- amount
- type
  - income
  - expense
- dueDate
- paidDate
- status
- category
- recurrence
- recurrenceInterval
- notes
- createdAt
- updatedAt
- isCompleted
- isArchived

## Status

Forslag:

- pending
- overdue
- paid
- received
- cancelled

`overdue` kan beregnes automatisk fra dato i stedet for å lagres permanent.

## Category

Felter:

- id
- name
- icon
- optional color identifier
- createdAt

Når kategori slettes:

- vis tydelig advarsel
- tilby:
  1. Flytt poster til annen kategori
  2. Sett kategori til "Ingen kategori"
  3. Slett kategori og alle tilhørende poster

Standardvalg bør **ikke** være permanent sletting av alle poster.

## Recurrence

Forslag:

- none
- monthly
- everyNMonths
- quarterly
- halfYearly
- yearly
- custom

For kompatibilitet med gammel løsning kan `recurrenceIntervalMonths` beholdes internt.

---

# 5. Milepæl 0 – Opprett nytt prosjekt

- [ ] Opprett nytt SwiftUI-prosjekt i Xcode.
- [ ] Appnavn: `SaldoPilot`
- [ ] Interface: SwiftUI
- [ ] Language: Swift
- [ ] Bruk SwiftData.
- [ ] Ikke aktiver CloudKit i første versjon.
- [ ] Sett minimum iOS-versjon.
- [ ] Opprett Git-repository.
- [ ] Første commit: `Initial SaldoPilot project`.

## Mappestruktur

```text
SaldoPilot/
├── App/
│   ├── SaldoPilotApp.swift
│   └── AppRouter.swift
│
├── Models/
│   ├── Transaction.swift
│   ├── Category.swift
│   ├── TransactionType.swift
│   ├── TransactionStatus.swift
│   └── RecurrenceRule.swift
│
├── Views/
│   ├── Dashboard/
│   ├── Transactions/
│   ├── Categories/
│   ├── Statistics/
│   ├── Settings/
│   └── Components/
│
├── ViewModels/
│
├── Services/
│   ├── StatisticsService.swift
│   ├── RecurrenceService.swift
│   ├── FilterService.swift
│   └── NotificationService.swift
│
├── AI/
│   └── AIService.swift
│
├── Utilities/
├── Resources/
└── Localization/
```

- [ ] Gi `ContentView` nytt navn, for eksempel `MainTabView`.
- [ ] Sørg for at prosjektet bygger uten feil.

---

# 6. Milepæl 1 – Grunnmodell med SwiftData

Mål: få en stabil datamodell før UI bygges videre.

- [ ] Opprett `Transaction`.
- [ ] Opprett `Category`.
- [ ] Opprett enums for type, status og gjentakelse.
- [ ] Lag relasjon mellom post og kategori.
- [ ] Lag testdata.
- [ ] Test oppretting.
- [ ] Test redigering.
- [ ] Test sletting.
- [ ] Test at data overlever omstart.
- [ ] Lag migreringsstrategi tidlig.

Akseptansekriterium:

> En bruker skal kunne opprette, endre og slette en post lokalt uten iCloud.

---

# 7. Milepæl 2 – Ny hovednavigasjon

Mål: gjøre appen forståelig for nye brukere.

Opprett `MainTabView` med:

- [ ] Oversikt
- [ ] Poster
- [ ] Statistikk
- [ ] Innstillinger

I tillegg:

- [ ] Global `+`-knapp for ny post.
- [ ] Tydelige SF Symbols.
- [ ] Native SwiftUI-design.
- [ ] Dynamic Type.
- [ ] VoiceOver-labels.
- [ ] God visning i både portrait og landscape der relevant.
- [ ] iPad-støtte vurderes fra starten.

---

# 8. Milepæl 3 – Ny Oversikt

Forsiden skal erstatte dagens mer grafiske, men mindre intuitive startside.

## Øverst

- [ ] Velkomsttekst, valgfri.
- [ ] Valgt periode.
- [ ] Hurtigvalg:
  - Denne måneden
  - Forrige måned
  - Dette året
  - Egendefinert

## Sammendragskort

- [ ] Inntekter
- [ ] Utgifter
- [ ] Netto
- [ ] Til gode

## Oppmerksomhet

- [ ] Forfalte poster.
- [ ] Poster som forfaller snart.
- [ ] Ventende inntekter.
- [ ] Hurtigknapp "Se alle".

## Handlinger

- [ ] Ny inntekt
- [ ] Ny utgift
- [ ] Registrer betaling

Akseptansekriterium:

> En ny bruker skal kunne forstå egen økonomisk situasjon uten å åpne filter eller statistikk.

---

# 9. Milepæl 4 – Poster

Lag én samlet liste for alle poster.

## Segmenter

- [ ] Alle
- [ ] Forfalt
- [ ] Kommende
- [ ] Betalt
- [ ] Til gode

## Hver rad viser

- [ ] Tittel
- [ ] Kategori
- [ ] Beløp
- [ ] Forfallsdato
- [ ] Status
- [ ] Type

## Swipe actions

- [ ] Marker betalt
- [ ] Rediger
- [ ] Dupliser
- [ ] Slett

## Trykk på rad

Åpner detaljvisning.

---

# 10. Milepæl 5 – Opprett / rediger post

Erstatt dagens skjema med en ryddigere `Form` eller moderne seksjonsoppsett.

Felter:

- [ ] Navn
- [ ] Beløp
- [ ] Inntekt / Utgift
- [ ] Kategori
- [ ] Forfallsdato
- [ ] Betalt-/mottattdato
- [ ] Status
- [ ] Gjentakelse
- [ ] Notat

## Gjentakelse

I stedet for bare "Intervall i måneder":

Vis:

- Ingen
- Hver måned
- Hver 2. måned
- Hver 3. måned
- Hver 6. måned
- Hvert år
- Egendefinert

Ved betaling av gjentakende post:

- [ ] Nåværende forekomst markeres som betalt.
- [ ] Neste forekomst opprettes automatisk.
- [ ] Brukeren ser en kort bekreftelse.

Dette er sikrere enn å flytte samme post fremover og miste historikken.

---

# 11. Milepæl 6 – Kategorier

Bytt navn fra `Klient` til `Kategori` i hele appen.

Eksempler:

- Bolig
- Strøm
- Telefon
- Transport
- Mat
- Abonnement
- Forsikring
- Lønn
- Refusjon
- Andre inntekter

Funksjoner:

- [ ] Opprett kategori.
- [ ] Rediger kategori.
- [ ] Slett kategori.
- [ ] Vis antall poster.
- [ ] Vis sum i valgt periode.
- [ ] Velg ikon.

Ved sletting:

- [ ] Vis antall poster som påvirkes.
- [ ] Ikke slett poster automatisk uten ekstra bekreftelse.
- [ ] Tilby flytting til annen kategori.

---

# 12. Milepæl 7 – Filter

Dagens filter har mange muligheter, men kan forenkles.

Opprett filter-sheet med:

## Dato

- [ ] Denne måneden
- [ ] Forrige måned
- [ ] Dette året
- [ ] Egendefinert periode

## Datotype

- [ ] Forfallsdato
- [ ] Betalt-/mottattdato

## Status

- [ ] Alle
- [ ] Ventende
- [ ] Forfalt
- [ ] Betalt
- [ ] Mottatt

## Type

- [ ] Alle
- [ ] Inntekt
- [ ] Utgift

## Kategori

- [ ] Alle kategorier
- [ ] En bestemt kategori

## Beløp

- [ ] Fra
- [ ] Til

- [ ] Knapp: Nullstill filter.
- [ ] Vis aktive filtre som chips over listen.

---

# 13. Milepæl 8 – Statistikk

Forbedre dagens månedsvisning.

## Hovedvisning

- [ ] Inntekter
- [ ] Utgifter
- [ ] Netto
- [ ] Til gode

## Diagrammer

- [ ] Inntekter vs. utgifter per måned.
- [ ] Utgifter per kategori.
- [ ] Netto utvikling.
- [ ] Utestående beløp.

Bruk native Swift Charts.

## Detaljer

Trykk på en måned eller kategori:

- [ ] åpner postene bak tallet.

---

# 14. Milepæl 9 – Innstillinger

Ny `SettingsView`.

## Utseende

- [ ] System
- [ ] Lys
- [ ] Mørk

## Personlig

- [ ] Vis navn på forsiden.
- [ ] Navn.

## Poster

- [ ] Vis ferdigbehandlet-status.
- [ ] Standardperiode.
- [ ] Standard datotype.

## Varsler

- [ ] Forfall i dag.
- [ ] Forfall i morgen.
- [ ] Forfall om X dager.

## App

- [ ] Versjon
- [ ] Build
- [ ] Personvern
- [ ] Support
- [ ] Eksporter data

---

# 15. Milepæl 10 – Lokalvarsler

Før AI bør appen allerede være smart.

- [ ] Varsel før forfall.
- [ ] Varsel på forfallsdato.
- [ ] Varsel ved ubetalt forfalt post.
- [ ] Valgfri påminnelse for ventende inntekter.
- [ ] Varsler kan skrus av.

Eksempel:

> Strøm – 1 249 kr forfaller i morgen.

---

# 16. Milepæl 11 – AI fase 1

AI skal i første omgang være rådgivende.

## AI-oppsummering

Eksempler:

> Utgiftene dine denne måneden er 2 300 kr høyere enn forrige måned.

> Du har 4 regninger på totalt 5 840 kr som forfaller de neste 7 dagene.

> Abonnement-kategorien har økt med 18 % de siste tre månedene.

## AI-funksjoner

- [ ] Forklar økonomisk situasjon i vanlig språk.
- [ ] Finn endringer i forbruk.
- [ ] Oppdag mulige gjentakende poster.
- [ ] Fremhev uvanlige beløp.
- [ ] Foreslå kategorier.
- [ ] Lag ukentlig/månedlig sammendrag.

AI skal aldri:

- automatisk slette poster
- automatisk merke en betaling som utført
- sende persondata uten informasjon og samtykke
- gi inntrykk av å være bank eller finansiell rådgiver

---

# 17. Milepæl 12 – AI fase 2

Mulige videre funksjoner:

- [ ] Naturlig språk-søk.

Eksempel:

> Vis alle strømregninger over 1 000 kr i 2026.

- [ ] "Hvor mye brukte jeg på abonnement i år?"
- [ ] "Hva forfaller neste uke?"
- [ ] "Hvilke utgifter har økt mest?"
- [ ] "Hva kan jeg spare på?"
- [ ] Automatisk forslag til kategori ved ny post.
- [ ] Oppdag duplikater.
- [ ] Oppdag unormale beløp.

---

# 18. Milepæl 13 – Personvern og AI

Før AI kobles mot ekstern tjeneste:

- [ ] Kartlegg hvilke data som sendes.
- [ ] Send minst mulig data.
- [ ] Unngå navn/persondata når de ikke trengs.
- [ ] Oppdater Privacy Policy.
- [ ] Lag tydelig AI-informasjon i appen.
- [ ] Lag samtykke før data sendes eksternt.
- [ ] Vurder Apple Intelligence/Foundation Models dersom tilgjengelig og egnet.
- [ ] Vurder serverbasert AI kun for funksjoner som ikke kan kjøres lokalt.

---

# 19. Milepæl 14 – iCloud / CloudKit – fase 2

Ikke gjør dette før lokal datamodell er stabil.

- [ ] Aktiver iCloud.
- [ ] Aktiver CloudKit.
- [ ] Test SwiftData + CloudKit.
- [ ] Test samme Apple-ID på to enheter.
- [ ] Test konflikt ved samtidige endringer.
- [ ] Test sletting.
- [ ] Test offline → online.
- [ ] Test app reinstallasjon.
- [ ] Test store datamengder.

Målet er at iPhone og iPad kan dele samme data uten manuell eksport.

---

# 20. Milepæl 15 – Import fra gammel app

Dette bør vurderes dersom dagens brukere skal flyttes over.

Muligheter:

- [ ] JSON-eksport fra gammel app.
- [ ] JSON-import i SaldoPilot.
- [ ] CSV som reserveformat.
- [ ] Import av kategorier.
- [ ] Import av gamle poster.
- [ ] Import av gjentakende regler.

Viktig:

> Bygg migrering som egen funksjon. Ikke koble ny datamodell direkte til gammel database før ny modell er stabil.

---

# 21. Milepæl 16 – Backup og eksport

- [ ] Eksport til CSV.
- [ ] Eksport til JSON.
- [ ] Del eksportfil via Share Sheet.
- [ ] Import fra backup.
- [ ] Bekreft før overskriving / sammenslåing.

Dette bør være tilgjengelig selv om iCloud senere aktiveres.

---

# 22. Milepæl 17 – App Store-funksjoner

Før første TestFlight:

- [ ] Appikon.
- [ ] Launch experience.
- [ ] Privacy Policy.
- [ ] Support URL.
- [ ] App Store-beskrivelse.
- [ ] Screenshots.
- [ ] App Privacy-skjema.
- [ ] TestFlight intern testing.
- [ ] Test på flere skjermstørrelser.
- [ ] Test med tom database.
- [ ] Test med mange poster.
- [ ] Test mørk modus.
- [ ] Test norsk og engelsk.

---

# 23. Milepæl 18 – Pris / Premium – fase 2

Ikke bygg betaling før appen gir tydelig verdi.

## Forslag til modell

### Gratis

- Lokal lagring
- Poster
- Kategorier
- Gjentakende poster
- Enkel statistikk
- Lokale varsler

### SaldoPilot Plus

Mulig premium:

- iCloud-synk
- Avansert statistikk
- AI-oppsummeringer
- AI-søk
- Smart kategorisering
- Eksport / avansert backup
- Flere automatiseringer

Vurder:

- Månedlig abonnement
- Årlig abonnement
- Eventuelt lifetime-kjøp

Pris bestemmes senere etter TestFlight-feedback og AI-kostnader.

---

# 24. Milepæl 19 – TestFlight

- [ ] Opprett App Store Connect-record.
- [ ] Opprett Bundle ID.
- [ ] Sett versjon til for eksempel `0.1`.
- [ ] Build starter på `1`.
- [ ] Archive.
- [ ] Upload til App Store Connect.
- [ ] Intern TestFlight.
- [ ] Minst 1–2 uker aktiv testing.
- [ ] Samle feil og forslag.
- [ ] Ikke legg til nye store funksjoner rett før review.

---

# 25. Milepæl 20 – App Store Release

- [ ] Alle kritiske bugs lukket.
- [ ] Ingen testdata i produksjonsbuild.
- [ ] Privacy Policy ferdig.
- [ ] Support-side ferdig.
- [ ] App Privacy riktig.
- [ ] Screenshots ferdig.
- [ ] Beskrivelse ferdig.
- [ ] Keywords ferdig.
- [ ] Age Rating ferdig.
- [ ] Review Notes ferdig.
- [ ] Send inn versjon 1.0.

---

# 26. Prioritert rekkefølge

## Fase 1 – MVP

1. SwiftData lokal lagring
2. Ny datamodell
3. TabView
4. Oversikt
5. Poster
6. Ny/rediger post
7. Kategorier
8. Filter
9. Statistikk
10. Innstillinger
11. Lokale varsler
12. TestFlight

## Fase 1.5

13. Import/eksport
14. AI-oppsummering lokalt eller med begrenset ekstern AI
15. Forbedret onboarding

## Fase 2

16. iCloud / CloudKit
17. AI-søk
18. Smart kategorisering
19. Premium
20. App Store lansering / videreutvikling

---

# 27. Forslag til AI-opplevelse på forsiden

Legg til et lite kort kalt:

**SaldoPilot Innsikt**

Eksempler:

- "Du har 6 420 kr i regninger de neste 14 dagene."
- "Strømforbruket ditt er 18 % høyere enn gjennomsnittet de siste 6 månedene."
- "Du har tre abonnement som totalt koster 877 kr per måned."
- "Du venter på 4 500 kr i innbetalinger."
- "Hvis alle ventende inntekter kommer inn, blir netto for måneden +8 230 kr."

Trykk på kortet åpner forklaring og postene som ligger bak beregningen.

---

# 28. UX-forbedringer fra gammel app

- Erstatt store spesialknapper med standard navigasjon der det passer.
- Bruk konsekvent grønn for inntekt/positivt.
- Bruk rød primært for feil, fare og forfalt.
- Bruk ikke farger som eneste statusindikator.
- Vis alltid tekststatus.
- Bruk norsk valutaformat konsekvent: `9 809,30 kr`.
- Bruk samme datoformat overalt.
- Gi tydelig bekreftelse etter handling.
- Bruk undo ved sletting der det er mulig.
- Behold historikk for gjentakende poster.
- Gjør det mulig å åpne tall i statistikken og se postene bak.

---

# 29. Første Codex-oppgave

Når prosjektet er opprettet og denne filen ligger i rotmappen:

```text
Read SALDOPILOT_MILESTONES.md carefully.

Start with Milestone 0 and Milestone 1 only.

Create the proposed project folder structure.
Rename ContentView to MainTabView.
Create the SwiftData models and enums described in the milestone file.
Do not implement iCloud, AI, payments, statistics or advanced UI yet.

Keep the project compiling after every change.
Use native SwiftUI and SwiftData patterns.
Do not remove existing project files unless necessary.
When finished, summarize exactly what was created and what remains for the next milestone.
```

---

# 30. Definition of Done for første App Store-versjon

Versjon 1.0 er klar når brukeren kan:

- [ ] Opprette inntekt.
- [ ] Opprette utgift.
- [ ] Velge kategori.
- [ ] Registrere forfallsdato.
- [ ] Registrere betalt/mottatt.
- [ ] Opprette gjentakende poster.
- [ ] Se forfalte poster.
- [ ] Filtrere poster.
- [ ] Se oversikt for periode.
- [ ] Se statistikk.
- [ ] Motta lokale varsler.
- [ ] Eksportere egne data.
- [ ] Bruke appen uten konto.
- [ ] Forstå appen uten instruksjonsmanual.

---

## Sluttmål

SaldoPilot skal føles som en enkel økonomisk assistent, ikke som et regneark.

Først bygges en robust og enkel økonomiapp. Deretter legges iCloud, AI og premium-funksjoner oppå en stabil kjerne.
