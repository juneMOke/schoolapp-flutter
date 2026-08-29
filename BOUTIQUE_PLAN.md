# BOUTIQUE_PLAN.md — caisse point-de-vente de l'école

> **Statut :** en cours de livraison, **révision 2** (2026-08-29).
>
> | Lot | État |
> |---|---|
> | BQ-0 · contrat, permissions, porte d'entrée | ✅ livré |
> | BQ-1 · catalogue offline (schéma v31) | ✅ livré |
> | BQ-2 · panier, domaine pur | ✅ livré |
> | BQ-3 · l'écran | ✅ livré (points d'accroche BQ-4/5/6 posés) |
> | BQ-4 · désigner un bénéficiaire | ✅ livré |
> | BQ-5 · payeur et répertoire local | ✅ livré |
> | BQ-6 · encaisser | ✅ livré |
> | BQ-7 · la preuve de paiement | ✅ livré |
> | BQ-8 · le pull des ventes | ✅ livré |
> | BQ-9 · états, a11y, l10n | ✅ livré |
> | BQ-10 · revue adversariale | ✅ livré |
>
> **Plan entièrement livré (BQ-0 → BQ-10).** Catalogue offline, panier qui
> calcule juste, bénéficiaires, répertoire de payeurs, encaissement money-grade
> par outbox, ticket thermique imprimé, barre de reçu, pull des ventes de l'autre
> guichet, et revue adversariale passée (3 mutations, 2 défauts corrigés).
>
> ⚠️ **Une dette assumée** : le mélange de devises est détecté mais non bloqué —
> voir D2, renvoyé à une branche dédiée.
>
> ⚠️ Ne jamais lancer la suite complète en arrière-plan pendant qu'on travaille :
> les `flutter test`/`analyze` concurrents la font rendre des « did not
> complete » qui ne sont pas des échecs.
>
> **Ce qui a changé depuis la révision 1 :** le back a repris **six des sept
> demandes** de `BOUTIQUE_DEMANDES_BACK.md` et y a ajouté sa propre revue
> adversariale (V98, V99, deux routes neuves). Les dix divergences de la r1 sont
> tombées à **quatre**, et deux d'entre elles ont changé de nature — dont une qui
> est devenue **plus** dangereuse pour le front. Le journal de l'alignement est au
> §3.
>
> **Origine :** `Boutique - Spec Flutter (standalone).html`, scratch IntelliJ
> `eteelo-connect/` · code back de la branche `feat/parametrage-automatique-l0`
> (travail boutique toujours **non commité**, `git status` = `A` sur ~45
> fichiers).
>
> **Ce que le module fait :** un écran, une action — encaisser une vente
> d'articles de l'école au comptant intégral en espèces, et remettre une preuve.
> Aucune dette, aucun reste, aucun lien avec le minerval.
>
> **Docs de contexte :** `BOUTIQUE_DEMANDES_BACK.md` (les demandes et leur
> statut) · `AGENTS.md` §"États partagés" · `CLAUDE.md` §règles non-négociables ·
> `openApi.yaml` du back §Boutique (routes 6331-6700, schémas 13271-13760) ·
> `FACTURATION_OFFLINE_PLAN.md` (le patron d'encaissement qu'on recopie).

---

## 1. Le fait déterminant

**Le contrat n'est plus le problème. La spec l'est restée.**

En révision 1, l'écart tenait au serveur : il servait autre chose que ce que la
spec annonçait. Cet écart a été comblé — le payeur est en trois champs, l'article
porte sa famille, le reçu porte son caissier, l'ACK porte l'identifiant du reçu,
et deux routes ont été ouvertes pour réclamer une pièce et lire les anomalies.

Ce qui reste tient en une phrase : **la spec §02 décrit une API qui n'a jamais
existé** (`POST /api/v1/boutique/ventes`, montants en dollars, `clientRef`,
`moyen`), et **trois de ses redlines sont contredites par le serveur** — pas par
inadvertance, mais parce que le serveur a raison et que le document a été écrit
contre une maquette React.

La règle de lecture n'a pas bougé : **partout où la spec et le serveur se
contredisent, le serveur décide.** Le reste de la spec — anatomie, invariants,
formulations, états — reste la référence et n'a pas d'équivalent ailleurs.

Il y a une nouveauté, et elle va dans le mauvais sens : en cessant de refuser une
vente multi-devises, le serveur a transféré au front un garde-fou qu'il tenait —
que le front a ensuite choisi de ne pas reprendre, le sujet étant renvoyé à une
branche dédiée. Voir **D2 ⚠️**, la seule dette ouverte du module.

---

## 2. État des lieux vérifié

### 2.1 Ce que le back sert

