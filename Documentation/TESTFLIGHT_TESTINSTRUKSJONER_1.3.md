# SaldoPilot 1.3 – TestFlight-testinstruksjoner

## Før du begynner

1. Lag en ny JSON-backup fra **Innstillinger → Backup og eksport** og oppbevar den urørt.
2. Kontroller noen kjente poster og summer før oppdateringen.
3. Stopp dersom det oransje testbanneret vises eller vanlige data mangler.
4. Ikke slett alle data, importer en backup eller fremprovoser konflikter med viktige poster.
5. Bruk anonymiserte testnavn og små testbeløp når en ny post må opprettes.

## Betaling og gjentakelse

1. Opprett en liten månedlig testutgift med framtidig forfallsdato.
2. Åpne posten og registrer den som betalt med riktig dato.
3. Kontroller at den opprinnelige posten står som **Betalt**.
4. Kontroller at neste forekomst er opprettet som **Venter**, uten betalingsdato og med riktig neste forfallsdato.
5. Hvis beløpet er større enn tilgjengelig beløp, kontroller at appen foreslår å beholde posten som ventende.

## Søk, synk og rapport

1. Søk etter testpostens navn, notat og kategori, og prøv periode- og statusfiltrene.
2. Kontroller synk av bare den anonymiserte testposten mellom iPhone og iPad uten duplikat.
3. Opprett en PDF-rapport og sammenlign antall og totaler med kjente poster.
4. Kontroller første og siste PDF-side, lagring/deling og utskriftsdialog.

## Backup og feilrapportering

- JSON er formatet for full gjenoppretting; ikke importer bare for å teste.
- Noter appversjon/build, enhet, iOS-versjon, tidspunkt og forventet resultat ved feil.
- Ikke legg økonomiske detaljer i offentlige feilrapporter.

## Kjente avgrensninger

- Svært stor CSV/PDF-eksport kan midlertidig gjøre grensesnittet mindre responsivt.
- Faktisk levering av lokale varsler ble ikke kjørt i det isolerte testoppsettet, fordi testmodus deaktiverer varsler.
