# SaldoPilot 1.3 (14) – release readiness

Kontrollert: 2026-10-18

## Build identity

| Felt | Verdi |
|---|---|
| Version | 1.3 |
| Build | 14 |
| Bundle ID | `com.terjemoe.SaldoPilot` |
| Signing | Automatic |
| Team | `4LR68777XL` |
| Deployment target | iOS 27.0 |
| Destinasjon for sluttbuild | Any iOS Device (arm64) |

Buildnummer 14 er valgt fordi build 13 allerede brukes i TestFlight.

## Automated verification

- [x] Hele testpakken kjørt
- [x] 18 av 18 tester bestod
- [x] Ingen feilede, hoppede over eller ikke-kjørte tester
- [x] Full Xcode-build for Any iOS Device bestod
- [x] Ingen build-advarsler rapportert

Testene dekker blant annet:

- Valutaformater og ugyldige beløp
- Sikker CSV-eksport
- PDF-grensedata
- Tilgjengelig saldo
- Månedlig gjentakelse og korte måneder
- Lokal lagring og SwiftData-migrering
- Kategorimigrering
- Sparing og saldojusteringer utenfor vanlig kontantstrøm
- Kategoriforslag og refusjonskobling
- Unike eksportfilnavn uten overskriving

## Før arkivering

- [x] Bekreftet at build 13 allerede brukes i TestFlight
- [x] Buildnummeret er økt til 14
- [ ] Kontroller at riktig Apple Developer-team er valgt
- [ ] Kontroller at Release-signering viser gyldig distribusjonsprofil
- [ ] Arkiver med Any iOS Device (arm64)
- [ ] Kjør Validate App før opplasting
- [ ] Last opp og vent til Apple har behandlet builden