| Route | Permission | Vérifié dans |
|---|---|---|
| `GET /api/v1/sync/referential` → section `boutiqueArticles` | `boutique.catalog.read` (caviardage) | `EnrollmentSyncReadService.java:211` |
| `POST /api/v1/sync/boutique/sales` | `boutique.sale.write` **ET** `editique.write` | `BoutiqueSyncController.java:59` |
| `GET /api/v1/sync/boutique/sales?academicYearId&cursor&limit` | `boutique.sale.read` | `BoutiqueSyncController.java:74` |
| **`POST /api/v1/boutique/sales/{id}/receipt`** → octets PDF + `X-Document-Id` | `boutique.sale.write` **ET** `editique.write` | `BoutiqueSaleController.java:51` |
| **`GET /api/v1/boutique/sales/anomalies?since`** | `boutique.sale.read` | `BoutiqueSaleController.java:71` |
| `GET /api/v1/boutique/articles?academicYearId` (gestion) | `boutique.catalog.read` | `BoutiqueCatalogController.java:45` |
| `POST·PUT·DELETE /api/v1/boutique/articles` (gestion) | `boutique.catalog.write` | `BoutiqueCatalogController.java:57-76` |
| `GET /api/v1/boutique/till?date` | `boutique.sale.read` | `BoutiqueTillController.java:27` |
| `GET /api/v1/editique/documents/{id}` (octets d'une pièce) | `editique.read` | déjà consommée par le front |

Quatre permissions neuves semées sur tout le parc (`V97.0.0`) : `DIRECTOR` et
`SUPER_ADMIN` les quatre, `ACCOUNTANT` tout sauf `boutique.catalog.write` — qui
tient la caisse ne réécrit pas la grille. `ACCOUNTANT` détient par ailleurs
`editique.read` et `editique.write`, donc la conjonction d'encaissement et le
téléchargement du reçu lui sont ouverts.

Cinq migrations : `V95` (catalogue et ventes), `V96` (type éditique `RV`),
`V97` (permissions), `V98` (anomalie `CATALOG_UNRESOLVABLE`), `V99` (payeur en
trois champs + famille d'article).

Le flux `boutique.sales` est déclaré au plan (`SyncStream.java:90`, `KEYSET`,
`clientResource` = `boutique_sales`, `NEVER_ENTAILED`).

### 2.2 Ce que le front a déjà, et qui se recopie

| Besoin de la boutique | Ce qui existe | Fichier |
|---|---|---|
| Bundle référentiel + caviardage `null` ≠ `[]` | `feeTariffs` fait exactement ça | `referential_pull_models.dart:91` |
| Écriture money-grade par outbox | `PaymentOutboxHandler`, garde de dépendance incluse | `payment_outbox_handler.dart` |
| Répertoire de payeurs local | dérivé des paiements, téléphone compris (v28) | `local_payer_identity.dart` |
| Recherche d'élèves inscrits, locale | `searchCurrentYearEnrolledByAcademicInfo` | `search_local_enrollments_use_case.dart:40` |
| Garde « élève inconnu du serveur » | `IsStudentKnownToServerUseCase` (*fail-closed*) | `is_student_known_to_server_use_case.dart` |
| Ticket thermique 80 mm, ESC/POS | gabarit texte 48 colonnes + port imprimante | `ticket_text_layout.dart`, `thermal_printer_port.dart` |
| Lecture de `X-Document-Id` | déjà branchée sur l'éditique | `editique_document_mapper.dart:29` |
| Téléchargement d'une pièce par son id | `GET /editique/documents/{id}` | `editique_remote_data_source.dart:81` |
| États chargement / vide / erreur | `EteeloListSkeleton`, `EteeloEmptyResult`, `EteeloErrorResult` | `lib/core/widgets/`, `lib/core/components/skeletons/` |
| Champ téléphone E.164 | socle en place | cf. §BQ-5 |

`grep -ril boutique lib test` ne rend **rien**. Schéma local en **v30**
(`app_constants.dart:435`) ; la boutique prendra la **v31**.

### 2.3 Le seul trou côté socle front

`ApiErrorParser` lit `code`, `message`, `incidentId` — **pas `detailCode`**
(`api_error_parser.dart:60-73`). Le champ que le back vient d'ajouter pour rendre
les 422 exploitables n'est donc lu par personne. Trois lignes à ajouter, mais
elles conditionnent tout le diagnostic d'échec de push (BQ-6).

---

## 3. Journal de l'alignement back

Ce que `BOUTIQUE_DEMANDES_BACK.md` a produit, vérifié dans le code.

| # | Demande | Statut | Livré comme |
|---|---|---|---|
| R1 | Payeur en trois champs | ✅ | `payerFirstName/LastName/MiddleName` sur `BoutiqueSaleInput` **et** `BoutiqueSaleDelta` ; `payer_name` **dérivé serveur**, plus jamais envoyé par le client (V99) |
| R2 | Caissier sur la vente et dans le reçu | ✅ | `collectedById` + `collectedByName` sur le delta ; `caissierNom` dans `RecuDeVenteCorps`, résolu depuis `createdBy` avec repli silencieux |
| R3 | `family` sur l'article | ✅ | enum `ArticleFamily` **dont l'ordre de déclaration est l'ordre d'affichage** ; `family` dans les deux DTO ; V99 avec rétro-remplissage en `FOURNITURES` |
| R3′ | tailles vendables par article | ❌ | **non fait** — seul point non repris |
| R4 | `receiptDocumentId` dans l'ACK d'un 201 | ✅ | record `SealedReceipt` porté depuis le scellement, `outcome.sale()` n'est plus lu ; **corrigé aussi côté paiement** ; **test retourné** (`ingestReturns(sale(null), true)`) |
| R5 | Endpoint de reçu par `saleId` | ✅ | `POST /boutique/sales/{id}/receipt` → octets PDF + `X-Document-Id`, idempotent sous verrou |
| R6 | Code machine par cause de 422 | ✅ | `detailCode` dans `ApiErrorResponse` + `BoutiqueErrorCodes` |
| R7 | Clamp d'horloge borné au futur seul | ⏸ | information, non traitée (attendu) |

**Et ce que le back a ajouté de lui-même**, après revue adversariale :

- **V98 — `CATALOG_UNRESOLVABLE`.** Un prix que le serveur ne sait plus résoudre
  (grille rééditée, devise changée, bénéficiaire réinscrit ailleurs) ne refuse
  **plus** la vente : elle est enregistrée, `catalog_price_in_cents` reste `null`,
  et l'écart est consigné. Le commentaire de la migration est net : le 422
  d'origine était « l'invariant cardinal du module retourné contre lui-même ».
- **La multi-devise ne refuse plus non plus.** Une référence dans une autre devise
  est simplement écartée de la comparaison — voir **D2 💀**.
- **`GET /boutique/sales/anomalies`.** Sans elle, « une anomalie muette dans une
  table que personne ne lit ne détecterait rien » restait vrai.
- **`UNKNOWN_ACADEMIC_YEAR`.** Une année étrangère créait une séquence éditique
  fantôme et rendait la vente invisible au pull.

---

## 4. Les quatre divergences qui restent

Six sont tombées. Les quatre survivantes, dont deux ont changé de nature.

### D1 — Les tailles n'ont pas de source *(reliquat de l'ancienne D1)*

La famille est arrivée : groupes, ordre, chips et accents sont désormais
constructibles tels que la spec les décrit (§04, §05, §06, §19), et l'ordre
d'affichage est celui de l'énumération serveur — exactement ce que la spec
exigeait (« jamais alphabétique »).

**Les tailles, non.** `BoutiqueSaleLineInput.size` reste un `varchar(16)` libre,
et rien ne dit au poste quelles tailles proposer. Le select de la spec §08 n'a
pas de source.

**Arbitrage inchangé : masquer le select en V1.** La taille est facultative et
sans effet sur le prix (I-3) ; la caisse s'en passe sans rien casser. **Ne pas**
ouvrir un champ texte : la colonne se remplirait de « M », « m », « Medium »,
« moyen », dans une donnée que le back voudra fermer.

### D2 — Multi-devises : dette assumée, renvoyée à une branche dédiée ⚠️

**Personne ne refuse plus un panier multi-devises — ni le serveur, ni le front.**

Côté serveur, le contrôle a disparu : `requireReadableTotals` ne vérifie plus que
l'arithmétique (`lineTotal = pu × qté`, `Σ lignes = total`), et une ligne dont
l'article est dans une autre devise voit simplement sa référence écartée, avec
une anomalie `CATALOG_UNRESOLVABLE` à la clé.

Côté front, la garde bloquante a été **retirée le 2026-08-29 sur arbitrage
produit** : la gestion des deux devises sera traitée sur une branche dédiée, où
le panier portera des totaux **ventilés par devise** plutôt qu'une somme unique —
exactement ce que fait déjà `GET /boutique/till`, qui ne les additionne jamais.

**Ce que cela laisse ouvert d'ici là**, et qu'il faut lire comme une dette et non
comme un oubli : un panier USD + CDF est additionné par `BoutiqueCart.totalInCents`,
encaissé, poussé et scellé avec un total qui n'a pas de sens, **sans que rien ne
le signale au caissier**.

Ce qui a été gardé pour que la branche à venir s'y appuie :

- `BoutiqueCart.isMultiCurrency` et `currencies` — le prédicat existe, il n'est
  simplement plus branché sur le blocage ;
- la clé `boutiqueBlockerMixedCurrency` dans les deux `.arb` ;
- trois tests **retournés** qui épinglent la décision plutôt que l'ancienne
  garde : sans eux, la remettre passerait pour une correction et la retirer pour
  une régression.

### D3 — Le contrat de push reste étranger à la spec

La spec §02 est toujours fausse, autrement : elle décrit `POST
/api/v1/boutique/ventes` avec `{payeur{tel,nom,post,prenom}, moyen, lignes[{…,
pu}], total, clientRef}`.

Le contrat réel — `POST /api/v1/sync/boutique/sales` :

```jsonc
{
  "sale": {
    "id": "<uuid CLIENT, clé d'idempotence>",
    "academicYearId": "<uuid, DOIT être une année de cette école>",
    "payerFirstName": "Willy",          // facultatif
    "payerLastName":  "Ndombo",         // OBLIGATOIRE, seul champ exigé
    "payerMiddleName": "Lelo",          // facultatif
    "payerPhoneNumber": "+243810220145",// facultatif, format libre
    "totalInCents": 3500,               // CENTS
    "currency": "USD",
    "soldAt": "2026-08-29T11:42:00Z"    // heure MÉTIER, clampée serveur
  },
  "lines": [
    { "articleId": "…", "beneficiaryStudentId": "…", "schoolLevelId": null,
      "size": "M", "quantity": 1,
      "unitPriceInCents": 1500, "lineTotalInCents": 1500 }
  ],
  "authorId": "<uuid serveur de l'agent — 403 si ≠ celui qui pousse>"
}
```

Différences qui coûtent si on suit la spec : **cents** et non dollars ·
`lineTotalInCents` obligatoire et vérifié · idempotence par `sale.id` et non
`clientRef` · **pas de `payerName`** (dérivé serveur, en `NOM Post-nom Prénom`
avec le nom en capitales) · pas de champ `moyen` · `academicYearId`, `authorId`
et `soldAt` obligatoires.

**Le 422 se réduit à trois causes réelles**, toutes des bugs client :
`INCONSISTENT_TOTAL`, `UNKNOWN_ARTICLE`, `UNKNOWN_ACADEMIC_YEAR`.

> ⚠ L'`openApi.yaml` annonce encore `PRICE_UNRESOLVABLE` comme quatrième cause et
> mentionne la « vente multi-devises » dans sa prose. **Ni l'une ni l'autre ne
> peut plus se produire** sur cette route : l'ingestion appelle `tryResolve()`,
> et `BoutiquePriceResolver.resolve()` — le seul à lever ce code — n'est appelé
> nulle part en production. Le front doit gérer le code par prudence, mais ne
> doit pas construire de parcours de récupération dessus.

### D4 — La spec §16 prévoit un « 422 prix » qui ne peut pas arriver

Inchangé sur le fond, renforcé dans les faits : non seulement l'écart de prix
ressort en 201 + `divergences[]`, mais désormais l'**absence** de référence aussi.
La spec §16 (« 422 prix … + action Recharger le catalogue ») décrit un chemin qui
n'existe pas.

**Arbitrage :** retirer ce cas de la modale de confirmation. Une divergence arrive
**après** l'ACK, sur une vente enregistrée : ce n'est pas une erreur d'écran.
Elle se consigne localement et se consulte — le back offre maintenant
`GET /boutique/sales/anomalies` pour cela (cf. Q3).

---

## 5. Décisions à trancher avant d'écrire

| # | Question | Recommandation |
|---|---|---|
| Q1 | Tailles : redemander au back, ou masquer le select ? | **Masquer en V1**, redemander sans urgence. Seul point de D1 encore ouvert |
| Q2 | Pull `boutique.sales` : dans la V1 ? | ✅ **tranché — oui, livré** (BQ-8). Le reçu a deux voies : la réclamation directe (immédiate) et ce pull (différé) |
| Q3 | Écran des anomalies : V1 ou V2 ? | **V2.** La route existe, le front consigne les `divergences[]` dès BQ-6 ; l'écran de contrôle peut attendre |
| Q4 | Reçu A4 : le front le compose (§13), ou le télécharge ? | **Le télécharge.** Il est rendu et scellé serveur ; le recomposer produirait une pièce concurrente non scellée |
| Q5 | Ticket 80 mm : nouveau gabarit, ou extension de `TicketTextLayout` ? | **Gabarit frère**, même socle ESC/POS. Le modèle de perception porte élève, matricule et répartition — rien de ce que la vente imprime |
| Q6 | Répertoire payeur : local seul, ou croisé avec celui de la Facturation ? | ✅ **tranché — local seul** (BQ-5). Les deux annuaires parlent le même vocabulaire depuis R1 : le croisement reste trivial le jour où le guichet le réclame |

Q4 mérite un mot : la spec §13 décrit un A4 complet jusqu'aux signatures et au
cartouche de sceau. C'est la maquette du document que **le serveur** produit — pas
un gabarit à réimplémenter en Flutter. Le front en a besoin comme **référence de
recette**, pour vérifier que le PDF descendu correspond.

---

## 6. Modèle de données local — schéma v31

Quatre tables. **Plus simple qu'en révision 1** : le payeur en trois champs a
supprimé les colonnes locales non transmises.

```
ref_boutique_articles              (remplacement en bloc, bundle référentiel)
  id, school_id, academic_year_id, code, label,
  family,                          -- UNIFORME|FOURNITURES|ACTIVITES|ACTES
  pricing_mode, unit_price_in_cents, currency
  UNIQUE(school_id, academic_year_id, code)

ref_boutique_article_level_prices  (remplacement en bloc)
  article_id, school_level_id, price_in_cents
  UNIQUE(article_id, school_level_id)

boutique_sales                     (argent, outbox)
  id (uuid client), school_id, academic_year_id,
  payer_first_name, payer_last_name, payer_middle_name,   -- transmis
  payer_phone_number,              -- E.164
  collected_by_id, collected_by_name,                     -- du delta
  total_in_cents, currency, sold_at,
  receipt_document_id,             -- null tant que non scellé
  sync_status, server_updated_at

boutique_sale_lines                (argent)
  id, sale_id, article_id, article_label,   -- libellé figé (I-6)
  beneficiary_student_id, school_level_id, size,
  quantity, unit_price_in_cents, line_total_in_cents,
  catalog_price_in_cents           -- null = le catalogue ne dit plus rien
```

Points d'attention :

- `family` **non nullable** côté local aussi : le back la rétro-remplit et
  l'exige à la création, un `null` descendu signalerait un bug de projection
  plutôt qu'un article sans famille.
- `school_id` sur les deux tables de référentiel, et **curseur de
  `boutique_sales` scopé école**. Le défaut « une tablette = une école » est déjà
  consigné sur dix flux : ne pas en ajouter un onzième.
- `article_label` figé sur la ligne : le catalogue est remplacé en bloc à chaque
  bundle, et une vente d'hier doit rester lisible après le retrait d'un article.
- `catalog_price_in_cents` nullable et **jamais 0** : `null` veut dire « le
  catalogue ne disait rien », zéro voudrait dire « il disait gratuit ».
- Aucune colonne de reste, de solde ni de statut de paiement. Comptant intégral
  (I-5) : en ajouter une laisserait croire le contraire.
- ⚠ `null` en `whereArgs` avec `IS ?` : défaut latent consigné sur les deux DAO
  finance. Le SQL est juste, c'est le validateur sqflite qui refuse — ne pas
  reproduire le motif.

---

## 7. Les lots

### BQ-0 — Contrat, permissions, porte d'entrée

- `Perm` ×4 : `boutiqueCatalogRead('boutique.catalog.read')`,
  `boutiqueCatalogWrite`, `boutiqueSaleRead`, `boutiqueSaleWrite`.
- `MenuConstants.boutiqueId = 'boutique'` sous `financesMenuId`.
- `kModuleAccessRegistry` : `boutiqueId → ModuleAccess([Perm.boutiqueSaleRead])`.
  Lecture seule pour la **visibilité** ; encaisser est gardé à part.
- `kBoutiqueCollectAccess = ModuleAccess([Perm.boutiqueSaleWrite,
  Perm.editiqueWrite], requiresAll: true)`, dans `kGuardedWriteActions` sous
  « encaisser une vente boutique ». **Conjonction**, comme
  `kPaymentCollectAccess` — et le serveur l'exige littéralement
  (`@RequiresBothPermissions`), sur les **deux** routes d'écriture.
- Route `/finances/boutique` + `AppRoutesNames` + endpoints dans `AppConstants`.
- **`detailCode` dans `ApiErrorParser`** (§2.3) et dans `ApiValidationFailure` —
  sans quoi BQ-6 ne peut rien diagnostiquer.
- ⚠ `accueil_page_test.dart` code en dur le nombre de sous-modules.

### BQ-1 — Le catalogue offline

- `boutiqueArticles` ajouté à `ReferentialYearBundleDto`, **hors** de `pullList`
  comme `feeTariffs` : la distinction `null` ≠ `[]` porte la différence entre
  « pas communiqué » (pas de `boutique.catalog.read`) et « école sans article ».
  Deux états vides distincts à l'écran, sinon le guichet conclut que l'école n'a
  rien paramétré.
- Schéma v31, deux tables de référentiel, purge scopée conditionnée à la nuance.
- Entités : `BoutiqueArticle` (`pricingMode` **déclaré**, `family`), `LevelPrice`.
- `ArticleFamily` en enum front, **dans l'ordre du serveur** — c'est l'ordre
  d'affichage, et le back le dit explicitement (« réordonner ces constantes
  réordonne le catalogue de toutes les caisses »). Un test doit épingler l'ordre.
- `resolveBoutiquePrice(article, levelId)` — **le seul** chemin par lequel un
  montant entre dans une ligne. `null` = ligne incomplète, **jamais 0**.
- ⚠ I-1 en dur : le badge « par niveau » se rend depuis `pricingMode`, jamais
  d'une comparaison min/max. Test avec les deux articles réels de La Fontaine :
  une Lacoste à grille dont toutes les cases valent 10 $ (badge) et un écusson
  plat à 10 $ (pas de badge).
- Le serveur trie par `code` ; le front regroupe par famille et trie par libellé
  à l'intérieur. Ce n'est pas une demande back — le critère existe désormais.

### BQ-2 — Le panier, domaine pur

Aucun widget. Une classe testable seule :

- ajout par article (incrémente une ligne existante **sans** bénéficiaire, sans
  niveau et sans taille ; empile sinon) ;
- niveau effectif = `bénéficiaire ? niveau de l'élève : niveau de la ligne`, une
  seule fonction ;
- exclusion mutuelle bénéficiaire ⊕ niveau ;
- total en **cents**, `lineTotal = pu × qté` calculé ici (le serveur le vérifie
  et rend `INCONSISTENT_TOTAL` sinon) ;
- ⚠️ **mélange de devises détecté mais NON bloquant** (D2) — décision produit,
  dette renvoyée à la branche multi-devises ;
- blocages nommés dans l'ordre fixe de la spec §10 : Nom · Post-nom · Prénom ·
  Téléphone · lignes sans niveau. « Panier vide » est seul, les autres muets.

### BQ-3 — L'écran

Anatomie §03 : deux colonnes au-dessus de 1080, panier collant ; une colonne en
dessous. ⚠ `AppPageBackground` **plafonne à 1180 px** — un seuil au-dessus rend
la disposition large inatteignable ; 1080 passe, le vérifier quand même.

Carte d'article (§04, toute la surface tapable, ≥ 128 dp), recherche + chips
(§06), **groupes par famille (§05) — désormais constructibles**, bandeau de
rappel I-1/I-2, ligne de panier (§08) avec l'état ambre « Prix à résoudre » et
**jamais de `0.00 $`** pour une ligne non résolue.

Pied §10 : le bouton inactif dit ce qui manque. ⚠ `FilledButton`/`OutlinedButton`
inline sans `minimumSize` **crashe** (thème plein-largeur) — piège déjà corrigé
ailleurs, ne pas le rouvrir.

### BQ-4 — Désigner un bénéficiaire ✅

Modale bi-mode §09 — c'est le patron `SearchModeSwitch` de la règle
non-négociable #12 : **bascule exclusive**, jamais deux blocs reliés par un
« OU ». Recherche libre (seuil 2 lettres, max 8) ou par niveau (liste complète,
sans seuil).

⚠️ **Le second mode est « par niveau », pas « par classe »**, à rebours de la
lettre de la spec : c'est le niveau qui résout le prix, il est porté par chaque
ligne d'inscription (`LocalEnrollmentListItem.schoolLevelId`), et passer par la
classe demanderait ensuite de l'en dériver — une lecture de plus, et une
dépendance boutique → classes, pour la même réponse.

⚠️ **Le mode par défaut est l'identité**, à rebours du socle (`SearchMode.level`
en premier). Cas d'usage différent : en Facturation on traite une classe
entière, à la caisse on sert **une** personne, souvent présente.

