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

## Lot 2 — défaut par école (attend le back)

### Ce que le front attend du back

Un entier facultatif `ticketCopies` (1 → 5, `null` ⇒ le client applique 1),
sur le modèle de `tillPhone` (V137) :

1. **Écriture** — `SchoolDto` (`PUT /api/v1/schools/{id}`) : champ
   **facultatif**, l'omettre conserve la valeur déjà saisie (même exception à la
   mise à jour complète que `tillPhone`). Hors bornes ⇒ 400.
2. **Lecture hors ligne** — `ReferentialBundle.school`
   (`GET /api/v1/sync/referential`) : `ticketCopies`, `nullable`.

Question ouverte pour le back : un seul défaut pour les deux tickets, ou deux
champs (perception / vente) ? Le lot 1 accepte les deux.

### Côté front, une fois le contrat livré

- Migration tenant : colonne sur la table de l'école du référentiel. ⚠️ Le
  palier v52 est **pris par `feat/expense-validation-circuit`** (PR #59, non
  fusionnée) : prendre le prochain palier libre **au moment** du lot.
- Lecture du pull (`referential_pull_models.dart`, à côté de `tillPhone`).
- Saisie dans Configuration ▸ Identité de l'école (`school_identity_step.dart`).
- Brancher le défaut : `defaultCopies` dans `_sendTicketToPrinter`
  (`provisional_ticket_print_flow.dart`) et `initialCopies` de
  `printThermalBytes` dans `sale_ticket_print_flow.dart`.
- Le champ reste inerte tant que le back n'est pas déployé : `null` ⇒ 1.
