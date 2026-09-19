# SaldoPilot Pro - testplan for kjøp og restore

Sist oppdatert: 2026-09-19

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
| [ ] | Appen er fortsatt gratis i Pricing and Availability. |
| [ ] | SaldoPilot Pro finnes under In-App Purchases i App Store Connect. |
| [ ] | Product ID er nøyaktig `com.terjemoe.SaldoPilot.pro`. |
| [ ] | Produktet er non-consumable. |
| [ ] | Pris er satt til 39 kr eller nærmeste tilsvarende Apple price tier. |
| [ ] | Produktet er lagt til versjonen/builden hvis App Store Connect ber om det. |
| [ ] | Ny TestFlight-build er lastet opp etter StoreKit-koden. |

## Test 1 - Produkt vises

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Installer appen fra TestFlight. |
| [ ] | Åpne Innstillinger. |
| [ ] | Åpne SaldoPilot Pro. |
| [ ] | Sjekk at nåværende plan viser Gratis. |
| [ ] | Sjekk at pris vises. |
| [ ] | Sjekk at kjøpsknappen vises. |

Forventet resultat:

- Produktet lastes fra App Store.
- Pris vises i lokal valuta.
- Ingen funksjoner er låst ennå.

## Test 2 - Kjøp Pro

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Trykk Kjøp Pro. |
| [ ] | Fullfør sandbox/TestFlight-kjøpet. |
| [ ] | Sjekk at status endres til SaldoPilot Pro. |
| [ ] | Lukk og åpne appen på nytt. |
| [ ] | Sjekk at status fortsatt er SaldoPilot Pro. |

Forventet resultat:

- StoreKit fullfører kjøpet.
- Appen oppdaterer Pro-status.
- Pro-status overlever app-restart.

## Test 3 - Restore purchases

| Ferdig | Kontrollpunkt |
|---|---|
| [ ] | Installer appen på en annen enhet med samme Apple ID/sandbox-bruker. |
| [ ] | Åpne Innstillinger > SaldoPilot Pro. |
| [ ] | Trykk Gjenopprett kjøp / Restore purchases. |
| [ ] | Sjekk at status blir SaldoPilot Pro. |

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
| Build | TestFlight-builden må inneholde StoreKit-koden. |
| Tilknytning | App Store Connect kan kreve at IAP legges til versjonen. |
| Apple behandling | Nye produkter kan bruke litt tid før de vises i TestFlight/App Store Connect. |

## Før funksjoner låses

Ikke lås funksjoner bak Pro før dette er bekreftet:

| Ferdig | Krav |
|---|---|
| [ ] | Kjøp fungerer i TestFlight. |
| [ ] | Restore fungerer i TestFlight. |
| [ ] | Appen viser riktig status etter restart. |
| [ ] | Appen viser riktig status på en annen enhet. |
| [ ] | Gratisappen fungerer fortsatt uten kjøp. |

## Foreløpig beslutning

Funksjonslåsing utsettes. Først skal kjøp og restore være stabilt. Etterpå kan vi bestemme hvilke funksjoner som skal kreve Pro.