Source : `searchCurrentYearEnrolledByAcademicInfo`, raffinement du nom **en
Dart** (le SQL ne filtre jamais sur un nom — piège consigné).

**Garde `IsStudentKnownToServerUseCase`, mais son motif a changé.** Un élève
inconnu du serveur ne fait plus perdre la vente (le 422 est mort, cf. §3) : elle
passe, avec une anomalie `CATALOG_UNRESOLVABLE` et un reçu au bénéficiaire
**anonyme** — `BoutiqueDocumentService.beneficiaryName()` avale l'échec de
lecture et rend `null`. La garde reste donc, pour la qualité du reçu, et elle
nomme le repli : vendre au niveau, sans bénéficiaire, ce qui donne le même prix.

### BQ-5 — Payeur et répertoire local ✅

Bloc §07 : téléphone d'abord (il est la clé), puis Nom + Post-nom, puis Prénom.
**Les trois champs partent tels quels** ; `payerLastName` est le seul obligatoire
côté serveur, ce qui coïncide avec le blocage nommé de la spec.

Deux pièges refermés à l'écriture :

- **la course frappe / lecture** — le guichet continue de taper pendant que le
  répertoire répond ; un résultat périmé proposerait le payeur d'un numéro qu'il
  vient de corriger. Le BLoC compare le numéro avant d'appliquer ;
