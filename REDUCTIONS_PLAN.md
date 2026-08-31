# Réductions par élève — plan front V1

> **Contrat back : ADR-021, note « Réductions par élève », plan V1 du 31 août 2026.**
>
> 🔴 **Le back n'a rien livré.** Dernière migration `V106.0.0__grant_school_grid_assign.sql`,
> zéro occurrence de `reduction` dans `src/`. Les deux routes et les deux sections
> du bundle n'existent pas. **`openApi.yaml` ne fait donc PAS foi ici** — les noms
> de champs de ce document sont *proposés*, à confronter à la spec dès que V107
> est poussée (cf. §6).
>
> ✅ **Le contrat est entièrement additif** — un champ optionnel en entrée, deux
> sections et une liste en sortie. Le front peut partir devant sans rien casser,
> **à condition que l'absence des sections soit un non-événement** et pas une
> erreur. C'est la contrainte n°1 de RD-F1.

**Décisions actées.**

| | |
|---|---|
| Le taux à l'écran | **Masqué en V1.** On coche un libellé, jamais un pourcentage — rien ne promet un montant, donc rien ne peut sembler faux |
| Écran de gestion du barème | **Hors périmètre.** Le barème se peuple côté serveur en attendant. La liste à cocher reste vide sur une école non préparée, et c'est assumé |
| Le calcul | **Aucun.** Les montants de la V1 sont ceux d'aujourd'hui, au centime |
| Permission dédiée | **Aucune.** `finance.grid.read` caviarde le barème, `enrollment.write` couvre l'octroi — les deux existent déjà dans `Perm` |
| Types sans ligne de barème | **Non proposés à la saisie** — voir §3, piège 5 |

---

## 1. L'invariant, et il vaut aussi de notre côté

**Aucun centime ne change de valeur en V1.**

`FinanceChargeSeedDao` continue de semer les créances `PROVISIONAL` au **tarif
plein**, et on n'y touche pas d'une ligne. Le `student_charges` local n'a ni
`gross_amount_in_cents` ni `reduction_code`, **n'en a pas besoin**, et n'en
reçoit pas : les colonnes que le back ajoute à son DTO seront simplement
ignorées au parsing, comme tout champ inconnu.

La tentation reviendra — « appliquer la remise sur la créance provisoire, juste
pour l'affichage ». Il faut la nommer pour la refuser : l'écran annoncerait un
net réduit que **le serveur régénère au plein tarif à l'ACK**. L'écart est
visible au guichet, il porte sur de l'argent, et il apparaîtrait *après* la
validation. Le semis local ne connaît pas les réductions.

---

## 2. Ce qui descend, ce qui remonte

### Le barème — **à la racine** du bundle

`reduction_type` et `reduction_line` n'ont **pas d'`academic_year_id`**. Ils
descendent donc à côté de `school`, pas dans `current`/`previous`.

```json
{
  "school":   { … },
  "current":  { … },
  "previous": { … },
  "reductionTypes": [
    { "id": "…", "code": "STAFF_CHILD", "label": "Enfant du personnel", "active": true }
  ],
  "reductionLines": [
    { "id": "…", "reductionCode": "STAFF_CHILD", "feeCode": "MINERVAL", "value": 50 }
  ],
  "serverTime": "…"
}
```

Les deux sections sont **nullable**, caviardées derrière `finance.grid.read`,
avec la règle du projet : `null` = « pas communiqué », `[]` = « cette école n'a
pas de barème ».

### L'octroi — dans l'agrégat d'inscription

Montant : `POST /api/v1/sync/enrollments`, champ `reductionCodes: ["STAFF_CHILD"]`
sur l'objet `enrollment`. Descendant : les mêmes codes dans l'ACK et sur
l'agrégat au pull snapshot.

**Aucune route neuve côté front, aucune entrée d'outbox propre.** Le client
pousse l'inscription, le serveur grave l'octroi et le renvoie. Exactement le
patron des créances.

### Un seul point d'insertion couvre les trois parcours

`enrollment_detail_page.dart` monte le même `EnrollmentStepperScope` pour
l'inscription, la réinscription **et** la préinscription. Et le back écrit
l'octroi au point 3.5 de `EnrollmentIngestService`, **avant** la bifurcation qui
prive la préinscription de son événement — donc un préinscrit garde ses codes à
la conversion, sans ressaisie. Les deux bouts sont cohérents ; il n'y a rien à
faire de spécial pour PRE.

