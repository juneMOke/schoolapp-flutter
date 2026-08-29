# BOUTIQUE_DEMANDES_BACK.md — ce que le front demande au back pour la caisse boutique

> ## ✅ RÉPONDU LE 2026-08-29 — six demandes sur sept livrées
>
> | # | Statut | Livré comme |
> |---|---|---|
> | R1 | ✅ | `payerFirstName/LastName/MiddleName` sur `BoutiqueSaleInput` **et** `BoutiqueSaleDelta` ; `payer_name` dérivé serveur (V99) |
> | R2 | ✅ | `collectedById`/`collectedByName` sur le delta ; `caissierNom` dans `RecuDeVenteCorps` |
> | R3 | ✅ | enum `ArticleFamily` ordonné + colonne `family` (V99) |
> | R3′ | ❌ | **tailles vendables : non repris.** Seul point ouvert — le front masque le select en V1 |
> | R4 | ✅ | record `SealedReceipt`, `outcome.sale()` n'est plus lu ; **corrigé aussi côté paiement** ; test retourné |
> | R5 | ✅ | `POST /api/v1/boutique/sales/{id}/receipt` → octets PDF + `X-Document-Id` |
> | R6 | ✅ | `detailCode` dans `ApiErrorResponse` + `BoutiqueErrorCodes` |
> | R7 | ⏸ | information, non traitée (attendu) |
>
> **Le back a aussi mené sa propre revue** et livré ce que ce document ne
> demandait pas : `CATALOG_UNRESOLVABLE` (V98 — un prix irrésoluble ne refuse plus
> une vente encaissée), la garde `UNKNOWN_ACADEMIC_YEAR`, et
> `GET /boutique/sales/anomalies`.
>
> ⚠ **Un effet de bord à connaître :** la vente multi-devises **n'est plus
> refusée** non plus. Le garde-fou passe intégralement au front — voir
> `BOUTIQUE_PLAN.md` §D2.
>
> Le reste de ce document est conservé **tel qu'émis**, comme trace de
> l'argumentation. Il n'est plus la description du contrat : c'est
> `BOUTIQUE_PLAN.md` (révision 2) qui l'est.

---

