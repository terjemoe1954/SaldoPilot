# SaldoPilot App Store Metadata

Sist oppdatert: 2026-10-18

Dette dokumentet er et arbeidsutkast for App Store Connect. Kopier tekstene inn i riktig språk/locale ved behov.

## App Name

SaldoPilot

## Primary Category

Finance

## Secondary Category

Productivity

## Subtitle - Norwegian

Budsjett, regninger og saldo

## Subtitle - English

Budget, bills & cash flow

## Promotional Text - Norwegian

Se hva du faktisk har igjen. Planlegg budsjett, følg regninger og inntekter, og få forståelig statistikk – uten bankkobling.

## Promotional Text - English

See what you actually have left. Plan budgets, track bills and income, and understand your spending – without connecting a bank account.

## Description - Norwegian

Se hva du faktisk har igjen – uten å koble til banken.

SaldoPilot samler budsjett, inntekter, utgifter og kommende betalinger i en ryddig oversikt. Registrer regninger, lønn, refusjoner og andre poster manuelt, og behold kontrollen over egne økonomidata.

Registreringen går raskt: skriv en beskrivelse, få et kategoriforslag basert på tydelige nøkkelord og tidligere poster, og velg selv før du lagrer. Gjentakende poster kan opprette neste forekomst automatisk når en betaling eller inntekt registreres.

Viktige funksjoner:

- Oversikt over inntekter, utgifter, netto og tilgjengelig saldo
- Månedsbudsjett per kategori med forventet og oppnådd inntekt
- Registrering av betalte regninger og mottatt lønn
- Forslag til kategori mens du skriver
- Gjentakende poster med intervall
- Filter, søk og sortering av poster
- Statistikk, grafer og månedsvis sammenligning
- Egne kategorier og støtte for blant annet refusjon og sparing
- Varsler for forfall og ventende inntekter
- Backup, gjenoppretting og eksport til JSON, CSV eller PDF
- Norsk, engelsk og thai språk
- Lokale innsikter basert på dataene du registrerer

SaldoPilot er laget for deg som ønsker en enkel og ryddig måte å se hva som skal betales, hva som er mottatt, og hva som kommer neste gang.

SaldoPilot er ikke en bank, kobler ikke til bankkontoer, gjennomfører ikke betalinger og gir ikke økonomisk rådgivning. AI-oppsummeringer er kun forslag og forklaringer basert på data du selv legger inn.

## Description - English

See what you actually have left – without connecting your bank.

SaldoPilot brings budgets, income, expenses, and upcoming payments into one clear overview. Add bills, salary, reimbursements, and other transactions manually while keeping control of your financial data.

Registration is quick: enter a description, get a category suggestion based on clear keywords and previous entries, and make the final choice yourself. Recurring transactions can automatically create the next occurrence when a payment or income is registered.

Key features:

- Overview of income, expenses, net cash flow, and available balance
- Monthly category budgets with expected and achieved income
- Register paid bills and received income
- Category suggestions as you type
- Recurring transactions with flexible intervals
- Search, filters, and sorting
- Statistics, charts, and monthly comparisons
- Custom categories, reimbursements, and savings support
- Due-date and pending-income reminders
- Backup, restore, and export to JSON, CSV, or PDF
- Norwegian, English, and Thai language support
- Local insights based on the data you enter

SaldoPilot is for people who want a simple way to understand what needs to be paid, what has been received, and what comes next.

SaldoPilot is not a bank, does not connect to bank accounts, does not process payments, and does not provide financial advice. AI-style summaries are informational suggestions based only on data you enter.

## Keywords - Norwegian

forbruk,økonomiplan,betalingsplan,faktura,sparekonto,kontantstrøm,månedsbudsjett,privatøkonomi

## Keywords - English

spending,money,planner,invoice,due,date,tracker,savings,personal,monthly,reimbursement,household

Nøkkelordene utfyller ordene i appnavn og undertittel i stedet for å gjenta dem. Begge feltene er innenfor App Store Connect-grensen på 100 tegn.

## What's New - Norwegian

SaldoPilot har fått en enklere og mer konsekvent kategorioversikt, raskere registrering med kategoriforslag og tydeligere budsjett og statistikk. Refusjoner kan nå følges som inntekt, og backup og databehandling er gjort mer robust.

Vi har også forbedret tilgjengelighet, språk og den visuelle presentasjonen i hele appen.

## What's New - English

SaldoPilot now has a simpler, more consistent category overview, faster entry with category suggestions, and clearer budgets and statistics. Refunds can now be tracked as income, while backup and data handling are more robust.

We have also improved accessibility, localization, and visual presentation throughout the app.

## Suggested Screenshot Texts - Norwegian

1. Se hva du faktisk har igjen
2. Få kontroll på månedens budsjett
3. Registrer raskt og enkelt
4. Følg regninger, lønn og refusjoner
5. Forstå hvor pengene går
6. Dine data. Din private iCloud.

## Suggested Screenshot Texts - English

1. See what you actually have left
2. Stay on top of your monthly budget
3. Register quickly and easily
4. Track bills, salary, and refunds
5. Understand where your money goes
6. Your data. Your private iCloud.

## App Review Notes

SaldoPilot does not require login and does not connect to banks. It is a personal finance planning tool for manually registered income and expenses.

Suggested test flow:

1. Create an expense due today.
2. Create an income transaction.
3. Mark the expense as paid.
4. Mark the income as received.
5. Create a recurring monthly transaction and mark it paid or received to verify that the next transaction is created automatically.
6. Enable local notifications in Settings to test due date reminders.
7. Export a JSON backup from Settings > Backup and export.

AI-style summaries and questions run locally in the current app version. Transaction data is not sent to an external AI service.

The app stores user-entered data with SwiftData and may use the user's private iCloud/CloudKit database when iCloud is enabled for the app.

## What To Test - TestFlight

Please test creating income and expense transactions, marking them as paid or received, recurring transactions, filters, statistics, backup/export, import, language selection, and local notifications.
