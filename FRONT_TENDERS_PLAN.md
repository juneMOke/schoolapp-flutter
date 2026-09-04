# Le taux au guichet — plan front (perçu ≠ imputé)

> **Statut :** plan écrit le **2026-09-01**. **Tout ce qui ne dépend d'aucun nom
> de contrat est livré** — schéma local **v39 → v41**, 96 tests neufs,
> **suite complète 5 330 verts**, `flutter analyze` clean sur tout l'arbre.
> F3 — l'émission sur le fil — est **commité** le 2026-09-04 (`34cec226`).
>
> | Lot | État |
> |---|---|
> | F0 · le taux hors ligne (v40) | ✅ **livré et branché** sur le flux `finance.exchange-rates` (bundle + ETag) |
> | F1 · le paramétrage (Configuration) | ✅ **livré** — le taux est PUBLIÉ chez le serveur, puis mis en cache |
> | **U1–U4 · le guichet bi-devise** | ✅ **livré** — bascule, taux, dérivées, barre à deux niveaux, popin |
> | F2 · la ligne d'encaissement locale (v41) | ✅ **livré** — table, backfill identité, modèle |
> | F2′ · `tenders[]` dans le `PaymentDelta` | 🟡 **débloqué** — le back le porte depuis le 01/09 |
> | F3 · le chemin d'écriture + la seconde garde | ✅ **livré** — local ET fil : `payment.tenders[]` part sur chaque versement, identité comprise, avec l'uuid client de la ligne locale |
> | F3′ · la boutique | ✅ **livré** — v42, `tenders[]` sur le fil, choix de devise par devise du panier |
> | F4 · le ticket thermique | ✅ **livré** — perçu, taux, répartition dérivée, avance en devise reçue |
> | F5 · l'écran caisse | ✅ **livré** — `encaisse[]` + `impute[]`, aucune voie de secours |
> | F6 · la divergence de taux | 🟡 **débloqué** — `RATE_DIVERGENCE` et son `fee_code` nullable sont au contrat |
> | F7 · les surfaces de relecture | ⏸ — |
>
> ### Le canal du taux — tranché le 2026-09-02
>
> Le back a déclaré **un flux à lui** : `finance.exchange-rates`, `SyncMode.BUNDLE`,
> scope école, propriété `finance.grid.read`, endpoint
> `GET /api/v1/sync/exchange-rates`, **entraîné par les droits d'ÉCRITURE des
> deux caisses** (`finance.payment.write`, `boutique.sale.write`) — parce qu'un
> poste qui encaisse sans connaître le taux publié en invente un, et se voit
> ensuite reprocher une anomalie sur chaque encaissement pris de bonne foi.
>
> Ni keyset ni section du socle référentiel : le socle est gelé sur la saison et
> n'a pas d'ETag, alors qu'un taux bouge dans la journée. L'y loger ferait
> retélécharger deux années de cycles et de tarifs pour rafraîchir un nombre.
>
> **Côté front** : réponse **enveloppée** (`{points, serverTime}` — une lecture à
> plat rendrait une série vide en silence), `ETag` mémorisé **par école** et
> renvoyé en `If-None-Match`, **304 qui ne purge rien**, et repli de résolution
> sur le point le plus ancien quand l'horloge de la tablette retarde (sans quoi
> elle n'aurait plus aucun taux alors qu'elle vient d'en recevoir la série).
>
> ⚠️ **Deux défauts APRÈS la réception, trouvés sur un appel réel** — le pull
> marchait, l'écran mentait :
> 1. `ExchangeRatesCubit` lisait le cache **une seule fois**, au montage, alors
>    que le pull part au même instant et écrit après. La série restait vide pour
>    toute la durée de l'écran. Il est maintenant abonné au `PullCompletionBus`.
> 2. « Aucun taux paramétré » se mesurait sur les **conversions en cours** et non
>    sur les **taux disponibles** : le message s'affichait dès qu'un frais était
>    coché, taux ou pas.

---

## 0. La provenance des encaissements — contrat du 2026-09-04

> Migrations back **V118 · V119 · V120**, branche `fix/finance-outstanding-per-charge`,
> **commité, pas encore déployé.** Audit front fait le 2026-09-04.