> **Émetteur :** front (`school_app_flutter`) · **Destinataire :** back
> (`eteelo-backend`, branche `feat/parametrage-automatique-l0`, travail boutique
> non commité au 2026-08-29).
>
> **Base de la confrontation :** `BOUTIQUE_PLAN.md` §3 (les dix divergences entre
> la spec d'écran et le contrat servi).
>
> **Ce document ne demande rien de neuf sur le fond.** Six de ses sept demandes
> consistent à faire pour la vente ce que le serveur fait **déjà** pour
> l'encaissement de frais. Chaque section nomme son précédent en une ligne de
> code existante.

---

## 0. Le partage de travail, d'abord

Il faut le poser avant les demandes, sinon elles se lisent comme une liste de
courses au lieu d'un partage.

**Le front produit la preuve de paiement, exactement comme pour l'encaissement de
frais.** Le ticket thermique 80 mm est composé et imprimé au comptoir,
immédiatement, hors ligne compris, sur le socle ESC/POS déjà en service
(ADR-013 : `TicketTextLayout`, `ThermalPrinterPort`, imprimante NT-8003DD
validée sur matériel). Il porte un numéro provisoire selon la convention
`PROV-…` déjà en place, et la mention « reçu définitif scellé à la
synchronisation ».

Le front prend donc en charge, **sans rien demander** :

- la résolution du prix hors ligne depuis la grille descendue (`pricingMode`
  déclaré, jamais inféré) ;
- le calcul des totaux, la garde mono-devise, les blocages de composition ;
- l'annuaire local des payeurs, dérivé des ventes locales ;
- le ticket provisoire et son impression ;
- le cache des pièces scellées et leur re-téléchargement
  (`GET /api/v1/editique/documents/{id}`, déjà branché).

**Ce que le front attend du serveur est le reçu de vente RV définitif — et les
moyens de le retrouver.** Les demandes ci-dessous ne portent que là-dessus, plus
deux champs de catalogue sans lesquels l'écran spécifié n'est pas constructible.

---

## Récapitulatif

| # | Demande | Précédent côté paiement | Poids |
|---|---|---|---|
| R1 | Découper le payeur en trois champs | `PaymentInput.payerFirstName/LastName/MiddleName` | **fort** |
| R2 | Porter le caissier sur la vente et dans le reçu | `PaymentDelta.collectedById/collectedByName` | **fort** |
| R3 | Ajouter `family` (et `sizes`) à l'article | `fee_tariffs` porte sa nature | **fort** |
| R4 | Propager `receiptDocumentId` dans l'ACK 201 | *défaut partagé* — à corriger des deux côtés | **fort** |
| R5 | Un endpoint de reçu par `saleId` | `POST /finance/payments/{id}/receipt` | moyen |
| R6 | Un code d'erreur machine par cause de 422 | — (dette connue, cf. présence) | moyen |
| R7 | `ClientClockGuard` ne borne que le futur | — | information |

---

## R1 — Découper le payeur en trois champs

### Ce qui est demandé

Remplacer, dans `BoutiqueSaleInput`, le champ unique

```java
@NotBlank @Size(max = 255) String payerName
```

par le triplet que `PaymentInput` porte déjà (lignes 49-53) :

```java
String payerFirstName,
String payerLastName,
String payerMiddleName,
```

et les faire redescendre par `BoutiqueSaleDelta`, comme `PaymentDelta` le fait
(lignes 45-47).

### Ce que ce n'est pas

**Ce n'est pas l'option R4 de l'ADR-020** — celle d'une entité tuteur derrière le
payeur, qui a été écartée et qui doit le rester. La demande porte sur trois
colonnes de texte au lieu d'une. Le payeur reste un nom libre, sans identifiant,
sans référentiel, recopié sur chaque vente. C'est exactement le statut qu'il a
côté paiement, où le triplet coexiste sans qu'aucune entité n'ait été créée.

`payer_name` peut d'ailleurs rester en base : le reçu a besoin d'un nom composé,
et le composer à l'affichage plutôt que le stocker est un détail d'implémentation
qui appartient au serveur.

### Pourquoi c'est le premier point

Le geste est **le même** des deux côtés du même guichet : identifier qui paie. La
même personne tient les deux caisses, souvent dans la même heure. Avec un seul
champ côté boutique :

1. Le front doit **composer** à l'aller (`"Ndombo Lelo Willy"`) et ne peut pas
   **décomposer** au retour. Une vente qui redescend du delta — celle du guichet
   d'à côté, ou la sienne après réinstallation — arrive avec un nom entier et
   indécoupable.
2. L'annuaire des payeurs se scinde en deux vocabulaires dans la même
   application : trois champs côté Facturation, un seul côté Boutique. La même
   personne y figure deux fois, sous deux formes, et le rapprochement entre les
   deux ne peut se faire que par le téléphone.
3. Une vente faite au poste A ne reconnaît pas le payeur au poste B. Le poste B
   voit « Ndombo Lelo Willy » dans un champ « Nom » et proposera de le
   ressaisir.

Le coût est de trois colonnes et d'une projection. Le coût de ne pas le faire
est un annuaire qui se dégrade à chaque synchronisation.

---

## R2 — Porter le caissier sur la vente et dans le reçu

### Ce qui est demandé

1. `BoutiqueSaleDelta` : ajouter `collectedById` + `collectedByName`, résolus à
   l'envoi, exactement comme `PaymentDelta` les porte (lignes 49-50) et pour la
   raison déjà écrite là-bas : `created_by` est l'adresse e-mail de connexion de
   l'auditeur JPA, ce n'est pas un nom qu'on imprime.
2. `RecuDeVenteCorps` : ajouter le nom du caissier.

### Pourquoi

La spec impose « Caissier : … » à deux endroits, et ce n'est pas décoratif — un
ticket de caisse sans caissier ne permet pas d'arbitrer un écart de tiroir en fin
de journée :

- §12, ticket thermique : `Caissier : Moke Junior`, sous la date ;
- §13, reçu A4 : cartouche **ENCAISSEMENT** — « Espèces · comptant intégral /
  Caissier : Moke Junior ».

`RecuDeVenteCorps` porte aujourd'hui `venteId`, `payeurNom`, `payeurTelephone`,
`lignes`, `total`. **Il n'y a pas de caissier**, donc l'A4 spécifié n'est pas
produisible en l'état : le serveur imprimerait un cartouche « ENCAISSEMENT »
amputé de la moitié de son contenu.

Le ticket front, lui, peut s'en sortir seul — mais alors le ticket porte le
caissier et le reçu définitif ne le porte pas, sur la même vente. C'est
exactement le genre d'écart que le guichet remarque et ne sait pas expliquer.

---

## R3 — Ajouter `family` à l'article, et les tailles

### Ce qui est demandé

Sur `boutique_articles` et dans les deux DTO (`BoutiqueArticleDto` et
`BoutiqueArticleSummaryDto`) :

```sql
family varchar(20) NOT NULL
  CHECK (family IN ('UNIFORME','FOURNITURES','ACTIVITES','ACTES'))
```

et, si l'arbitrage le permet, un porteur de tailles (`sizes text[]`, ou une table
fille sur le modèle de `boutique_article_level_prices`).

