# Tickets — nombre d'exemplaires

Choisir, au moment d'imprimer, combien d'exemplaires d'un ticket sortir, puis
les sortir tous. S'applique au **ticket de perception** et au **ticket de vente
boutique**, qui passent par le même sélecteur d'imprimante.

## Décisions (2026-09-25)

| # | Décision |
|---|---|
| D1 | Le compteur vit dans le **sélecteur d'imprimante thermique** (`thermal_printer_picker.dart`), pas dans l'aperçu : ce dialogue est redemandé à chaque ticket et ne concerne que la thermique, et la visionneuse commune aux dix sorties papier n'est pas touchée. |
| D2 | Les n exemplaires partent **en un seul envoi** : le canal natif préfixe chaque envoi d'un `LF`. C'est le port qui assemble (`EscPosTicketRenderer.joinCopies`), chaque exemplaire garde son `ESC @` et son avance, une ligne pointillée ASCII les sépare dans le blanc. |
| D3 | Exemplaires **strictement identiques** — aucune mention « original » / « copie » en V1. |
| D4 | Bornes 1 → 5 (`TicketCopies`), appliquées par le compteur **et** par le port. |
| D5 | La boutique prend la même fonctionnalité, sans rien à brancher. |
| D6 | Le défaut sera fixé **par école** → évolution back (lot 2). D'ici là : 1. |

## Lot 1 — mécanique front ✅

- `TicketCopies` (domaine) : bornes et défaut.
- `ThermalPrinterPort.printBytes(…, copies)` : le port répète le ticket en un
  seul flux.
- 🔴 **Délai d'écriture proportionnel** : `ThermalPrinterAdapter` multiplie son
  budget d'écriture (20 s par exemplaire) par le nombre d'exemplaires. Sous un
  budget fixe, un envoi long était déclaré « injoignable » pendant que le papier
  sortait, et le PDF de secours partait par-dessus : tickets en double.
- Sélecteur : compteur `(−) n (+)`, parti du défaut de l'appelant, jamais
  mémorisé.
- Repli PDF : `ThermalTicketFailed.copies` porte le nombre choisi (`null` si
  l'échec précède le choix ⇒ défaut de l'appelant) ; `PdfTicketRenderer`
  compose un exemplaire par page/feuille.
- Tests : assemblage ESC/POS, délai proportionnel (avec contre-épreuve),
  bornes du port, compteur, repli PDF (nombre choisi / défaut), boutique.

### ⚠️ Reste à faire sur le lot 1

- **Validation au banc `/dev/ticket-print` sur une vraie NT-8003DD** : 3 et 5
  exemplaires, **avec logo**. À vérifier : pas de coupure en cours d'écriture
  (tampon de l'imprimante), pointillé bien dans le blanc, budget de 20 s par
  exemplaire suffisant.

## Lot 2 — défaut par école ✅ front, 🔴 inerte jusqu'au back

Livré côté front le 2026-09-25, **sans effet tant que le back ne sert pas le
champ** : `null` ⇒ un exemplaire, exactement comme avant.

- Palier tenant **v53** : `ref_school.ticket_copies INTEGER` (colonne gardée,
  aucune reprise — le référentiel est renvoyé en entier à chaque pull).
- Pull : `RefSchoolDto.ticketCopies` (lu comme `num`), `SchoolRow`, entité
  `School`.
- `ResolveTicketCopiesUseCase` : le réglage de l'école de la session, borné,
  ou 1 — **ne rend jamais d'échec**, un défaut illisible ne bloque pas un
  ticket. Branché sur les deux flux (perception et boutique), y compris le
  repli PDF quand l'échec précède le compteur.
- Configuration ▸ Identité de l'école : « Exemplaires par ticket », liste 1→5,
  qui montre « 1 (par défaut) » tant que rien n'est choisi.
- Écriture : `SchoolIdentityModel.ticketCopies`, `null` quand rien n'est choisi.

### Ce que le front attend du back

📄 Page « Tickets — nombre d'exemplaires par école » (Claude Docs,
`https://claude.ai/artifact/LDktsqVACT1FvRUzBuQuXx`).

Un entier facultatif `ticketCopies` (1 → 5), sur le modèle de `tillPhone`
(V137) :

1. **Écriture** — `SchoolDto` (`PUT /api/v1/schools/{id}`) : absent **ou
   `null`** ⇒ le serveur conserve la valeur enregistrée (même règle que
   `tillPhone`). Revenir au comportement d'avant = enregistrer 1. Hors
   bornes ⇒ 400.
2. **Lecture hors ligne** — `ReferentialBundle.school`
   (`GET /api/v1/sync/referential`) : `ticketCopies`, `nullable`.

Question ouverte : un seul défaut pour les deux tickets, ou deux champs ? Le
front est parti sur **un seul** (`ticketCopies`).

⚠️ Comme `tillPhone`, le réglage **ne se vide pas** : l'écran n'offre que 1→5,
jamais « aucun ».