---

## 3. Les cinq pièges

### 1 · La racine n'a pas d'année — la purge scopée par année ne s'applique pas

`_applyReferential` (`enrollment_pull_repository_impl.dart:407`) dérive des
`yearIds` pour purger la grille tarifaire et le catalogue boutique. **Ici il n'y
en a pas.** Recopier le patron tel quel ne compile même pas, et le contourner en
inventant une année serait pire.

### 2 · …et c'est là que la tablette multi-école mord

Le barème porte un `school_id` côté serveur mais pas d'année. Une purge
**globale** au pull effacerait celui de l'autre école sur une tablette partagée —
et contrairement au reste du référentiel, **aucun filtre `academic_year_id` ne
viendra masquer le défaut en vide plutôt qu'en fuite**.

`school_id` est donc stampé depuis `CurrentUserContext` — *jamais* depuis le
payload — comme `ref_academic_years` le fait déjà, et **la purge est scopée à
l'école**. Le défaut est documenté deux fois dans le dépôt (éditique, PRE) ;
c'est la troisième fois qu'on écrit la garde, autant l'écrire juste.

### 3 · Le tri-état `null` / `[]` porte de l'argent

Même nuance que `feeTariffs` et `boutiqueArticles`, même conséquence : replier
`null` sur `[]` fait lire à la purge un ordre de tout supprimer, et **un pull par
un compte sans `finance.grid.read` effacerait le barème dont dépend le poste
d'à côté**.

Donc : section absente ou `null` → **on ne purge rien**. Section présente et
vide → ordre de purge légitime. Hors de `pullList`, qui replie `null` sur la
liste vide — c'est exactement la distinction à préserver.

### 4 · `reductionCodes` absent d'un payload d'outbox écrit avant le champ

Une inscription confirmée dort peut-être déjà dans la file sans cette clé. Un
`as List` y lèverait et **bloquerait l'outbox entier**. Exactement le piège
`formerStudent` (`enrollment_outbox_payload.dart:215`), avec le même repli :
lecture tolérante, liste vide par défaut.

Corollaire : à l'envoi, **on n'émet le champ que s'il est non vide**. Un
`reductionCodes: []` systématique dirait « retire tout » à un serveur qui n'a
peut-être pas encore le champ, et dirait la même chose demain à un serveur qui
l'a.

### 5 · Le taux étant masqué, un type sans ligne est indiscernable d'un type qui réduit

Décision de cocher un libellé seul : à l'écran, « Enfant du personnel » avec
trois lignes de barème et « Enfant du personnel » avec zéro ligne sont le même
texte. Le second ne réduira jamais rien, et l'octroi serait un mensonge que la
V2 hériterait.

**La liste ne propose donc que les types actifs ayant au moins une ligne.** Une
jointure, et le problème n'existe pas.

---

## RD-F0 · Schéma v36

**Objectif.** Les trois tables locales, et rien d'autre.

`lib/core/database/schema/enrollment_finance_offline_schema.dart` :

```sql
CREATE TABLE ref_reduction_types (
  id         TEXT PRIMARY KEY,
  school_id  TEXT NOT NULL DEFAULT '',
  code       TEXT NOT NULL,
  label      TEXT NOT NULL,
  active     INTEGER NOT NULL DEFAULT 1,
  synced_at  INTEGER NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX idx_ref_reduction_types_school_code
  ON ref_reduction_types(school_id, code);

CREATE TABLE ref_reduction_lines (
  id             TEXT PRIMARY KEY,
  school_id      TEXT NOT NULL DEFAULT '',
  reduction_code TEXT NOT NULL,
  fee_code       TEXT NOT NULL,
  value          REAL NOT NULL,
  synced_at      INTEGER NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX idx_ref_reduction_lines_school_code_fee
  ON ref_reduction_lines(school_id, reduction_code, fee_code);

CREATE TABLE enrollment_reductions (
  enrollment_id  TEXT NOT NULL,
  reduction_code TEXT NOT NULL,
  updated_at     INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (enrollment_id, reduction_code)
);
CREATE INDEX idx_enrollment_reductions_enrollment
  ON enrollment_reductions(enrollment_id);
```

**Points de conception.**