### Pourquoi la famille n'est pas un détail d'affichage

Elle porte **quatre** choses dans la spec, et aucune n'est cosmétique :

- l'**ordre** des groupes (§05 : « celui de l'énumération — jamais alphabétique,
  jamais par volume de ventes ») ;
- le **découpage** du catalogue en sections avec compteur « n au panier » ;
- les **chips de filtre** exclusives (§06), qui sont la seule navigation d'un
  catalogue de plusieurs dizaines d'articles ;
- l'**accent de couleur** et l'icône du médaillon (§04, §19).

Sans elle, le catalogue est une grille plate rendue dans l'ordre de
`findCatalogWithPrices`, c'est-à-dire `order by a.code asc` : **BULT, CHEM, ECUS,
JDCL, POLO, PROM, RETD, SURV**. Un caissier ne parcourt pas ça à midi avec une
file d'attente.

Le tri lui-même n'est pas le problème — le front peut retrier. C'est **le critère
de tri** qui n'existe nulle part.

Le précédent est immédiat : `fee_tariffs` porte la nature du frais, et le back
vient précisément d'ajouter au catalogue les natures qu'il accepte
(`a30eacd feat(finance): publish the fee natures the catalogue accepts`). La
famille d'article est le même objet, sur le catalogue d'à côté.

### Pourquoi les tailles, et pourquoi pas un champ libre

`boutique_sale_lines.size` est un `varchar(16)` libre, et le commentaire de
`V95.0.0` le justifie bien : « le jour où une école vend des chaussures, "42"
doit passer sans migration ».

Mais **rien ne dit au poste quelles tailles proposer**. Deux issues, et une
seule est acceptable :

- ✅ le catalogue porte les tailles vendables par article, le front rend un
  select fermé (§08) ;
- ❌ le front ouvre un champ texte — et la colonne se remplit de « M », « m »,
  « Medium », « moyen », dans une donnée que le serveur voudra un jour fermer.

**En attendant, le front masque le select.** La taille est facultative et sans
effet sur le prix (I-3) : la V1 s'en passe sans rien casser. C'est la seule
demande de ce document qui a un repli propre.

---

## R4 — Propager `receiptDocumentId` dans l'ACK d'un 201

### Le défaut

`BoutiqueSaleSubmissionService.toResponse()` (ligne 73) lit :

```java
BoutiqueSale sale = outcome.sale();
... new BoutiqueSaleResponse.SaleAck(sale.getId(), sale.getReceiptDocumentId(), ...)
```

`outcome.sale()` vient de `ingestService.ingest()`, qui est `@Transactional` :
l'instance est **détachée** quand `submit()` reprend la main. `sealReceipt()`
appelle ensuite `emitRecuDeVente()`, lui aussi `@Transactional`, qui **recharge**
la vente (`saleRepository.findWithLines(saleId)`) et pose le `receiptDocumentId`
sur **une autre instance, dans une autre transaction**.

L'instance rendue à `toResponse()` ne le voit jamais.

Le javadoc de la méthode promet pourtant l'inverse, mot pour mot :

> *« Relit la vente pour l'ACK plutôt que de réutiliser l'instance d'ingestion :
> le scellement lui a posé son `receiptDocumentId` dans une transaction
> distincte, et l'objet en mémoire ne le porterait pas. La caisse recevrait alors
> un ACK annonçant un reçu sans identifiant. »*

