# INSCRIPTION_INTAKE_PLAN.md — ce que le guichet sait vraiment d'un élève

> **Statut :** **PLAN ENTIÈREMENT LIVRÉ** (2026-08-30). Les quatre arbitrages
> sont tranchés (§7), les huit lots INT-0 → INT-8 sont écrits, non commités.
>
> **Origine :** quatre demandes fonctionnelles sur le formulaire d'inscription —
> moyenne / rang / année validée facultatifs, case « ancien élève », tuteur
> « contact d'urgence », zone de texte sur l'état de santé de l'enfant.
>
> **Le back est déjà livré.** Commit `1f78985` *feat(enrollment): record what the
> desk actually knows about a pupil* sur `feat/parametrage-automatique-l0`
> (41 fichiers, migrations **V100** et **V101**, `openApi.yaml` à jour, ~640 lignes
> de tests). Ce plan ne redemande rien au back sur le fond : il aligne le front
> sur un contrat qui existe, et n'ouvre que quatre points de finition (§8).
>
> **Docs de contexte :** `openApi.yaml` du back (source de vérité) ·
> `CLAUDE.md` §règles non-négociables · `AGENTS.md` §"États partagés" ·
> `OFFLINE.md` (régimes de sync).

---

## 1. Le fait déterminant

**Les données étaient déjà facultatives ; c'était l'écran qui les exigeait — et
quand l'écran n'exigeait pas, le serveur inventait.**

En base, `previous_rate`, `previous_rank` et `validated_previous_year` sont
nullables **depuis V6.0.1**. La contrainte ne vivait que dans le DTO
`UpdateEnrollmentRequest`. Conséquence directe, corrigée par `1f78985` : la
prévisualisation de réinscription (`createEnrollmentDetail`) injectait **70 %,
1er de classe, année validée** dans *chaque* dossier — des valeurs nées d'un
`@NotNull`, indiscernables à l'écran d'une vraie saisie.

Le front reproduit aujourd'hui la même fabrication, d'un cran plus bas. La
couche offline est pourtant déjà nullable de bout en bout :

| Couche front | `previousRate` | `validatedPreviousYear` |
|---|---|---|
| `enrollment_finance_offline_schema.dart:142` (`enrollments`) | `REAL` nullable | `INTEGER` nullable |
| `local_enrollment.dart:25` | `double?` | `bool?` |
| `enrollment_outbox_payload.dart` | `double?` | `bool?` |
| **`enrollment_school_detail.dart:19`** (entité de rendu) | **`double` non nullable** | **`bool` non nullable** |
| `local_enrollment_detail_mapper.dart:79` | `?? 0` | `?? false` |

Le `?? 0` et le `?? false` de la ligne 79 sont l'exact équivalent du 70 % du
back : ils transforment « on ne sait pas » en « zéro pour cent, année non
validée », et le résumé l'imprime tel quel
(`summary_previous_academic_section.dart:70` → `'${previousRate}%'` = **« 0% »**).

Et il y en a une troisième, dans le formulaire lui-même. Les trois listes
déroulantes de l'étape ne sont **jamais vides** :
`_resolveYear` rend `options.first` quand la valeur est absente
(`previous_academic_info_step.dart:99`), et `_syncCycleAndLevelWithCatalog`
retombe sur `catalog.firstCycle` puis `firstLevelForCycle`. Un dossier neuf
s'ouvre donc déjà sur « 2025-2026 · Maternelle · 1ʳᵉ année » — trois réponses que
personne n'a données. Tant que les champs étaient obligatoires, cela passait pour
une commodité de saisie ; du jour où ils deviennent facultatifs, c'est de
l'invention pure.

**Rendre le bloc facultatif n'est donc pas un travail de formulaire. C'est faire
remonter un `null` jusqu'à l'écran, lui donner un rendu, et cesser de le remplir
en chemin.** Le reste des demandes (ancien élève, santé, contact d'urgence) est
du transport neuf, plus mécanique.

---

## 2. Ce que le back a livré, exactement

### 2.1 Bloc « école précédente » facultatif

`UpdateEnrollmentRequest` perd son bloc `required:` entier ; `previousRate`,
`previousRank`, `validatedPreviousYear` deviennent nullables. `createEnrollmentDetail`
ne fabrique plus rien : la preview RE renvoie désormais `null` sur les quatre
champs de résultat.

⚠ **Sémantique de remplacement.** `PUT /api/v1/enrollments/{id}/previous-school-info`
réécrit le bloc **en entier** : un champ omis est **effacé**, pas conservé. C'est
voulu (sans quoi une valeur saisie par erreur ne pourrait jamais être remise à
vide). **Deux exceptions**, et seulement deux :

- `formerStudent` — colonne `NOT NULL`. Omis → **valeur stockée conservée**
  (jamais re-dérivée du type d'inscription, qui écraserait une déclaration du
  guichet).
- `medicalNotes` — omis → **conservé** ; chaîne vide → **vidé**. La perte serait
  asymétrique et muette : la note peut venir d'une tablette, et un poste encore
  déployé en version antérieure effacerait des allergies en corrigeant l'école
  précédente, à travers un `@Modifying` qui ne laisse **aucune trace** au journal.

### 2.2 `formerStudent` — « nouveau / ancien » du formulaire

`enrollments.former_student BOOLEAN NOT NULL DEFAULT FALSE` (V100), backfill
`TRUE` sur `enrollment_type = 'RE_ENROLLMENT'`.

**Délibérément indépendant de `enrollment_type`** : l'enum décrit le chemin
technique du dossier, le drapeau un fait déclaré au guichet. Une école qui
démarre sur l'application inscrit **tous ses anciens élèves en
`NEW_ENROLLMENT`**, faute de dossier N-1 — c'est précisément le cas que la case
à cocher sert à dire.

Repli serveur (`EnrollmentType.formerStudentOrDefault`) : absent → dérivé du
type (`RE_ENROLLMENT` → `true`, **`PRE_ENROLLMENT` → `false`**), **à la création
seulement**. Les postes déjà déployés continuent donc de pousser sans mise à jour.

Porté par : `UpdateEnrollmentRequest`, `UpdateEnrollmentResponse`,
`EnrollmentDetailInternal`, `EnrollmentInput` (push agrégat),
`EnrollmentSnapshot` (pull hydratant). **Absent** de `EnrollmentDelta` et de
`PreEnrollment`.

### 2.3 `medicalNotes` — fiche santé

`enrollments.medical_notes TEXT` (V100), **max 2000** au contrat (`@Size` sur
`EnrollmentInput`). Portée par l'**inscription**, pas par l'élève : `saveStudent`
est un *get-or-return*, une note posée sur `students` serait figée à vie dès la
première saisie.

Donnée de santé : **rédigée au journal d'activité** (motif `"medical"` ajouté à
`SensitiveFields`), jamais rendue dans les pièces imprimées, jamais exposée au
portail parent.

