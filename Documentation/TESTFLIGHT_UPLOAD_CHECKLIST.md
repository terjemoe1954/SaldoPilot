# SaldoPilot 1.3 build 8 – TestFlight-opplasting

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