- `value` en `REAL` : c'est un **pourcentage**, pas de l'argent. On stocke ce qui
  descend sans le réinterpréter. L'arrondi est un problème de V2, et le back a
  déjà tranché (HALF_UP au centime) — le front n'a rien à décider ici.
- `ref_reduction_lines` est peuplée alors que **rien ne la lit en V1** hors le
  filtre du piège 5. C'est délibéré : la section descend de toute façon, et la
  jeter maintenant coûterait une migration v37 à la V2.
- Aucune `FOREIGN KEY`, comme tout le module (l'intégrité est portée par les
  DAO, cf. l'en-tête du fichier de schéma).
- Palier `upTo(36)` dans `app_database.dart` : `_asIfNotExists` +
  `_indexAsIfNotExists`, comme les paliers voisins.

**Test.** Le palier v36 : trois tables absentes en v35, présentes en v36, et la
base v35 existante survit avec ses données.

**Fini quand** `AppConstants.offlineDbSchemaVersion == 36` et que les tables
existent sans que personne ne les lise.

---

## RD-F1 · La descente du barème

**Objectif.** Les deux sections racine parsées, stockées, purgées juste.

**Contrat** — `referential_pull_models.dart` :

```dart
class ReferentialBundleDto {
  final RefSchoolDto school;
  final ReferentialYearBundleDto current;
  final ReferentialYearBundleDto? previous;
  final List<RefReductionTypeDto>? reductionTypes;   // nullable : cf. piège 3
  final List<RefReductionLineDto>? reductionLines;
  final String serverTime;
}
```

Décodage **hors de `pullList`** — `j['reductionTypes'] == null ? null : pullList(…)`.

**Application** — un `_applyReductionCatalog(body)` frère de
`_applyBoutiqueCatalog`, mais **scopé école, pas année** :

- les deux sections `null` → retour immédiat, **zéro écriture** ;
- sinon, dans une transaction : `DELETE … WHERE school_id = ?` puis insertion,
  `school_id` venant de `currentUser.schoolId ?? ''`.

⚠️ Les deux sections se traitent **ensemble** : le serveur les caviarde derrière
le même droit, donc l'une sans l'autre n'existe pas. Si le cas survient quand
même, on applique celle qui est là et on laisse l'autre — jamais de purge sur une
section absente.

**Lecture** — un `ReductionCatalogDao` avec une seule requête utile en V1 :

```sql
SELECT t.code, t.label FROM ref_reduction_types t
WHERE t.school_id = ? AND t.active = 1
  AND EXISTS (SELECT 1 FROM ref_reduction_lines l
              WHERE l.school_id = t.school_id AND l.reduction_code = t.code)
ORDER BY t.label
```

C'est le piège 5, réglé à la source.

**Tests.** Le tri-état (`null` ne purge pas · `[]` purge · présente remplace) et
le scope école (le barème de l'école B survit à un pull de l'école A).

**Fini quand** un bundle porteur des deux sections peuple les tables, et qu'un
bundle sans elles ne touche à rien.

---

## RD-F2 · La saisie au guichet

**Objectif.** Cocher, retenir, envoyer.

**Où.** Dans l'étape **Frais** (`student_charges_step`), au-dessus de la liste
des créances. Pas de huitième étape : les réductions portent sur des natures de
frais, elles appartiennent à cet écran.

**Ce qui est réutilisé tel quel.** L'étape porte déjà la garde
`PermissionGate.allows(context, [Perm.financeGridRead])` **avec son abonnement
aux changements de droits en séance** (`_syncTariffsWithheld` /
`_onPermissionsChanged`). Le barème est caviardé par le même droit que la
grille : le verdict existant vaut pour les deux, il n'y a **rien à recâbler**.

**Rendu** (taux masqué, décision actée) :

```
┌ Réductions ────────────────────────────┐
│ ☑ Enfant du personnel                  │
│ ☐ Fratrie (2e enfant)                  │
└────────────────────────────────────────┘
```

- Barème vide → **la section ne s'affiche pas**. Un cadre vide ferait chercher
  au guichet ce qui manque.
- Droit absent → rien non plus, et le bandeau « grille non communiquée » déjà
  présent dit ce qu'il faut.
- **Pas de mention de montant, pas de total barré, aucun chiffre.**

**Persistance.** À la validation de l'étape, `enrollment_reductions` est
remplacée pour cette inscription (delete + insert dans la transaction du
brouillon). Le brouillon local doit survivre à une sortie/reprise du wizard,
comme le reste de l'étape.

**Envoi.** `EnrollmentPayload.reductionCodes` → `EnrollmentCommand.toJson()` →
`EnrollmentAggregateRequest.toJson()`, **émis seulement si non vide** (piège 4),
et relu en tolérance (`as List<dynamic>?  ?? const []`).

**Tests.** L'aller-retour du payload d'outbox, **y compris un payload legacy sans
la clé** ; et un test qui prouve que le semis des créances est identique avec et
sans codes cochés.

**Fini quand** cocher deux réductions envoie deux codes, et ne bouge aucun
montant.

---

## RD-F3 · La relecture

**Objectif.** Ce que le serveur a gravé redescend et s'affiche.

- `EnrollmentAggregateSnapshotDto` : `reductionCodes` sur l'objet `enrollment`,
  **liste tolérante** (absente = pas de section, pas « aucune réduction »).
- L'ACK (`ResponseEnrollment`) : idem, et il écrase le local — le serveur fait
  foi sur ce qu'il a réellement gravé.
- Hydratation de `enrollment_reductions` **uniquement quand la section est
  portée**. Un delta pull qui ne la porte pas ne doit rien effacer : c'est le
  piège 3, transposé à l'inscription.
- Affichage : la même section, en lecture seule, dans le wizard en consultation
  et sur la fiche élève.

⚠️ Le back le note et ça nous concerne : **un octroi ne touche pas
`enrollments.server_updated_at`**. En V1 c'est sans effet — l'octroi est
simultané à l'inscription, la ligne est neuve de toute façon. Mais dès que la V2
détachera l'octroi, **un octroi posé après coup sera invisible à notre pull**.
Ne pas construire d'écran V2 qui suppose le contraire.

**Test.** Un agrégat porteur de deux codes hydrate la table ; un agrégat sans la
section ne l'efface pas.

**Fini quand** une inscription poussée puis repullée réaffiche ses réductions.

---

## 4. Hors périmètre, et pourquoi

| | |
|---|---|
| **RD-F4** · écran de gestion du barème | Décision actée. Le barème se peuple côté serveur. C'est le premier lot de la suite |
| Le calcul, l'arrondi, la collision de rubrique | V2 côté back d'abord — le front n'a rien à calculer, jamais |
| `gross_amount_in_cents` local | Inutile tant que rien n'est réduit. Le DTO du back peut le porter, on l'ignore |
| Octroi hors inscription | V2, et il lui faudra son flux (cf. l'avertissement de RD-F3) |
| Réduction sur l'attestation / le ticket | L'éditique est scellée serveur, rien à faire ici |

---

## 5. Volume

Quatre lots, schéma **v35 → v36**, ~8 fichiers touchés et ~5 créés, aucune
route Retrofit nouvelle, **aucune permission nouvelle**. Strings FR + EN pour
le titre de section et les libellés d'état vide — et `dart format lib/l10n/`
après `gen-l10n`, sinon 3 clés = 1500 lignes de churn.

Tests ciblés, quatre : le palier v36 · le tri-état + le scope école · l'aller-
retour d'outbox y compris legacy · **les montants ne bougent pas**.

---

## 6. À confirmer contre `openApi.yaml` dès que V107 est poussée

Les noms ci-dessous sont **proposés**, pas relevés — le back n'a rien livré.

1. `reductionTypes` / `reductionLines` — nom exact des deux sections racine.
2. Les champs d'un type : `code`, `label`, et le nom du drapeau d'activité
   (`active` ? `enabled` ?).
3. Les champs d'une ligne : `reductionCode` ou `typeCode` ? `value` ou
   `percentage` ? Type numérique (entier 0–100, ou décimal).
4. `reductionCodes` sur l'`enrollment` : **au même niveau que `medicalNotes`**,
   ou dans un objet à part ?
5. L'ACK renvoie-t-il les codes sur `enrollment`, ou dans une section propre ?
6. Le 422 sur un code inconnu : `detailCode` exact, et **est-il terminal** ? Un
   code retiré du barème pendant que la tablette était hors ligne ne doit pas
   condamner l'inscription entière — c'est la leçon de `422 AMBIGUOUS_EMERGENCY_CONTACT`.

Le point 6 est le seul qui puisse coûter une inscription au guichet. Les cinq
autres coûtent un renommage.