Reprise N-1 sur les **deux** canaux : `ReenrollmentCandidate.medicalNotes`
(cohorte offline) et la preview en ligne. ⚠ Côté cohorte, c'est une
**proposition** : elle ne devient la valeur du nouveau dossier **que si le poste
la repousse dans son agrégat**. L'ingest écrit `in.medicalNotes()` tel quel — un
front qui la lit sans la renvoyer perd la fiche santé à chaque changement d'année.

V100 supprime au passage `students.medical_information_id` (colonne morte depuis
V5), derrière un garde qui **arrête le déploiement** si elle porte des valeurs.

### 2.4 `emergencyContact` — le tuteur à appeler

`student_parent_relationship.emergency_contact BOOLEAN NOT NULL DEFAULT FALSE`
(V101) + **index unique partiel** `ux_emergency_contact_per_student`
(`WHERE emergency_contact`). Le drapeau appartient au couple **(élève, tuteur)**,
comme `relationship_type` depuis V70 : un tuteur est *get-or-create* par
téléphone, une même ligne `parents` sert toute une fratrie — posé sur `parents`,
« contact d'urgence » deviendrait vrai pour **tous** les enfants du tuteur.

**Tri-état, partout :**

| Valeur envoyée | Effet serveur |
|---|---|
| `true` | désigne ce tuteur **et démote** les autres tuteurs de cet élève |
| `false` | retire **seulement celui-là** |
| absent / `null` | **ne touche à rien** — un client qui ignore le champ n'efface jamais une désignation |

Trois portes d'entrée :

1. `POST /api/v1/parents` (`CreateParentRequest.emergencyContact`) — déclare la
   parenté **et** pose le drapeau dans le même appel ;
2. `POST /api/v1/sync/enrollments` (`ParentInput.emergencyContact`) — le canal du
   wizard ;
3. **`PUT /api/v1/parents/students/{studentId}/emergency-contact`** — route neuve,
   permission `STUDENT_WRITE`, corps `{ parentId }` (**`null` = n'en désigner
   aucun**). Elle existe *parce qu'elle porte un `studentId`*, que
   `PUT /api/v1/parents/{parentId}` n'a pas : cette dernière applique ce qu'elle
   reçoit à **tous** les enfants du tuteur.
   Réponses : `204` · `404` (élève inconnu, ou tuteur non rattaché) · `409`
   (course entre deux tablettes — **rejouable, le rejeu converge**) · `422`
   `UNDECLARED_RELATIONSHIP` (tuteur rattaché mais parenté jamais déclarée — cas
   d'un élève créé par `POST /students` avec `parentIds` ; sortie : rejouer
   `POST /api/v1/parents`).

⚠ **`422 AMBIGUOUS_EMERGENCY_CONTACT` sur le push.** L'agrégat porte la liste
**complète** des tuteurs de l'élève : en désigner deux n'est pas un conflit entre
postes, c'est une contradiction interne à un seul push. Le serveur refuse
**avant toute écriture**, sans arbitrer. **Un rejeu identique échouera toujours** :
c'est une erreur terminale, à empêcher à la saisie, jamais à retenter.

Le pull d'agrégat descend les tuteurs en `ParentDetailDto`, qui porte désormais
`emergencyContact` (`StudentPortImpl.getParentsByStudentIds` lit la relation
entière, plus seulement son type).

---

## 3. Ce qui manque côté front

### 3.1 Transport (rien n'existe)