- **les contrôleurs de saisie vivent dans l'écran**, jamais dans le widget de
  bloc payeur : celui-ci est reconstruit à chaque frappe, et des contrôleurs
  recréés à chaque build replaceraient le curseur en tête à la deuxième lettre.

Répertoire local dérivé des ventes locales **et des ventes descendues** — depuis
R1 le delta rend l'identité découpée, donc une vente du poste d'à côté alimente
correctement l'annuaire. Reconnaissance sur les 9 derniers chiffres, calculée
**en Dart** : ⚠ `LOWER()` de SQLite ne plie pas les accents et le pré-filtre SQL
fusionne `+242`/`+243`.

Badge « Payeur connu » retiré dès que le téléphone change — jamais un badge qui
survit à son fait. Socle E.164 pour le champ téléphone (⚠ indicatif figé v1,
trunk 0 avant plafond de longueur). `EteeloTextInput` capitalise seul, mot par
mot pour une identité (règle #11).

> Pour que le ticket front et le reçu back se ressemblent : le serveur compose
> `payer_name` en `NOM Post-nom Prénom`, **nom en capitales**
> (`composePayerName`, `BoutiqueSaleIngestService.java:299`).

### BQ-6 — Encaisser ✅ 💀

Le cœur money-grade. Écriture locale d'abord, push par outbox ensuite.

- `RecordSaleUseCase` → écrit `boutique_sales` + lignes + entrée d'outbox dans
  **une** transaction, rend immédiatement.
- `BoutiqueSaleOutboxHandler`, `aggregateType = 'BOUTIQUE_SALE'` :
  - garde de dépendance ENROLLMENT scopée année → `blocked`, jamais `failed`.
    **Moins critique qu'en r1** (plus de 422), mais elle évite un reçu au
    bénéficiaire anonyme et une anomalie inutile ;
  - `POST /sync/boutique/sales` ;
  - ACK → `receipt_document_id` **depuis `documents[]` et `sale.receiptDocumentId`,
    désormais cohérents** (R4) ; consigne les `divergences[]` ; passe `SYNCED` ;
  - échecs : transitoire pour le transport / 5xx / 401 / 408 / 409 / 429 ;
    déterministe pour les autres 4xx. **Sur un 422, lire `detailCode`** — les
    trois causes possibles sont des bugs client, à surfacer comme tels et non
    comme un incident réseau.
- Modale de confirmation §11 : récapitulatif **non modifiable**, un seul moyen,
  montant en texte et jamais en champ. `Encaisser {total}` — on confirme un
  chiffre, pas une intention.
- ⚠ Aucun log d'argent (checklist money-grade).

### BQ-7 — La preuve de paiement ✅

**Le front produit la preuve immédiate ; le serveur produit la pièce de
référence.** C'est le partage acté avec le back.

- Modèle `SaleTicketModel` + gabarit `SaleTicketTextLayout` (48 colonnes), frère
  de l'existant, même socle ESC/POS et même port d'imprimante.
- Anatomie §12 : en-tête centré, `PAYEUR :` en capitales, ligne
  `{qté} × {libellé}` + méta `{pu} /u · {niveau} · T. {taille}` **sans séparateur
  orphelin**, ligne indentée `↳ pour {élève} ({classe})`, et
  **`Reste à payer 0.00 $` toujours imprimé** — preuve visuelle de I-5.
- Le caissier s'imprime sur le ticket comme sur l'A4 (R2).
- **Trois états de reçu**, et le troisième a maintenant deux sorties :

| | Ticket | A4 | Sortie |
|---|---|---|---|
| Hors ligne | provisoire | — | file d'attente |
| ACK avec `documents[0]` | définitif | scellé | rien à faire |
| ACK avec `documents` vide | provisoire | — | **`POST /boutique/sales/{id}/receipt`** (immédiat, idempotent) ou le delta (différé) |

- Réimpression : même route, elle rend les octets et pose `X-Document-Id` — que
  le front sait déjà lire (`editique_document_mapper.dart:29`).
- `EditiqueDocumentType.saleReceipt('RV')`, archivé et rejouable. ⚠ Le front ne
  l'**émet** jamais à la vente : il le réclame.

### BQ-8 — Le pull des ventes ✅

- `SyncPlanKeys.boutiqueSales = 'boutique.sales'` + alias `['boutique_sales']`.
- Handler keyset, 304 = rien de neuf, curseur **scopé école**.
- Réconciliation : une vente descendue avec `receiptDocumentId` non nul remplace
  le ticket provisoire local ; `collectedByName` et l'identité découpée du payeur
  alimentent le répertoire (BQ-5).
- ⚠ Le `RV` est **délibérément exclu** du delta éditique
  (`EditiqueDocumentRepository.findDeltaKeyset`, `docType not in (BU, RV)`) : ce
  flux n'est gardé que par `editique.read`, que le secrétariat détient sans
  aucun droit boutique, et un reçu de vente porte le payeur, son téléphone, les
  prénoms des enfants et les prix. **Ne jamais demander à l'y remettre.** C'est
  ce pull-ci qui apprend les reçus à la caisse.
- Aucune arête d'ordre : `NEVER_ENTAILED`, et aucun autre module ne lit les
  ventes (I-4).

### BQ-9 — États, a11y, l10n ✅

Règle non-négociable #10, sans exception : `EteeloListSkeleton` (8 cartes, même
géométrie que la carte réelle — §14), `EteeloEmptyResult` pour les **deux** vides
distincts de BQ-1 plus celui de la recherche, `EteeloErrorResult` via un
`BoutiqueResultsErrorState` à quatre types — **403 ne propose jamais
« Réessayer »**.

