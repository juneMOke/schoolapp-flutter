# Encaissement — désigner la tranche (`feeTariffId`)

> **Contrat back :** note « Encaisser une tranche » (poste de perception) +
> `openApi.yaml` §`PaymentAllocationInput` / §`StudentChargeRef`.
>
> ✅ **Confronté au dépôt back en local** (`~/my_project/eteelo-backend`,
> `0353c2c docs(finance): say that a tariff, not a nature, designates a charge`).
> Les noms de ce document sont **lus dans le code serveur**, pas devinés — la
> leçon d'ADR-021, où cinq noms inventés étaient faux et l'ont été
> silencieusement.
>
> 🔴 **Ce n'est pas un cas limite.** En base dev : 88 élèves avec un minerval en
> 7 tranches, 82 avec des frais d'examen en 2 ou 3, 36 avec 9 tranches
> d'encadrement. Chaque poste heurte le mur au **premier** encaissement de
> minerval — et l'argent est déjà dans le tiroir quand il le heurte.

## État — 2026-08-31

**Les sept lots sont écrits** (FT-0 → FT-6), `flutter analyze` clean.

| Lot | État | Notes |
|---|---|---|
| FT-0 | ✅ | schéma **v38**, palier gardé, `toPullPatch` exclut le tarif |
| FT-1 | ✅ | la chaîne complète ; `''` normalisé au point de sortie |
| FT-2 | ✅ | + **le second chemin de dissolution**, que le plan n'avait pas vu (ci-dessous) |
| FT-3 | ✅ | `PaymentOutboxTariffBackfill`, branchée dans `registerOfflineCore` |
| FT-4 | ✅ | l'écart back/front **est levé** : `fee_tariffs.school_level_id` est `NOT NULL` côté serveur (V7, conservé par V94), et la seule écriture locale de `ref_fee_tariffs` est le pull — la clause de cycle du front est une tolérance dormante, elle ne fabrique aucune créance fantôme |
| FT-5 | ✅ | `charges[]` décodé via `StudentChargeDto` (même forme JSON que le pull) |
| FT-6 | ✅ | popin **et** ligne de saisie (le plan croyait la seconde déjà juste) |

**Trois écarts au plan, tous dans le sens de la prudence.**

1. **`_remapProvisionalCharge` dissolvait par nature, lui aussi.** Le plan ne
   visait que `_dissolveProvisionalTwins` (pull de masse). Or l'accusé d'un
   paiement passe par l'autre chemin, et FT-4 venait justement de multiplier les
   tranches : l'accusé d'UNE créance canonique aurait supprimé les six autres
   provisoires et ré-imputé leurs versements sur elle. Corrigé, et les deux
   chemins partagent désormais **une seule** implémentation
   (`provisional_charge_dissolver.dart`) — la règle qui décide de ce qu'on
   efface ne doit pas exister en deux exemplaires.