C'est la description exacte du bug, en commentaire au-dessus du code qui le
contient.

### Pourquoi personne ne l'a vu

**Le rejeu masque le 201.** Sur un rejeu idempotent, `ingest()` sort par
`saleRepository.findWithLines(input.id())` — une lecture en base, dans une
transaction ouverte, sur une vente qui porte déjà son `receiptDocumentId`. L'ACK
d'un **200 est donc correct**. Seul le **201** est faux, et il ne se produit
qu'une fois par vente.

Et le test ne l'attrape pas. `BoutiqueSaleSubmissionServiceTest.java:62` :

```java
ingestReturns(sale(RECEIPT), true);   // la vente porte DÉJÀ le receiptDocumentId
...
assertThat(outcome.response().sale().receiptDocumentId()).isEqualTo(RECEIPT);
```

Il fabrique la valeur avant l'appel, puis vérifie qu'elle est encore là. Il
passerait à l'identique si `toResponse()` ne propageait rien du tout.

### Ce qui est demandé

1. Relire la vente après `sealReceipt()`, comme le javadoc l'annonce.
2. **Retourner le test** : faire rendre par `ingest()` une vente **sans**
   `receiptDocumentId`, faire poser la valeur par le mock de `emitRecuDeVente`,
   et vérifier que l'ACK la porte quand même. Un test qui épingle le mauvais
   comportement coûte plus cher qu'un test absent.

### ⚠ Le même défaut est dans le paiement

`PaymentSubmissionService.toResponse()` fait exactement la même chose avec
`outcome.payment().getReceiptId()`. Ce n'est pas une copie fautive de la
boutique : c'est le patron d'origine.

Et il a une conséquence en production. Le front documente ce champ ainsi
(`payment_push_response_models.dart:164`) :

> *« UUID de la pièce scellée, **seule clé de re-téléchargement du reçu
> définitif** (`GET /editique/documents/{id}`). `null` est un cas NORMAL : le
> scellement serveur est best-effort et hors transaction. »*

Le front a raison sur la conclusion et se trompe sur la cause : ce `null` n'est
pas *normalement* dû à un scellement raté, il est **systématique sur tout 201**.
Le reçu définitif d'un paiement n'a donc jamais été re-téléchargeable
directement après l'ACK — il fallait attendre que le delta le redescende.

À corriger des deux côtés, dans le même geste.

---

## R5 — Un endpoint de reçu par `saleId`

### Ce qui est demandé

```
POST /api/v1/boutique/sales/{saleId}/receipt   →  application/pdf
@RequiresPermission(EDITIQUE_WRITE)
```

Strictement le symétrique de `POST /api/v1/finance/payments/{paymentId}/receipt`
(`FinanceDocumentController.java:40`), et il s'appuierait sur un service qui
existe déjà : `BoutiqueDocumentService.emitRecuDeVente(saleId)`, idempotent par
`boutique_sales.receipt_document_id`. Il ne reste qu'à l'exposer.

### Pourquoi

Deux cas de guichet, tous deux ordinaires :

1. **L'ACK est revenu sans `documents`.** Le scellement est best-effort et son
   échec est avalé — c'est le bon arbitrage, personne ne le conteste. Mais la
   caisse doit pouvoir **réclamer** le reçu, pas seulement l'attendre.
   Aujourd'hui, son seul chemin est `GET /api/v1/sync/boutique/sales` (un cycle
   de pull keyset complet) puis `GET /api/v1/editique/documents/{id}`.
2. **La réimpression.** Le payeur revient trois jours plus tard avec son ticket
   provisoire et demande son reçu. Même parcours en deux appels, dont un pull.

Le paiement, lui, a l'appel direct depuis le premier jour.

### Ce qu'il ne faut pas faire à la place

Ne pas réintégrer le `RV` au delta éditique. Le back l'en a exclu délibérément
(`EditiqueDocumentRepository.findDeltaKeyset`, `docType not in (BU, RV)`), et
l'argument est juste : ce flux n'est gardé que par `editique.read`, que le
secrétariat détient sans aucun droit boutique, et un reçu de vente porte le nom
du payeur, son téléphone, les prénoms des enfants, leurs niveaux et les prix.
L'isolation I-4 vaut plus que la commodité.

---

## R6 — Un code d'erreur machine par cause de 422

