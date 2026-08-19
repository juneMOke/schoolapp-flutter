# Backlog de revue — branche `feature/auth_permissions`

Sortie de la revue `/code-review high` du **2026-08-19**, portée sur les
38 commits non poussés de la branche (233 fichiers) plus l'arbre de travail.
`flutter analyze` propre, **3621 tests verts** au moment de la revue.

Quinze défauts confirmés. **Le #13 est corrigé** (commit `5123439`) ; les
quatorze autres sont listés ici, aucun n'est traité.

> Ordre : gravité décroissante. Un défaut « haut » a une conséquence métier
> directe et irréversible sans intervention ; un « moyen » dégrade une décision
> ou un affichage ; un « bas » attend un appelant qui n'existe pas encore, ou ne
> se manifeste que sur une transition rare.

---

## 🔴 Haut

### H-1 · Le champ « Prénom » de la recherche de parent est intapable

`lib/features/enrollment/presentation/widgets/guardian_info/parent_search_dialog.dart:127`

La bascule `pinsForm` compare la hauteur disponible à un seuil de 480 dp. Or un
`Dialog` soustrait déjà `viewInsets` : l'ouverture du clavier fait passer sous le
seuil, le `Column` tombe de 5 enfants à 3, et la réconciliation d'éléments
apparie l'en-tête et le `Divider` par le haut, le `Flexible` final par le bas —
le `Padding` qui porte le formulaire est donc **démonté** puis reconstruit dans
la vue défilante. Les `EteeloTextInput` n'ont ni clé ni `FocusNode` externe : le
focus meurt, le clavier se referme, la hauteur revient, la bascule repart en
sens inverse.

Reproduit sur tablette 10" en paysage (~800 dp − ~360 dp de clavier) et sur tout
téléphone en portrait.

**À faire** — donner une identité stable aux champs (clé ou `FocusNode` hissé
hors de la branche conditionnelle), ou calculer le seuil sur une hauteur qui
n'inclut pas les inserts de clavier.

---

### H-2 · Un flux rejeté au parsing désarme l'arête créances → paiements

`lib/core/offline/pull_coordinator.dart:225`

`sync_plan_parser.dart:84` écarte tout flux dont le `mode` ou le `scope` est
inconnu de cet APK. `_covers()` le rate donc, et il atterrit dans la branche
`outOfPlan` — **délibérément exclue** de `unusableResources`, parce qu'un flux
hors périmètre n'est pas un amont en panne.

Sauf qu'un flux *rejeté* n'est pas un flux hors périmètre : c'est un amont dont
le miroir local ne sera pas rafraîchi. Si le serveur déploie un nouveau `mode`
sur `finance.student-charges`, les créances ne descendent plus, `_isBlockedBy`
ne trouve rien à bloquer, et les paiements descendent par-dessus un
`amount_paid_in_cents` périmé : **la créance s'affiche impayée et le caissier
réencaisse**.

C'est exactement le scénario que la docstring de `unusableResources`
(l. 144-157) décrit et traite pour le cas `forbidden`.

**À faire** — faire entrer les `rejectedKeys` (déjà en main l. 188) dans
`unusableResources`, au même titre qu'un échec ou qu'un refus de droits.

---

### H-3 · « Le client n'a rien compris » est classé « rien à tirer »

`lib/features/sync/data/repositories/sync_plan_repository_impl.dart:187`

Si le parseur rejette **tous** les flux — un `mode` renommé, un `scope` neuf
déployé d'un coup sur le parc — `plan.streams` finit vide, l'état devient
`SyncPlanEmpty`, et `pull_coordinator.dart:236` saute alors toutes les
ressources non-socle. Pire : `_fetch` met le corps en cache parce que l'état
n'est pas `SyncPlanUnknown`, donc **la panne survit au redémarrage**. Plus rien
ne descend, et seule une mise à jour d'APK répare.

Un plan que le client ne sait pas interpréter est une **absence d'information**
(repli sur `requiredPermissions`), jamais l'information « il n'y a rien à
tirer ».

**À faire** — classer ce cas en `SyncPlanUnknown` et ne pas le mettre en cache.

---

## 🟠 Moyen

### M-1 · Un 403 transitoire sur `/sync/plan` gèle le repli pour la session

`lib/core/offline/plan/sync_plan_holder.dart:139`

`refreshFromNetwork()` ne rend `null` que pour `transport` et `malformed` ;
`unauthorized` (401/403) et `absent` (uid pas encore posé) reviennent avec un
état, donc `_commit(..., fresh: true)` efface `_stale` **définitivement** — et
`markStale()` n'a qu'un seul déclencheur, un vrai changement d'ensemble de
droits. Un seul 403 et toute la session tourne sur le filtre `requiredPermissions`
codé en dur, derrière une pastille verte (`isDegraded` ignore ce cas).