Cas particulier §16 : un échec de push **ne remplace pas l'écran par une erreur
pleine**. La vente est composée, le panier intact, l'erreur s'affiche dans la
modale.

Strings FR + EN dans les deux `.arb`, puis `flutter gen-l10n` **et
`dart format lib/l10n/`** (sans quoi 3 clés = 1500 lignes de churn).

### BQ-10 — Revue adversariale money-grade ✅

**Trois mutations, trois rougissements.** Une garde qu'aucune mutation ne fait
tomber est une garde qu'on croit avoir :

| Mutation | Effet |
|---|---|
| débrancher la garde de dépendance ENROLLMENT | 2 tests rouges |
| débrancher le verrou anti-double-envoi | 2 tests rouges |
| inventer un numéro de reçu sur un ACK sans document | 1 test rouge |

⚠️ La mutation de la garde mono-devise a disparu **avec la garde** (cf. D2). Ce
qui reste vérifié est que le mélange demeure *détectable*.

**Deux défauts réels trouvés et corrigés**, tous deux dans le chemin de
l'encaissement :

1. **Le bouton « Encaisser » restait actif après la vente.** Le panier reste
   intact pour permettre la réimpression, donc `canCollect` restait vrai. Le
   bloc refusait en silence — le guichet appuyait, rien ne se produisait. Un
   bouton actif qui ne fait rien est pire qu'un bouton inactif. « Vider le
   panier » avait le même défaut, en pire : il aurait effacé ce que la barre de
   reçu sert à réimprimer. Les deux gestes disparaissent désormais, et un test
   les épingle.