### Ce qui est demandé

Distinguer les cinq causes techniques du 422 par un code lisible par machine, et
non par le seul texte du message. Aujourd'hui, `GlobalExceptionHandler` rend
`code: ApiErrorCode.UNPROCESSABLE` pour **toutes** :

| Cause | Où | Le front peut-il s'en remettre ? |
|---|---|---|
| `lineTotal ≠ pu × qté` | `requireCoherentTotals` | non — bug client, à corriger |
| `Σ lignes ≠ total` | `requireCoherentTotals` | non — idem |
| vente multi-devises | `requireCoherentTotals` | non — idem |
| article inconnu de l'école | `loadArticles` | non — vente perdue, à ressaisir |
| **prix irrésoluble** (bénéficiaire sans inscription, ou inscription sans niveau) | `BoutiquePriceResolver` | **oui** |

La dernière ligne est celle qui compte. Elle est **récupérable** — l'inscription
du bénéficiaire finira par se synchroniser, ou le caissier peut rebasculer la
ligne en walk-in au niveau — mais le front ne peut pas la distinguer des quatre
autres. Il ne peut donc offrir qu'un « contactez le support » sur une vente déjà
encaissée, là où il pourrait dire « l'inscription de David n'est pas encore
partie ; la vente repartira seule » ou « vendez au niveau ».

### Précédent, en négatif

C'est la dette déjà constatée sur la présence : l'aplatissement des 400/422 sur
un message unique rend la feuille de reprise muette, et une journée d'appel se
perd sans que personne puisse dire pourquoi. Le remède est le même : un code, pas
une phrase.

Deux formes acceptables, au choix du back — un enum `ApiErrorCode` élargi
(`PRICE_UNRESOLVABLE`, `UNKNOWN_ARTICLE`, `INCONSISTENT_TOTAL`,
`MIXED_CURRENCY`), ou un champ `detailCode` à côté du code générique. La seconde
n'oblige pas à toucher les autres modules.

---

## R7 — Information : `ClientClockGuard` ne borne que le futur

Sans demande, mais à savoir avant d'ouvrir le rapport de caisse.

`ClientClockGuard.clamp` ramène un `soldAt` postérieur à `now + 5 min`, et laisse
passer **tout** timestamp dans le passé. Une tablette dont l'horloge retarde de
trois jours datera sa vente de trois jours en arrière, et
`GET /api/v1/boutique/till?date=` — qui compte sur l'heure métier, à juste
titre — la rangera dans une caisse déjà comptée.

Aucune conséquence en V1 : il n'y a ni clôture ni rapport de caisse (spec §20).
La journée où l'un des deux arrive, c'est la première question à reposer.

---

## Ce qu'il ne faut **pas** faire

Deux symétries apparentes qui seraient des régressions.

**Ne pas ajouter `url` à `SealedSaleDocument`** par alignement sur
`GeneratedDocument.url`. Ce champ existe côté paiement et
`PaymentSubmissionService` l'envoie **toujours à `null`** : c'est un champ mort
qui promet un chemin d'accès inexistant. `SealedSaleDocument` a raison de ne pas
l'avoir. C'est plutôt le paiement qui devrait le perdre.

**Ne pas rejeter une vente sur un écart de prix.** Le contrat actuel — 201 +
`divergences[]`, l'anomalie enregistrée, la vente conservée — est exactement le
bon arbitrage, et le front s'y aligne. La spec d'écran §16 prévoit un « 422
prix » : **c'est la spec qui a tort**, le front ne l'implémentera pas, et il ne
faut surtout pas la suivre pour lui faire plaisir.

---

## Ordre de traitement suggéré

**R1, R2, R3** conditionnent la structure du front : elles changent des colonnes
locales et le schéma de la table `boutique_sales`. Les livrer après que le front
a écrit BQ-5 et BQ-6 coûterait une migration locale supplémentaire sur un parc
déjà en v31.

**R4** est indépendante et urgente pour une autre raison : elle touche aussi le
paiement, en production.

**R5, R6** peuvent suivre — le front sait vivre sans, au prix d'un parcours plus
long et d'un diagnostic plus pauvre.

⚠ L'arbre de travail du back est partagé et a déjà changé de branche en cours de
session : passer par `git worktree` pour ce travail.