| Fichier | Manque |
|---|---|
| `core/database/schema/enrollment_finance_offline_schema.dart` | `enrollments.former_student`, `enrollments.medical_notes`, `student_parent.emergency_contact`, `ref_previous_year_students.medical_notes` |
| `core/database/app_database.dart` | palier `upTo(32)` — la base est en **v31** (`app_constants.dart:441`) |
| `offline/domain/entities/local_enrollment.dart` | 2 champs |
| `offline/data/sync/enrollment_outbox_payload.dart` | 2 champs sur `EnrollmentPayload`, 1 sur `ParentPayload` |
| `offline/data/sync/enrollment_aggregate_request.dart` | 3 clés au JSON de push |
| `offline/data/sync/enrollment_snapshot_pull_models.dart` | 2 champs sur `EnrollmentSnapshotDto`, 1 sur `ParentSnapshotDto` |
| `offline/data/sync/reenrollment_cohort_pull_models.dart` | `medicalNotes` |
| `offline/domain/repositories/enrollment_offline_repository.dart` | `ConfirmParentDraft.emergencyContact` |
| 4 DAO (`enrollment_draft_dao`, `enrollment_reconciliation_dao`, `enrollment_read_dao`, `enrollment_dao_support`) | lecture/écriture des colonnes |

### 3.2 Gardes qui bloquent (facultatif ≠ possible)

- `enrollment_stepper_state_helper.dart:59-63` — exige **les sept champs** du
  bloc (école, cycle, niveau, année, moyenne `> 0`, rang non nul). Ferme l'étape
  et, par ricochet, la finalisation.
- `previous_academic_info_step.dart` — `_recomputeFormState` et
  `_buildValidationErrors` exigent les mêmes sept.
- `validated_year_selector.dart` — `SegmentedButton<bool>` à deux segments :
  **aucun moyen d'exprimer « non renseigné »**. C'est le vrai obstacle d'INT-2.
- `previous_academic_info_step.dart:_applyAutoValidatedYearFromRate` — dérive
  « année validée » de la moyenne (`> 50`). Sans moyenne, la valeur reste à son
  initial `false` : une réponse inventée, exactement ce que le back a supprimé.
- **Les trois listes déroulantes se remplissent seules** (§1) : `_resolveYear`,
  `catalog.firstCycle`, `firstLevelForCycle`. Aucune ne sait rester vide.

### 3.3 Chemins morts à traiter au passage

`ParentBloc` et `EnrollmentAcademicInfoBloc` sont **enregistrés dans
`injection.dart` (l.710, l.736) et consommés par aucune page** : toute écriture
réelle du wizard passe par l'agrégat offline. Or
`UpdateEnrollmentAcademicInfoRequest` déclare `previousRate` **non nullable** et
`validatedPreviousYear` **non nullable** : rebranché tel quel, il enverrait
`0.0` / `false` — la fabrication, une quatrième fois.

**Décision (§7.4) : suppression, différée.** Aucun lot n'y touche ; le chemin
reste inerte jusqu'à son retrait. Une conséquence à assumer dès maintenant : le
`PUT /previous-school-info` est le **seul** moyen de corriger l'école précédente
ou la fiche santé d'un dossier finalisé. Le supprimer ferme cette porte — la
correction après finalisation se limite alors au **contact d'urgence** (INT-7),
qui a sa propre route. Rouvrir les autres champs plus tard voudra dire réécrire
ce chemin, proprement, avec des champs nullables.

### 3.4 Une contrainte qui décide du périmètre

