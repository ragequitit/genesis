# chriswhippit.com

Statisk sida, inga byggsteg. Filerna ska ligga i **roten** av det repo som har
domänen www.chriswhippit.com, inte i en undermapp — annars stämmer inte
canonical-URL:erna och sitemapen.

## Så här läggs den upp

1. Skapa ett eget repo, t.ex. `chriswhippit`.
2. Lägg innehållet i den här mappen direkt i repots rot.
3. Settings → Pages → Source: main / root.
4. Settings → Pages → Custom domain: `www.chriswhippit.com` (CNAME-filen ligger redan här).
5. Hos domänleverantören: CNAME-post för `www` → `<ditt-användarnamn>.github.io`.

Ligger sidan kvar under `genesis/chriswhippit/` fungerar allt utom att
adresserna blir `/chriswhippit/...` medan canonical pekar på `/`. Google följer
canonical, så indexeringen blir fel. Flytta hellre.

## Filer

- `index.html` — startsidan
- `setup/`, `schema/`, `faq/`, `nedladdningar/`, `shop/` — en mapp per sida, egen titel och beskrivning
- `admin/` — redigeringsgränssnittet, noindex. Lösenord: whippit
- `content.json` — allt redigerbart innehåll. Skrivs av admin via GitHubs API
- `media/` — bilder som lagts in via admin
- `support.js`, `styles.css`, `assets/` — delas av alla sidor
- `robots.txt`, `sitemap.xml`, `site.webmanifest`, `CNAME`

## Efter uppladdning

- Google Search Console: lägg till egenskapen `https://www.chriswhippit.com`, verifiera
  med DNS-posten, och skicka in `https://www.chriswhippit.com/sitemap.xml`.
- YouTube-API-nyckeln måste tillåta `www.chriswhippit.com/*` i sin referrer-lista.
