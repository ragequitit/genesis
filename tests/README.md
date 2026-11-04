# Automatiska tester för Project Genesis

Testerna startar spelet i en riktig webbläsare (Chromium) på din egen dator, med en
**låtsasserver** i stället för Supabase. Ingen inloggning, inga nycklar och inget nätverk behövs.

## Så kör du

```bash
cd tests
npm install        # bara första gången
npm test
```

Allt kör av sig självt (ca 3–4 minuter). Längst ned står hur många tester som är gröna och röda.
En färdig rapport med skärmbilder från de röda testerna öppnas med `npx playwright show-report`.

## Vad som testas

**Utan webbläsare** (läser filerna direkt):
- Versionen är exakt likadan på sina tre platser: `sn-ver`, `desc` (Inställningar → Version) och `"ver"` i `genesis-catalog`.
- Översta (nyaste) posten i `patchnotes.json` har samma version, och ingen post längre ned har högre.
- `patchnotes.json` innehåller inga HTML-taggar, och varje post har alla sina fält (ver, date, title_en, title_sv, hint_en, fun_en, fun_sv, discord, en, sv).
- Varje bildsökväg i klientens katalog (`genesis-catalog`) finns på disken.
- Varje hjälpare i `PETS` har en bild, och katalogens hjälparlista är densamma som `PETS`.

**I webbläsaren, på sju skärmar** (1920x1080, 1440x900, 1280x800, 1000x800, 820x1180, 390x844, 360x740):
- Sidan laddar utan JS-fel, utan saknade filer och utan sidledsskroll.
- Dessa fönster öppnas med sin riktiga knapp, visar testdatan och stängs med krysset – utan fel:
  inventory, vault, helpers, achievements, events, How to play, auction house, mail, map och Mission Board.

## Testdatan

Låtsasservern finns i `helpers/fake-server.mjs`. Svaren ligger i `fixtures/`:
- `fixtures/tables/<tabell>.json` – svar när spelet läser en tabell.
- `fixtures/rpc/<funktion>.json` – svar när spelet anropar en serverfunktion.
- En `.mjs`-fil räknar fram svaret (t.ex. en hjälpare av varje art, eller ett event som pågår just nu).

Saknas en fil svarar låtsasservern med tomt. Testkaraktären "Testrunner" står i The Landing i Voxholm
och har saker i väskan och valvet, tre brev, två annonser i auktionshuset, tre uppdrag och alla hjälpare.

## Bra att veta

- Testerna ändrar inget i spelet.
- Mappen `tests/` följer med när sajten publiceras (publiceringen kopierar hela repot). Den innehåller inga hemligheter.