2. **La sonde de connectivité pouvait faire perdre une vente.** `isOnline()`
   traverse un canal natif ; une exception remontait jusqu'à `_collect` et
   empêchait l'encaissement — pour un renseignement qui ne décide que d'une
   *phrase* dans la confirmation, sur un client qui a déjà payé. Elle est
   désormais inoffensive et retombe sur « hors ligne », la formulation la plus
   prudente.

**Deux nettoyages** : une lecture non bornée de la table des grilles (elle
chargeait l'historique de toutes les écoles à chaque ouverture de la caisse), et
une référence à ce plan dans un doc-comment de production — le code vivra plus
longtemps que le document.

**Axes vérifiés sans finding** : aucun log d'argent, aucun `null` en `whereArgs`,
aucun montant en `double`, parsing tolérant sur l'ACK serveur, et aucune lecture
d'affichage qui remonte une erreur au milieu d'un flux d'argent (le répertoire
des payeurs avale et rend « inconnu »).

## 8. Ce qui reste au back

Un seul point, et il n'est pas bloquant.

| # | Demande | Statut |
|---|---|---|
| R3′ | Tailles vendables portées par l'article | ouvert — le front masque le select en attendant (Q1) |
| — | **Format des montants sur ticket** : la boutique imprime « 35.00 $ » (spec §12), la perception « 1 234,56 CDF ». Les deux sortent de la MÊME imprimante — écart assumé, à arbitrer | ouvert, côté front |
| — | `openApi.yaml` : le 422 annonce encore `PRICE_UNRESOLVABLE` et la « vente multi-devises », ni l'un ni l'autre atteignables | cosmétique, mais c'est un contrat |
| R7 | Le clamp d'horloge ne borne que le futur | information — à reposer le jour du rapport de caisse |

