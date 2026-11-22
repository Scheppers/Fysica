# Mission Control — interactief prototype

Open `mission-control.html` (of gebruik de nieuwe Kaartenarena-tegel in `index.html`).

## Wat werkt
- 24 verschillende kaarttypes met domein, zeldzaamheid, actie, kennis, energie en vernietigingswaarde.
- Eén verzameling/deck, geschud bij elke run; 5 openingskaarten, 2 actiepunten.
- Kaart trekken kost 1 actiepunt; actiekaart spelen kost 1 actiepunt; gespeelde actiekaart gaat naar de aflegstapel.
- Fase 2 begint bij 0 actiepunten of vrijwillig; handkaarten plaatsen in missievelden.
- 4 missies, inclusief domeinvereisten, aanpasbare veldjes, kennis/energie, energieverdubbeling en conversie.
- Permanente vernietiging uit de collectie met LabCoins-vergoeding; zwart gat, quantumtunneling en andere speciale effecten.
- Mystery boxes met 3 kaarten, zeldzaamheidsgewichten, duplicaten en demo-economie.
- Maximaal 3 officiële pogingen per lokale kalenderdag.

## BELANGRIJK — nog niet voor productie
Dit is een **zelfstandig lokaal speelprototype**. De LabCoins, collectie, pogingen en missieprogressie worden uitsluitend opgeslagen in de `localStorage` van de browser. De initiële 500 coins zijn testgeld. Er is nog **geen** verbinding met de Supabase-accounts of gedeelde Chemie-economie, en de daglimiet is client-side en kan worden omzeild. Voor echte uitrol zijn beveiligde server-side transacties nodig voor het openen van boxes, vernietigen van kaarten, saldo en daglimieten. Geen bestaande chemietabellen of functies zijn aangepast.

## Bekende ontwerpkeuzes voor verdere test
- Bij een lege trekstapel is trekken niet mogelijk; er wordt niet automatisch opnieuw geschud.
- De actie van een kaart wordt exclusief gebruikt; de kaart kan in dezelfde run niet meer als productiekaart worden ingezet, tenzij een ander effect ze terughaalt.
- Zwart gat vernietigt kaarten uit de bekeken top drie definitief; overige kaarten komen bovenaan of onderaan het deck.
- De actie 'Vernietig' kan overgeslagen worden. De daglimiet geldt bij het starten van de poging.
- Kaartillustraties zijn nu **gestileerde pictogrammen** in een eigen collectible-cardtemplate; uitgewerkte unieke illustraties zijn een volgende stap.
- De gegenereerde steampunk-illustratie wordt gebruikt voor de nieuwe Mission Control-ingang.
