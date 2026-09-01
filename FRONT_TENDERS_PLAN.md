# Le taux au guichet — plan front (perçu ≠ imputé)

> **Statut :** plan écrit le **2026-09-01**. **Tout ce qui ne dépend d'aucun nom
> de contrat est livré** — schéma local **v39 → v41**, 96 tests neufs,
> **suite complète 5 330 verts**, `flutter analyze` clean sur tout l'arbre.
> Non commité.
>
> | Lot | État |
> |---|---|
> | F0 · le taux hors ligne (v40) | ✅ socle, table et DAO livrés · ⛔ **le remplissage attend la question 1** |
> | F1 · le paramétrage (Configuration) | ⏸ attend E0 |
> | F2 · la ligne d'encaissement locale (v41) | ✅ **livré** — table, backfill identité, modèle |
> | F2′ · `tenders[]` dans le `PaymentDelta` | ⛔ **ne devine aucun nom** — attend E7 |
> | F3 · le chemin d'écriture + la seconde garde | ✅ **partie locale livrée** · ⛔ l'émission sur le fil attend E2 |
> | F3′ · la boutique | ⏸ attend E5 |
> | F4 · le ticket thermique | ✅ **livré** — perçu, taux, répartition dérivée, avance en devise reçue |
> | F5 · l'écran caisse | ⏸ attend E4 — **rupture de lecture** |
> | F6 · la divergence de taux | ⏸ attend E3 + le contrat du signal |
> | F7 · les surfaces de relecture | ⏸ — |
>
> **Ce qui est en place et tourne :** `core/money/exchange_rate.dart` (taux en
> micro-unités entières, série résolue à `paidAt`, conversion half-up en
> `BigInt`) · `MoneyFormat.displayUnitInCents` (la tolérance de l'invariant) ·
> `ref_exchange_rates` (v40) et son DAO scopé école · `payment_tenders` (v41)
> avec **backfill identité** de tout l'historique local ·
> `PaymentTenderComposition` (composition par pivot + l'invariant du taux) ·
> le chemin d'écriture qui écrit les deux listes en une transaction ·
> le **ticket thermique** qui imprime le perçu, le taux et la répartition
> dérivée, résidu absorbé par la dernière ligne.
>
> **Six mutations prouvées** : arrondi tronqué, tolérance uniforme, invariant
> désarmé, purge non scopée, résidu non absorbé, taux imprimé sur un règlement
> ordinaire — toutes rougissent.
>
> **Origine :** plan back « Perçu et imputé », lots E0→E7, six arbitrages
> tranchés le 01/09 — <https://claude.ai/code/artifact/b7f4b47c-1712-40fb-9da9-015e7315651c>.
> Version illustrée de ce plan-ci (maquettes de l'écran et du ticket) :
> <https://claude.ai/code/artifact/9b59cdc4-06d3-4a53-9729-e56ef3ae4a18>.
>
> **Docs de contexte :** `MULTIDEVISE_PLAN.md` (le socle `core/money` qu'on
> étend) · `FACTURATION_OFFLINE_PLAN.md` (le patron d'encaissement) ·
> `ENCAISSEMENT_TARIF_PLAN.md` (le dernier passage sur ce chemin d'écriture) ·
> `BOUTIQUE_PLAN.md` (la caisse jumelle) · `AGENTS.md` · `CLAUDE.md`.
>
> **Vérifié dans l'arbre** au 2026-09-01 sur `feat/configuration-provisioning`,
> schéma local **v39** ; back lu en local sur `fix/finance-outstanding-per-charge`
> (`~/my_project/eteelo-backend`).

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

## 6. Ce qu'on demande au back

### 1 · Par quel canal le taux descend-il sur une tablette hors ligne ? — **bloquant**

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
