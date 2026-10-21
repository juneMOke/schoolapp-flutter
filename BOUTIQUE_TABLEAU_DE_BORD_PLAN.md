# BOUTIQUE_TABLEAU_DE_BORD_PLAN.md — date de vente & tableau de bord

> **Statut :** plan émis le 2026-10-21 · BQ-19 codé (branche
> `feat/boutique-sale-date`, non commité).
>
> | Lot | Objet | Dépend du back |
> |---|---|---|
> | BQ-19 ✅ | Date de la vente au panier | non (R10 améliore le RV, ne bloque pas) |
> | BQ-20 | Données du tableau de bord (API, modèles, dépôt) | **R8, R9** |
> | BQ-21 | Écran : en-tête, période, tuiles, encart provisoires | R8 |
> | BQ-22 | Analyses : recettes dans le temps, familles, top articles | R8 |
> | BQ-23 | Élèves concernés | R9 |
> | BQ-24 | Dernières ventes (local) → fiche de vente existante | non |
> | BQ-25 | États : squelettes, vides, erreurs 4 types, hors-ligne | R8 |
> | BQ-26 | Navigation : Historique remplacé par Tableau de bord | non (en dernier) |
> | BQ-27 | Revue adversariale | — |
>
> **Origine :** `Boutique - Spec module & tableau de bord (standalone).html`
> (2026-10-21). **Demandes back :** `BOUTIQUE_DEMANDES_BACK.md`, deuxième vague
> (R8 → R11). **Plan parent :** `BOUTIQUE_PLAN.md` (BQ-0 → BQ-18, livrés).

---

## 1. Ce que la spec suppose et qui est faux ici

La spec est écrite contre une maquette, comme la précédente. On garde ses
questions, son anatomie et ses états ; on ne garde pas son socle.

| Spec | Réalité du projet | Décision |
|---|---|---|
| Riverpod, freezed, Hive, `AsyncValue` | flutter_bloc, Equatable, SQLCipher, `Either` | patrons du projet |
| `GET /boutique/stats`, `/beneficiaires`, `/ventes`, `/ventes/{n}/recu` | aucune n'existe | **routes serveur** pour stats et bénéficiaires, contrat réécrit (R8, R9) ; dernières ventes et reçu **en local** |
| Mono-devise USD, montants décimaux | USD **et** CDF ; centimes ; jamais additionnés | recettes, panier moyen, série, familles **par devise** |
| Menu à créer, redirection `/finances/boutique` | menu propre déjà livré (BQ-11) : Achats / Historique | Historique → Tableau de bord ; pas de redirection |
| Champ `dateVente` distinct de `encaisseLe` | `soldAt` = heure **métier** côté serveur, la caisse du jour la compte déjà | la date choisie **est** `soldAt` ; aucun champ neuf |
| « La date figurera sur le reçu » | le RV imprime la date serveur, délibérément | ticket thermique : oui ; RV : demande R10 |
| Antidatage : caissier J-1, promoteur sans limite | aucune permission ne le porte, le serveur ne borne que le futur | **année scolaire, pour tous** (décision du 2026-10-21) |
| `BqRecuModal` reconstruit | `BoutiqueSaleDetailPage` : ticket + RV + réclamation | la fiche existante |
| Couleurs en hexadécimal | règle 5 : `AppColors` | `AppColors.terreCuite`, `boutique_family_style.dart` |

**Décisions du 2026-10-21 :** tableau de bord sur routes serveur (contrat à nous) ·
liste complète des ventes **supprimée** avec l'historique · antidatage dans
l'année scolaire · demande au back pour la date sur le RV.

---

## 2. BQ-19 — Date de la vente au panier

**Le geste.** En tête du panier, au-dessus du bloc payeur : « Date de la vente »,
aujourd'hui par défaut, `showDatePicker` borné de **l'ouverture de l'année
scolaire active** à **aujourd'hui**.

- **Domaine.** `BoutiqueCart.saleDate` (jour, sans heure ; `null` = aujourd'hui).
  « Vide » n'existe pas : `null` vaut aujourd'hui. **Pas de `CartBlocker`** pour
  l'avenir : le sélecteur ne le propose pas (`lastDate` = aujourd'hui), seule
  une horloge qui recule peut le produire — le dépôt refuse alors d'écrire
  (`ValidationFailure`), avant toute ligne en base.
- **`soldAt` = jour choisi + heure réelle d'encaissement**, en heure locale puis
  UTC. Aujourd'hui ⇒ `now` exactement, comportement inchangé. Le dépôt reçoit
  une horloge murale injectable (`wallClock`), distincte de l'horloge technique
  en millisecondes que les tests figent à 1970.
- **Antidatée** ⇒ note ambre (`clock`) sous le champ : « Vente antidatée — la
  date figurera sur le ticket ». Dans le récapitulatif de confirmation : ligne
  « Date ».