**À faire** — ne traiter comme verdict définitif que `notDeployed`.

---

### M-2 · `PermissionGate` deux-états affiche « relève de la caisse » à un caissier qui a le droit

`lib/features/finance/presentation/widgets/facturation_detail_payments_section.dart:49`
· même trou dans `facturation_charge_allocations_section.dart:75` et
`facturation_charge_detail_dialog.dart:38`

`PermissionGate.allows` rend `false` quand `AuthState.permissions == null` —
l'état de **tout le parc** jusqu'au premier refresh suivant la migration v24.
Un caissier qui détient `finance.payment.read` se voit refuser l'historique des
encaissements sur l'écran même où il décide s'il faut encaisser.

Le tri-état `permissionHolding(...) == missing` existe et est utilisé
correctement ailleurs dans le même PR (`fee_control_results_view.dart:150`,
`facturation_student_table.dart:150`), précisément pour éviter ça.

**À faire** — passer ces trois sites au tri-état.

---

### M-3 · La décision de permission est prise une fois, puis bascule en faux « aucun versement »

`lib/features/finance/presentation/widgets/facturation_detail_data_loader.dart:55`

`_requestData()` ne part que du post-frame d'`initState` et du `didUpdateWidget`
sur changement d'id ; rien ne s'abonne à `AuthBloc`. Si les permissions sont
encore `null` à cet instant, `PaymentsRequested` n'est jamais émis — puis
l'ensemble arrive en cours de session, un rebuild survient, `canReadPayments`
passe à `true` alors que le bloc est resté `initial` : l'écran affiche
**« Aucun versement enregistré »**. Seul un aller-retour sur la page corrige.

**À faire** — s'abonner au changement de permissions et redemander, ou refuser
de trancher tant que l'ensemble est inconnu.

---

### M-4 · Une lecture de tarifs en échec est rendue « aucun frais défini pour ce niveau »

`lib/features/finance/presentation/bloc/fee_control/fee_control_tariffs_resolver.dart:53`

Sur `Left`, le resolver rend `failed: true, tariffs: [], gridMissing: false`.
`tariffsStatus: failure` est bien stocké mais **personne ne le lit**
(`fee_control_page.dart` ne transmet que `isTariffsLoading` et
`feeGridMissing`), donc `fee_control_form_fields.dart:59-76` affiche
`feeControlFeeEmptyForLevel`. Une base SQLCipher verrouillée annonce ainsi à
l'opérateur que l'école n'a pas de frais pour ce niveau.

**À faire** — consommer `tariffsStatus: failure` et lui donner son propre état
d'erreur (règle non-négociable #10 : `EteeloErrorResult`).

---

### M-5 · La garde d'école des préinscriptions est inopérante au premier démarrage

`lib/features/enrollment/offline/data/local/pre_enrollments_school_guard.dart:103`

Rien n'amorce `kPreEnrollmentsSchoolResource` : la première session après mise à
jour prend donc toujours le chemin « rien à purger » et **adopte** ce qui est sur
le disque. Une tablette qui portait le vivier de l'école A, réaffectée à B,
garde les candidats de A indéfiniment — `searchPreEnrollmentCandidates` et
`findPreEnrollmentById` n'ont aucun prédicat `school_id` (la colonne n'existe
pas), donc le guichet de B peut lister et amorcer des brouillons depuis les
lignes de A.

Un vivier non attribuable est le cas « fermé par défaut » que la docstring de la
classe défend elle-même.

**À faire** — traiter le marqueur absent comme « inconnu ⇒ purger ».

---

### M-6 · La garde de préinscriptions court contre le cycle de login

`lib/main.dart:182`

La garde et `syncOnLogin()` sont toutes deux en `unawaited`, alors que le
commentaire affirme un ordre (« AVANT le cycle »). Si l'insert +
`setCursor` du pull des préinscriptions atterrit entre le
`deleteAllPreEnrollments()` et le `deleteCursorsOf` de la garde, les lignes
fraîchement tirées sont effacées **derrière un curseur keyset avancé** : le
serveur répond « rien de neuf » pour toujours et ces préinscriptions deviennent
inatteignables, `ref_pre_enrollments` étant désormais la seule source d'amorçage.

Fenêtre étroite (SQLite local contre mint + flush + révocation + deux pulls
réseau), mais elle n'existait pas avant ce PR.

**À faire** — `await` la garde avant de lancer le cycle.

---

### M-7 · Le verrou de tarifs mute sans reconstruire

`lib/features/enrollment/presentation/widgets/student_charges/student_charges_step.dart:130` (listener l. 332)

