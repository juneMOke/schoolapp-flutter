# Ré-édition d'un dossier d'inscription complété — plan

**But.** Un dossier déjà complété redevient modifiable. L'enregistrement le
repasse en `IN_PROGRESS` **local** et le remet dans la file de synchro ; le
push met réellement à jour le serveur. Même rôle que la création
(`ENROLLMENT_WRITE` côté back, `kEnrollmentSubmitAccess` côté app).

---

## Ce qui bloquait, et qui n'est pas dans l'app

`POST /sync/enrollments` est un chemin de **création**, pas de mise à jour.
Sur un dossier déjà ingéré :

| Étape (`EnrollmentIngestService`) | Comportement actuel |
|---|---|
| `studentPort.saveStudent` | *get-or-return* — « aucun écrasement » |
| `resolveEnrollment` | « Rejeu strict : même id → renvoyer l'existant » |
| `resolveStatus` | `in.status()` **jamais honoré** (NEW/RE → `COMPLETED`) |

Un dossier ré-édité et ré-envoyé serait donc acquitté 200 **sans effet**, et le
pull suivant écraserait les modifications locales. C'est très probablement la
raison pour laquelle la reprise d'un dossier serveur `IN_PROGRESS` a été
court-circuitée en lecture seule (fix #19, `enrollment_detail_policy.dart`).

Le back doit donc bouger en premier. Le front qui pousserait dans le vide est
pire que pas de fonctionnalité : il ferait croire à l'enregistrement.

---

## Décisions prises

1. **Statut serveur : inchangé.** `resolveStatus` continue de dériver
   `COMPLETED` pour NEW/RE. `IN_PROGRESS` est l'état **local** du dossier en
   cours d'édition et en attente d'envoi — exactement ce que vit déjà un
   NEW/RE (`finalizeStatus` local, `sync_status` pour le reste). Le pull
   ramène `COMPLETED` une fois le dossier ingéré. Aucune machine à états à
   écrire, aucune attestation à dé-sceller.

2. **Le niveau ne change pas en V1.** `materializeChargesForEnrollment` est
   idempotente *« s'il existe déjà des créances pour l'année, ne rien
   créer »* : changer le niveau laisserait l'élève facturé sur l'ancienne
   grille, **en silence**. Le front verrouille l'étape Classe cible et
   l'étape Frais ; le back refuse un niveau différent en 422.

3. **Bascule en brouillon à la 1re modification réelle**, pas à l'ouverture.
   Tant qu'un dossier est `DRAFT`, il sort de la recherche « élèves réellement
   inscrits » (`sync_status ∈ {SYNCED, PENDING_SYNC, SYNC_ERROR}`) : ouvrir un
   dossier « pour voir » ne doit pas le retirer de la facturation.

---

## Lot BACK — ✅ LIVRÉ (commit `2186e11`, branche `feat/parametrage-automatique-l0`)

2073 tests back verts. Contre-épreuve faite : chemin de mise à jour retiré ⇒
`editedFieldsAreApplied` et `changingLevelIsRejected` rougissent, les
garde-fous (rejeu identique, PRE intacte, annulé intact) restent verts.

**Trouvaille hors périmètre, à examiner à part** : la conversion d'une
préinscription réutilise le même id d'inscription, donc elle tombe sur le
« rejeu strict » et n'a **aucun effet serveur** — le dossier reste
`PRE_REGISTERED`, sans créances ni attestation, pendant que l'app affiche
`COMPLETED`.

## Lot BACK — détail de ce qui a été fait

**B1. Inscription : mettre à jour au lieu de renvoyer l'existant.**
Uniquement sur la branche `findById` (rejeu strict par id) — la branche de
dédup `byStudentYear` répond à un *autre* id client et garde son comportement
actuel : y écrire reviendrait à laisser un poste écraser le dossier d'un autre.
Champs mutables : identité recopiée, `previousSchool*`, `transferReason`,
`previousRate/Rank`, `validatedPreviousYear`, `formerStudent`, `medicalNotes`,
`enrollmentDate`. Jamais : `id`, `studentId`, `academicYearId`,
`enrollmentCode`, `enrollmentType`, `sourceRef`.

**B2. Garde de niveau (422).** Sur la branche de mise à jour, un
`schoolLevelId`/`schoolLevelGroupId` différent de celui en base est refusé —
code dédié, message qui nomme la raison (créances déjà projetées). Un rejeu
légitime envoie le même niveau et n'est pas concerné.

**B3. Élève : upsert.** `saveStudent` reste *get-or-return* (la voie en ligne
en dépend) ; l'ingest passe par un **nouveau** chemin de port qui met à jour
les champs de fiche. Jamais le matricule.

**B4. Tuteurs.** `ParentPort.upsertParent` : le rattachement était un
*get-or-create par téléphone* qui renvoyait le tuteur retrouvé **tel quel** —
un nom corrigé au guichet repartait et ne changeait rien. L'identité est
désormais rafraîchie ; le téléphone, clé de rapprochement, jamais touché.
⚠️ Un tuteur est partagé par la fratrie : le corriger depuis un dossier le
corrige pour tous — même sémantique que `PUT /api/v1/parents/{id}`.

**B5. Réductions — ⬜ RESTE À FAIRE.** `reductionGrantPort.grant` est rejoué à
chaque ingestion : son idempotence et le sort d'un code **retiré** de la liste
n'ont pas été vérifiés dans ce lot.

**B6. Tests.** ✅ 6 tests : champs corrigés appliqués · rejeu à l'identique
n'écrit pas (curseur de synchro) · niveau différent → 422 · préinscription
intacte · dossier annulé intact · l'élève passe par l'upsert.

---

## Lot FRONT — rouvrir, éditer, remettre en file

**État : ✅ TOUT LIVRÉ (F1→F6).**

- ✅ **F3** — ré-ouverture `SYNCED|SYNC_ERROR → DRAFT` de bout en bout (DAO →
  repository → usecases → bloc). Elle voyage **dans la transaction de la
  première sauvegarde d'étape** : deux événements séparés courraient l'un
  contre l'autre sur le bloc, et une ré-ouverture qui réussit devant une
  écriture qui échoue laisserait un dossier déclassé sans correction pour le
  justifier. Armée sans rien écrire par `ReeditionSessionStarted`. 6 tests DAO,
  dont le silence d'avant épinglé.
- ✅ **F2** — `CompletedReeditionDetailPolicy` + origine `completedReedition` +
  intent. Classe cible et Frais en lecture seule, `finalizeStatus =
  IN_PROGRESS`.
- ✅ **F1** — « Modifier » dans l'en-tête, derrière `kEnrollmentSubmitAccess`.
  La correction se rend **par la même vue que la consultation** (l'agrégat
  local est déjà celui qu'il faut), en échangeant seulement la politique.
  Proposée pour un dossier `SYNCED|SYNC_ERROR` non annulé ; jamais pour un
  `PENDING_SYNC` (sa commande d'outbox est constituée).
  Le piège annoncé a été traité : `refreshesFromLocalAggregate` route la
  ré-hydratation vers `LoadLocalEnrollmentDetail`, et `_onLocalDetail` accepte
  désormais le dossier en correction — sans ces deux points, l'écran restait
  sur l'agrégat d'avant la correction, enregistrée en base et invisible à
  l'écran.
  Au passage : le bandeau annonçait « non modifiable » à côté d'un bouton
  « Modifier ». Il dit maintenant ce que l'enregistrement fera.
- ✅ **F5** — popin de sortie quand le dossier est resté en brouillon, avec la
  seule information qui compte à ce moment-là : l'élève ne réapparaîtra en
  facturation qu'une fois la correction validée. Aucune popin si rien n'a été
  enregistré — c'est l'état de la base qui le dit, pas une intention mémorisée
  à l'écran.
- ✅ **F6** — 21 tests : 6 DAO (ré-ouverture), 5 bloc (session de correction),
  8 page (entrée, exclusions, sortie), 2 bandeau, plus 9 sur la politique.
  Contre-épreuves faites sur la porte de rafraîchissement et sur la garde de
  ré-éditabilité.

## Lot FRONT — spécification

**F1. Entrée.** Action « Modifier » sur la consultation lecture seule d'un
dossier finalisé, derrière `kEnrollmentSubmitAccess`.

**F2. Politique dédiée.** Toutes les étapes éditables **sauf** le récapitulatif,
la Classe cible et les Frais (décision 2). `usesLocalDraft` vrai,
`requiresDraftSeed` faux (l'agrégat est déjà local), `finalizeStatus` =
`IN_PROGRESS`.

**F3. Ré-ouverture.** Nouvelle opération locale : `SYNCED|SYNC_ERROR → DRAFT`
sur l'inscription **et** l'élève, id conservé. Déclenchée à la **première**
sauvegarde d'étape (décision 3), idempotente. Un dossier `PENDING_SYNC` n'est
pas ré-ouvrable : il est déjà dans la file.
⚠️ `seedDraft` refuse un dossier non-`DRAFT` (garde délibérée) — on ouvre un
chemin **explicite et nommé**, on ne relâche pas la garde générale.

**F4. Finalisation.** `finalizeDraft(finalStatus: 'IN_PROGRESS')` → `DRAFT →
PENDING_SYNC` + outbox `outbox-enr-<id>` (id déterministe, donc idempotent) +
flush. Rien de neuf hors le `finalStatus`.

**F5. Le trou de facturation.** Rappel à la sortie du wizard si le dossier est
resté `DRAFT` sans être re-validé : l'élève est invisible de la facturation
jusqu'à re-validation.

**F6. Tests miroir**, dont : ouvrir sans modifier ne déclasse pas le dossier ;
la première sauvegarde le déclasse ; Classe cible et Frais sont en lecture
seule ; la finalisation écrit `IN_PROGRESS` et enfile.

---

## Ordre

Back (B1→B6) **puis** front (F1→F6). Entre les deux, rien n'est livrable
côté app.
