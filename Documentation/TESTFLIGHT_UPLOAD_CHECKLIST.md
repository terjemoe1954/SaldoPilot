# SaldoPilot 1.5 build 21 – TestFlight

- [x] Release-arkiv 1.5 (21), riktig bundle-ID og kodesignatur kontrollert.
- [x] Åtte målrettede tester bestått; utkast, godkjenning, avbryting og lagring kontrollert i isolert simulatorlager.
- [x] Apples validering og opplasting fullført uten feil.
- [x] Behandling fullført og krypteringsopplysning registrert i Info.plist.
- [x] Norske testnotater for iPhone og Mac lagret.
- [x] `Internal` viser **Testing** for 1.5 (21).
- [ ] Oppdater via TestFlight på iPhone og Mac og gjennomfør eiertesten.

Testinstruksjoner: `AppStore/TestFlight_1.5_21.txt`.
Utgivelsesstatus og buildlenke: `AppStore/Release_1.5_21.json`.

---

## Historisk sjekkliste for 1.4.1 build 20

- [x] Release-arkiv 1.4.1 (20), riktig bundle-ID og signatur kontrollert.
- [x] Migrering og AI-kort verifisert med tre relevante regresjonstester.
- [x] Nødvendige gjentakelsesfelt publisert til CloudKit Production.
- [x] Apple-validering og opplasting fullført uten feil.
- [x] Behandling fullført og krypteringsopplysninger avklart.
- [x] Norske testnotater lagret og `Internal` viser status **Testing** for build 20.
- [ ] Installer build 20 gjennom TestFlight på ønskede enheter og gjennomfør eiertesten.

Endringsnotater: `AppStore/TestFlight_1.4.1_20.txt`.

---

## Historisk sjekkliste for 1.3 build 8


## Før Archive

- Bekreft versjon **1.3** og build **8**.
- Behold siste JSON-backup urørt.
- Bekreft at Signing & Capabilities bruker riktig team, Push Notifications og iCloud/CloudKit.
- Bekreft i CloudKit Console at nødvendig skjema for produksjonscontaineren `iCloud.com.terjemoe.SaldoPilot` er distribuert til Production. Ikke endre eller slett produksjonsdata.
- Testcontaineren `iCloud.com.terjemoe.SaldoPilot.Test` kan være med i utviklingsentitlements, men Release-koden kan ikke velge den.
- Kontroller at personverntekst, TestFlight-notater og testinstruksjoner er klare.

## Archive i Xcode

1. Velg skjema **SaldoPilot**.
2. Velg **Any iOS Device (arm64)** som kjøremål.
3. Velg **Product → Archive**.
4. Vent til Organizer åpnes og velg det nye arkivet for 1.3 (8).
5. Velg **Validate App** og løs eventuelle feil før opplasting.
6. Velg **Distribute App → App Store Connect → Upload**.
7. Behold standard automatisk signering dersom valideringen viser riktig team og bundle-ID.

## Etter opplasting

- Build 8 er validert, lastet opp og ferdig behandlet i App Store Connect.
- Legg inn endringsnotater og TestFlight-testinstruksjoner fra dokumentene i prosjektet.
- Intern gruppe med én tester er aktivert.
- TestFlight-builden er kontrollert på iPhone og iPad uten oransje testbanner; kjente produksjonsposter vises og isolerte testposter mangler.
- Gjennomfør deretter den ikke-destruktive eiertestlisten før flere testere inviteres.

## Stopp hvis

- arkivet viser feil versjon/build, bundle-ID, team eller iCloud-container
- validering feiler
- TestFlight viser testbanner eller mangler kjente data
- appen ber om uventede tillatelser eller viser migrerings-/synkfeil

Ikke slett appdata, iCloud-data eller importer backup som første feilsøkingstiltak.
