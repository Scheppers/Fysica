# Fysica Escape — installatie

## 1. GitHub en Netlify
Maak een nieuwe, liefst private, GitHub-repository voor Fysica. Upload **de inhoud van deze map** naar de hoofdmap van die repository (`index.html` moet in de root staan). Maak een nieuwe Netlify-site met die repository. Build command: **leeg**. Publish directory: **.** (projectroot). De site is statisch.

## 2. Supabase: hetzelfde project als Chemie
`config.js` bevat dezelfde **publieke** Supabase-URL en publishable key als je bestaande Chemie-site. Dit zijn geen geheime sleutels. Gebruik nooit een `service_role`-sleutel in de browser.

Maak eerst een back-up en voer `supabase/01_fysica_basis.sql` uit in de SQL Editor van **het bestaande Supabase-project**. De migratie maakt afzonderlijke tabellen `physics_*` en RPC-functies aan. Ze past de bestaande Chemie-tabellen niet aan. Je bestaande gebruikers, skins, LabCoins en XP blijven in `profiles` staan. In deze eerste Fysica-versie worden geen munten uitgegeven of verdiend.

## 3. Login
Log in met **exact dezelfde gebruikersnaam en hetzelfde wachtwoord** als bij Chemie. Leerkrachten gebruiken hun bestaande teacher-account (`profiles.role = 'teacher'`). Accounts worden **niet** aangemaakt via deze site. Twee Netlify-domeinen delen niet automatisch een aanmeldsessie: een leerling moet mogelijk op beide sites apart inloggen.

## 4. Vragen beheren
Na aanmelding als leerkracht verschijnt onderaan **Leerkrachtenbeheer · Fysica**. Kies tijdperk en puzzel, stel naam/actief/aantal vragen in en voeg vragen toe. Per puzzel en moeilijkheid zijn minstens 3, 5 of 10 actieve vragen nodig volgens de instelling. Er worden **geen chemievragen gekopieerd**. De nieuwe vragen staan in `public.physics_questions`, afzonderlijk van `public.quiz_questions`.

## 5. Testen
1. Log in met je leerkrachtaccount; maak 3 basisvragen aan bij Klassieke mechanica → Krachten.
2. Log in als testleerling en start de puzzel. Controleer dat vragen geen correcte antwoorden vooraf tonen.
3. Beantwoord drie vragen foutloos en controleer de voortgang links.
4. Herlaad de pagina tijdens een poging om hervatten te testen.
5. Controleer de skin en LabCoins van dezelfde leerling in Chemie en Fysica.

## Grenzen van deze eerste versie
- Vier tijdperken en vier puzzelplaatsen per tijdperk; de leerkracht kan puzzels activeren/verbergen.
- Basis, gemiddeld en moeilijk, met één antwoordpoging per vraag.
- Bonusspellen zijn lokale oefenspellen, **zonder** serverbeloning, leaderboard of munten.
- Geen raketbouw, inventaris, synthese, kluis of kaartenarena.
- Geen gedeelde sessie tussen domeinen, geen eigen leerlingregistratie.
- Geen nieuwe XP of LabCoins voor Fysica; zo vermijden we ongewenste wijzigingen aan de bestaande Chemie-economie.
- Er zijn nog geen fysicavragen ingevuld: de leerkracht bouwt de vragenbank op.
- De migratie is statisch nagekeken, maar niet op jouw live Supabase-project uitgevoerd.

## Bestandsindeling
- `index.html`, `style.css`, `app.js`, `config.js`: de volledige website.
- `assets/backgrounds/`: vier Fysica-WebP-labo's (inclusief `U = I · R` in het tweede labo).
- `assets/avatars/`: de bestaande Chemie-skins als afbeeldingen.
- `supabase/01_fysica_basis.sql`: database-uitbreiding.


## Update: zes puzzelplaatsen en nieuwe tijdperkopmaak

- Bovenaan staat nu **Een fysische tijdreis**. De ondertitel van het tijdperk staat onder de tijdperktitel, niet op de achtergrond.
- Per leerjaar bestaan zes puzzelplaatsen. De eerste drie zijn standaard actief, plaatsen vier tot en met zes zijn standaard verborgen. Een leerkracht kan de namen, zichtbaarheid en aantallen vragen instellen.
- De rechterzijbalk toont een uitklapbaar bonusspellenmenu. Een bonusspel opent in het centrale puzzelvenster, met een terugknop naar het labo.
- De drie overige achtergronden zijn iets scherper geëxporteerd; achtergrond twee is ongewijzigd.

**Als de basis-SQL al op Supabase is uitgevoerd:** voer uitsluitend `supabase/02_zes_puzzelplaatsen_en_interface.sql` uit. Voer `01_fysica_basis.sql` niet opnieuw uit.

**Bij een nieuwe installatie:** voer alleen `supabase/01_fysica_basis.sql` uit; daarin zijn zes puzzelplaatsen meteen voorzien.

**Opgelet:** er zijn nog geen fysicavragen ingevuld. De drie actieve puzzelplaatsen zijn onderwerpen/knoppen, geen kant-en-klare vragenbanken. Voeg via het leerkrachtenpaneel minstens drie actieve basisvragen per puzzel toe.