Reste à confirmer, hors demandes : que `V95`→`V99` partent bien dans la même
livraison que le code — le travail est **toujours non commité** au 2026-08-29.

⚠ L'arbre de travail du back est **partagé** et a déjà changé de branche en cours
de session : passer par `git worktree` pour tout travail dessus.

---

## 9. Ordre d'exécution proposé

```
BQ-0 ─┬─ BQ-1 ── BQ-2 ─┬─ BQ-3 ─┬─ BQ-4
      │                │        └─ BQ-5
      │                └─ BQ-6 ── BQ-7
      └────────────────── BQ-8
                                   └─ BQ-9 ── BQ-10
```

BQ-6 ne peut pas commencer avant BQ-2 (le total et la garde de devise en
dépendent) ni avant que `detailCode` soit lu (BQ-0). BQ-8 est indépendant de
l'écran et peut partir en parallèle dès BQ-0.

**Jalon minimal démontrable :** BQ-0 → BQ-1 → BQ-2 → BQ-3 donne un catalogue
groupé par famille et un panier qui calcule juste, sans encaisser. C'est le bon
moment pour confronter l'écran à la spec avant d'y mettre de l'argent.

---

## 10. Hors périmètre

Repris de la spec §20, moins ce que le back a livré entre-temps :

CRUD du catalogue (l'état vide y renvoie — **seul lien mort assumé de l'écran**) ·
stock et inventaire · remise d'article · retour / annulation d'une vente scellée ·
rapport de caisse et clôture (`GET /boutique/till`, servi mais non consommé) ·
**écran de contrôle des anomalies** (`GET /boutique/sales/anomalies`, servi —
V2, cf. Q3) · le sélecteur « Démo état », outil de revue qui n'a rien à faire
dans une build.