`_syncTariffsWithheld` compte sur `_recomputeFormState` pour appeler `setState`,
et `tariffsWithheld` n'entre dans ce calcul que via
`blocked = (tariffsWithheld || feeGridUnavailable) && _studentCharges.isEmpty` —
donc sans effet dès que les créances sont chargées, c'est-à-dire dans le cas
normal. Une perte de `finance.grid.read` en cours de session laisse les montants
de tarifs à l'écran jusqu'à la fin. Les deux widgets frères touchés par le même
commit, eux, reconstruisent inconditionnellement.

**À faire** — reconstruire sur le changement de droit, comme les frères.

---

## 🟡 Bas

### B-1 · `PullCycleGuard.run<T>` fait un transtypage aveugle

`lib/core/offline/pull_cycle_guard.dart:65` (et l. 84)

`run<T>` agrège un appelant qui arrive sur la future déjà programmée et la
transtype en `T`. Or `PullCoordinator.guarded()` expose publiquement le verrou
avec `T = void` pour les appelants qui tirent hors coordinateur, quand les
handlers l'utilisent avec `T = PullOutcome`. Deux `guarded('enrollments', …)`
suivis du cycle du coordinateur sur la même ressource lui rendent la future
`void` : `null as PullOutcome` lève, le `catch` du coordinateur compte un échec,
et `handler.pull()` ne tourne jamais.

Aucun appelant ne l'exerce aujourd'hui — l'API est neuve dans ce PR.

**À faire** — séparer les deux usages, ou rendre le verrou non générique.

---

### B-2 · Les drapeaux de lecture dégradée survivent au logout

`lib/core/components/status/sync_status_cubit.dart:80`

Le cubit est app-lifetime et `_pullDegraded` / `_pullRetriable` ne sont réécrits
que par un cycle qui a réellement observé quelque chose. Le compte A pose les
drapeaux sur un cycle `forbidden > 0`, A se déconnecte, B se connecte et son
`syncNow()` s'arrête tôt (hors ligne, sans jetons, mint refusé) : **B porte la
pastille « Partiellement à jour » de A**, sans cycle à lui pour la corriger — et
sur la tablette en Wi-Fi permanent que ce chantier vise, la transition réseau
qui rattraperait n'arrive jamais.

**À faire** — les remettre à zéro là où `CurrentPermissions.clear()` et
`SyncPlanHolder.clear()` sont déjà appelés.

---

### B-3 · `_sameSet` accepte un doublon comme égal

`lib/core/auth/current_permissions.dart:105`

`_sameSet(['a','a'], ['a','b'])` rend `true` : les longueurs concordent et
chaque élément du premier est dans le second. Un refresh livrant le second après
le premier ne notifierait donc pas, `SyncPlanHolder` ne serait jamais marqué
périmé, et le plan d'avant le changement continuerait de gouverner le périmètre
de pull jusqu'au logout.

**À faire** — comparer `a.toSet()` à `b.toSet()`.

---

### B-4 · La recherche par niveau n'a pas d'état « inscriptions pas encore synchronisées »

`lib/features/finance/presentation/widgets/fee_control_results_view.dart:161`

`feeControlEmptyNoLocalEnrollment` n'est atteignable que si
`lastQuery.classroomId != null`. Sur « toutes les classes du niveau », une
tablette fraîchement hydratée dont le pull Inscription n'a pas atterri tombe sur
« Aucun élève ne correspond à ces critères. Modifiez le formulaire » — on envoie
l'opérateur corriger des critères qui n'y peuvent rien.

**À faire** — rendre l'état atteignable sur les deux formes de recherche.

---

## ✅ Traité

### ~~#13 · L'anti-rafale de reprise n'est pas monotone~~ — corrigé (`5123439`)

`lib/core/components/status/sync_status_cubit.dart` — l'horloge est celle du
device, donc reculable : un NTP corrigeant une dérive de RTC laissait
`_lastCycleAtMs` dans le futur, l'écart devenait négatif et le déclencheur de
reprise ne repartait plus jamais en cycle complet. Un écart négatif prend
désormais le chemin long, avec test de régression vérifié par mutation.

---

## Vérifié sain par la revue

L'escalier de migration v27 (bornes `upTo`, DDL v9 inliné, plus aucune lecture
du schéma vivant sur une table retirée, `UPDATE students` gardé), le câblage DI
de `credentialsProbe` / `permissions` / `planHolder` sur `PullCoordinator`,
l'arithmétique en centimes du contrôle des frais et la jointure `fee_code` par
lots de 500, `ClientSidePaginator`, `PullSequencer`, la table d'alias des
18 clés, `leaveWizardToListing` / `onDetailReturned`, `SyncStateIcon`
(null vs DRAFT), et l'observateur de reprise du lot 1.
