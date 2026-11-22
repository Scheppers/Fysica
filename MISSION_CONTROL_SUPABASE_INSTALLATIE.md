# Mission Control v0.3 — Supabase-integratie (installatie vereist)

## Installatie
1. Maak een back-up van je bestaande Supabase-database en test eerst in een aparte Supabase-omgeving.
2. Zorg dat de bestaande chemie-/fysica-tabellen `public.profiles` met `id` en `coins` aanwezig zijn.
3. Open Supabase Dashboard → SQL Editor en voer `03_mission_control_supabase.sql` uit. **Dit SQL-script is nog niet op jouw live database uitgevoerd.**
4. Deploy de volledige map `Fysica-main` op dezelfde origin als je bestaande fysicaomgeving. De bestanden `config.js` en de bestaande Supabase-auth worden hergebruikt.
5. Meld je aan via `index.html`, open daarna `mission-control.html`.

## Wat is gedeeld?
- LabCoins worden direct afgeschreven/bijgeschreven in `public.profiles.coins`.
- Mystery-boxopeningen en kaartvernietiging verlopen via server-side transacties.
- De speler krijgt eenmalig twaalf starterkaarten bij eerste gebruik; geen gratis testcoins.
- Missievoortgang en drie dagelijkse pogingen staan in Supabase. De daggrens is **Europe/Brussels**.
- Lokale testcollecties uit v0.2 worden bewust niet naar de echte database geïmporteerd.

## Belangrijke beperking voor live publicatie
Deze versie is een **integratie-kandidaat**, geen volledig anti-cheat-gehard productieproduct. De server controleert identiteit, saldo, kaarten, dagelijkse limieten en basisvoorwaarden, maar speelt nog niet de volledige fase-1-actielog opnieuw af. Een technisch vaardige gebruiker zou de aangeleverde actiebonussen kunnen manipuleren of de vernietigingsactie zonder de juiste gespeelde kaart kunnen aanroepen. Voor gebruik met waardevolle LabCoins en echte leerlingen moet de complete run (trekvolgorde, acties, vernietigingen, fasewissel en plaatsingen) server-side worden beheerd of gevalideerd. Publiceer niet als definitieve live-economie vóór die beveiligingsstap.

## Bekende beperkingen
- Browser herladen tijdens een run verbruikt de poging; herstel van lopende runs is nog niet geïmplementeerd.
- Er is geen oefenmodus; maximaal drie pogingen per kalenderdag.
- De kaartillustraties van deeltjesversneller, quantumtunneling, zonnecel en kernfusie zijn gemoderniseerd.
- Vereenvoudigde theorie verlaagt de vereiste kennis met **2**.