2. **Le semis ne dédoublonne pas *seulement* par `tariff.id`.** Une créance
   conservée d'un AUTRE niveau (elle est payée, on ne la supprime jamais) couvre
   sa NATURE entière : le tarif du nouveau niveau porte un autre id, mais c'est
   le même frais, et le semer une seconde fois ferait devoir deux scolarités au
   même élève. Idem pour une créance sans tarif (base d'avant). Un test existant
   épinglait déjà cet invariant.

3. **La ligne de saisie affichait la nature, elle aussi.** Le §piège 6 affirmait
   que l'écran « sait distinguer les tranches » ; il ne le savait pas. Corriger
   la seule popin aurait laissé le guichetier cocher à l'aveugle puis vérifier.
   ⚠️ Le discriminant affichable est le `label` et rien d'autre : le `code` de
   V94 (« T1 », « OM2 ») n'atteint ni `StudentChargeRef`, ni le DTO du pull, ni
   `ref_fee_tariffs` en local.

**Reste à faire** — l'**arbitrage A** : `TariffBackfillReport.allocationsUnmatched`
donne le comptage sur base réelle, mais personne ne l'a encore lu. Tant qu'il
n'est pas connu, aucun écran de re-désignation ne s'écrit.

---

**Décisions actées.**

| | |
|---|---|
| Le tarif dans le payload | **Figé à l'encaissement**, comme `studentChargeLabel`. Jamais relu au push : la grille peut avoir bougé entre les deux |
| `feeTariffId` absent | **Légitime** — créance *ad hoc*, hors grille. Elle continue de se résoudre par sa nature |
| La chaîne vide | **Jamais envoyée.** `''` n'est pas un uuid ; le mapper local→online en fabrique un (piège 1) |
| Reprise de l'outbox | Appariement par **id d'allocation**, pas par `studentChargeId` — la note se trompe de clé (piège 4) |
| Nouveau geste de guichet | **Aucun tant qu'on n'a pas compté** — cf. §6 A |
| Périmètre | **Les sept lots.** Le push seul laisserait l'élève inscrit hors ligne à une tranche sur sept |
| Le chemin back-office en ligne | **Hors périmètre** — le serveur n'y expose pas encore le tarif (§5) |

---

## 1. Ce que le serveur fait vraiment

`StudentChargeResolver`, politique `REMAP_BY_FEE_CODE` (le seul chemin de la
tablette) :

1. `allocations[].studentChargeId` est **ignoré** — il peut être provisoire.
2. Si `feeTariffId` désigne **exactement une** créance candidate → c'est elle.
   L'index unique V58 tient une créance par `(école, élève, année, tarif)` : deux
   ici signaleraient une base incohérente, pas une saisie discutable.
3. Sinon, repli sur `feeCode` : aucune candidate → `UNKNOWN_FEE_CODE` ; plusieurs
   → `AMBIGUOUS_FEE_CODE` ; une seule → elle. **Le repli ne devine rien.**

⚠️ **Ce que la note ne dit pas, et qui décide de tout :** les candidates sont
chargées par `lockCandidatesForRemap(studentId, academicYearId, feeCodes)` —
**filtrées sur les `feeCode` du payload**. Un `feeTariffId` juste porté par un
`feeCode` faux ne trouve rien et retombe sur le repli, donc sur le même 422. Les
deux champs doivent sortir de **la même ligne de créance**, jamais de deux
sources.

Et côté matérialisation, `StudentChargeService.buildChargesFromTariffs` projette
**une créance par tarif** — pas par nature. C'est la moitié du problème, et elle
n'est pas dans le push (§ FT-4).

---

## 2. Ce qui est déjà en place — ne pas le refaire

| | |
|---|---|
| `student_charges.fee_tariff_id` | ✅ colonne locale existante |
| Pull `GET /sync/student-charges` | ✅ `StudentChargeDto.feeTariffId` → `toLocalModel` |
| Semis offline | ✅ `FinanceChargeSeedDao` écrit `feeTariffId: tariff.id` |
| Remontée jusqu'à l'UI | ✅ `LocalStudentCharge.feeTariffId` → `StudentCharge.feeTariffId` (mais aplati, piège 1) |
| `AMBIGUOUS_FEE_CODE` | ✅ déclaré, classé `isClientDefect` → `SYNC_ERROR`, `detailCodeOf` branché sur le handler |
| Feuille de reprise | ✅ `OutboxDao.errors()` + `requeue()` |

**Ce qui manque tient en six trous**, et un seul est dans le payload :

| # | Trou | Où |
|---|---|---|
| 1 | `payment_allocations` n'a pas de colonne de tarif | schéma v37 |
| 2 | `PaymentAllocationInput` ne porte pas le champ | payload d'outbox |
| 3 | La chaîne UI → draft → modèle local ne le transporte pas | 4 classes |
| 4 | `_resolveChargeLink` re-lie **au hasard** entre deux tranches | DAO d'écriture |
| 5 | Le semis local ne fabrique **qu'une créance par nature** | `FinanceChargeSeedDao` |
| 6 | L'ACK d'inscription porte `charges[]` — le front ne l'ouvre pas | `EnrollmentAggregateResponse` |

---

## 3. Les sept pièges

### 1 · `toOnlineEntity()` aplatit `null` en `''`

`LocalStudentChargeToOnline` écrit `feeTariffId: feeTariffId ?? ''`, et c'est
l'entité **online** que lit la page d'encaissement. Reprendre `entry.charge.feeTariffId`
tel quel enverrait `""` au serveur sur toute créance *ad hoc* : ni un uuid, ni un
`null`. Normaliser au point de sortie (`trim().isEmpty ? null : …`), et pas en
remontant le mapper — l'entité online est partagée, sa forme n'est pas le
problème du push.

### 2 · Le semis local est bridé à **une créance par nature**

```dart
final coveredFeeCodes = kept.map((c) => c.feeCode).toSet();
for (final row in tariffs) {
  if (!coveredFeeCodes.add(tariff.feeCode)) continue;   // ← les 6 autres tranches
```

Le commentaire l'assume (« invariant `fee_code` unique DANS une année »). Cet
invariant est **mort depuis V94**. Un élève inscrit hors ligne ne doit donc
qu'une tranche de minerval sur sept, sur l'appareil qui l'a inscrit, jusqu'au
pull suivant. Aucun `feeTariffId` dans le payload ne répare ça : le trou est en
amont du guichet.

### 3 · `_resolveChargeLink` impute au hasard, en local et en silence

Quand l'uuid de créance ne tient plus, le DAO d'écriture re-résout par
`student_id + fee_code + academic_year_id`… `limit: 1`. Avec sept tranches, il
en attrape une arbitraire — celle que SQLite rend en premier. Le miroir local
ment **avant** le push, donc le reçu imprimé aussi.

### 4 · La note se trompe de clé pour la reprise

Elle propose d'apparier les payloads en attente « par `studentChargeId` quand il
est là ». Or le payload d'outbox est **figé**, tandis que
`payment_allocations.student_charge_id` **bouge** : `_dissolveProvisionalTwins`
le repointe au pull, l'ACK le remappe. L'appariement par `studentChargeId`
raterait donc exactement les cas qu'il vise — les créances provisoires.

La clé stable est **`allocations[].id`**, qui est `payment_allocations.id` : elle
ne bouge jamais, elle donne accès à la colonne de tarif (FT-0) et, à défaut, au
`student_charge_id` **à jour**.

### 5 · La dissolution des jumelles regroupe par nature

`_dissolveProvisionalTwins` prend la clé `(élève, année, fee_code)`. À l'arrivée
des sept tranches canoniques, la **première du lot** avale la provisoire et
récupère ses imputations, puis `twins.remove(key)` protège les six autres.

Pas de destruction, donc — le filet tient. Mais l'argent atterrit sur la tranche
que le hasard du lot a mise en tête, pas sur celle qui a été encaissée.

### 6 · La popin de confirmation affiche la **nature**, pas la ligne

`entry.charge.feeCode.localizedFeeLabel(l10n)` : sept lignes « Minerval »
identiques, sept montants différents, aucune façon de vérifier. Le guichetier
valide à l'aveugle un écran qui, lui, sait distinguer les tranches (`charge.label`
porte « Organisation matériel examens — 2/3 »).