- **Ticket thermique** : lit déjà `soldAt` — rien à faire, à prouver par test.
- **Remise à zéro** : « Nouvelle vente » et « Vider le panier » reposent
  aujourd'hui.
- ⚠️ **Le jour qui tourne.** Un panier ouvert à 23 h 58 et encaissé à 0 h 01 :
  un `saleDate` explicite à « aujourd'hui » de la veille devient antidaté sans
  que personne ne l'ait voulu. ⇒ `null` = aujourd'hui **au moment d'encaisser** ;
  seul un choix explicite fige un jour.
- ⚠️ **Taux de change.** Le règlement se résolvait sur `soldAt` ; il se résout
  désormais sur l'**heure réelle d'encaissement** — sinon une vente antidatée
  prendrait l'ancien taux pour des francs entrés aujourd'hui (prouvé par
  mutation). Le bundle ne porte de toute façon aucun point antérieur au taux en
  vigueur.
- ⚠️ Année scolaire précédente : le sélecteur ne descend pas sous l'ouverture
  de l'année **active** — une vente de l'an dernier n'est pas une vente du
  panier courant.

## 3. BQ-20 → BQ-25 — Le tableau de bord

**Question unique :** « Combien la boutique a-t-elle vendu, quoi, et à quels
élèves ? » Un flux, jamais un stock ni une dette.

- **Données (BQ-20).** `BoutiqueDashboardApi` (Retrofit) sur R8/R9,
  `BoutiqueStatsModel` → `BoutiqueStats` dans le dépôt, `Either` partout.
  `DashboardPeriod { today, sevenDays, thirtyDays }` : **fenêtres glissantes**
  qui finissent aujourd'hui, converties en `from`/`to` par le client. Période
  mémorisée par utilisateur. **Ne pas confondre** avec `SalesHistoryPeriod`
  (calendaire), qui disparaît avec l'historique.
- **Tickets provisoires.** Les ventes locales `PENDING_SYNC` / en échec de la
  fenêtre sont **ajoutées** aux agrégats serveur (le serveur ne les connaît
  pas), et annoncées par l'encart ambre. ⚠️ Fenêtre de double compte : une vente
  poussée dont l'ACK s'est perdu est comptée par le serveur ET encore locale
  jusqu'au rejeu (200). Rare, borné, documenté — pas de parade en V1.
- **Écran (BQ-21, BQ-22).** Une colonne : en-tête + période + « Ouvrir la
  caisse » · encart provisoires · tuiles (Recettes pleine, Ventes, Panier
  moyen, Articles vendus, delta masqué si précédent = 0) · recettes dans le
  temps (heure par heure / jour par jour ; dimanche retiré **s'il est vide**) ·
  par famille · top 5 par quantité, chaque ligne filtre la liste des élèves.
  Recettes et panier moyen : **une valeur par devise**, empilées dans la tuile.
- **Élèves concernés (BQ-23).** Filtres nom (debounce 300 ms, côté serveur),
  article, classe ; 8 lignes puis « Voir les n élèves » ; filtres conservés au
  changement de période ; mention des achats sans élève (`walkInLineCount`).
  Avatar = photo locale de l'élève, repli initiales.
- **Dernières ventes (BQ-24).** Les 6 dernières de la période, **lues en local**
  (provisoires compris, pastille ambre), chaque ligne ouvre
  `BoutiqueSaleDetailPage`. Lien « Nouvelle vente → » vers la caisse.
- **États (BQ-25).** Règle 10 : `EteeloListSkeleton`/`EteeloSkeletonBox`,
  `EteeloEmptyResult` (aucune vente / aucun élève), `EteeloErrorResult` via
  `BoutiqueResultsErrorState` (surface `dashboard`, 4 types, 403 sans
  « Réessayer »). Changement de période : valeurs à 50 % d'opacité, pas de
  squelette plein écran. **Hors-ligne :** dernière réponse mise en cache par
  fenêtre (table locale, schéma +1), datée dans l'en-tête ; sans cache ⇒ erreur
  réseau, l'encart provisoires restant visible.

## 4. BQ-26 — Navigation, en dernier

`boutique-historique` → `boutique-tableau-de-bord`, premier sous-menu ; Achats
devient « Caisse ». Suppression de `BoutiqueHistoryPage`, de son bloc, de son
DAO, de son cas d'usage et de `SalesHistoryPeriod` — **après** que le tableau de
bord est prêt, pour ne jamais livrer un module sans lecture. Carte d'accueil et
`boutique_module_placement_test` à mettre à jour.

## 5. Points ouverts

- Périmètre caissier (toutes les ventes ou les siennes) : tranché par le serveur
  via `boutique.sale.read` ; rien côté front.
- Export de la liste des élèves (PDF/CSV) : hors V1.
- Clôture de caisse : hors V1 (voir R7/R11).
