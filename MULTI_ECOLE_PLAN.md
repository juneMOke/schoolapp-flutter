# Cloisonnement des données par école — état des lieux et préconisation

> ## ⚠️ Statut au 2026-09-08 : **préconisation, non validée**
>
> Ce document **recommande** l'option C. Elle n'est **pas arbitrée**, et son §8
> laisse trois questions produit ouvertes. Entré au dépôt pour être relu et
> corrigé, pas pour être appliqué : rien de ce qu'il décrit n'est écrit.
>
> **Il est lui-même la démonstration de son propre argument.** Écrit le
> 2026-09-04 et gardé quatre jours hors du dépôt, il annonçait un numéro de
> schéma **déjà pris** sans que rien ne le signale. Un document qui cite des
> `fichier:ligne` pourrit ; dans le dépôt il pourrit **visiblement**, dehors il
> pourrit en silence. C'est la raison qui l'y fait entrer.

> Étude du 2026-09-04, sur le schéma local **v45** — 51 tables, 21 flux de pull,
> 185 sites de lecture SQL, 655 fichiers de test.
>
> **Le schéma a bougé depuis** : v46 (extourne d'un encaissement) puis v47 (logo
> de l'école). Les paliers annoncés plus bas sont corrigés en conséquence.
> Aucun code de ce plan n'est écrit : il sert à trancher, pas à exécuter.

---

## 1. Les cas d'usage (arbitrés le 2026-09-05)

Trois usages, énoncés par le porteur du produit. Ils ne pèsent pas pareil.

| # | usage | nature | fréquence du switch |
|---|---|---|---|
| **U1** | **Chef de 2-3 établissements** — il bascule pour évaluer où en est chaque école | **consultation** (tableaux de bord, contrôle des frais, KPI) | régulière |
| **U2** | **Tablettes de staging** — tests et débogage | lecture *et* écriture, toutes fonctions | fréquente, imprévisible |
| **U3** | **Plus tard : un compte réellement multi-école** — le directeur gère ses écoles sans se déconnecter | tout | permanente, sans re-login |

**Ce que U1 + U2 tranchent définitivement.** Le va-et-vient A→B→A est le régime
nominal, pas l'exception. **L'option A (purger au changement d'école) est close** :
elle rendrait l'application vide à chaque retour. Le raisonnement déjà écrit dans
`owner_scope.dart` pour les enseignants s'applique mot pour mot.

**Ce que U1 change dans la hiérarchie des défauts.** Un chef qui *consulte* n'imprime
pas de reçus et ne cherche pas de tuteurs : D4/D5/D6 comptent moins pour lui. En
revanche il lit des **chiffres pour décider**, et deux défauts deviennent les pires
de la liste parce qu'ils sont **silencieux et plausibles** :

- **D2** — l'année courante mal résolue fait lire à un tableau de bord une année qui
  n'appartient pas à l'école affichée. Aucun message, des nombres crédibles, faux.
- **D7** — la pastille « données complètes » verte au-dessus d'une base qui n'a rien
  reçu. L'outil de décision affirme sa propre fiabilité au moment exact où il ne
  l'a pas.

**Ce que U2 impose tout de suite.** Sur une tablette de staging qui a déjà switché,
**« il manque des données » est le comportement attendu (D1), pas un bug de la
fonctionnalité testée**. Tout rapport d'anomalie émis depuis une de ces tablettes est
aujourd'hui suspect. Contournement disponible **immédiatement, sans une ligne de
code** : « Effacer les données » d'Android entre deux écoles — c'est sûr parce que
cela emporte `sync_meta` *et* la clé SQLCipher (secure storage) avec la base.
⚠️ **À ne faire que file d'attente vide** : l'outbox part avec le reste.

**Ce que U3 est vraiment.** Ce n'est pas une variante de U1 : c'est un changement de
contrat serveur. `User.schoolId` est une colonne UUID **unique**
(`auth/domain/User.java:57`), et `auth_local_user.school_id` est `NOT NULL`. Voir
§1 bis — c'est le point qui décide de tout le reste.

---

## 1 bis. Ce que le compte multi-école change, et ce qu'il ne change pas

### Le back est mieux préparé qu'il n'y paraît

Le tenant serveur **ne vient pas de la ligne utilisateur** : il vient d'un *claim du
jeton*.

```java
// auth/config/JwtAuthenticationFilter.java:103
UUID schoolId = jwtService.extractSchoolId(token);
...
TenantContext.set(schoolId);
```

Conséquence : U3 ne demande **ni** `schoolId` sur les routes (ce qui contredirait
toute la conception du back), **ni** de toucher `TenantFilterAspect`. Il demande
trois choses, et trois seulement :

1. un lien `user_schools` — quelles écoles un compte peut revendiquer ;
2. un **échange de jeton** (`POST /auth/switch-school`) qui rend un token portant un
   autre claim `schoolId`, après vérification de l'appartenance ;
3. le reste de la chaîne serveur est **inchangé**.

C'est petit. Et c'est la forme à demander au back **maintenant**, même pour livrer
plus tard : elle ne coûte rien de plus, et elle évite de bâtir le front sur une
hypothèse qu'il faudrait défaire.

### Le front, lui, n'est pas préparé du tout — et c'est ce qui décide

Aujourd'hui, **la seule chose qui cloisonne le chemin d'écriture est la garde
d'auteur** (`isForeignOutboxAuthor`), et elle ne fonctionne que parce que
*un compte = une école*. Sous U3, un même `uid` couvre plusieurs écoles :
**la garde ne partitionne plus rien.**

Et `CurrentUserContext.schoolId`, aujourd'hui figé pour toute la session, devient
**mutable en cours de session**. C'est là que les deux options divergent pour de bon :

| | sous l'option B (colonne) | sous l'option C (fichier) |
|---|---|---|
| basculer d'école | 185 lectures SQL doivent relire l'école **au moment de la requête**, et chaque écran ouvert doit s'invalider | `TenantDatabase.attach(schoolB)` — un appel |
| BLoC tenant une liste en cache | affiche des lignes de l'autre école jusqu'au prochain chargement | la base sous lui a changé, il recharge |
| file d'écriture | exige `pendingReadyForSchool` **et** les 6 sites d'estampillage manquants | idem — l'outbox reste au niveau appareil (voir §5) |
| coût de U3 une fois le socle posé | un second chantier de la taille du premier | l'écran de bascule, et c'est tout |

**U3 ne rend pas l'option C plus élégante : il la rend décisive.**

## 2. L'acquis — ce qui tient déjà

Le socle n'est pas nu. Cinq mécanismes cloisonnent déjà correctement :

1. **La frontière réelle est serveur.** Le tenant est dérivé du token ; aucune
   donnée d'une école ne peut être *écrite* dans une autre par erreur de
   paramètre. `SyncAttributionGuard` refuse en 403 tout item d'outbox dont
   l'`authorId` ne correspond pas au `uid` du JWT.
2. **La file d'écriture est protégée par l'auteur.** `SyncEngine.flush()` appelle
   `isForeignOutboxAuthor(payload, currentUid)` **avant** tout appel réseau et
   diffère proprement (sans consommer de tentative, sans poison) les écritures
   d'un autre compte. Un compte = une école ⇒ la file est de fait cloisonnée par
   école. C'est la pièce la plus solide du dispositif.
3. **La résolution de l'année courante est scopée école.**
   `EnrollmentReferentialDao.findCurrentAcademicYearId(schoolId)` filtre sur
   `school_id AND is_current = 1`, et l'application du bundle référentiel remet
   `is_current = 0` **uniquement dans l'école courante** — deux écoles coexistent
   donc sans se désarmer.
4. **Dix tables portent déjà `school_id`** : `outbox`, `auth_local_user`,
   `ref_academic_years`, `editique_cache_entries`, `provisioning_drafts`,
   `ref_boutique_articles`, `boutique_sales`, `ref_exchange_rates`,
   `ref_fee_code_sections`, `ref_reduction_types`, `ref_reduction_lines`.
   Les modules les plus récents (Boutique, Réductions, Multi-devise,
   Configuration) sont **nés corrects**.
5. **Deux gardes de session existent et fonctionnent** :
   `EditiqueCacheSessionGuard` et `PreEnrollmentsSchoolGuard` — marqueur d'école
   dans `sync_meta`, **tri-état** (absent = purge), et **purger PUIS rembobiner**
   dans cet ordre.

---

## 3. Le diagnostic

### 3.1 Couche 1 — les curseurs de pull : le défaut structurant

`sync_meta(resource PK, cursor, synced_at)` ne connaît pas l'école. Sur les
21 flux, **11 portent une clé de curseur nue** :

| flux | clé `sync_meta` | scope effectif |
|---|---|---|
| `enrollment_referential` | nue | ❌ |
| `enrollment_snapshots` (hydratant) | nue | ❌ |
| `enrollments` (delta) | nue | ❌ |
| `classrooms` | nue | ❌ |
| `classroom_members` | nue | ❌ |
| `classroom_transfers` (+ `_bootstrap`) | nue | ❌ |
| `finance_student_charges` | nue | ❌ |
| `finance_payments` | nue | ❌ |
| `attendance` (+ `_bootstrap`) | nue | ❌ |
| `disciplinary_cases` (+ `_bootstrap`) | nue | ❌ |
| `schedule_time_slots` | nue | ❌ |
| `enrollment_reenrollment_cohort` | `:<yearId>` | ⚠️ **année mal résolue** (§3.3) |
| `enrollment_pre_enrollments` | `@<schoolId>` | ✅ |
| `finance_exchange_rates` | `:<schoolId>` | ✅ |
| `editique_documents` | `@<schoolId>` | ✅ |
| `boutique_sales` | `@<schoolId>` | ✅ |
| `academics_cours`, `academics_grades_referential`, `schedule_sessions` | `@<uid>` | ✅ par ricochet |
| `academics_evaluations`, `academics_notes` | `:<coursId>` | ✅ par ricochet |

**Et le serveur ne rattrape rien.** Le jeton keyset est
`SyncCursor(v, resource, ts, id)` — vérifié dans
`common/sync/SyncCursor.java`. Il **ne porte aucun tenant**. Un curseur émis
pour l'école A est donc parfaitement valide quand il est rejoué avec le token de
B : le serveur applique `(server_updated_at, id) > (ts, id)` **à l'intérieur du
tenant de B** et répond « rien de neuf ».

> ⚠️ Le repli « 400 ⇒ rembobinage » présent dans chaque pull (`rejectedCursor`)
> **ne se déclenchera jamais** ici : le curseur n'est ni forgé, ni d'une autre
> ressource. Il est simplement d'une autre école, et rien dans le format ne
> permet au serveur de le voir.

**Conséquence exacte :** les données de l'école B **ne descendent jamais** — pas
le temps d'un cycle, mais jusqu'à ce que B écrive du neuf côté serveur. Et ce
que B finit par recevoir est un *delta* sur une base qu'il n'a jamais hydratée.

### 3.2 Couche 2 — les tables sans axe école : le mélange en lecture

Sur 51 tables, **41 n'ont pas de `school_id`**. Le commentaire d'origine est
resté dans le code : *« pas de `school_id` local (tablette mono-établissement,
scope serveur via token) »*
(`classroom_attendance_offline_schema.dart:22`, `academics_offline_schema.dart:34`).

Le mélange est **masqué, pas absent** : la plupart des lectures filtrent sur
`academic_year_id`, et une année appartient à une école. B voit donc **du vide**,
pas les élèves de A. Cette protection indirecte a trois trous :

- **les tables sans aucun axe** : `parents`, `ref_previous_year_students`,
  `ref_pre_enrollments`, `ref_school`, `ref_time_slots`, `generated_documents`,
  `payment_anomalies` ;
- **les colonnes d'année nullables** : `ref_fee_tariffs.academic_year_id` est
  `NULL`-able, et `FinanceLedgerReadDao` inclut explicitement
  `academic_year_id IS NULL` (« une créance sans année appartient à… ») —
  la créance sans année franchit la frontière ;
- **la résolution de l'année elle-même**, si elle est fausse (§3.3).

### 3.3 Couche 3 — l'invariant qui fuit : `is_current` non scopé

Tout le cloisonnement indirect repose sur « la bonne année ». Or il existe
**deux** résolveurs, et un seul est scopé :

```dart
// enrollment_referential_dao.dart:206 — CORRECT
where: 'school_id = ? AND is_current = 1'

// enrollment_seed_dao.dart:141 — NON SCOPÉ
where: 'is_current = 1', limit: 1
```

Deux écoles en cache ⇒ **deux lignes `is_current = 1`** (l'application du bundle
ne désarme que l'école courante, délibérément). `EnrollmentSeedDao.findCurrentAcademicYearId()`
rend alors une année **arbitraire** (ordre de `rowid`). Cinq sites l'appellent :
le marqueur de la cohorte de réinscription et quatre lectures de
`EnrollmentOfflineRepositoryImpl` (lignes 495, 530, 563, 585).

### 3.4 Couche 4 — les caches remplacés en bloc

Trois caches sont écrits en *remplacement total*, sans axe école :

- **`ref_school`** — `delete()` puis `insert()`, ligne unique. Le dernier pull
  gagne. Les trois lecteurs font `LIMIT 1` **sans `WHERE`** :
  `EnrollmentReferentialDao.findSchool`, `ProvisionalTicketDao.findSchool`
  (en-tête Z1 des reçus) et `SaleTicketComposer._findSchool` — ce dernier reçoit
  pourtant un `schoolId` en paramètre **qu'il n'utilise pas**.
  ⇒ un ticket thermique imprimé hors ligne peut porter l'**en-tête de l'autre
  école**.
- **`ref_previous_year_students` / `_balances`** — `replaceReenrollmentCohort()`
  vide et réécrit la table entière. Combiné au marqueur « skip-si-complet »
  (§3.3), le cycle A→B→A laisse **la cohorte de B dans l'écran de réinscription
  de A**, définitivement : le marqueur de l'année de A existe déjà, donc aucun
  re-pull.
- **`ref_pre_enrollments`** — même forme, mais **déjà protégé** par
  `PreEnrollmentsSchoolGuard`.

### 3.5 Couche 5 — la file d'écriture : couverte, mais par accident

La garde d'auteur (§2.2) couvre le cas réel. Deux réserves :

- `OutboxDao.pendingReadyForSchool(schoolId, …)` existe et **n'est appelée nulle
  part dans `lib/`** — code mort. Ce serait sans importance si elle n'était pas
  aussi **inutilisable** : sur les 9 sites d'enfilage, **3 seulement** estampillent
  `school_id` (inscription, encaissement, boutique). La brancher telle quelle
  gèlerait à vie les écritures de présence, discipline, classes et academics.
- Une écriture **sans `authorId`** (backend hérité sans claim `uid`) est
  délibérément traitée comme « appartient à tout le monde » et part avec le token
  courant. Le serveur la refusera — refus visible, choix assumé et documenté.

---

## 4. Les défauts nommés

| # | défaut | scénario | gravité |
|---|---|---|---|
| **D1** | 11 curseurs nus | A pull jusqu'à T ; B repart de T ; le serveur répond « rien de neuf » | 🔴 **bloquant** — B n'a pas de données |
| **D2** | `is_current` non scopé (`enrollment_seed_dao.dart:141`) | 2 écoles en cache ⇒ année arbitraire sur 5 chemins d'inscription | 🔴 corrompt le cloisonnement indirect |
| **D3** | cohorte N-1 = swap total + marqueur année | A→B→A : l'écran Réinscription de A liste les élèves de **B** | 🔴 données d'une autre école affichées |
| **D4** | `ref_school` mono-ligne lue sans `WHERE` | reçu / ticket imprimé avec l'en-tête de l'autre établissement | 🟠 pièce comptable fausse |
| **D5** | `ParentSearchDao.search` sans aucun filtre | la popin « Rechercher un parent » de B propose les tuteurs de A (nom, téléphone) | 🟠 fuite de données personnelles |
| **D6** | `FinancePayerDirectoryDao` : `FROM payments` sans année ni école | l'annuaire des payeurs de B liste ceux de A | 🟠 fuite de données personnelles |
| **D7** | drapeaux `*_bootstrap` nus | pastille « données complètes » verte sur une base vide chez B | 🟡 fraîcheur mensongère |
| **D8** | `academic_year_id IS NULL` accepté en finance | une créance sans année traverse la frontière | 🟡 latent |
| **D9** | purge éditique au changement d'école | incohérent avec un modèle de coexistence : les pièces de A sont détruites quand B se connecte | 🟡 à réaligner |

---

## 5. Les options

### Option A — Purger au changement d'école

Généraliser les deux gardes existantes à tous les domaines : marqueur d'école,
tri-état, purger puis rembobiner.

- ✅ Aucun changement de schéma, aucun site de lecture touché. ~8 gardes.
- ✅ Le patron est déjà écrit deux fois, éprouvé, testé.
- ❌ **Casse l'offline-first** : cycle A→B→A hors ligne ⇒ A retrouve une app
  vide. C'est exactement l'argument par lequel `owner_scope.dart` a écarté la
  purge pour les enseignants ; l'accepter ici serait se contredire.
- ❌ Un effacement partiel sans rembobinage est **pire que rien** (table vide +
  curseur en avance = donnée jamais revue). Huit gardes = huit occasions.
- ❌ Ne résout **ni D4 ni D5 ni D6** : on ne peut pas purger sélectivement une
  table qui n'a pas d'axe école — il faut tout vider.

**Verdict : à écarter comme cible.** (Reste utile comme filet ponctuel.)

### Option B — Partitionner par colonne `school_id`

Ajouter `school_id` à ~25 tables racines, l'estampiller à l'application des
deltas (côté client, comme `owner_uid` : ce qui revient d'un cycle appartient par
construction à l'école connectée), et filtrer à la lecture.

- ✅ Coexistence : A et B vivent côte à côte, offline-first préservé.
- ✅ Le précédent existe (`owner_uid`, `ownerKey`, `scopedResource`) et
  10 tables le font déjà.
- ✅ Incrémental, livrable module par module.
- ❌ **185 sites de lecture SQL à auditer** (174 dans les DAO), et
  chaque nouveau site, pour toujours, devra y penser.
- ❌ **L'oubli est silencieux.** Un `WHERE` manquant ne lève pas, ne logge pas,
  et les tests ne le voient pas — ils montent une seule école. C'est la signature
  exacte des défauts D5/D6 : personne ne les a écrits par négligence, ils sont
  simplement *nés* dans un monde mono-école.
- ❌ Le backfill de migration n'a pas de réponse : les lignes existantes
  n'ont pas d'école connue. Il faut le tri-état d'adoption (la première session
  qui suit la mise à jour adopte le disque **ou** le purge) — donc on paie
  quand même une purge unique sur tout le parc.
- ❌ Ce n'est **pas une frontière**, c'est une discipline. Sur des données
  money-grade et des mineurs, l'écart compte.

### Option C — Une base SQLCipher par école

Éclater le fichier unique `school_offline.db` en deux natures :

```
device.db          ← auth_local_user, auth_local_session  (le parc, pas le tenant)
school_<uuid>.db   ← les 49 autres tables, outbox et sync_meta compris
```

`Database` reste un `lazySingleton` GetIt, mais l'instance enregistrée devient un
**proxy** (`TenantDatabase implements Database`) qui délègue au fichier de
l'école courante. **Aucun DAO ne change** : ils continuent de recevoir
`getIt<Database>()`.

- ✅ **D1, D2, D3, D4, D5, D6, D7, D8 disparaissent d'un coup**, sans toucher un
  seul `WHERE` : deux écoles ne partagent plus une seule ligne, donc plus un
  seul curseur, plus un seul `is_current`, plus un seul `ref_school`.
- ✅ **Les modules futurs sont corrects par construction.** C'est le seul point
  qui distingue vraiment C de B : B répare l'existant, C ferme la classe entière.
- ✅ Supprimer une école = supprimer un fichier + sa clé. Le « rembobiner après
  avoir purgé », piège récurrent du dépôt, devient sans objet.
- ✅ **Isolation au repos, pas seulement filtrage** : une clé SQLCipher par
  école. Ce que `owner_scope.dart` reconnaît ne pas être (« ce n'est pas une
  frontière de sécurité »), C l'est.
- ✅ **Le coût de découpage est étonnamment bas** : le schéma ne compte
  **qu'une seule clé étrangère**, `auth_local_session.user_id → auth_local_user`,
  interne à la paire auth. Aucune jointure SQL ne traverse la coupure.
- ❌ Re-plomberie DI : la base est aujourd'hui ouverte dans
  `configureDependencies()`, **avant** l'authentification. Il faut ouvrir
  `device.db` au démarrage et attacher le tenant **à la transition
  `authenticated`, avant que le routeur n'ouvre l'app**.
- ❌ Une fenêtre « aucun tenant attaché » existe entre le boot et le login. Un
  seul appelant lit du métier dans cette fenêtre (`PaymentAnomaliesCubit.refresh()`,
  déjà défensif — `catch` → état vide). À traiter explicitement plutôt qu'à
  laisser dégrader en silence.
- ❌ Migration **v47 → v48** non triviale : adopter le fichier hérité au nom de la
  première école qui ouvre une session, et déplacer les deux tables auth vers
  `device.db` (`ATTACH` + `INSERT … SELECT`, transactionnel).
- ❌ Tests : 60 fichiers passent par `openFullOfflineDb()` — **helper unique**,
  donc le coût est concentré ; s'y ajoutent les suites auth qui ouvrent leur
  propre base.
- ❌ **Le seul endroit où C coûte plus que B : la consolidation inter-écoles.**
  Un chef qui voudrait *comparer* ses trois écoles côte à côte lirait, sous B, un
  `GROUP BY school_id` ; sous C, il faudrait ouvrir trois fichiers. La réponse
  honnête est que cette vue n'appartient pas à la base offline — le serveur détient
  déjà les trois écoles, un endpoint consolidé la sert mieux et à jour. Mais c'est
  une décision produit à prendre les yeux ouverts (cf. §8).

---

## 6. Préconisation

**Option C — une base par école — comme cible, précédée d'un lot de correctifs
immédiats indépendants du choix d'architecture.**

Les raisons, dans l'ordre :

1. **D1 est un défaut de *clé*, pas de *donnée*.** Le rendre correct sous
   l'option B, c'est scoper 11 clés de curseur ; sous C, `sync_meta` vit dans le
   fichier de l'école et la question ne se pose plus. Même geste, portée
   infiniment plus large.
2. **Le dépôt a déjà refusé deux fois d'écrire un troisième cas particulier.**
   `PreEnrollmentsSchoolGuard` et `EditiqueCacheSessionGuard` sont deux copies du
   même raisonnement. L'option B en produirait vingt-cinq.
3. **L'oubli silencieux est le mode d'échec dominant de ce projet** — la mémoire
   de revue le répète (gardes jamais branchées, `null` en `whereArgs`,
   événements émis par personne). Une architecture où l'oubli est *impossible*
   vaut mieux qu'une où il est seulement *interdit*.
4. **Le coût structurel est plus bas qu'il n'en a l'air** : une seule clé
   étrangère à respecter, un seul helper de test, un proxy d'une vingtaine de
   méthodes, et zéro site de lecture touché.
5. **U3 tranche.** Le compte multi-école supprime la garde d'auteur — la seule
   chose qui cloisonne aujourd'hui le chemin d'écriture — et rend
   `CurrentUserContext.schoolId` mutable en cours de session. Sous B, cela rouvre
   les 185 lectures *et* tous les BLoC qui tiennent une liste en cache. Sous C,
   c'est `attach(schoolB)`. Le socle qu'on pose maintenant décide du coût de U3 :
   un écran de bascule, ou un second chantier de la taille du premier.
6. **La contrepartie honnête** : C concentre le risque sur un point unique (la
   migration + le moment d'attachement du tenant), là où B le dilue sur 185
   sites. Un risque concentré se teste ; un risque dilué se découvre en
   production.

**Si C est jugée trop lourde pour le calendrier**, le repli est B — mais alors
il faut l'assumer entièrement : `school_id` sur les 25 tables racines *et* un
test d'architecture qui échoue dès qu'un DAO interroge une table scopée sans
prédicat d'école. Sans ce filet, B redeviendra un chantier permanent.

**A n'est pas une cible**, seulement un outil : la garde éditique et la garde PRE
restent utiles, et deviennent d'ailleurs inutiles sous C (à retirer, cf. D9).

---

## 7. Plan de lots proposé

### Lot 0 — les défauts qui sont déjà faux aujourd'hui *(indépendant du choix)*

| tâche | fichier | coût réel |
|---|---|---|
| Scoper `findCurrentAcademicYearId()` par école (D2) | `enrollment_seed_dao.dart:137` | **pas une ligne** — voir ci-dessous |
| `sale_ticket_composer` : utiliser le `schoolId` **déjà reçu** (D4) | `sale_ticket_composer.dart:83` | **une ligne**, la seule du lot |
| `ref_school` : `WHERE id = ?` sur les 2 autres lecteurs (D4, **latent**) | `enrollment_referential_dao.dart:183`, `provisional_ticket_dao.dart:245` | un paramètre à faire descendre |
| `ParentSearchDao` : borner au corpus de l'école (D5) | `parent_search_dao.dart:62` | requête à scoper |
| `FinancePayerDirectoryDao` : borner à l'année/école (D6) | `finance_payer_directory_dao.dart:162` | requête à scoper |
| **Estamper `school_id` sur les 6 sites d'enfilage qui l'omettent** (présence, discipline, classes, academics ×3) — ⚠️ **renversement** : `pendingReadyForSchool` n'est plus du code mort à supprimer, c'est ce dont U3 aura besoin. La rendre utilisable coûte 6 lignes ; la supprimer coûterait de la réécrire. | `outbox_dao.dart:40` + les 6 dépôts offline | 6 lignes |

**Priorité pour U1 (le chef qui consulte) : D2 d'abord** — un tableau de bord qui
lit la mauvaise année ne se signale jamais.

#### ⚠️ Deux corrections au chiffrage initial

**« D2/D4 sont des correctifs d'une ligne » est faux pour trois sites sur
quatre.** Vérifié dans le code :

- **D2 est le plus cher du lot**, et c'est justement celui marqué prioritaire.
  `EnrollmentSeedDao` ne porte qu'une `Database`, aucun `schoolId`, et la méthode
  est **sans paramètre**. La scoper, c'est un paramètre de plus, **5 sites d'appel
  en production** (`enrollment_pull_repository_impl.dart:181`,
  `enrollment_offline_repository_impl.dart:495/530/563/585`) et **3 fichiers de
  test** qui la mockent en no-arg. Compter « une ligne » sous-estime d'un ordre
  de grandeur.
  *Piste à instruire au moment du lot :* `EnrollmentReferentialDao` porte **déjà**
  un `findCurrentAcademicYearId(String schoolId)` scopé et testé
  (`enrollment_ref_daos_test.dart:491`). D2 est peut-être « supprimer le doublon
  non scopé et router sur celui qui l'est » plutôt qu'« ajouter un paramètre » —
  même coût côté appelants.
- **Un seul site est vraiment une ligne** : `sale_ticket_composer._findSchool`
  **reçoit** un `schoolId` (ligne 36) et ne s'en sert pas dans la requête.

**D4 n'est pas un défaut ACTIF, contrairement à ce que ce lot laissait entendre.**
`ref_school` est un cache **mono-ligne** : `upsertReferential` fait
`DELETE FROM ref_school` puis un `INSERT` unique
(`enrollment_referential_dao.dart:75-89`), et le schéma le documente. Avec une
seule ligne par construction, `limit: 1` sans `WHERE` rend **toujours la bonne**.

Le défaut est donc **latent**, et son sort dépend de l'arbitrage :

- **sous l'option B**, il devient réel — plusieurs écoles dans la même table ;
- **sous l'option C** (préconisée), la table reste mono-ligne et **il ne se pose
  jamais**.

Ce lot 0 est présenté comme « indépendant du choix » ; **D4 ne l'est pas**. Seul
`sale_ticket_composer` mérite d'y rester : ignorer un identifiant qu'on reçoit est
trompeur à la lecture quel que soit le nombre de lignes.

**Et, à coût zéro, dès aujourd'hui pour U2 :** consigner que sur une tablette de
staging ayant switché d'école, « il manque des données » est le comportement
attendu (D1). Contournement : « Effacer les données » Android entre deux écoles —
sûr parce qu'il emporte `sync_meta` et la clé SQLCipher avec la base, **à ne faire
que file d'attente vide**.

### Lot 1 — décision & socle

- Trancher B vs C (ce document).
- Sous C : écrire `TenantDatabase` (proxy `Database`), séparer
  `deviceOfflineTables` de `tenantOfflineTables` dans `buildOfflineSchema()`,
  une clé SQLCipher par école dans `DatabaseKeyService`.

### Lot 2 — migration v47 → **v48**

> ⚠️ **Ce lot ne réserve pas son numéro, il le prendra en fusionnant.** La
> version initiale de ce document annonçait « v45 → v46 » ; v46 est partie à
> l'extourne et **v47 au logo de l'école**, arbitré devant le multi-école. D'où
> v48 — et rien ne garantit que ce soit encore vrai au moment de fusionner.
>
> Le dépôt porte déjà la trace de ce qu'il en coûte d'annoncer un palier à
> l'avance : `app_constants.dart` documente le **v24 brûlé**, « aucune migration
> ne le porte […] **Ne jamais le réattribuer** », après que deux branches l'ont
> revendiqué. Un numéro se prend au dernier moment, jamais sur un plan.

- Adoption du fichier hérité par la première école qui ouvre une session
  (tri-état : absent ⇒ on ne devine pas, on demande un pull complet).
- Déplacement transactionnel des deux tables auth vers `device.db`.
- ⚠️ Le piège connu du dépôt s'applique ici en entier : **purger sans rembobiner
  est pire que rien**. Sous C, on ne purge rien — on renomme.

### Lot 3 — attachement du tenant au cycle de session

- Ouvrir/attacher à la transition `authenticated`, **avant** que le routeur ne
  laisse passer.
- Détacher au logout ; définir explicitement le comportement « aucun tenant »
  (échec typé, pas un vide silencieux).

### Lot 4 — nettoyage

- Retirer `PreEnrollmentsSchoolGuard` et la purge d'école d'`EditiqueCacheSessionGuard`
  (D9) — devenus sans objet ; garder la purge « profil sans droit ».
- Retirer les scopes `@<schoolId>` devenus redondants sur les 4 curseurs déjà
  scopés (ou les laisser : inertes, ils ne nuisent pas — décider explicitement).
- Corriger les commentaires de schéma qui affirment encore « tablette
  mono-établissement ».

### Lot 5 — contre-épreuve

- Un test d'intégration qui **monte deux écoles** dans la même session de test et
  rejoue A→B→A : c'est le seul test qui aurait attrapé D1, D3, D5 et D6.
- ⚠️ Le piège consigné : *la contre-épreuve doit muter le câblage*, pas seulement
  ajouter des assertions.

---

## 8. Ce qui reste ouvert

Les quatre questions de la version initiale sont **répondues** par les cas d'usage
du 2026-09-05 : le va-et-vient est réel (U1/U2), deux à trois écoles par tablette,
et le compte multi-humain arrive (U3). Restent trois arbitrages, tous produit :

1. **La consolidation inter-écoles est-elle au programme ?** Un chef qui veut
   *comparer* ses écoles côte à côte, et non basculer entre elles, demande une vue
   que la base offline n'a pas vocation à servir. Si c'est le besoin réel de U1, la
   réponse est un **endpoint serveur consolidé**, pas une requête locale — et cela
   ne change rien au choix d'architecture ci-dessus.

2. **Quand demander `POST /auth/switch-school` au back ?** La forme est petite
   (§1 bis) et le back y est déjà prêt : son tenant vient d'un claim du jeton, pas
   de la ligne utilisateur. La demander **tôt** ne coûte rien et évite de bâtir le
   front sur une hypothèse à défaire ; la livrer plus tard reste possible.

3. **Les permissions sont-elles par compte ou par (compte, école) ?**
   `auth_local_user.permissions` est une colonne unique, et `CurrentPermissions` un
   holder unique. Si un directeur n'a pas les mêmes droits dans ses trois écoles,
   U3 duplique aussi ce holder — c'est une question à poser au back **en même temps**
   que le point 2, pas après.

---

## 9. Journal des décisions

| date | décision |
|---|---|
| 2026-08-22 | Diagnostic initial : curseurs non scopés, arbitrage purger/partitionner **non tranché** |
| 2026-09-04 | Étude complète : 9 défauts, 3 options, préconisation **option C** |
| 2026-09-05 | Cas d'usage arbitrés (U1/U2/U3) → **option A close**, option C **confirmée et renforcée** par U3 ; `outbox` et `editique_cache_entries` placés au niveau **appareil** ; lot 0 renversé sur `pendingReadyForSchool` |
| 2026-09-08 | **Entrée au dépôt**, après relecture contre le code. Quatre corrections : le schéma n'est plus v45 (v46 extourne, **v47 logo**) ; le lot 2 devient **v48** et ne réserve pas son numéro ; **D4 est latent**, pas actif, et disparaît sous l'option C ; le chiffrage « une ligne » ne vaut que pour `sale_ticket_composer`, **D2 coûte 5 sites d'appel et 3 fichiers de test**. Préconisation option C **toujours non validée**. |