### 7 · Un `requeue` sans backfill redonne le même 422

`AMBIGUOUS_FEE_CODE` est bien classé terminal, et `requeue` est la seule sortie.
Mais elle remet en file **le payload d'origine**, qui n'a pas de tarif : même
appel, même refus, à l'infini. La reprise doit **corriger le payload d'abord**,
remettre en file ensuite — jamais l'inverse.

---

## FT-0 · Schéma v38 — la colonne

- `payment_allocations.fee_tariff_id TEXT` (nullable).
- Palier `upTo(38)` idempotent, gardé par `_hasColumn` (patron des paliers
  existants). **Aucun backfill dans le palier** : la reprise des payloads est un
  geste de données, pas de schéma (FT-3).
- `AppConstants.offlineDbSchemaVersion = 38`.
- `PaymentAllocationLocalModel` : champ + `toMap` / `fromMap` /
  `withStudentChargeId`.
- ⚠️ **Pas dans `toPullPatch`.** `PaymentDelta.allocations` ne porte pas le
  tarif : l'y mettre écrirait `null` sur une ligne qui l'avait, au premier pull
  qui repasse dessus. Même raison que `student_charge_label`.

**Tests** — palier v37→v38 sur base réelle, rejouabilité, table neuve, et le
patch de pull qui **ne touche pas** la colonne.

---

## FT-1 · Le tarif traverse la saisie

Une ligne de plus dans cinq classes, dans cet ordre :

```
FacturationChargeEntry.charge.feeTariffId          (entité online, à normaliser)
  → CreatePaymentAllocationInput.feeTariffId       (String?)
  → PaymentsCreateRequested                        (déjà porteur, via l'input)
  → AllocationDraft.feeTariffId
  → PaymentAllocationLocalModel.feeTariffId        (FT-0)
  → PaymentAllocationInput.feeTariffId → toJson()
```

- `toJson` : `if (feeTariffId != null) 'feeTariffId': feeTariffId` — un `null`
  explicite est légal au contrat, mais l'omettre garde le payload lisible par
  toutes les versions.
- `fromJson` : `j['feeTariffId'] as String?` — les payloads d'avant n'en ont pas,
  et les refuser basculerait en `failed` de l'argent déjà reçu (même règle que
  `payerPhoneNumber` et que les trois formes de `amounts`).
