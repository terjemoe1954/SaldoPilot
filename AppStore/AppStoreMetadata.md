# SaldoPilot App Store Metadata

Sist oppdatert: 2026-09-18

Dette dokumentet er et arbeidsutkast for App Store Connect. Kopier tekstene inn i riktig språk/locale ved behov.

## App Name

SaldoPilot

## Primary Category

Finance

## Secondary Category

Productivity

## Subtitle - Norwegian

Kontroll på inntekt og utgift

## Subtitle - English

Track income and bills

## Promotional Text - Norwegian

Planlegg faste inntekter og utgifter, følg forfall, registrer betalinger og få bedre oversikt over måneden.

## Promotional Text - English

Plan recurring income and expenses, track due dates, register payments, and stay in control of your month.

## Description - Norwegian

SaldoPilot hjelper deg å holde oversikt over inntekter, utgifter, regninger, lønn og faste poster.

Legg inn regninger, lønn, pensjon eller andre inntekter med forfallsdato og kategori. Når en regning er betalt eller en inntekt er mottatt, registrerer du datoen. Har posten gjentakelse, oppretter SaldoPilot neste post automatisk.

Viktige funksjoner:

- Oversikt over inntekter, utgifter og saldo
- Registrering av betalte regninger og mottatt lønn
- Gjentakende poster med intervall
- Filter og sortering av poster
- Statistikk per kategori
- Varsler for forfall og ventende inntekter
- Backup og eksport til JSON eller CSV
- Norsk, engelsk og thai språk
- Lokal AI-oppsummering basert på data du registrerer

SaldoPilot er laget for deg som ønsker en enkel og ryddig måte å se hva som skal betales, hva som er mottatt, og hva som kommer neste gang.

SaldoPilot er ikke en bank, kobler ikke til bankkontoer, gjennomfører ikke betalinger og gir ikke økonomisk rådgivning. AI-oppsummeringer er kun forslag og forklaringer basert på data du selv legger inn.

## Description - English

SaldoPilot helps you keep track of income, expenses, bills, salary, and recurring transactions.

Add bills, salary, pension, or other income with due dates and categories. When a bill is paid or income is received, register the date. If the transaction repeats, SaldoPilot automatically creates the next one.

Key features:

- Overview of income, expenses, and balance
- Register paid bills and received income
- Recurring transactions with intervals
- Filters and sorting
- Statistics by category
- Due date and pending income notifications
- Backup and export to JSON or CSV
- Norwegian, English, and Thai language support
- Local AI-style summaries based on the data you enter

SaldoPilot is built for people who want a simple, clear way to see what needs to be paid, what has been received, and what comes next.

SaldoPilot is not a bank, does not connect to bank accounts, does not process payments, and does not provide financial advice. AI-style summaries are informational suggestions based only on data you enter.

## Keywords - Norwegian

budsjett,regninger,forfall,inntekt,utgift,økonomi,lønn,pensjon,betaling,oversikt

## Keywords - English

budget,bills,due,income,expense,finance,salary,pension,payment,overview

## Suggested Screenshot Texts - Norwegian

1. Full oversikt over inntekt og utgifter
2. Se regninger, lønn og faste poster
3. Marker regninger som betalt
4. Registrer lønn som mottatt
5. Neste post opprettes automatisk
6. Forstå hvor pengene går

## Suggested Screenshot Texts - English

1. See income and expenses clearly
2. Track bills, salary, and recurring items
3. Mark bills as paid
4. Register salary as received
5. Automatically create the next item
6. Understand where your money goes

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

