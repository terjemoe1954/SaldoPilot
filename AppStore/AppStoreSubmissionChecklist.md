# SaldoPilot – App Store submission checklist

Sist oppdatert: 2026-10-18

Denne listen skiller mellom det som allerede ligger klart i prosjektet og det som må fylles ut eller bekreftes manuelt i App Store Connect.

## Klart i prosjektet

- [x] Appnavn: SaldoPilot
- [x] Bundle-ID: `com.terjemoe.SaldoPilot`
- [x] Norsk og engelsk undertittel, kampanjetekst, beskrivelse og nøkkelord
- [x] Norsk og engelsk «Hva er nytt»
- [x] Seks norske App Store-bilder i 1206 × 2622
- [x] Seks engelske App Store-bilder i 1206 × 2622
- [x] Appikon i 1024 × 1024 uten alfakanal
- [x] Personvernerklæring
- [x] Supporttekst
- [x] App Review-notater og foreslått testflyt
- [x] Ingen innlogging eller demo-konto kreves
- [x] Ingen tredjepartsannonser eller sporings-SDK-er
- [x] Lokale AI-oppsummeringer sender ikke transaksjonsdata til en ekstern AI-tjeneste
- [x] Pro-kjøpets produkt-ID i appen: `com.terjemoe.SaldoPilot.pro`

## Må publiseres som nettsider

App Store Connect trenger offentlige HTTPS-adresser, ikke bare Markdown-filer i prosjektet.

- [ ] Publiser `PrivacyPolicy.md` og legg adressen i **Privacy Policy URL**
- [ ] Publiser `Support.md` og legg adressen i **Support URL**
- [ ] Åpne begge lenkene i privat nettleservindu og kontroller at de virker uten innlogging
- [ ] Bruk en stabil adresse som ikke endres mellom appversjoner

## Appinformasjon

- [ ] Primærkategori: **Finance**
- [ ] Sekundærkategori: **Productivity**
- [ ] Bekreft opphavsrett, for eksempel **© 2026 Terje Moe**
- [ ] Fyll ut kontaktopplysninger for App Review
- [ ] Velg at innlogging/demo-konto **ikke kreves**
- [ ] Lim inn App Review-notatene fra `AppStoreMetadata.md`
- [ ] Kontroller at versjonsnummer og buildnummer er høyere enn forrige opplasting

## Aldersgrense og innhold

- [ ] Fyll ut Apples aldersgrenseskjema sannferdig
- [ ] Appen skal ikke merkes som laget spesielt for barn
- [ ] Oppgi ingen gambling med mindre faktisk gamblinginnhold senere legges til
- [ ] Oppgi ingen ubegrenset nettilgang; vanlige systemlenker til support/personvern er ikke en innebygd nettleser
- [ ] Kontroller resultatet som App Store Connect beregner før innsending

## App Privacy

Bekreft mot den aktuelle binæren før innsending:

- [ ] Ingen sporing på tvers av apper eller nettsteder
- [ ] Ingen data brukt til tredjepartsannonsering
- [ ] Ingen SaldoPilot-konto eller innsamlet e-postadresse
- [ ] Brukerregistrert økonomiinformasjon lagres på enheten og kan synkroniseres med brukerens private iCloud
- [ ] Titler og notater behandles som brukerinnhold
- [ ] Eksport skjer bare etter brukerens handling via Apples systemgrensesnitt
- [ ] Sammenlign svarene med `AppPrivacyQuestionnaire.md`

Merk: App Store Connects betydning av «collected» må vurderes nøye for data som bare behandles på enheten eller i brukerens private iCloud. Ikke svar automatisk «ja» bare fordi appen lagrer data lokalt.

## SaldoPilot Pro

- [ ] Opprett eller kontroller ikke-fornybart kjøp med produkt-ID `com.terjemoe.SaldoPilot.pro`
- [ ] Legg til norsk og engelsk visningsnavn og beskrivelse
- [ ] Velg pris og tilgjengelige land/regioner
- [x] App Review-skjermbilde av kjøpssiden er laget
- [ ] Last opp `InAppPurchase/SaldoPilot-Pro-Review.png` i App Store Connect
- [ ] Sørg for at kjøpet har status **Ready to Submit**
- [ ] Send Pro-kjøpet sammen med appversjonen når det skal lanseres
- [ ] Kontroller aktiv Paid Apps Agreement, bank- og skatteinformasjon
- [ ] Test kjøp, avbrutt kjøp, ventende kjøp og gjenoppretting i TestFlight

## Build og skjermbilder

- [ ] Last opp ny build med det nye appikonet
- [ ] Vent til builden er ferdig behandlet i App Store Connect
- [ ] Velg riktig build på versjonssiden
- [ ] Last opp norske bilder under norsk bokmål
- [ ] Last opp engelske bilder under engelsk
- [ ] Kontroller rekkefølgen 1–6 og forhåndsvis hvert bilde
- [ ] Kontroller at alle synlige funksjoner i bildene finnes i builden

## Siste kontroll før «Add for Review»

- [ ] Test ren installasjon fra TestFlight
- [ ] Test oppgradering fra forrige TestFlight-build uten datatap
- [ ] Test oppretting, redigering og sletting av poster
- [ ] Test budsjett og statistikk med refusjon som inntekt
- [ ] Test JSON-backup, gjenoppretting, CSV og PDF
- [ ] Test «Slett alle data»
- [ ] Test iCloud-synk mellom to enheter hvis mulig
- [ ] Test varslingstillatelse og lokale varsler
- [ ] Test norsk, engelsk og thai
- [ ] Test kjøp og «Gjenopprett kjøp»
- [ ] Bekreft at ingen testmodus eller testdata finnes i Release-builden
- [ ] Velg manuell eller automatisk publisering etter godkjenning

## Filer som skal brukes

- Metadata: `AppStoreMetadata.md`
- Personvern: `PrivacyPolicy.md`
- Support: `Support.md`
- Personvernspørsmål: `AppPrivacyQuestionnaire.md`
- Testplan: `TestPlan.md`
- Norske bilder: `Screenshots/nb-iPhone-17-Pro/Final/`
- Engelske bilder: `Screenshots/en-iPhone-17-Pro/Final/`