- Page d'encaissement : normaliser (`piège 1`) au moment de construire
  `CreatePaymentAllocationInput`.

**Tests** — le payload porte le tarif de la créance visée ; `''` ne sort jamais ;
un payload sans tarif se relit sans lever ; le tarif figé survit à un changement
de grille entre l'enfilage et le push.

---

## FT-2 · Le lien local se résout par tarif

`FinancePaymentWriteDao._resolveChargeLink` :

1. uuid vivant → inchangé ;
2. **tarif présent** → `student_charges` par `(student_id, année-ou-NULL, fee_tariff_id)` ;
3. repli `fee_code` — mais **`null` si plusieurs candidates**, au lieu du
   `limit: 1` actuel. Ne rien lier est la sémantique du contrat (« créance pas
   encore matérialisée ») ; lier au hasard est un mensonge.

`FinanceLedgerSyncDao._dissolveProvisionalTwins` : clé par **tarif** quand les
deux côtés en portent un, repli sur `fee_code` sinon (créances *ad hoc*, et
bases d'avant).

⚠️ La clause d'année reste branchée en SQL (`IS NULL` vs `= ?`), jamais
`whereArgs: [null]` — sqflite avertit aujourd'hui, lèvera demain.

**Tests** — trois tranches en base, l'imputation vise la 2/3 : le lien local ne
dérive pas ; le pull des trois canoniques absorbe la provisoire sur la bonne ;
deux candidates sans tarif → lien `null`, pas un tirage au sort.

---

## FT-3 · Reprise de l'outbox déjà constituée

Les versements enfilés avant ce changement n'ont pas de tarif et repartiront en
422 **indéfiniment**. Ce sont des encaissements réels, reçus imprimés.

Reprise, une fois, au démarrage (pas dans le palier de schéma — c'est un geste de
données, et il doit pouvoir se rejouer seul) :

1. lire l'outbox `aggregate_type = 'PAYMENT'`, tous statuts confondus (`PENDING`
   compris : ils échoueront demain) ;
2. décoder le payload — les deux formes, imbriquée et à plat ;
3. pour chaque allocation sans tarif : `payment_allocations` par **`id`** →
   `fee_tariff_id` (FT-0), sinon `student_charge_id` **à jour** →
   `student_charges.fee_tariff_id` ;
4. réécrire le payload **seulement si** quelque chose a été trouvé ;
5. `requeue` **uniquement** les entrées `SYNC_ERROR` effectivement corrigées —
   jamais en bloc : une entrée figée pour une autre cause (`CHARGE_CURRENCY_MISMATCH`)
   repartirait pour rien et perdrait son diagnostic.

Une entrée non appariable reste intacte, en `SYNC_ERROR`, avec son message. Ce
qu'on en fait ensuite est l'**arbitrage A**.

**Tests** — payload sans tarif + créance locale → payload enrichi + requeue ;
allocation non appariable → payload intact, pas de requeue ; entrée en erreur
pour une autre cause → non touchée ; migration **rejouable** (deuxième passage :
aucun écrit).

---

## FT-4 · Le semis local matérialise chaque ligne de grille

Le vrai trou, et il est en amont du push (piège 2).

- Dédoublonner par **`tariff.id`**, plus par `tariff.feeCode` ; `kept` s'indexe
  de même.
- Vérifier derrière : `getChargesByStudent` (sept lignes au lieu d'une, libellés
  distincts), l'étape « Frais » du wizard, les KPI, et l'exigibilité.
- `getFeeChargeAggregates` (Contrôle des frais) agrège par `fee_code` avec des
  `SUM` : une position **par nature**, tranches confondues. C'est cohérent — ne
  pas le « corriger » sans demande.

⚠️ **Écart back/front à confirmer avant de coder** : le serveur projette
`getFeeTariffsBySchoolLevelId(levelId)` seul ; le front ajoute les tarifs définis
au **cycle** (`school_level_id IS NULL`). Si l'écart est réel, le semis local
fabrique des créances que le serveur ne régénérera jamais — un frais dû sur la
tablette, inconnu au grand-livre.

---

## FT-5 · L'ACK d'inscription remplace les provisoires

`EnrollmentAggregateResponse` ignore `charges[]` (`StudentChargeRef`, avec son
`feeTariffId`). Le serveur les matérialise pourtant **dans la transaction
d'inscription** — c'est le cas nominal de la rentrée.

