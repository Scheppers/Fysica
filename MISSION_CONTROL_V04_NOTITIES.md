# Mission Control v0.4 — visuele update

## Nieuw
- In fase 2 toont ieder bezet missieveld de **volledige geselecteerde kaart** (illustratie, titel, vakgebied, actie, kennis, energie, zeldzaamheid en LabCoin-waarde) in plaats van een emoji. De knop 'Terug op hand' blijft werken.
- Alle 24 kaarttypes hebben nu een eigen illustratiebestand in `assets/card-art/`. Historische fysici behouden hun karakter; technologie en moderne fysica hebben een strakkere uitstraling.
- Bestaande Supabase-accounts, LabCoins, mystery-boxaankopen, kaartvernietiging, missieprogressie en drie dagelijkse pogingen blijven ongewijzigd.
- De kaart Vereenvoudigde theorie verlaagt de vereiste kennis met 2 (reeds in v0.3).

## Installatie
Vervang de fysicawebsite door deze projectmap, met behoud van je eigen Supabase-configuratie. De bestaande `03_mission_control_supabase.sql` hoeft **niet opnieuw uitgevoerd** te worden voor deze visuele update. Maak een backup en test eerst met een testaccount.

## Beveiligingsstatus
De bestaande v0.3-serverfuncties controleren aankoop, eigendom, veldlimieten en basisvereisten, maar **reconstrueren de fase-1-kaartacties niet**. Daarom is de spelengine nog niet volledig server-authoritatief: gemanipuleerde clientverzoeken kunnen de missiescore beïnvloeden. Dit pakket is een visuele/UX-update, **geen voltooide anti-cheat-migratie**. Voor productie moet de server iedere actie en kaartverplaatsing valideren of de run volledig server-side uitvoeren. Gebruik de gedeelde economie alleen onder gecontroleerde testomstandigheden totdat dat klaar is.

## Testen
1. Meld je aan met je bestaande testaccount.
2. Start een missie en ga naar fase 2.
3. Plaats kaarten en controleer dat de juiste unieke illustraties, randkleur en waarden zichtbaar zijn.
4. Haal een kaart terug op hand en plaats ze opnieuw.
5. Controleer mystery boxes en saldo op je testaccount.