Le serveur distingue désormais ce que le guichet a **dit** avoir pris de ce
qu'il a **supposé** faute de déclaration. Chaque ligne de `tenders[]` qui
redescend porte un `source` : `DECLARED` (un poste l'a dit — une observation) ou
`DERIVED` (personne ne l'a dit, le serveur a posé l'identité). **Tout
l'historique est marqué `DERIVED`**, la seule valeur qui ne prétend rien.

Ce qui rendait ce champ nécessaire vaut d'être retenu : ne rien déclarer était
la voie la **moins risquée** pour qui pourrait empocher un écart de change. La
caisse annonçait « encaissé en dollars » sans que personne l'ait vu, et le
contrôle de taux, qui ne sait juger qu'une conversion déclarée, ne se
déclenchait jamais sur un poste silencieux.

### Ce qui ne nous touche pas — vérifié, pas supposé

- **`motif` gagne `RATE_DIVERGENCE` et `TENDER_UNDECLARED`** sur
  `GET /finance/arbitrages/payments`. L'app **n'appelle jamais cet endpoint** :
  aucune constante, aucun client. Sa propre liste d'anomalies vient de l'**ACK
  du push** (`OverpaymentSignal`), pas de là. Et `PaymentAnomalyKind.fromDbValue`
  retombe déjà sur `unknown` — aucun `enum.byName()` strict à faire lever.
- **`anomalyType` gagne `TENDER_UNDECLARED`** sur `GET /boutique/sales/anomalies`.
  L'URL existe dans `AppConstants` mais **rien ne l'appelle** (« écran de
  contrôle, hors V1 »). Pas de parseur à casser.
- **`source` est additif** : les DTO de pull ignorent les clés inconnues.

⚠️ **`excessInCents` n'est plus toujours strictement positif.** Sur les deux
faits du contrôle des encaissements il vaut `0` quand le fait n'est pas
chiffrable — deux taux dans un même versement, un taux appliqué sans taux
publié, rien de déclaré. **Zéro veut dire « il y a quelque chose à instruire »,
jamais « rien ne manque »** : le jour où un écran lira les arbitrages, un filtre
`> 0` ferait disparaître exactement les cas à regarder. Le bandeau local, lui,
ne filtre pas dessus (vérifié) — il lit l'ACK, dont le trop-perçu reste positif.

### Ce que le back attend de nous — et où on en est

**Déclarer `tenders` sur les deux POST, y compris quand l'argent est entré dans
la devise de ce qu'il éteint.** C'est la déclaration qui transforme la ligne en
observation. ✅ **Tenu des deux côtés pour tout acte neuf** : au guichet
`draft.tenders ?? TenderComposition.identityFor(...)`, en boutique
`settlement.tendersFor(...)` compose la ligne d'identité même en mono-devise.
Un test épingle désormais l'identité **sur le fil** de chaque chemin — le test
voisin n'éprouvait que la table locale, ce qui n'est pas la même promesse.

Reste un trou **assumé** : une entrée d'outbox mise en file *avant* ce champ
part encore sans `tenders`, donc `DERIVED`. La refuser la ferait basculer en
`failed` — issue terminale sur du cash déjà encaissé.

**Les deux refus de la déclaration** sont nommés dans les deux catalogues
(`FinanceErrorCodes`, `BoutiqueErrorCodes`) et classés **défauts de
composition** : jamais transitoires, donc jamais rejoués jusqu'au poison.

- `422 TENDER_SUM_MISMATCH` — le perçu déclaré, converti, n'éteint pas ce qui est
  dû. Vérifié **par devise pivot**, à une unité d'affichage près (1 FC, 0,01 $) :
  un excédent sur un pivot ne compense pas un manque sur un autre.
- `422 UNKNOWN_TENDER_PIVOT` — le pivot déclaré n'est soldé par aucune imputation
  du versement, ni par aucune ligne du panier.

`TenderComposition.check` existe pour que ces deux-là n'arrivent jamais jusqu'au
serveur : s'ils tombent, c'est que le fail-fast local a un trou.

### `source` en base — DIFFÉRÉ, décidé le 2026-09-04

Le champ **n'est pas porté** dans `payment_tenders` : ni migration, ni règle
d'affichage. Arbitrage du user.

Ce qui rouvrira la question : le ticket thermique **somme la table locale**.
Réimprimer un versement redescendu du serveur imprimerait donc un `DERIVED` —
un postulat du serveur — comme un constat de comptoir, faux dès qu'un parent a
réglé en francs une créance en dollars. Tant qu'aucun écran ne montre le perçu
d'un versement **ancien**, la dette dort. Le jour où l'un le fera, il faudra la
colonne, le pull qui la lit, et la règle qui tait une ligne dérivée au lieu de
la présenter comme observée.

### Le levier, et le calendrier

Le contrôle **ne s'arme que là où l'école publie un taux de guichet** — pas
d'interrupteur par école. Au 2026-09-04, base de dev : **2 écoles** publient un
taux, et `payment_tenders` compte 17 608 lignes, **dont aucune déclarée par un
client**. L'app déclarant déjà pour tout acte neuf, le déploiement n'attend rien
de nous.

---

## 1. Ce que le back ajoute

Un encaissement répond aujourd'hui à **une** question — « combien de sa dette
a-t-il éteint ? » — et y répond dans la devise de la créance. La V2 en ouvre une
seconde, dans une autre unité : « qu'est-ce qui est entré dans le tiroir ? ».

| | Imputation | Perçu |
|---|---|---|
| Question | combien de dette éteinte | ce qui est entré dans le tiroir |
| Unité | devise de la **créance** | devise **reçue** |
| Porteur | `PaymentAllocation` | `PaymentTender` *(neuf)* |
| Écran | `/finance-stats/recovery` | `/finance-stats/till` |
| État | complet, ne bouge pas | n'existe pas |

`payment_tenders` se pose **à côté** de `payment_allocations`, à la même
profondeur : une **liste**, jamais un scalaire.

| Colonne | Ce qu'elle porte |
|---|---|
| `amount_in_cents` | le **net conservé**, jamais le montant présenté |
| `currency` | la devise **reçue** |
| `rate` | `numeric(18,6)`, le taux de guichet **gelé**. `1` quand perçu = imputé |
| `pivot_currency` | la devise contre laquelle le taux s'applique |

Quatre règles qui gouvernent tout ce qui suit :

1. **L'invariant.** `Σ(tender ÷ rate)` par pivot `==` `Σ(allocation)` par devise.
   Tolérance = **une unité d'affichage de la devise reçue** (1 FC, 0,01 $).
2. **Le lien allocation ↔ tender est dérivé, jamais stocké.** Un versement de
   112 000 FC qui solde 40 $ et 50 $ n'a pas comporté deux paquets de billets.
   La part en devise reçue de chaque poste est `allocation × taux`, recalculée à
   chaque impression, la dernière ligne absorbant le résidu d'arrondi.
3. **On découpe le tender quand l'unité ou le taux change, jamais quand seul le
   geste change.** Deux créances de devises différentes imposent deux lignes
   parce que les **pivots** diffèrent — c'est le modèle qui découpe, pas le
   payeur.
4. **Le tender est le net conservé.** 120 000 tendus, 5 000 rendus : on écrit
   115 000.

Les six arbitrages, tels qu'ils nous concernent :

| # | Décision | Ce que ça nous impose |
|---|---|---|
| 1 | une série `effective_from`, pas une valeur remplacée | F0 stocke une **série**, pas un scalaire |
| 2 | deux devises reçues permises serveur, **différées à la saisie** | l'UI ne propose **qu'une** devise de règlement |
| 3 | tolérance dans la devise **reçue**, une unité d'affichage | la garde de F3 compare **côté reçu** |
| 4 | rendu de monnaie dans une autre devise **interdit** en V2 | rien à faire — mais rien à ouvrir non plus |
| 5 | le taux pointe vers la **devise de la créance** | `pivot_currency` = devise de l'allocation |
| 6 | bande de tolérance en % par école, défaut 2 % | descend avec le taux (F0), sert à F6 |

---

## 2. Ce qui est déjà en place — ne pas le refaire

La bascule multi-devise a été payée il y a un mois (`MULTIDEVISE_PLAN.md`,
MD-0→MD-12, schéma v32→v35). Sont acquis :

- **`core/money/`** — `Money` (centimes entiers), `MoneyBag` (une entrée par
  devise, **aucun total scalaire**), `CurrencyCode.normalize` (jamais de rejet),
  `MoneyFormat` (décimales décidées sur la devise, « FC » à l'affichage).
- **`amounts[]`** sur le versement, de bout en bout : entité, modèle online,
  `PaymentInput` d'outbox, pull, ticket.
- **Les deux écrans sont déjà scindés** côté front comme côté serveur :
  `financeRecoveryStatsEndpoint` et `financeTillStatsEndpoint`.
- **Les tolérances de l'outbox.** `PaymentInput.fromJson` relit trois formes
  d'`amounts` ; `PaymentAggregateRequest.fromJson` relit la forme à plat comme
  l'imbriquée ; `feeTariffId` se lit en `String?`. Toutes pour la même raison :
  un refus au parse bascule en `failed`, issue **terminale**, sur du cash déjà
  encaissé et un ticket déjà imprimé.
- **`PaymentAnomalyKind.unknown`** — un motif servi par un serveur plus récent
  s'affiche au lieu de disparaître.
- **Le ticket thermique** existe, s'imprime en ESC/POS sur le matériel, et porte
  déjà un `MoneyBag`.

**Autrement dit : l'axe imputation est complet, l'axe perçu n'existe pas.** Le
même diagnostic qu'en face.

---

## 3. Les quatre angles morts

Aucun ne relève du contrat. Tous se déclenchent **avant** qu'une requête parte,
ou **après** qu'une réponse soit acceptée — là où le plan back n'a pas de vue.

### 1 · Rien ne contrôle le couple perçu/imputé, et la garde qui existe porte sur autre chose

`finance_offline_repository_impl.dart:82-96` pose un fail-fast local : le total
déclaré doit égaler la somme des imputations, **devise par devise**. Il est là
exprès, pour qu'un `ALLOCATION_SUM_MISMATCH` ne tombe pas sur du cash déjà reçu
et ne fige pas le versement en `SYNC_ERROR`.

**Cette garde reste juste après la V2, et il ne faut pas y toucher** :
`draft.amounts` porte l'**imputé** — la page d'encaissement le compose depuis
les montants saisis créance par créance, dans la devise de chaque créance. Elle
compare donc de l'imputé à de l'imputé, et un versement bi-devise ne la
contredit pas : elle ne le voit simplement pas passer.

Ce qui manque est une **seconde** garde, qui n'existe nulle part : l'invariant du
taux. Elle se pose **dans la devise reçue** —

```
pour chaque tender :
    attendu = Σ(allocation.amount × rate) sur les allocations de son pivot
    |tender.amount − attendu| ≤ toleranceCents(tender.currency)
```

`toleranceCents(c) = 10^(2 − MoneyFormat.decimalsOf(c))` — 100 centimes de franc
(= 1 FC), 1 cent de dollar. Comparer côté **pivot** obligerait à convertir la
tolérance elle-même, alors qu'elle est définie dans la devise reçue
(arbitrage 3).

⚠️ **C'est aussi ce qui rend la question 2 dangereuse au-delà de l'affichage.**
Si `amounts[]` devait porter le perçu, la garde existante refuserait **tout**
versement bi-devise en local, en `ValidationFailure`, sans qu'aucune requête ne
parte : un fail-fast conçu pour protéger de l'argent deviendrait ce qui l'empêche
d'être encaissé. La réponse à la question 2 décide donc de deux choses, pas
d'une.

### 2 · Le ticket a le défaut que le lot E6 corrige côté back

E6 corrige `RecuDePaiementCorps.montantsRecus`, nommé « reçus » et portant de
l'imputé. **`TicketReceiptModel.amountReceived` a exactement le même défaut, au
même mot** : il est alimenté par `payment.amounts`, c'est-à-dire l'imputation. Et
`advance` — la ligne « avance » imprimée quand le versement dépasse le dû — est
une soustraction entre `amountReceived` et `allocated`, donc dans la même unité.

Différence avec le reçu scellé : celui-ci **refusera de se rendre** quand
l'assertion tombera. Le ticket, lui, **s'imprimera faux**, dans les mains d'un
parent qui vient de poser des francs et lit « Montant reçu : 30,00 $ ».

`ticket_receipt_model.dart:140-198`.

### 3 · Un delta ne rétro-remplit rien

E1 écrit une ligne d'identité pour chaque paiement déjà en base **serveur**. Le
pull paiements est un delta par curseur : il ne redescend que ce qui bouge. Les
versements déjà en base **locale** ne seront donc jamais retouchés et n'auront
jamais de tender — sauf à rembobiner le curseur, ce qui rejouerait tout
l'historique.

Il faut le même backfill identité au palier de migration local. Sans lui, la
seule alternative est un `if null then allocations` à la lecture — exactement ce
qu'E1 s'interdit côté serveur, et pour la même raison : deux voies de lecture
divergent toujours une fois. Une réimpression de ticket, six mois plus tard, est
le moment où ça se verrait.

*Régression déjà payée sur `ref_cours` : un delta ne supprime ni ne comble.*

### 4 · `PaymentArbitrage` n'accueille pas `RATE_DIVERGENCE`, et n'est pas pull-ée

Lu dans le back, `PaymentArbitrage.java` :

- `fee_code` est **non nul** et typé `FeeCode` ;
- `excess_in_cents` est documenté « toujours strictement positif » ;
- `student_charge_id` est le seul champ optionnel ;
- sa javadoc dit : « **cette table n'est pas pull-ée par les tablettes** — le
  trop-perçu se règle côté administration, pas au guichet ».

Une divergence de taux n'a **ni poste de frais, ni excédent**. Et le seul canal
existant vers le guichet est le signal `overpayment` de la réponse de push
(`OverpaymentSignal`, `payment_push_response_models.dart:109`).

Deux conséquences à remonter au back : la table doit assouplir ces deux colonnes,
et le signal doit voyager **à côté d'`overpayment` dans la réponse d'ACK**, en
portant le **taux appliqué** et le **taux de référence** — sans quoi l'écran dira
« anomalie » sans pouvoir dire laquelle.

---

# Les lots

```
F0  le taux hors ligne (v40)          ← BLOQUÉ : question 1
 │
 ├── F1  paramétrage (Configuration)
 │
F2  payment_tenders local (v41) + backfill identité
 ├── F2′ tenders[] dans le PaymentDelta
 │
F3  chemin d'écriture + garde retournée   ← sans UI d'abord (taux 1)
 ├── F3′ la boutique
 │
F5  l'écran caisse lit deux blocs         ← la caisse cesse de mentir ICI
 │
F4  le ticket · F6  la divergence · puis l'UI de F3
 │
F7  les surfaces de relecture
```

**Le pari : F2, F3 sans UI et F5 avant toute saisie.** Ils rendent le rendu
**identique** tant que perçu = imputé — un taux 1 partout — donc les suites
existantes restent vertes et servent de filet.

---

## F0 · Le taux, hors ligne *(schéma v40)*

**Objectif.** Qu'une tablette sans réseau connaisse le taux que l'école a
paramétré, à la date du versement.

**Table locale** — `lib/core/database/schema/` :

```sql
CREATE TABLE ref_exchange_rates (
  id TEXT PRIMARY KEY,
  school_id TEXT NOT NULL,
  base TEXT NOT NULL,
  quote TEXT NOT NULL,
  rate_micros INTEGER NOT NULL,
  effective_from TEXT NOT NULL,
  set_by TEXT,
  divergence_band_bp INTEGER
)
```

**Points de conception non négociables.**

- **`rate_micros`, entier, jamais un `REAL`.** Le serveur stocke
  `numeric(18,6)` : six décimales, c'est exactement une micro-unité. Un `double`
  qui traverserait la couche métier finirait par arrondir de l'argent — c'est
  déjà la règle de `Money`, elle vaut ici.
- **La conversion se fait en centimes des deux côtés**, ce qui rend le facteur
  identique : `centsReçus = centsCréance × rate`. Vérification sur l'exemple du
  plan back : 30,00 $ = `3000` cents ; `3000 × 1 666,67 = 5 000 010` centimes de
  franc = **50 000,10 FC**, ce qui est bien le chiffre que l'arbitrage 3 cite.
  En entiers : `(centsPivot × rateMicros) ~/ 1000000`, arrondi **half-up
  explicite**, jamais la troncature implicite de `~/`.
- **`school_id` n'est pas décoratif.** Dix flux portent déjà un curseur non
  scopé sur cette base ; un taux d'une école servi à la tablette d'une autre est
  un défaut d'argent, pas d'affichage.
- **Une série, pas une valeur.** On résout « le taux qui vaut à `paidAt` », pas
  « le taux courant » : un versement encaissé hors ligne remonte parfois trois
  jours plus tard.
- `divergence_band_bp` (points de base, défaut 200 = 2 %) descend avec le taux —
  arbitrage 6 — et sert à F6.

**Résolveur pur** — `lib/core/money/exchange_rate.dart`, à côté de `Money` et
non dans `features/finance` : la boutique en aura besoin et ne peut pas importer
finance.

```dart
final class ExchangeRate { final int rateMicros; final String base, quote; … }
abstract final class ExchangeRates {
  static ExchangeRate? at(List<ExchangeRate>, DateTime paidAt);
  static int convertCents(int cents, ExchangeRate r);   // half-up
}
```

**Une lecture ne remonte jamais d'erreur.** Pas de taux pour la paire ⇒ `null`,
jamais une exception : l'écran taira la bascule de devise plutôt que d'afficher
un 1 par défaut, qui écrirait un tender faux.

**Tests.** `test/core/money/exchange_rate_test.dart` — résolution à la borne
exacte de `effective_from`, série non triée en entrée, taux absent, arrondi
half-up sur `x,5`, l'exemple 30,00 $ → 50 000,10 FC, et le sens inverse.

**Fini quand** la table existe, le résolveur est testé, et rien ne l'utilise.

---

## F1 · Le paramétrage, dans Configuration

**Objectif.** Que la direction pose le taux, en ligne.

**Où.** `lib/features/configuration/` — page de réglages, à côté des autres
paramètres d'établissement. **Aucune outbox** : changer un taux n'est pas un
geste de guichet, et un taux mis en file serait un taux appliqué avant d'exister.

**Points de conception non négociables.**

- **Tri-état `null` ≠ `[]`.** Le bundle référentiel caviarde par permission, et
  sa convention est écrite dans `ReferentialBundle.java` : `null` = « pas
  communiqué », `[]` = « cette école n'en a pas ». Les confondre ferait dire
  « aucun taux » à un caissier qui n'a simplement pas le droit de le voir — et
  il inventerait le sien. Le tri-état a déjà été payé une fois sur les
  permissions de session.
- **Deux décimales à la saisie.** Voir F3 · décision d'interface n° 3.

**Fini quand** un taux posé sur l'écran de configuration est lu par le résolveur
de F0 après un pull.

---

## F2 · La ligne d'encaissement locale *(schéma v41)*

**Objectif.** Que le local sache porter un perçu, pour tout paiement — y compris
ceux qui existent déjà.

**Table locale** — miroir de `payment_allocations`, append-only, donc **sans
`version`** :

```sql
CREATE TABLE payment_tenders (
  id TEXT PRIMARY KEY,
  client_uuid TEXT NOT NULL,
  payment_id TEXT NOT NULL,
  amount_in_cents INTEGER NOT NULL,
  currency TEXT NOT NULL,
  rate_micros INTEGER NOT NULL,
  pivot_currency TEXT NOT NULL
)
```

**Backfill identité, dans le même palier** — perçu = imputé, `rate_micros`
= 1 000 000, `pivot_currency = currency`, une ligne par `(payment_id, currency)`
agrégée depuis `payment_allocations`.

**Points de conception non négociables.**

- **Aucun repli à la lecture.** Après ce palier, `payment_tenders` est la seule
  voie ; jamais un `if null then payment_allocations` (angle mort n° 3).
- **Le palier se fige à sa date.** Il ne lit `payment_allocations` que telle
  qu'elle est à v41. Écrire un palier avec l'index d'aujourd'hui sur la table
  d'alors a déjà cassé toute base montant d'une version antérieure
  (`INSCRIPTION_INTAKE_PLAN.md`).
- **Backfill idempotent** : `INSERT … SELECT … WHERE NOT EXISTS`, jamais
  `INSERT OR REPLACE` — la paire index unique + `OR REPLACE` est une destruction
  silencieuse, déjà payée une fois.

**Tests.** Migration v39→v41 sur une base peuplée (paiements mono-devise,
multi-devise, sans allocation), rejeu du palier, et une lecture qui ne retombe
jamais sur les allocations.

---

## F2′ · `tenders[]` dans le `PaymentDelta`

**Objectif.** Que le versement encaissé à l'autre guichet arrive complet.

`PaymentPullTenderDto` à côté de `PaymentPullAllocationDto`
(`finance_pull_models.dart:229`), et `PaymentDeltaDto.tenders`.

**Point de conception non négociable.** **Tolérance obligatoire** : un delta sans
`tenders` — serveur pas encore à jour, paiement d'avant E1 — ne doit pas faire
tomber le lot. C'est la règle déjà écrite dans `CurrencyCode`, et pour la même
raison : sinon de l'argent déjà encaissé devient invisible au pull, sur des
tablettes qu'on ne met pas à jour à la demande.

**Tests.** Depuis du **JSON brut** : `tenders` absent, `[]`, devise inconnue,
`rate` absent. Une fixture construite en Dart n'exerce jamais `fromJson` — piège
déjà payé sur la multi-devise.

---

## F3 · Le chemin d'écriture, et la garde retournée

**Objectif.** Écrire le perçu en local, l'émettre sur les deux chemins, et poser
l'invariant du taux.

**Ce qu'on touche.**

| Fichier | Changement |
|---|---|
| `finance_offline_repository.dart` | `TenderDraft`, `RecordPaymentDraft.tenders` (nullable ⇒ identité) |
| `finance_offline_repository_impl.dart` | la **seconde** garde (angle mort n° 1), à côté de celle qui existe |
| `payment_push_request_models.dart` | `PaymentInput.tenders` + `fromJson` **tolérant à l'absence** |
| `create_payment_request_model.dart` | `tenders[]` sur le chemin direct |
| `payment_local_model.dart`, DAO | écriture de la table de F2 |

**Points de conception non négociables.**

- **Les tenders se composent par pivot, pas par geste.** Un règlement unique en
  francs qui solde une créance en dollars et une en francs produit **deux**
  lignes : le modèle l'impose (règle 3 du §1), le caissier n'a rien décidé. Il ne
  doit donc rien avoir à saisir de plus.
- **`tenders` absent au parse ⇒ identité, jamais un refus.** L'outbox d'une
  tablette mise à jour hors ligne porte encore des versements écrits par la
  version précédente. Ce parseur tolère déjà trois formes d'`amounts` pour cette
  raison exacte.
- **`amounts[]` reste l'imputé** (question 2). Si le back en changeait le sens,
  la ligne de paiement, le ticket et l'historique changeraient de sens **sans
  qu'une seule ligne de code ne bouge**.
- **On envoie `rate` explicitement**, même quand le serveur saurait le résoudre :
  c'est le chiffre imprimé sur le papier remis au parent, il ne se re-résout pas.
- **On envoie `tenders` TOUJOURS, l'identité comprise.** Se taire n'est pas
  neutre : le serveur écrit alors l'identité, c'est-à-dire qu'il consigne des
  DOLLARS dans un tiroir qui n'a vu que des francs. La caisse du jour, la
  divergence de taux et le second poste lisent tous cette affirmation-là.
- **Chaque ligne poussée porte l'uuid de la ligne LOCALE.** Le serveur honore cet
  id comme celui de l'allocation ; sans lui il en invente un, le pull redescend
  la ligne sous CET id, et l'upsert — qui apparie par id — l'INSÈRE à côté de la
  nôtre. Le versement se relirait avec deux fois ce qui est entré dans le
  tiroir, et le ticket, qui somme cette table, l'imprimerait.

**Deux temps.** D'abord **sans UI** : taux 1 partout, perçu = imputé, le format
part sur le fil et s'exerce en production sur du trafic réel. L'UI n'ouvre
qu'après F5 (voir §4).

**Tests.** La garde : mono-devise inchangée (l'identité passe sans arithmétique),
bi-devise juste accepté, écart d'une unité d'affichage accepté, écart de deux
refusé, tolérance en FC ≠ tolérance en $, pivot imputé sans tender refusé. Plus
une **mutation** sur `displayUnitInCents` — un test de rendu ne couvre pas la
projection qui l'alimente.

---

## F3′ · La boutique

**Objectif.** Que la moitié boutique de la caisse ne redevienne pas fausse.

`boutique_sale_tenders` en miroir, le panier compose ses tenders par pivot avec
le **même** résolveur de `core/money` — deux implémentations de la même règle
divergent toujours une fois. Le panier calcule déjà ses `totals` en `MoneyBag`
par devise d'article ; le pivot en découle.

---

## F4 · Le ticket dit ce qu'il a reçu

**Objectif.** Que le papier remis au parent porte le perçu, le taux, et une
répartition recomptable.

**Ce qu'on touche** — `ticket_receipt_model.dart`, `ticket_text_layout.dart`,
`esc_pos_ticket_renderer.dart`, `pdf_ticket_renderer.dart`, + `app_fr.arb` /
`app_en.arb`.

- `amountReceived` prend les **tenders** ; `amountImputed` apparaît à côté ;
- le **taux** s'imprime, une ligne par pivot ;
- chaque poste porte sa valeur dérivée `allocation × taux` ;
- `advance` se calcule **en devise reçue**.

**Point de mise en page.** Le gabarit fait 48 colonnes (80 mm) et **32 en
58 mm** : une ligne « libellé + montant » y occupe déjà toute la largeur. La
valeur dérivée passe donc **sous** le libellé, alignée à droite, jamais dans une
troisième colonne.

**Le reçu scellé est un PDF produit par le serveur** : rien à faire ici. Mais les
deux pièces coexistent dans les mains du même parent et doivent tomber sur les
mêmes chiffres — d'où la question 4.

**Livré le 2026-09-01.** Trois décisions prises en écrivant :

- **`amountReceived` n'est plus posable à la main** — c'est un getter sur
  `tenders`. Le défaut était qu'un champ nommé « reçu » acceptait de l'imputé ;
  le rendre dérivé rend l'erreur impossible plutôt que déconseillée, comme
  `MoneyBag` rend impossible le total scalaire.
- **Le taux ne s'imprime pas quand perçu = imputé.** Un « 1,00 » sur un
  règlement ordinaire ferait chercher au parent ce qui a été converti. Et sur
  32 colonnes (58 mm), la paire « FC / $ » cède la place au seul nombre : c'est
  lui qui compte.
- **Aucune dérivée quand deux règlements de devises différentes visent le même
  pivot.** Le modèle l'autorise, la saisie ne le produit pas, et imprimer l'une
  des deux conversions ferait recompter le parent sur un chiffre qui n'explique
  que la moitié de la ligne.

---

## F5 · L'écran caisse lit deux blocs *(rupture)*

**Objectif.** Que « encaissé » cesse de désigner de l'imputé.

`encaisse[]` (total, frais, boutique, buckets, par devise **reçue**) et
`impute[]` (`byFeeCode`, par devise de **créance**) remplacent `byCurrency[]`.
Touche `finance_till_response_model/`, `finance_till_kpi_band.dart`,
`finance_till_fee_code_section.dart`, `finance_till_success_view.dart`, et les
entités miroir.

**Point de conception non négociable.** Le danger n'est pas le travail, il est
dans le silence : `byCurrency` absent retombe sur `?? const []` et la vue rend
son **état vide** — « aucun mouvement aujourd'hui », à un caissier qui a le
tiroir plein. Les trois montants du résumé lèvent, eux, délibérément, mais on ne
les atteint jamais. La même tolérance a masqué cinq noms devinés faux sur les
réductions, tous silencieux.

⇒ **Un test qui rougit si les deux clés manquent.** Et jamais de repli
`encaisse ?? byCurrency` conservé au-delà de la bascule : ce serait les deux
voies de lecture qu'E1 s'interdit en face.

**Règle d'affichage.** Les deux blocs ne s'additionnent jamais. La bande KPI
garde ses trois cartes en devise **reçue** ; la ventilation par poste descend
sous un titre qui dit explicitement qu'elle est dans une autre unité.

---

## F6 · La divergence de taux

**Objectif.** La voir **avant** que l'argent parte, et la relire après.

- `PaymentAnomalyKind.rateDivergence` à côté d'`overpayment`. Le repli
  `unknown` existe déjà : rien ne casse en attendant, mais l'alerte reste sans
  libellé.
- **Le même contrôle se pose au guichet**, sous le champ de taux : au-delà de la
  bande (F0), un avertissement en ligne, **jamais un blocage**. L'arbitrage
  ADR-013 vaut ici mot pour mot — on n'échoue pas un encaissement déjà pris. Une
  fois le versement passé, l'arbitrage ne fait plus que constater ; sous le
  champ, il se corrige devant le parent.

**Ce lot attend le contrat, et ne devine aucun nom.** Cinq noms devinés faux sur
les réductions ont tous été **silencieux**, masqués par la tolérance « section
absente = non-événement ». Les colonnes locales de l'anomalie ne se posent
qu'après la réponse à la question 5.

---

## F7 · Les surfaces qui relisent un versement

`facturation_payment_line.dart`, `facturation_payment_detail_dialog.dart`,
`facturation_payment_detail_allocations_table.dart` affichent aujourd'hui
`payment.amounts`. Elles gagnent le **perçu en tête, l'imputé en second** —
l'ordre du guichet. Petit lot, mais sans lui un versement encaissé en francs se
relit en dollars sur la fiche de l'élève le lendemain.

---

## 4. L'ordre de bascule

Le plan back note « E4 = rupture front » et s'arrête là. Il ne peut pas ordonner
ce qui suit, et c'est pourtant ce qui empêche de fabriquer soi-même
l'incohérence : **tant que `/till` agrège sur la devise de la créance, le premier
franc encaissé contre un dollar rend l'écran caisse faux.**

1. **F0, F1, F2, F2′** — le taux descend, la table locale existe, l'historique
   est comblé. Rien ne change à l'écran.
2. **F3 sans UI** — le format part sur le fil avec un taux 1. Perçu = imputé pour
   tout le monde, contrat exercé sur du trafic réel.
3. **F5** — l'écran caisse sait lire les tenders. *C'est ici que la caisse cesse
   de mentir*, et c'est le préalable à toute saisie.
4. **F4, F6, puis l'UI de F3** — le ticket sait imprimer le taux, le contrôle est
   en place, et seulement alors la bascule de devise apparaît au guichet.
5. **F7** — sans urgence.

---

## 5. Le guichet — six décisions d'interface

La page d'encaissement demande aujourd'hui « combien impute-t-on sur chaque
créance ». Le geste réel est l'inverse : le parent pose des billets, le caissier
décide ensuite. **On ne retourne pourtant pas la saisie en V2** — répartir
automatiquement un perçu, c'est la proration que le plan back refuse de stocker,
remontée d'un cran dans l'interface ; et l'arbitrage 2 diffère déjà la saisie
multi-devise. La page garde son sens et gagne **un seul contrôle neuf**.

1. **Une bascule, jamais deux champs reliés par un « ou ».** La devise de
   règlement est un **mode**, comme la recherche bi-mode (règle non négociable
   n° 12) : on choisit l'un, seuls ses critères partent.
2. **Le taux est proposé, jamais inventé.** Rempli depuis le référentiel, en
   lecture, avec un « Modifier » explicite. Un taux absent du référentiel
   **éteint la bascule et dit pourquoi** — il n'ouvre pas un champ vide.
3. **Deux décimales à la saisie, pas six.** La colonne stocke `numeric(18,6)`,
   le ticket imprime le taux, le parent recompte. Si l'affichage arrondit ce qui
   est stocké, il ne retombe pas sur son total. Contraindre la saisie au
   centième rend l'imprimé et le stocké identiques par construction, sans rien
   perdre : un taux de guichet est un chiffre rond.
4. **La barre basse porte le perçu en grand, l'imputé en petit.** C'est la
   hiérarchie du métier : le caissier compte des billets, la comptabilité lit
   l'imputation. Le même couple, dans le même ordre, sur la popin de
   confirmation et sur le ticket.
5. **L'écart de taux se dit sous le champ, en ligne, sans bloquer** (F6).
6. **Le cas courant ne coûte rien.** Devise de règlement = devise de la créance
   par défaut, taux 1, aucun champ ni ligne de plus : l'écran d'aujourd'hui à
   l'identique. La ligne de taux et la valeur dérivée n'apparaissent que lorsque
   les unités divergent — au moment précis où le caissier a besoin de les voir.

**Hors périmètre V2**, comme côté serveur : pas de saisie « le parent a tendu X,
répartis », pas de rendu de monnaie dans une autre devise, pas de fond de caisse
ni de comptage du soir. Chacune demande une ligne négative ou une session de
caisse — c'est-à-dire la V3.

---


### Livré le 2026-09-01 — lots U1 à U4

| Lot | Ce qui tourne |
|---|---|
| U1 | `FacturationSettlement` — objet pur : options de règlement, taux, conversion, composition des tenders, contrôle de divergence |
| U2 | `getExchangeRates` (repo, usecase, DI) + `ExchangeRatesCubit`, chargé au montage |
| U3 | `FacturationSettlementSection` — la bascule, la ligne de taux, l'avertissement |
| U4 | La dérivée par ligne de frais, la barre basse à deux niveaux, la popin de confirmation |

**Quatre décisions prises en écrivant, qu'aucune ne figurait dans le plan :**

- **La vue ne lit pas le cubit, elle reçoit la série.** Monter
  `FacturationCreatePaymentView` sur un `context.watch` aurait cassé les vingt-six
  tests qui l'instancient seule. Le paramètre `rates` par défaut vide dit la même
  chose que la réalité : sans taux, l'écran d'avant.
- **« Converti » n'est pas « une devise a été choisie ».** Régler en dollars des
  créances en dollars n'est pas une conversion, et la barre annonçait « À
  percevoir » sur un versement où rien n'avait bougé d'unité. Le prédicat porte
  sur *un taux s'applique quelque part*.
- **Le repli « chaque frais » devient un segment explicite dès qu'il y a
  plusieurs devises de créance.** Sur un seul pivot, le repli porte déjà un nom :
  la devise de ce pivot. Sur deux, il n'en a aucun — et sans segment pour le
  représenter, un caissier qui a converti par erreur n'avait aucun moyen de
  revenir en arrière.
- **La mise en forme du taux vit sur `ExchangeRate.formatted()`.** Elle avait été
  écrite deux fois — une pour le ticket, une pour l'écran. Deux copies auraient
  divergé au premier ajustement, et le parent aurait lu deux taux pour un seul
  versement.

**Ce que l'UI ne peut pas encore faire, et pourquoi c'est voulu :** elle est
**dormante par construction**. La bascule ne s'allume que si `ref_exchange_rates`
porte un taux, et cette table reste vide tant que la question 1 n'est pas
tranchée. Rien ne peut donc rendre l'écran caisse faux avant que quelqu'un
paramètre un taux — moment où F5 devra être livré.

### Livré le 2026-09-02 — F5, l'écran caisse sur deux blocs

Le back a livré ses six lots le 01/09 au soir : les noms ne se devinent plus,
ils se lisent (`FinanceTillStatsResponse`, `TillImputationDto`,
`TillSummaryDto` sans `byFeeCode`). La bascule est donc franche.

| Couche | Ce qui change |
|---|---|
| Entités | `FinanceTill.byCurrency` → `encaisse` + `impute` · `TillSummary` perd `byFeeCode` · `TillImputation` neuve |
| Modèles | `TillImputationModel` neuf · `encaisse` **lève** si absent, `impute` cède à vide |
| Écran | les barres prennent la largeur du bloc de devise reçue ; la ventilation descend sous un titre qui nomme son unité |
| l10n | `financeTillImputationHeading` / `Hint` / `CardTitle` / `Total` / `SectionA11yLabel` · `financeTillSectionFeeCodes` et `financeTillFeeCodeSectionA11yLabel` **supprimées** (« frais encaissés » était devenu faux : c'est de l'imputé) |

**Trois décisions prises en écrivant :**

- **Aucune voie de lecture de secours, et un test qui l'épingle.** La fixture
  `tillLegacyByCurrencyJson` porte le corps d'hier, 90 000 FC bien réels : la
  lecture doit **lever**. Un `?? const []` en aurait fait « aucun mouvement
  aujourd'hui » devant un caissier au tiroir plein — et personne n'aurait su que
  le serveur était resté en arrière. ⇒ **l'écran caisse exige le back à jour**,
  c'est le prix assumé de la bascule.
- **La fixture nominale porte l'écart, exprès.** Le bloc USD d'`impute`
  (1 500,00 $) dépasse la moitié frais du bloc USD d'`encaisse` (1 000,00 $) :
  des créances en dollars réglées en francs. Toute tentative de recontrôler
  « imputé == frais encaissés » rougit — c'est précisément l'égalité que la
  bascule rend fausse.
- **Le total d'imputation ne se refabrique pas depuis ses lignes.** Il lève.
  Sommer les postes pour reconstituer le total masquerait le seul jour qui
  compte : celui où les deux divergent.

**Une lacune se voit au lieu de s'escamoter** : des frais entrés sans aucun bloc
d'imputation affichent la section avec son état vide, jamais rien du tout.

**Deux mutations prouvées** : tolérance rétablie sur `encaisse` (2 tests
rougissent), titre d'unité retiré de l'écran (3 tests rougissent).

### Livré le 2026-09-02 — le guichet par frais, puis la boutique

**Le choix de devise se pose sur la ligne, pas sur le versement.** La bascule
globale a été retirée : chaque frais coché demande « le parent règle en quoi ? »,
et quand la réponse change d'unité, la ligne montre **deux champs couplés** —
l'imputé et le reçu. Remplir l'un remplit l'autre, et le champ que le caissier
tape n'est jamais réécrit.

| | Guichet | Boutique |
|---|---|---|
| Où se pose la question | par **frais** | par **devise du panier** |
| Ce qui se saisit | l'imputé **et** le reçu | le reçu seul — le prix ne se négocie pas |
| L'écart d'arrondi | imputation calée au centime **inférieur**, le reste en monnaie à rendre | monnaie à rendre au-dessus du dû, **« Il manque X »** en dessous |

**Quatre décisions prises en écrivant :**

- **Le montant reçu ne peut pas être librement rond.** 50 000 FC à 2 800 valent
  17,857 $ : ni 17,85 ni 17,86 ne retombent sur 50 000, et le serveur n'admet
  qu'une unité d'écart. L'imputation se cale donc au centime inférieur et la
  différence **repart avec le parent** — c'est déjà la règle du contrat (« 120 000
  tendus, 5 000 rendus : on écrit 115 000 »), pas une invention.
- **Une vente boutique est comptant INTÉGRAL, et le guichet ne l'est pas.**
  `boutique_sales` n'a aucune colonne de reste : un client qui pose moins que le
  dû n'a pas payé, il ne « fait pas de monnaie ». Le tiroir garde donc toujours
  le prix converti, et l'écran dit ce qui manque. Copier le guichet aurait écrit
  des ventes à moitié payées qu'aucune colonne ne sait porter.
- **L'invariant local refusait un cas que le nouveau guichet rend possible.**
  Une même créance réglée moitié en francs moitié en dollars se comparait paire
  par paire. Elle se compare désormais **côté créance** dès qu'un pivot est
  réglé de deux façons — le seul régime où l'unité du serveur n'existe pas.
  ✅ **Répondu par le back le 2026-09-02, et le front est aligné dessus** :
  `Encaissements.exigerInvariant` compare **côté créance**, pivot par pivot, avec
  une tolérance **accumulée par ligne** — `max(1, versPivot(unité d'affichage de
  la devise reçue))`. Aucune unité reçue commune n'est nécessaire : l'écart naît
  dans la devise reçue, on l'y borne, chaque ligne le porte au pivot par SON
  taux. ⚠️ Un centime forfaitaire — ce que le front faisait — **refuse des
  versements que le serveur accepte** : une créance en francs réglée en dollars
  admet ~2 299 centimes de franc, pas 1 (cas P3-37 du cahier de recette).
- **Trois remontées au socle**, parce que la boutique en avait autant besoin :
  `core/money/tender_composition.dart` (l'invariant), `tender_settlement.dart`
  (le règlement par ligne, vocabulaire neutre), `local/exchange_rate_dao.dart` +
  `ExchangeRateReader` (le taux est un référentiel d'**école**).

**Cinq mutations prouvées** : plancher d'imputation remplacé par l'arrondi au
plus proche, champ source réécrit sous les doigts, lignes d'encaissement non
fusionnées par paire, tiroir qui garderait l'excédent d'une vente, règlement
orphelin survivant à la ligne supprimée.

## 6. Ce qu'on demande au back

### 1 · Par quel canal le taux descend-il sur une tablette hors ligne ? — ✅ **TRANCHÉE**

> **Réponse lue dans le back** (`ExchangeRateController`) : une route dédiée,
> `GET /api/v1/finance/exchange-rates`, sous `finance.grid.read`, qui sert la
> série complète. Le taux ne voyage dans **aucun** bundle ni delta : le front
> l'appelle lui-même (`ExchangeRateRemoteDataSource`, Dio direct) et remplace
> son cache local **en bloc, scopé école**. Pull enregistré avant les créances.

E0 décrit un CRUD direction, pas un flux de synchro. Un taux illisible sans
réseau rend E2, E3 et toute la saisie inatteignables là où elles servent.

Le bundle référentiel est l'endroit naturel : `ReferentialBundle` porte déjà
`school` et `reductions` **à la racine**, hors slot d'année, avec exactement
l'argument qui vaut ici — « une politique d'établissement, pas un prix de
saison ».

⇒ **`exchangeRates[]` à la racine du bundle, en série `effectiveFrom`.**
Sous-question : le bundle sert-il la **série complète** ou le seul taux courant ?
Les tables de cache sont réécrites en bloc par le pull ; un serveur qui ne
servirait que le courant effacerait l'historique, et un versement offline daté ne
se résoudrait plus.

### 2 · Le sens d'`amounts[]` change-t-il ?

Il porte aujourd'hui l'imputé, vérifié devise par devise contre les allocations,
et alimente ici la ligne de paiement, le ticket et l'historique. S'il devenait le
perçu, ces trois surfaces changeraient de sens **sans qu'une seule ligne de code
ne bouge** — la pire forme de rupture, celle qu'aucun test ne rougit.

⇒ **Le figer dans le contrat : `amounts[]` = imputé, les tenders portent le
perçu.**

### 3 · Que devient la clé `byCurrency` de `/till` ?

Renommée en `encaisse` sans transition, elle ne produit pas une erreur ici mais
un écran « aucun mouvement » (voir F5).

⇒ **Publier la forme exacte d'E4 avant de la servir.**

### 4 · Quelle règle exacte d'arrondi sur les montants dérivés poste par poste ?

Le ticket provisoire est composé localement, le reçu définitif est scellé par le
serveur, et le parent tient les deux. « La dernière ligne absorbe le résidu » ne
suffit pas à faire converger deux implémentations : il faut **le sens de
l'arrondi** et **l'ordre de tri** qui désigne cette dernière ligne.

### 5 · Que porte une ligne `RATE_DIVERGENCE`, et par où arrive-t-elle ? — *lu dans le back*

Voir angle mort n° 4 : `fee_code` non nul, `excess_in_cents` strictement positif,
table non pull-ée. ⇒ assouplir les deux colonnes, et faire voyager le signal à
côté d'`overpayment` dans la réponse d'ACK, avec **taux appliqué** et **taux de
référence**.

### 6 · Le taux est-il résolu à `paidAt` ou à l'instant du push ? — *déjà tranché*

L'arbitrage 1 répond : « on lit celui qui vaut à `paidAt` ». Le front enverra
malgré tout `rate` explicitement dès F3 — c'est le chiffre imprimé sur le papier.

---

## 7. Rappels qui ne se négocient pas

- **Un test de rendu ne couvre pas la projection qui l'alimente.** Le dérivé
  `allocation × taux` s'affiche à trois endroits ; c'est la fonction de calcul
  qu'il faut tester et muter, pas les trois widgets.
- **Une fixture construite en Dart n'exerce jamais `fromJson`.** Les tolérances
  de F2′ et F3 ne valent que testées depuis du JSON brut.
- **Le grand-livre local porte des devises vides**, et une lecture ne remonte
  jamais d'erreur : le résolveur rend « pas de taux » sans lever.
- **Un bloc né dans `setUp` ne dénoue pas ses futures sous `pump()`** →
  `runAsync`. Les tests de la page d'encaissement le font déjà.
- **`AppPageBackground` plafonne à 1180 px** : tout seuil responsive au-dessus
  rend la disposition large inatteignable.
- Checklist de `CLAUDE.md` : `flutter analyze` clean, `flutter test` vert,
  `build_runner` si modèle/Retrofit, strings dans **les deux** `.arb` +
  `gen-l10n` **puis `dart format lib/l10n/`**, chaque `Failure` mappée.

---

## 8. Volume

| Lot | Fichiers | Tests | Palier |
|---|---|---|---|
| F0 | ~4 créés, 2 touchés | ~15 | v40 |
| F1 | ~5 | ~10 | — |
| F2 + F2′ | ~6 | ~20 | v41 |
| F3 + F3′ | ~10 touchés | ~35 | — |
| F4 | ~6 touchés | ~15 | — |
| F5 | ~10 touchés | ~20 | — |
| F6 | ~6 | ~12 | (v42 ?) |
| F7 | ~3 touchés | ~8 | — |

Deux paliers de schéma sûrs (**v39 → v41**), un troisième conditionnel à la
réponse 5. Ordre de grandeur : **~135 tests**, à comparer aux 4 836 verts du
chantier multi-devise.
