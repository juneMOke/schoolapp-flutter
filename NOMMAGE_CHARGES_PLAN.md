# Nommer une créance — « libellé (code du tarif) »

> **Contrat back :** `FeeTariff.code` (V94), `FeeTariffSummaryDto`,
> `CreateFeeTariffCommand`, `ProvisioningRequest.FeeInput`.
>
> ✅ **Confronté au dépôt back en local** (`~/my_project/eteelo-backend`,
> `e674615`). Les noms de ce document sont **lus dans le code serveur**, pas
> devinés — la leçon d'ADR-021, où cinq noms inventés étaient faux et l'ont été
> silencieusement.
>
> 🔴 **Suite immédiate de `ENCAISSEMENT_TARIF_PLAN.md`** (FT-0→FT-6, dans
> l'arbre de travail, schéma v38). FT a appris au *push* à désigner la tranche ;
> il reste à l'apprendre à **l'œil du guichetier**. Sept tranches de minerval
> s'affichent aujourd'hui sept fois « Minerval », et la ligne qu'on coche ne se
> distingue de la suivante que par son montant.

**Décisions actées.**

| | |
|---|---|
| Format | **`libellé de la créance (code du tarif)`** — jamais la nature du frais |
| Code absent → parenthèse **masquée** | « Absent » couvre trois cas : créance *ad hoc* sans tarif ; tarif hors de cet appareil ; **et code égal à la nature** — le serveur écrit la nature par défaut, cette valeur ne distingue donc rien (piège 1) |
| Étape 6 du wizard | **Bornée à l'année du dossier**, dans les deux flux (brouillon ET consultation) |
| Périmètre | NC-0 → NC-6, plus la demande au back NC-7 |
| Saisie du code au paramétrage | **Hors périmètre**, et lourd de conséquences — cf. §5 |
| Contrôle des frais, statistiques | **Inchangés** : ils agrègent PAR NATURE, c'est voulu |

---

## 1. Ce que le serveur fait vraiment

`FeeTariff.code` (`@Column(name = "code", nullable = false, length = 32)`) :

> *Ce qui distingue deux lignes de même nature sur un niveau : « T1 » et « T2 »
> pour un minerval étalé, « INFO » et « BIBLI » pour deux frais scolaires
> distincts. […] Ce n'est pas la clé d'imputation d'un paiement : celle-ci est
> l'identifiant du tarif. `code` est ce que l'opérateur lit et saisit.*

Trois faits en découlent, et chacun décide d'un lot :

1. **Le code est facultatif à la saisie et jamais nul en base.**
   `FeeTariffService.codeOuDefaut` retombe sur `feeCode.name()`, normalisé en
   majuscules. Une grille simple retrouve ainsi l'unicité « un tarif par
   nature » qu'elle connaissait avant V94 — au prix d'un code qui ne dit rien.

2. **Le code descend déjà sur la tablette.** `FeeTariffSummaryDto.code` est dans
   `ReferentialYearBundle.feeTariffs`, peuplé par MapStruct. Le front ne le lit
   pas : `RefFeeTariffDto` ne le déclare pas, `ref_fee_tariffs` n'a pas la
   colonne, aucune des trois entités de tarif ne le porte.

3. **Le code n'est pas sur la créance.** Ni `StudentChargeDto` (pull
   `/sync/student-charges`) ni `StudentChargeRef` (ACK d'inscription) ne le
   portent — seulement `feeTariffId`. Le seul chemin front est donc une
   **jointure locale**, et NC-7 demande au back de la rendre facultative.

---

## 2. Ce qui est déjà en place — ne pas le refaire

| | |
|---|---|
| `student_charges.fee_tariff_id` | ✅ colonne, remplie au pull comme au semis |
| `payment_allocations.fee_tariff_id` | ✅ v38 (FT-0) |
| Semis d'une créance **par ligne de grille** | ✅ FT-4 |
| `chargeDesignation(charge, l10n)` | ✅ FT-6 — libellé, repli sur la nature. **C'est le point d'extension**, pas un nouveau helper |
| Encaissement : lignes + popin de confirmation | ✅ FT-6, déjà sur `chargeDesignation` |

**Ce qui manque tient en six trous :**

| # | Trou | Où |
|---|---|---|
| 1 | `ref_fee_tariffs` n'a pas de colonne `code` | schéma v39 |
| 2 | Le pull référentiel jette `code` | `RefFeeTariffDto` |
| 3 | La créance ne connaît pas le code de son tarif | `FinanceLedgerReadDao` |
| 4 | Trois écrans Facturation affichent la **nature** | 3 widgets |
| 5 | L'étape 6 affiche la nature, **et toutes les années** | 2 widgets + 1 bloc |
| 6 | Le ticket thermique imprime le libellé nu | `ProvisionalTicketDao` |

---

## 3. Les huit pièges

### 1 · Le code arrive **toujours renseigné**, même quand personne ne l'a saisi

`codeOuDefaut` écrit `TUITION` faute de mieux. Tester `code == null` ne suffit
donc pas : la parenthèse s'afficherait « Minerval (TUITION) » sur toute grille
simple, c'est-à-dire partout. **« Absent » se teste sur trois conditions** :
`null`, vide, ou strictement égal au `fee_code` de la créance.

### 2 · Le front ne sait pas **saisir** un code — et ne peut donc pas créer deux tranches

Ni `FeeTariffPayloadModel` (`POST`/`PUT /finance/tariffs`) ni
`ProvisioningRequestModel` n'émettent `code` — alors que `ProvisioningRequest`
l'accepte déjà (`@Size(max = 32)`, `[A-Za-z0-9_ -]+`). Sur une école paramétrée
depuis l'application :

- la deuxième tranche est **refusée** (`DuplicationResourceException` :
  « Un tarif « TUITION / TUITION » existe déjà sur ce niveau ») ;
- tous les codes valant la nature, la parenthèse ne s'affichera **jamais**.

⚠️ **Ce plan est donc juste et invisible** tant que les codes ne sont pas posés
(par le back-office, par SQL, ou par le lot hors périmètre du §5). Le vérifier
en recette sur une école qui en a, sinon on validera un écran inchangé.

### 3 · La jointure rate quand la grille n'est pas sur l'appareil

`ref_fee_tariffs` est un **cache référentiel** : caviardé pour qui n'a pas
`finance.grid.read` (ADR-014), purgé année par année par `replaceTariffsForYears`.
Une créance N-1 consultée après rotation du référentiel n'aura plus de tarif en
face. Repli sur le libellé seul — jamais d'erreur, jamais de parenthèse vide.
C'est exactement ce que NC-7 fait disparaître.

### 4 · `StudentCharge.feeTariffId` est **aplati en `''`**

`LocalStudentChargeToOnline` écrit `feeTariffId ?? ''` (piège 1 de FT). Joindre
en Dart sur l'entité online ne trouverait donc rien pour une créance *ad hoc*, et
personne ne le verrait. **La jointure se fait en SQL**, sur la colonne, avant le
mapper.

### 5 · Nommer les tranches sans les **ordonner** déplace le problème

`getChargesByStudent` trie `ORDER BY sc.fee_code ASC` : entre sept tranches d'une
même nature, l'ordre est celui que SQLite rend, c'est-à-dire l'ordre
d'insertion. Le guichetier lirait « 3/3, 1/3, 2/3 ». Même remarque sur
`getAllocationsByPayment` (`ORDER BY pa.fee_code`).

### 6 · Le popin de détail d'un frais s'ouvre **aussi par route**

`FacturationChargeDetailIntent.fromRouteContext` retombe sur `.invalid` quand
l'`extra` manque (deep-link, restauration). Les champs neufs y seront vides : la
désignation doit se replier sur la nature, comme le reste de la popin le fait
déjà pour l'identité.

### 7 · Le ticket est une **saisie gelée**, pas un calcul

`student_charge_label` est un champ du contrat serveur, figé à l'encaissement et
poussé tel quel. Y concaténer le code contaminerait le payload. La composition se
fait **à la projection**, par jointure sur `payment_allocations.fee_tariff_id`
(colonne v38, déjà là).

### 8 · La borne d'année ne doit pas écarter les créances à année `NULL`

`LocalStudentCharge.belongsToYear` rattache une créance sans année à **toutes**
les années, et le repo offline-first applique déjà cette règle. NC-4 lui passe
l'année ; il ne réécrit pas le filtre.

---

## NC-0 · Le code descend (schéma v39)

- `ref_fee_tariffs.code TEXT` (nullable), palier `upTo(39)` idempotent gardé par
  `_hasColumn` — patron des paliers existants.
- `AppConstants.offlineDbSchemaVersion = 39`.
- `RefFeeTariffDto.code` (`String?`), `FeeTariffLocalModel.code`,
  `LocalFeeTariff.code`, et le mapping du pull
  (`enrollment_pull_repository_impl.dart`).
- **Aucun backfill.** `replaceTariffsForYears` réécrit chaque ligne des années
  du bundle au pull suivant : le cache référentiel se jette, il ne se rattrape
  pas (leçon de v37). Entre la migration et ce pull, `code` est `NULL` → la
  parenthèse est masquée, ce qui est le comportement d'aujourd'hui.
- ⚠️ Tolérance de contrat : un bundle **sans** `code` (serveur plus ancien) ne
  doit pas lever. Mais épingler le **niveau** de la section dans un test, pas
  seulement la règle — c'est la tolérance elle-même qui a rendu les cinq écarts
  d'ADR-021 invisibles.

**Tests** — palier v38→v39 sur base réelle, rejouable, table neuve ; DTO sans
`code` accepté ; le pull écrit le code ; un second pull le met à jour.

---

## NC-1 · Le code atteint la créance

`FinanceLedgerReadDao.getChargesByStudent` :

```sql
SELECT sc.*, …paid_pending…,
       t.code AS t_fee_tariff_code
FROM student_charges sc
LEFT JOIN ref_fee_tariffs t ON t.id = sc.fee_tariff_id
WHERE sc.student_id = ?
```

`LEFT JOIN` — jamais `JOIN` : une créance *ad hoc* n'a pas de tarif, et perdre
une ligne de grand-livre pour un défaut d'affichage serait sans commune mesure.

- `LocalStudentCharge.feeTariffCode` (`String?`) → `StudentCharge.feeTariffCode`
  (`String?`, **jamais aplati en `''`** — la leçon du piège 4).
- Colonne préfixée `t_` : `pa.*`/`sc.*` sont lues par `fromMap`, une colonne
  homonyme les masquerait (convention déjà en place avec `p_`).

**Tests** — créance avec tarif → code ; créance *ad hoc* → `null` ; tarif absent
de l'appareil → `null` ; le `LEFT JOIN` ne perd aucune ligne.

---

## NC-2 · Une seule fonction de désignation

`chargeDesignation(charge, l10n)` (FT-6) est étendue — **pas doublée** :

| Entrée | Rendu |
|---|---|
| libellé + code distinct | `Organisation matériel — 2/3 (OM2)` |
| libellé + code `null`/vide | `Organisation matériel — 2/3` |
| libellé + code == nature | `Organisation matériel — 2/3` (piège 1) |
| libellé vide + code | `Frais d'examen (OM2)` — repli sur la nature localisée |
| libellé vide + pas de code | `Frais d'examen` |

Une clé ARB **dans les deux fichiers** — la composition est une chaîne d'UI, pas
une concaténation en dur (règle non négociable n°4) :

```json
"chargeDesignationWithTariffCode": "{label} ({code})"
```

Puis `flutter gen-l10n` **et** `dart format lib/l10n/` (sans quoi trois clés
produisent 1500 lignes de churn).

**Tests** — les cinq lignes du tableau, en test pur.

---

## NC-3 · Facturation — les trois écrans

| Fichier | Aujourd'hui | Après |
|---|---|---|
| `facturation_charge_line.dart:73` | `feeCode.localizedFeeLabel` | `chargeDesignation` |
| `facturation_charge_detail_dialog.dart:172` | idem, sur `intent.feeCode` | `chargeDesignation`, l'intent portant désormais `chargeLabel` + `feeTariffCode` |
| `facturation_payment_detail_allocations_table.dart:91` | `allocation.feeCode.localizedFeeLabel` | libellé gelé de l'imputation + code joint |

- `FacturationChargeDetailIntent` gagne deux champs (`props`, `withRouteParams`,
  `.invalid` à vide) ; `facturation_detail_page.dart:152` les alimente depuis la
  `StudentCharge` complète qu'il tient déjà.
- Les imputations : même `LEFT JOIN ref_fee_tariffs` dans `getAllocationsByPayment`
  et `getAllocationsByCharge` → `LocalPaymentAllocation.feeTariffCode` →
  `PaymentAllocation.feeTariffCode`. Le libellé, lui, est celui **gelé à
  l'encaissement** (`student_charge_label`) : c'est ce que le guichet a validé ce
  jour-là, et il ne se recalcule pas.

**Tests** — la ligne de frais affiche le code ; la popin ouverte par route
(`.invalid`) se replie sans parenthèse ; la table d'imputations nomme la tranche.

---

## NC-4 · Inscription — étape 6 et récapitulatif

**Le nommage.** `StudentChargeRow` et `SummaryChargeLine` portent chacun leur
propre cascade, inverse de celle du guichet : la nature d'abord, le libellé
seulement si la nature est inconnue. Les deux passent par `chargeDesignation`.

**La borne d'année** — le vrai défaut. En consultation
(`initializeDraftCharges: false`), le handler émet `StudentChargesRequested`, qui
n'a pas de champ d'année ; `_readCharges` lit alors **toutes** les créances de
l'élève. Un réinscrit voit son minerval N-1 sous celui de N, additionné dans le
pied de page.

- `StudentChargesRequested` gagne `academicYearId` (le handler l'a déjà :
  `context.detail.enrollmentDetail.academicYearId`).
- `_onStudentChargesRequested` le passe en `scopedAcademicYearId` — le même
  chemin que le flux brouillon, pas un second filtre.
- ⚠️ La clause existante conserve les créances à année vide (piège 8). Ne pas la
  réécrire.

**Tests** — un élève avec des créances sur deux années : la consultation d'un
dossier n'en montre qu'une ; le total suit ; le libellé porte le code ; une
créance à année `NULL` reste visible.

---

## NC-5 · L'ordre des tranches

`getChargesByStudent` : `ORDER BY sc.fee_code ASC, sc.due_at ASC, t.code ASC`.
L'échéance d'abord — c'est l'ordre dans lequel une famille paie — le code
ensuite, pour les tranches sans échéance. Même traitement sur
`getAllocationsByPayment`.

⚠️ `due_at` est nullable : `ORDER BY` place les `NULL` en tête sous SQLite. Une
tranche sans échéance remonterait avant la première. Trier explicitement.

**Tests** — trois tranches d'échéances 30/11, 28/02, 31/05 sortent dans cet
ordre, quel que soit l'ordre d'insertion.

---

## NC-6 · Le ticket thermique

`ProvisionalTicketDao.findAllocations` lit `payment_allocations` à plat. Ajouter
le `LEFT JOIN ref_fee_tariffs` sur `fee_tariff_id` et composer comme les écrans.

- ⚠️ **Ne pas toucher `student_charge_label`** (piège 7).
- ⚠️ Le papier est un **instantané** : si le tarif a quitté l'appareil, le ticket
  retombe sur le libellé seul. C'est la même règle que partout ailleurs, et elle
  vaut mieux qu'une parenthèse vide sur un reçu.
- La note de perception (éditique en ligne) est **hors périmètre** : elle est
  rendue par le serveur, avec ses propres libellés.

**Tests** — la répartition imprimée nomme la tranche ; sans tarif joignable, elle
imprime le libellé nu.

---

## NC-7 · Demande au back — le code sur la créance

**Additif, non bloquant.** Tant qu'il n'est pas servi, NC-1 tient : le front
joint la grille locale, et ne perd le code que lorsqu'elle n'est pas sur
l'appareil (piège 3) — le seul trou qu'il ne peut pas fermer lui-même.

### ⚠️ Correction : ce n'est PAS « deux lignes plus leurs mappers »

La première rédaction de ce lot annonçait deux champs de DTO. **C'était faux, et
vérifié depuis dans le code serveur** (`e674615`) : `StudentCharge` ne porte
qu'un `feeTariffId` (`UUID`), **aucune association vers `FeeTariff`**. MapStruct
n'a donc rien à auto-mapper — le code doit venir d'ailleurs.

### Le dessin qui suit la maison

La créance **gèle déjà ce que le tarif disait** à la matérialisation : `label`
est une copie, `expectedAmountInCents` est « une copie de la grille, pas une
jointure », `grossAmountInCents` est écrit explicitement, `reductionValue` est
« gelé, jamais relu depuis le barème courant ». Le code appartient à cette
famille : **une colonne dénormalisée, figée à la matérialisation** — pas une
jointure à la lecture.

| | |
|---|---|
| Migration | `V110` : `student_charges.fee_tariff_code varchar(32)`, nullable |
| Backfill | `UPDATE student_charges sc SET fee_tariff_code = ft.code FROM fee_tariffs ft WHERE ft.id = sc.fee_tariff_id` — le serveur a les deux tables, contrairement à la tablette |
| Entité | `StudentCharge.feeTariffCode` |
| Matérialisation | **2 sites**, tous deux `.label(tariff.label())` avec le tarif en main : `StudentChargeService.buildChargesFromTariffs` et le second constructeur de la même classe → `.feeTariffCode(tariff.code())` |
| DTO | `StudentChargeSummaryDto`, `StudentChargeDto`, `StudentChargeRef` (auto-mappés une fois l'entité pourvue) |
| Contrat | `openApi.yaml` |

Sept fichiers et une migration, donc — pas deux lignes. Le coût reste modeste,
mais il se décide sur ce chiffre-là.

### Ce que le front fera ensuite

Colonne `student_charges.fee_tariff_code` (**v40**), remplie au pull et à l'ACK.
La jointure locale de NC-1 devient alors le **repli**, plus la source — et
l'ordre de préséance doit être : la valeur gelée d'abord, la grille ensuite. Une
grille qui a changé depuis ne doit pas renommer une tranche déjà encaissée.

### Non écrit dans l'arbre du back, et pourquoi

Au moment de ce lot, `~/my_project/eteelo-backend` porte du travail **indexé sur
`main`** (V109, `parent_surname_optional`). Y ajouter ce changement mêlerait deux
sujets dans un même index. À reprendre dans un `git worktree` dédié — le patron
déjà retenu pour ce dépôt partagé.

---

## 5. Hors périmètre, et pourquoi

**La saisie du code au paramétrage** — un champ « code » dans
`tariff_edit_dialog`, `FeeTariffPayloadModel.code`, `ProvisioningRequestModel.code`.
Écarté sur arbitrage. **Conséquence assumée et à ne pas perdre de vue** : sans
ce lot, une école paramétrée depuis l'application ne peut poser qu'un tarif par
nature et par niveau — la parenthèse restera invisible, et le mur
`AMBIGUOUS_FEE_CODE` que FT vient de contourner ne peut pas y être reproduit. Le
présent plan sert les écoles dont la grille est posée ailleurs.

**Contrôle des frais et statistiques** — `getFeeChargeAggregates` agrège par
`fee_code` avec des `SUM` : une position par nature, tranches confondues. C'est
cohérent avec ce que l'écran promet ; ne pas le « corriger » sans demande.

**Le calcul des réductions** — toujours V2, rien ici ne le touche.

---

## 6. Volume

| Lot | Fichiers | Nature |
|---|---|---|
| NC-0 | 6 + tests | schéma, DTO, modèle |
| NC-1 | 3 + tests | jointure de lecture |
| NC-2 | 1 + 2 `.arb` + tests | composition |
| NC-3 | 5 + tests | Facturation |
| NC-4 | 4 + tests | étape 6, récapitulatif, borne d'année |
| NC-5 | 1 + test | tri |
| NC-6 | 1 + test | ticket |
| NC-7 | 7 + migration (dépôt back) | demande de contrat |

Une clé ARB neuve. Un bump de schéma. Aucun geste de données.

**Ordre d'exécution** : NC-0 → NC-1 → NC-2 → NC-3 → NC-4 → NC-5 → NC-6, puis
NC-7. NC-2 après NC-1 : la fonction ne peut pas se tester sur un champ qui
n'existe pas encore.

**Recette** — sur une école dont les tarifs portent de vrais codes, la tranche
**du milieu** : ni la plus ancienne ni la plus récente, la seule qu'aucun repli
implicite ne pourrait deviner juste.

```
élève 1b8da043… · année 09b47494… · 3 créances impayées
OM1  Organisation matériel examens — 1/3   500 000 CDF   30/11/2026
OM2  Organisation matériel examens — 2/3   500 000 CDF   28/02/2027   ← celle-ci
OM3  Organisation matériel examens — 3/3   500 000 CDF   31/05/2027
```

Attendu, à l'identique dans les six écrans et sur le papier :
`Organisation matériel examens — 2/3 (OM2)`.
