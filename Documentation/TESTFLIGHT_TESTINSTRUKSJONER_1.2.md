# SaldoPilot 1.2 – TestFlight-testinstruksjoner

## Før du begynner

1. Lag en ny JSON-backup fra **Innstillinger → Backup og eksport** og oppbevar den urørt.
2. Kontroller noen kjente poster og summer før oppdateringen.
3. Ikke slett alle data, importer en backup eller fremprovoser konflikter med viktige poster.
4. Bruk anonymiserte testnavn og små testbeløp når en ny post må opprettes.

## Betaling og gjentakelse

1. Opprett en liten månedlig testutgift med framtidig forfallsdato.
2. Åpne posten og registrer den som betalt med riktig dato.
3. Kontroller at den opprinnelige posten står som **Betalt**.
4. Kontroller at neste forekomst er opprettet som **Venter**, uten betalingsdato og med riktig neste forfallsdato.
5. Hvis beløpet er større enn tilgjengelig beløp, kontroller at appen foreslår å beholde posten som ventende.

## Søk og filtre

1. Søk etter testpostens navn, notat og kategori.
2. Prøv **Neste 7 dager**, **Neste 30 dager**, **Betalt** og **Kommende**.
3. Kontroller at **Tilbakestill** fjerner filtrene.

## Synk mellom iPhone og iPad

1. La begge enhetene være på nett og åpne samme Apple-ID/iCloud-data.
2. Opprett eller rediger bare den anonymiserte testposten på én enhet.
3. Kontroller at samme verdi og status kommer på den andre enheten uten duplikat.
4. Start begge apper på nytt og kontroller posten igjen.
5. Ikke rediger samme viktige post samtidig på begge enhetene.

## Rapport og PDF

1. Gå til **Innstillinger → Rapporter**.
2. Velg rapporttype, måned, datotype og ønsket omfang.
3. Sammenlign antall og totaler i forhåndsvisningen med kjente poster.
4. Opprett PDF, kontroller første og siste side, og lagre den lokalt i Filer.
5. Åpne utskriftsdialogen. Skriv bare ut hvis du ønsker det.

## Backup og CSV

1. Kontroller at en ny JSON-backup kan lagres i Filer. Ikke importer den bare for å teste.
2. CSV kan åpnes i Numbers/Excel for kontroll, men JSON er formatet for full gjenoppretting.
3. Del aldri økonomiske filer til en mottaker du ikke selv har valgt.

## Rapporter feil

Noter appversjon/build, enhet, iOS-versjon, tidspunkt, skjerm og hva som var forventet. Bruk anonymiserte navn og beløp i skjermbilder og feilrapporter. Ikke legg økonomiske detaljer i offentlige GitHub-saker.

## Kjente avgrensninger

- Svært stor CSV/PDF-eksport kan midlertidig gjøre grensesnittet mindre responsivt.
- Faktisk levering av lokale varsler er ikke kjørt i det isolerte testoppsettet, fordi testmodus deaktiverer varsler.