Un dossier **finalisé est en consultation intégralement en lecture seule**
(`LocalConsultationDetailPolicy`, court-circuitée systématiquement pour
`firstRegistration`). Il n'existe aujourd'hui **aucun chemin de correction d'un
dossier confirmé**, et le push d'agrégat est un *get-or-return* par `(élève,
année)` : un second push ne réécrit rien.

Conséquence : la route `PUT …/emergency-contact` n'a aujourd'hui **aucun
consommateur**. **Décision (§7.3) : on ouvre cette écriture** — c'est le lot
**INT-7**, désormais obligatoire. Il perce le premier trou dans une page qui
était jusqu'ici figée par construction, et c'est pour cela qu'il reste un lot
séparé, en fin de chaîne : la lecture seule reste la règle, la désignation du
contact d'urgence en devient l'unique exception, nommée et gardée.

---

## 4. Les cinq pièges

1. **Le `?? 0` déplacé.** Rendre le champ nullable dans l'entité sans traiter les
   rendus produirait `null%` à l'écran. Chaque site d'affichage doit rendre `—`.
2. **Le payload outbox déjà en file.** Une inscription confirmée avant la mise à
   jour attend dans l'outbox avec un JSON **sans** `formerStudent`. `fromJson`
   doit replier (dérivation par le type), jamais `as bool`. Même précaution que
   `sourceRef` en son temps.
3. **La fiche santé qui s'évapore en réinscription.** La cohorte propose
   `medicalNotes` ; si le seed du brouillon la lit sans que le push la renvoie,
   la note disparaît à chaque changement d'année — le canal tablette ferait
   silencieusement pire que le guichet en ligne.
4. **Deux contacts d'urgence dans un même agrégat.** `422` terminal, non
   rejouable, **inscription bloquée dans l'outbox**. La garde doit être à la
   saisie (exclusivité visible) *et* avant l'écriture en outbox — jamais
   seulement au retour serveur.
5. **`false` n'est pas « ne rien dire ».** Envoyer `emergencyContact: false` sur
   tous les tuteurs non désignés retire une désignation posée ailleurs. Règle :
   `true` sur le désigné, **omis** sur les autres (le serveur démote déjà) ;
   `false` uniquement quand l'utilisateur a explicitement **retiré** la
   désignation sans en poser d'autre.
6. **Un formulaire qui répond à la place du guichet.** Rendre les quatre champs
   texte facultatifs sans neutraliser les auto-sélections (§1) donnerait le pire
   des deux mondes : plus aucune obligation de saisir, et une école précédente
   quand même écrite en base — celle du haut du catalogue. Un champ facultatif
   doit pouvoir **rester vide**, y compris à l'ouverture.

---

## 5. Les lots

**Huit lots, tous obligatoires** depuis les décisions du §7. Chacun compile,
passe `flutter analyze` et `flutter test` seul.

### INT-0 — Socle de données (schéma **v32**) — ✅ LIVRÉ

- 4 colonnes (§3.1), toutes en `ALTER TABLE … ADD COLUMN` idempotent.
  `former_student INTEGER NOT NULL DEFAULT 0`, les trois autres nullables.
  Backfill `former_student = 1` sur `enrollment_type = 'RE_ENROLLMENT'`, même
  compromis assumé que V100 côté serveur.
- Index unique partiel local, miroir de V101 :
  `CREATE UNIQUE INDEX ux_emergency_contact_per_student ON student_parent(student_id) WHERE emergency_contact = 1`.
- `AppConstants.offlineDbSchemaVersion` 31 → 32, palier `upTo(32)`.
- Tests : `test/core/database/offline_migration_intake_v32_test.dart` (10).

**Deux choses que l'écriture a apprises, et que le plan n'avait pas vues :**

**a. Le palier v2 cassait toute base montant de v1.** Il rejoue le schéma
d'*aujourd'hui* en `IF NOT EXISTS` sur une base d'*alors* — et pour une table
déjà présente, `CREATE TABLE IF NOT EXISTS` est un no-op tandis que ses index,
eux, sont créés quand même. Notre index partiel filtre sur
`student_parent.emergency_contact`, colonne née trente paliers plus loin :
`no such column`, et l'escalier entier échouait. Défaut structurel latent depuis
toujours, révélé par le premier index citant une colonne postérieure. Corrigé
là où il est : ce palier ne pose plus que les index des tables qu'il vient
lui-même de créer — ce que son propre commentaire annonçait déjà. Test de
non-régression au v32.

**b. L'index n'est pas le filet qu'on croyait.** Les liens `student_parent`
s'écrivent en `INSERT OR REPLACE`, et sous ce mode SQLite **supprime la ligne en
conflit** au lieu de refuser. Une seconde désignation ne lèverait donc pas :
elle ferait disparaître le lien du tuteur désigné en premier — le tuteur, pas
seulement son drapeau. La garde est donc **applicative et préalable**
(`AmbiguousEmergencyContactException`, levée avant toute écriture, y compris
avant la purge des liens) ; l'index ne protège que les chemins qui n'écrasent
pas.

### INT-1 — Transport (modèles, payloads, DAO) — ✅ LIVRÉ

- `LocalEnrollment`, `EnrollmentLocalModel` : `+ bool formerStudent` (défaut
  `false`), `+ String? medicalNotes`.
- `EnrollmentPayload` : idem, **`fromJson` tolérant** (piège 2) — un payload
  d'outbox antérieur au champ retombe sur la dérivation par le type.
- `ParentPayload` / `ConfirmParentDraft` / `ParentDraft` / `LocalParent` :
  `+ emergencyContact` — le tri-état est conservé **jusqu'au fil**, pas aplati
  en `bool`. (`LocalParent` fait exception : c'est une lecture d'état, pas une
  intention — `bool` non nullable.)
- `EnrollmentAggregateRequest.toJson` : `formerStudent`, `medicalNotes`, et
  `emergencyContact` par tuteur — **omis quand `null`** (`if (… != null)`),
  jamais `false` par défaut.
- Pull : les 3 DTO (§3.1), tous en lecture tolérante ; cohorte N-1 →
  `ref_previous_year_students.medical_notes` (écriture au pull + relecture).
- DAO : brouillon, détail, réconciliation.
- Tests : 5 fichiers touchés, ~20 cas ajoutés.

**Ce que l'écriture a appris :** `_replaceParentsIn` **purge tous les liens de
l'élève** avant de les réécrire. Un draft muet (`null`) y perdait donc la
désignation en place à chaque passage sur l'étape Tuteurs — corriger un numéro
de téléphone aurait effacé le contact d'urgence. La photo des désignations est
désormais prise **avant** la purge et reconduite pour tout draft qui ne dit
rien : « ne rien dire » vaut « ne touche à rien » **en local aussi**, pas
seulement sur le fil.

Et à la sortie, la projection du payload n'envoie que la désignation :
`emergency_contact = 1` → `true`, tout le reste → **clé absente**. Le serveur
démote déjà les autres tuteurs quand il reçoit une désignation ; un `false`
projeté sur chaque tuteur ordinaire retirerait une désignation faite depuis un
autre poste. Le `false` explicite reste possible, mais viendra de l'écran qui le
demande (INT-5), jamais d'une projection.

`AmbiguousEmergencyContactFailure` est typée dès maintenant (et non rabattue sur
`StorageFailure`) : l'écran d'INT-5 doit pouvoir dire **quoi** corriger.

### INT-2 — Bloc « école précédente » entièrement facultatif — ✅ LIVRÉ

Décision §7.1 : **les sept champs** deviennent facultatifs, pas seulement les
trois nommés. L'étape peut être traversée **vide** — c'est le cas de l'enfant
qui entre en première année de maternelle, et il n'a plus à inventer une
scolarité pour avancer.

- `EnrollmentSchoolDetail` : `previousRate` → `double?`,
  `validatedPreviousYear` → `bool?` ; suppression des `?? 0` / `?? false` du
  mapper (`local_enrollment_detail_mapper.dart:79-81`, `:133-135`). Les quatre
  champs texte restent `String` mais leur `''` doit se rendre `—`, jamais un
  libellé de catalogue.
- `isAcademicPreviousInfoValid` : ne valide plus la **complétude** — le bloc vide
  est valide. Elle ne garde que la **cohérence de format** (une moyenne saisie
  doit parser, un rang saisi doit être un entier). Renommer en conséquence :
  la fonction ne dit plus « le bloc est rempli » mais « le bloc est lisible ».
- **Neutraliser les auto-sélections** (piège 6) : `_resolveYear` rend `null` —
  jamais `options.first` — quand la valeur est absente ; le cycle et le niveau
  restent `null` tant que le dossier n'en porte pas. Les trois `DropdownField`
  ouvrent sur un `hint`, pas sur une valeur. ⚠ `_syncCycleAndLevelWithCatalog`
  ne doit alors plus « résoudre » un vide vers le premier élément, seulement
  reconnaître une valeur existante dans le catalogue.
- `PreviousAcademicInfoStep` : `_buildValidationErrors` ne signale plus
  d'absence, seulement des formats. Borne `0 ≤ moyenne ≤ 100` : garde **front
  seule**, le contrat n'en pose pas.
- `ValidatedYearSelector` : troisième segment explicite **« Non renseigné »**
  (`SegmentedButton<bool?>`), plutôt qu'une déselection invisible. Reste neutre
  en couleur, comme aujourd'hui.
- `_applyAutoValidatedYearFromRate` : ne s'applique qu'avec une moyenne saisie ;
  moyenne effacée → retour à « non renseigné » tant que l'utilisateur n'a pas
  tranché lui-même.
- Rendus : `—` partout (résumé, détail) via `EnrollmentSummaryUtils.fallbackValue`.
  La section « Année précédente » du résumé doit rester lisible **entièrement
  vide** — pas une grille de tirets sans en-tête.
- ⚠ Ce lot rend possible un bloc vide **envoyé au serveur** : le PUT étant un
  remplacement (§2.1), c'est exactement ce qu'il faut pour effacer une saisie
  erronée. Aucun garde-fou à ajouter — mais le dire dans le test.
- `UpdateEnrollmentAcademicInfoRequest` : **hors périmètre**, suppression
  différée (§3.3, §7.4).
- Tests : 5 fichiers touchés, 2 fichiers neufs
  (`previous_academic_step_optional_test.dart`,
  `summary_previous_academic_section_test.dart`).

**Cinq tests retournés, aucun supprimé.** Ils épinglaient l'ancienne règle —
« sans rang, l'étape est invalide », « un payload muet vaut 0 % » — et un test
qui garde un défaut coûte plus cher qu'un test absent. Retournés, ils protègent
maintenant la règle inverse. Chacun a reçu sa contre-épreuve : une moyenne
**saisie** à zéro s'affiche bien « 0.0% », un « Non » reste réservé à un
redoublement déclaré. Sans elles, rendre `—` pour toute valeur passerait pour
une correction.

**Ce que l'écriture a appris — un gage mort.** `TargetAcademicInfoStep` ne
lançait le calcul automatique de la classe cible que si
`previousRank != null`. Ce n'était pas un caprice : le rang étant obligatoire
pour enregistrer l'étape Antécédents, sa présence prouvait qu'un humain était
passé par là — et donc que `validatedPreviousYear`, qui ne savait pas dire « non
renseigné », reflétait une vraie saisie plutôt que son défaut `false`. **Le rang
devenu facultatif, ce proxy ne prouve plus rien** : le calcul aurait cessé de
s'appliquer, sans un bruit, à tout dossier sans rang — c'est-à-dire à la
plupart. Le champ dit désormais lui-même s'il a été renseigné
(`validatedPreviousYear != null`), et le test qui gardait l'ancien gage a été
retourné puis doublé d'une contre-épreuve : *sans rang mais avec un verdict, le
calcul s'applique*.

C'est la trace la plus nette de ce que le tri-état répare. Un champ qui ne
savait pas se taire avait forcé, ailleurs, l'invention d'un signal détourné pour
deviner s'il avait parlé.

### INT-3 — Case « ancien élève » — ✅ LIVRÉ

- **Où** : en tête de l'étape *Scolarité antérieure*. C'est la question qui dit
  comment lire le reste du bloc — si l'enfant est un ancien de la maison,
  « l'école précédente », c'est nous.
- Défauts, alignés sur `formerStudentOrDefault` : `RE_ENROLLMENT` → coché et
  **non modifiable** (lecture seule *pleine couleur*, jamais grisé — cf. mémoire
  « champs lecture seule ») ; `NEW_ENROLLMENT` et `PRE_ENROLLMENT` → décoché,
  modifiable.
- Persistance : `SaveDraftPreviousAcademicRequested` porte le drapeau ; le DAO
  l'écrit sur `enrollments`.
- Résumé : ligne « Ancien élève de l'école — Oui / Non ».
- Tests : NEW coché → poussé `true` ; RE → `true` verrouillé ; PRE → `false` par
  défaut, modifiable.

### INT-4 — Fiche santé — ✅ LIVRÉ

- **Où** : étape *Identité*, bloc « Santé » en fin de formulaire (décision
  §7.2). C'est une donnée de l'enfant, pas de sa scolarité.
  `SaveDraftIdentityRequested` écrit déjà les deux tables — le champ y trouve sa
  place sans détour, même si la colonne vit sur `enrollments`.
- `EteeloTextInput` multiligne (`maxLines: 4`, `minLines: 3`), **`maxLength: 2000`**
  (le contrat rejette au-delà), capitalisation par défaut (`sentence` en
  multiline — rien à déclarer, règle #11).
- **Reprise N-1** : `ref_previous_year_students.medical_notes` → seed du
  brouillon RE → champ pré-rempli → **repoussé au push** (piège 3).
- Résumé et détail : section « Santé », `—` si vide.
- **Zéro log** : la fiche ne doit apparaître dans aucun `debugPrint`, aucun
  message d'erreur, aucun dump d'agrégat. Même doctrine que « zéro log argent ».
- Tests : seed RE conserve la note ; note vidée → chaîne vide poussée (et non
  clé omise) ; 2001 caractères refusés à la saisie.

### INT-5 — Contact d'urgence — ✅ LIVRÉ

- **UI** : sélection **exclusive** par carte tuteur — un `Radio` groupé à
  l'échelle de l'élève, pas une checkbox par carte : l'exclusivité doit se voir
  **avant** l'erreur, pas s'apprendre par un refus serveur. Désélectionnable
  (« aucun contact désigné »).
- **Local** : le DAO démote les autres tuteurs de l'élève **puis** promeut, dans
  la même transaction (miroir de `ParentService.demoteEmergencyContacts`).
- **Push** : garde *avant écriture en outbox* — au plus un `true` dans l'agrégat.
  Un `AMBIGUOUS_EMERGENCY_CONTACT` ne doit jamais partir (piège 4). Envoi :
  `true` sur le désigné, **omis** sur les autres (piège 5).
- **Pull** : `emergencyContact` du `ParentDetailDto` reflété en local à la
  réconciliation.
- Résumé, détail, ligne tuteur : pastille « Contact d'urgence ».
- Tests : désigner B décoche A dans l'UI **et** en base ; deux `true` impossibles
  à construire ; agrégat sans désignation → aucune clé `emergencyContact` ;
  pull d'un dossier désigné → pastille au bon tuteur.

### INT-6 — Rendu du dossier et réconciliation — ✅ LIVRÉ

- Page détail (lecture seule) : ancien élève, fiche santé, pastille contact
  d'urgence.
- Snapshot hydratant : les 3 champs écrits en local ; `formerStudent` est
  `NOT NULL` au contrat, mais la lecture reste tolérante (`?? dérivé du type`) —
  un snapshot servi par un back plus ancien ne doit pas faire tomber le pull.
- Tests : hydratation d'une tablette neuve restitue les 3 informations.

### INT-7 — Corriger le contact d'urgence après finalisation — ✅ LIVRÉ

Décision §7.3 : **on ouvre cette écriture.** C'est la première — et pour
l'instant la seule — brèche dans une page de consultation figée par
construction (§3.4). Elle est donc nommée, gardée, et sans effet de bord sur le
reste du dossier.

**Chemin, de haut en bas**

- `AppConstants` : `parentEmergencyContactEndpoint =
  '/api/v1/parents/students/{studentId}/emergency-contact'`.
- `ParentRemoteDataSource` : `@PUT`, corps `{ parentId }` — **`null` autorisé et
  signifiant** (« n'en désigner aucun »), donc jamais un `@Query` ni une route
  sans corps : un paramètre absent ne se distingue pas d'un oubli.
- Repository → usecase → `ParentBloc` (aujourd'hui dormant, ici **rebranché**).
- UI : action sur la ligne du tuteur, dans la page détail en consultation.

**100 % online, hors outbox** — même doctrine que l'éditique
(`editique_repository_impl.dart:177`) : pré-garde `ConnectivityService.isOnline()`
dans le repository, `NetworkFailure` explicite, **jamais** de mise en file. Une
désignation n'est pas une saisie de guichet qu'on rejoue plus tard : la route
n'est pas idempotente au sens de l'outbox, et un rejeu différé désignerait
peut-être un tuteur que quelqu'un a entre-temps délogé.

**Le reflet local, sinon l'écran ment.** La consultation est intégralement
locale (`LocalConsultationDetailPolicy`). Après un `204`, écrire le drapeau en
base locale dans la foulée — **démote puis promeut, même transaction**, comme
INT-5 — sinon l'ancien contact reste à l'écran jusqu'au prochain pull. Le
serveur, lui, remonte le curseur de synchro du dossier (`GuardianChangedEvent`) :
le pull confirmera, il ne fait pas foi dans la seconde.

**Les quatre réponses, et ce qu'elles valent**

| Code | Conduite |
|---|---|
| `204` | reflet local, puis rendu |
| `404` | élève inconnu **ou** tuteur non rattaché — erreur de données, pas de rejeu |
| `409` | course entre deux tablettes — **rejouable, le rejeu converge** ; proposer « Réessayer » |
| `422 UNDECLARED_RELATIONSHIP` | tuteur rattaché mais parenté jamais déclarée : message avec **sa sortie** (déclarer la parenté), pas un « contactez le support » |

⚠ Le `422` n'est distinguable qu'**au préfixe du message** tant que la demande
back n°1 (§8) n'est pas servie : `detailCode` n'est pas renseigné sur cette
cause. Isoler ce test dans **une seule fonction** de parsing, marquée comme
provisoire, pour n'avoir qu'un endroit à corriger le jour où le code arrive.

**Gardes** : `PermissionGate(requires: [Perm.studentWrite])` — la permission
existe (`permissions.dart:114`) et n'est **branchée nulle part** aujourd'hui,
c'est ici son premier usage — composé avec `SessionWriteGate` (une session en
lecture seule gèle, une permission absente masque : deux gestes, deux causes).

- Tests : `204` → base locale à jour sans pull ; `409` → « Réessayer » proposé ;
  `422` → message avec sortie ; hors ligne → action inerte et **rien en outbox** ;
  permission absente → action absente ; session lecture seule → action gelée.

### INT-8 — Revue et durcissement — ✅ LIVRÉ

Revue adversariale ciblée, puis **mutations** — débrancher chaque garde et
vérifier qu'un test rougit :

- retirer la garde « au plus un `true` » avant outbox ;
- ne pas repousser `medicalNotes` au seed RE ;
- remettre `?? 0` dans le mapper ;
- retirer le repli `formerStudent` du `fromJson` outbox ;
- envoyer `false` au lieu d'omettre sur les tuteurs non désignés ;
- rétablir `options.first` dans `_resolveYear` (le formulaire se remplit seul) ;
- supprimer le reflet local après le `204` d'INT-7 (l'écran garde l'ancien
  contact et personne ne s'en aperçoit avant le pull suivant).

Une garde qu'aucune mutation ne fait rougir n'est pas testée.

**Résultat : 7 mutations, 6 rouges du premier coup, 1 verte — et c'est celle-là
qui comptait.** Remettre le `?? 0` dans `local_enrollment_detail_mapper` ne
faisait rougir personne. Les rendus ont bien leurs tests, mais ils construisent
leur `EnrollmentSchoolDetail` à la main : aucun ne passait par le mapper, et la
garde la plus centrale d'INT-2 — celle qui empêche « on ne sait pas » de
s'afficher « 0% » — n'était donc pas tenue. Deux cas ajoutés au mapper, la
mutation rougit, les sept passent.

### La revue, et ce qu'elle a trouvé que la mutation n'atteignait pas

Quatre défauts, tous dans le travail de ces lots. Trois portaient sur des gardes
que je croyais posées.

**1. `INSERT OR REPLACE` détruisait le lien au PULL (critique).** J'avais
identifié le piège pour l'étape Tuteurs — SQLite résout un conflit d'unicité en
*supprimant* la ligne — et posé la garde applicative là. **Le chemin du pull
écrivait le même drapeau sous le même mode, sans garde.** Hydrater un dossier
dont le serveur désigne A faisait disparaître le lien entier d'un tuteur local
provisoire B désigné localement : celui-là même que `_pruneStudentParentLinks`
s'interdit de purger, et qui n'avait même pas l'occasion d'être épargné.

Pire, le correctif évident ne suffisait pas : **ne pas écrire la colonne ne la
préserve pas** sous `REPLACE`, qui supprime puis réinsère — `emergency_contact`
retombait à 0 à chaque pull. Le lien s'écrit désormais en `INSERT OR IGNORE`
suivi d'un `UPDATE` ciblé, et la désignation s'applique en une passe séparée,
après toute la liste, en démote-puis-promeut. Trois cas la couvrent, dont le
tri-état du serveur : `true` désigne, `false` démote, `null` (back antérieur au
champ) **ne touche à rien** — une désignation locale en attente de push ne doit
pas mourir du silence d'un vieux serveur.

**2. Le retrait de désignation mourait au dernier saut (haut).** L'écran
produisait bien un `false` explicite, mais la projection du DAO rendait
`0 → null` : la base ne distingue pas « jamais désigné » de « retiré », et mon
commentaire « `true` ou rien » raisonnait sur un tuteur isolé. Résultat : case
décochée, lien local à 0, clé absente du fil, serveur inchangé — et le pull
suivant qui remet tout comme avant. **Un test épinglait ce comportement comme
une garantie** ; il a été retourné. L'agrégat portant la liste complète des
tuteurs, envoyer `false` n'écrase rien qu'il ne dise déjà.

**3. Le verdict de l'année s'effaçait en corrigeant autre chose (haut).** La
dérivation « moyenne > 50 ⇒ année validée » était rejouée à **chaque frappe,
dans n'importe quel champ**. Sans importance tant que la moyenne était
obligatoire ; depuis INT-2, un dossier peut porter « Oui » sans moyenne — et
corriger une faute dans le nom de l'école suffisait à effacer ce verdict, puis à
couper le calcul automatique de la classe cible, qui s'arrête sur `null`. La
déduction ne se déclenche plus que si la **moyenne** a changé.

**4. « Réessayer » sur un écran quitté (bas).** Un bandeau d'erreur survit au
changement de route ; le rappel touchait un élément mort. Garde `mounted`.

Les trois premiers sont devenus les mutations **8, 9 et 10** — toutes rouges.

---

## 6. Ordre et dépendances

```
INT-0 (schéma v32)
  └─ INT-1 (transport)
       ├─ INT-2 (bloc précédent facultatif)   ← indépendant des trois autres
       ├─ INT-3 (ancien élève)
       ├─ INT-4 (santé)  ← dépend d'INT-1 pour la cohorte N-1
       └─ INT-5 (contact d'urgence, dans le wizard)
            └─ INT-6 (rendu + réconciliation)
                 └─ INT-7 (correction après finalisation)
                      └─ INT-8 (revue)
```

INT-2 est le lot le plus risqué — il touche une entité partagée, quatre écrans,
et c'est lui qui doit **cesser de remplir** trois listes déroulantes — et le seul
qui ne dépende d'aucun des autres : le livrer en premier après INT-1 laisse le
maximum de temps de recul avant la revue.

INT-7 vient **après** INT-6 et non en parallèle : il écrit le même drapeau, par
un autre chemin, dans une page dont le rendu n'existe qu'à partir d'INT-6. Le
brancher plus tôt reviendrait à corriger une information qui n'est pas encore
affichée.

---

## 7. Décisions (2026-08-30)

Les quatre arbitrages sont tranchés. Ils sont reportés dans les lots ; ce
paragraphe garde la raison, que le code ne dira pas.

1. **Tout le bloc « école précédente » devient facultatif** — les sept champs,
   pas les trois nommés. On rejoint la portée du back : *un enfant entrant en
   première année de maternelle n'a pas d'école précédente*, et devait jusqu'ici
   en inventer une pour franchir l'étape. Conséquence non triviale, traitée dans
   INT-2 : les trois listes déroulantes doivent **apprendre à rester vides**, ce
   qu'aucune ne sait faire aujourd'hui (§1, piège 6).
2. **Fiche santé sur l'étape *Identité***. C'est une donnée de l'enfant, et
   l'étape écrit déjà `students` **et** `enrollments` — la colonne peut vivre sur
   l'inscription sans que le formulaire s'en aperçoive.
3. **La correction après finalisation est ouverte** : INT-7 passe d'optionnel à
   obligatoire. Elle reste **strictement bornée au contact d'urgence** — la
   consultation demeure en lecture seule pour tout le reste. C'est la seule
   information du dossier qui doive pouvoir changer un jour d'accident, sans
   rouvrir le dossier entier.
4. **Le chemin online dormant sera supprimé**, pas aligné — et pas dans ces
   lots : il reste inerte, hors périmètre. À noter pour plus tard : c'est le seul
   moyen de corriger l'école précédente ou la fiche santé d'un dossier finalisé.
   Le retirer ferme cette porte volontairement ; la rouvrir voudra dire réécrire
   ce chemin avec des champs nullables, pas ressusciter celui-ci.

---

## 8. Demandes au back

Quatre points de finition. Aucun ne bloque un lot, mais le premier a changé de
statut depuis les décisions du §7.

1. **`detailCode` sur les deux 422** — *devenue nécessaire depuis la décision
   §7.3 : INT-7 doit reconnaître `UNDECLARED_RELATIONSHIP` pour offrir sa sortie,
   et n'a pour l'instant qu'un préfixe de message français pour le faire.*
   `AMBIGUOUS_EMERGENCY_CONTACT` et
   `UNDECLARED_RELATIONSHIP` sont aujourd'hui **préfixés dans le message**
   (`ParentService.java:140`, `EnrollmentIngestService.java:180`), alors que
   `UnprocessableException` sait porter un `detailCode` depuis `9bf9655` — écrit
   *après* eux. Brancher sur une phrase française est exactement la dépendance
   que ce champ existe pour éviter.
   *Côté front, dette jumelle déjà connue : `ApiErrorParser` ne lit pas encore
   `detailCode`.*
2. **`PreEnrollment` ne porte pas `medicalNotes`.** Une fiche santé saisie dans
   une préinscription est perdue au passage Pré → Première. Voulu ?
3. **`EnrollmentDelta` ne porte ni `formerStudent` ni `medicalNotes`.** Sans
   conséquence tant que le front hydrate par snapshot — à confirmer.
4. **Confirmation de doctrine** (aucun code attendu) : sur le push d'agrégat,
   `medicalNotes` omis vaut `null` — l'ingest écrit `in.medicalNotes()` tel quel,
   contrairement au PUT qui conserve. C'est bien au client de repousser la
   proposition N-1.

---

## 9. Checklist de sortie

- [ ] `flutter analyze` sans une seule issue (le hook de push l'exige)
- [ ] `flutter test` vert ; delta de tests annoncé lot par lot
- [ ] `build_runner` relancé — Retrofit est touché par INT-7
- [ ] Strings dans **les deux** `.arb`, `flutter gen-l10n` **puis
      `dart format lib/l10n/`** (sans quoi 3 clés = 1500 lignes de churn)
- [ ] Aucune couleur, dimension ni string en dur
- [ ] Migration v31 → v32 exercée sur une base réelle, pas seulement en création
- [ ] Aucune trace de `medicalNotes` dans un log, un toast ou un message d'erreur
- [ ] Un dossier neuf ouvre l'étape *Scolarité antérieure* sur **trois listes
      vides** — le test qui garde la décision §7.1
- [ ] Rien de ce que pose INT-7 n'atterrit dans l'outbox (100 % online)
- [ ] Les sept mutations d'INT-8 font rougir un test chacune
