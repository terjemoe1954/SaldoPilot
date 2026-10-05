# SaldoPilot Pro - testplan for kjøp og restore

Sist oppdatert: 2026-09-24

Formål: teste at SaldoPilot Pro fungerer som non-consumable in-app purchase før funksjoner låses bak Pro.

## Produkt

| Felt | Verdi |
|---|---|
| Produktnavn | SaldoPilot Pro |
| Type | Non-Consumable In-App Purchase |
| Pris | 39 kr |
| Product ID | `com.terjemoe.SaldoPilot.pro` |
| App-modell | Gratis basisapp med Pro som engangskjøp |

## Før TestFlight-test

| Ferdig | Kontrollpunkt |
|---|---|
| [x] | Appen er fortsatt gratis i Pricing and Availability. |
| [x] | SaldoPilot Pro finnes under In-App Purchases i App Store Connect. |
| [x] | Product ID er nøyaktig `com.terjemoe.SaldoPilot.pro`. |
| [x] | Produktet er non-consumable. |
| [x] | Pris er satt til 39 kr eller nærmeste tilsvarende Apple price tier. |
| [x] | Produktet er lagt til versjonen/builden hvis App Store Connect ber om det. |
| [x] | Ny build med StoreKit-koden er godkjent og ligger på App Store som 1.0.3 build 1. |

## Testmiljø Nå

- App Store-versjon: 1.0.3 build 1
- Pro-produkt: SaldoPilot Pro, non-consumable, 39 kr
- Funksjoner er fortsatt ikke låst bak Pro
- Målet er å bekrefte produktlasting, kjøp, restore og status etter restart/enhetsbytte

## Test 1 - Produkt vises

| Ferdig | Kontrollpunkt |
|---|---|
| [x] | Installer appen fra TestFlight/App Store. |
| [x] | Åpne Innstillinger. |
| [x] | Åpne SaldoPilot Pro. |
| [x] | Sjekk at nåværende plan viser Gratis før kjøp. |
| [x] | Sjekk at pris vises. |
| [x] | Sjekk at kjøpsknappen vises. |

Forventet resultat:

- Produktet lastes fra App Store.
- Pris vises i lokal valuta.
- Ingen funksjoner er låst ennå.

## Test 2 - Kjøp Pro

| Ferdig | Kontrollpunkt |
|---|---|
| [x] | Trykk Kjøp Pro. |
| [x] | Fullfør kjøpet. |
| [x] | Sjekk at status endres til SaldoPilot Pro. |
| [x] | Lukk og åpne appen på nytt. |
| [x] | Sjekk at status fortsatt er SaldoPilot Pro. |

Forventet resultat:

- StoreKit fullfører kjøpet.
- Appen oppdaterer Pro-status.
- Pro-status overlever app-restart.

## Test 3 - Restore purchases

| Ferdig | Kontrollpunkt |
|---|---|
| [x] | Installer appen på en annen enhet med samme Apple ID/sandbox-bruker. |
| [x] | Åpne Innstillinger > SaldoPilot Pro. |
| [x] | Trykk Gjenopprett kjøp / Restore purchases. |
| [x] | Sjekk at status blir SaldoPilot Pro. |

Forventet resultat:

- Non-consumable kjøp gjenopprettes.
- Brukeren trenger ikke kjøpe på nytt.

## Test 4 - Ingen kjøp funnet

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Test med en bruker som ikke har kjøpt Pro. |
| [ ] | Trykk Restore purchases. |
| [ ] | Sjekk at appen viser at ingen Pro-kjøp ble funnet. |
| [ ] | Sjekk at appen fortsatt fungerer som gratisapp. |

## Hvis produktet ikke vises

Sjekk dette først:

| Punkt | Hva du sjekker |
|---|---|
| Product ID | Må matche `com.terjemoe.SaldoPilot.pro` nøyaktig. |
| IAP-status | Produktet må være opprettet og lagret i App Store Connect. |
| Status | Hvis produktet står som `Prepare for Submission`, er det ikke klart for TestFlight-kjøp ennå. |
| Availability | Trykk `Set Up Availability` og velg land/regioner før ny test. |
| Build | TestFlight-builden må inneholde StoreKit-koden. |
| Tilknytning | App Store Connect kan kreve at IAP legges til versjonen. |
| Apple behandling | Nye produkter kan bruke litt tid før de vises i TestFlight/App Store Connect. |

Første non-consumable in-app purchase må normalt sendes inn sammen med en ny appversjon. Når metadata og availability er ferdig, bruk `Add for Review` på IAP-produktet og koble det til riktig appversjon hvis App Store Connect ber om det.

## Før funksjoner låses

Ikke lås funksjoner bak Pro før dette er bekreftet:

| Ferdig | Krav |
|---|---|
| [x] | Kjøp fungerer. |
| [x] | Restore fungerer. |
| [x] | Appen viser riktig status etter restart. |
| [x] | Appen viser riktig status på en annen enhet. |
| [x] | Gratisappen fungerer fortsatt uten kjøp. |

## Foreløpig beslutning

Kjøp og restore er bekreftet. Neste beslutning er hvilke funksjoner som skal kreve Pro, og om første Pro-låsing skal vente til Budsjett/Prognose er implementert.