Sans ce décodage, entre l'ACK et le pull suivant, le guichet encaisse sur des
créances provisoires dont **une seule tranche sur sept existe** (FT-4). Le
décoder, puis l'appliquer comme le pull : upsert autoritaire + dissolution des
provisoires par tarif (FT-2).

`charges` est vide pour une PRE_ENROLLMENT ou sans niveau — cas normal, pas une
panne.

---

## FT-6 · L'écran ne confond plus deux tranches

- Popin de confirmation : `entry.charge.label` (« Organisation matériel
  examens — 2/3 »), repli sur `feeCode.localizedFeeLabel(l10n)` si le libellé est
  vide. Rien à traduire : le libellé vient du référentiel serveur.
- **Recette sur la tranche du milieu** — ni la plus ancienne ni la plus récente,
  la seule qu'aucun repli implicite ne pourrait deviner juste :

```
élève 1b8da043… · année 09b47494… · 3 créances impayées
OM1  Organisation matériel examens — 1/3   500 000 CDF   30/11/2026
OM2  Organisation matériel examens — 2/3   500 000 CDF   28/02/2027   ← encaisser
OM3  Organisation matériel examens — 3/3   500 000 CDF   31/05/2027
```

Attendu : **201**, et `allocations[0].canonicalStudentChargeId ==
15dc3cb6-c84e-4f24-866c-8f0d3bec4b22` (la 2/3). Les `charges` de l'ACK portent le
nouveau solde — canal unique de réconciliation, aucun pull de suivi.

---

## 5. Hors périmètre, et pourquoi

**`POST /api/v1/finance/payments`** (back-office en ligne). Le serveur y applique
`HONOR_PROVIDED_ID` : `studentChargeId` fait autorité, et un id introuvable lève
`UNKNOWN_STUDENT_CHARGE` plutôt que de retomber sur la nature. Le front y envoie
déjà l'id réel de la créance → **le mur ne s'y présente pas**. Le champ n'y est
pas exposé ; même mur un chemin plus loin, à traiter séparément.

**Le trop-perçu** reste un signal, jamais un refus : le cash est au tiroir.

**Le calcul des réductions** — toujours V2, rien ici ne le touche.

---

## 6. Les deux arbitrages — tranchés

**A · Le versement qu'aucune ligne ne peut désigner → compter d'abord.**

Après FT-3, il reste en `SYNC_ERROR` avec un `requeue` qui ne peut rien : le
payload figé n'a pas de tarif, et personne d'autre que le guichetier ne peut
trancher — l'argent est dans le tiroir, mais rien ne dit sur quelle tranche il a
été reçu.

Sauf que ce cas suppose une créance provisoire **sans** tarif, or le semis en
écrit toujours un (`feeTariffId: tariff.id`) et le pull aussi. **Il est
probablement vide.** FT-3 se termine donc par un comptage sur base réelle — un
`SELECT` sur les payloads non appariables — et c'est ce chiffre qui décide entre
un message dans la feuille de reprise et un geste de re-désignation. Écrire
l'écran avant de compter, c'est écrire un écran pour zéro entrée.

**B · Périmètre → les sept lots (FT-0→FT-6).**

Le push et l'amont dans la même passe. FT-4 et FT-5 ne sont pas du confort : sans
eux, un `feeTariffId` juste dans le payload désignerait une créance qui n'existe
pas localement, et le cas nominal de la rentrée — inscrire hors ligne, encaisser
avant tout pull — resterait cassé.

Ordre d'exécution : **FT-0 → FT-1 → FT-2 → FT-4 → FT-5 → FT-3 → FT-6**. FT-3
passe **après** FT-4/FT-5 délibérément : la reprise lit `student_charges` pour
retrouver les tarifs, et elle doit lire une table déjà juste.

⚠️ **À vérifier avant d'entamer FT-4** : le serveur projette
`getFeeTariffsBySchoolLevelId(levelId)` seul, le front y ajoute les tarifs de
cycle. Si l'écart est réel, il se règle **avant** de multiplier les créances,
pas après.

---

## 7. Volume

| Lot | Fichiers | Nature |
|---|---|---|
| FT-0 | 3 + tests | schéma, modèle |
| FT-1 | 6 + tests | traversée du champ |
| FT-2 | 2 + tests | résolution locale |
| FT-3 | 1 neuf + tests | reprise de données |
| FT-4 | 1 + vérifications | semis |
| FT-5 | 2 + tests | ACK |
| FT-6 | 1 + test | affichage |

Aucune string neuve dans les `.arb` sauf issue 2 de l'arbitrage A.
