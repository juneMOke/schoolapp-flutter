# Le téléphone du tuteur devient facultatif — plan front

> Contrepartie front de la **V117** serveur
> (`V117.0.0__parent_phone_number_optional.sql` + `GuardianMatcher`),
> aujourd'hui **non commitée**, dans l'arbre de `fix/finance-outstanding-per-charge`.

## Ce que le serveur dit désormais

| Point de contact | Avant | Maintenant |
|---|---|---|
| `ParentInput` (push agrégat inscription) | `@NotBlank phoneNumber` | `String phoneNumber` — facultatif |
| `CreateParentRequest` / `UpdateParentRequest` | `@NotNull` | facultatif |
| `parents.phone_number` (Postgres) | `NOT NULL` depuis V6 | nullable · `CHECK (IS NULL OR ~ E.164)` |
| Rapprochement d'un tuteur | get-or-create **global** par téléphone (clé naturelle, ADR-005 D11) | **inchangé quand il y a un numéro** ; sans numéro → nom complet exact, **dans le dossier de CET élève seulement** |
| Notification WhatsApp | tuteur toujours joignable | tuteur sans numéro **ignoré en silence** (`debug`, pas un warning : c'est un fait normal) |
| Portail parent (ADR-019) | identifiant = le numéro | un tuteur sans numéro n'y a **pas accès** |

Trois règles descendent de là :

1. **`NULL`, jamais `''`, et surtout jamais un placeholder.** Le serveur détaille
   pourquoi : `parents_phone_number_key` est UNIQUE **global**, donc un
   placeholder n'existe qu'une fois dans toute la base — collision invisible
   entre écoles (409 en boucle), et *pire* à l'intérieur d'une école : ça marche,
   tous les tuteurs sans numéro fusionnent dans une fiche, et le portail parent
   ouvre alors l'accès aux dossiers de tous leurs enfants.
2. **Sans numéro, un tuteur n'est jamais partagé avec la fratrie.** C'est
   exactement ce que le téléphone prouvait et que son absence ne prouve plus.
   Deux homonymes sans numéro dans deux familles ne sont rapprochés par rien.
3. **Le rapprochement par nom ne traverse pas les dossiers** — ni phonétique, ni
   distance d'édition : nom écrit, aux espaces et à la casse près.

## Ce qui reste exigé

Le **format** du numéro quand un numéro est entamé, et la tolérance à la valeur
héritée intacte. Identique à ce qui vient d'être fait pour le payeur — c'est déjà
la forme de `ParentItemValue.isPhoneAcceptable`, seul le « vide = refusé » saute.

## Lots

> **Livré dans un worktree isolé** — `.claude/worktrees/telephone-tuteur`,
> branche `feat/telephone-tuteur-facultatif`. L'arbre principal était occupé par
> le chantier GF-0 (sections de frais), qui tenait `app_database.dart`,
> `enrollment_finance_offline_schema.dart` et `app_constants.dart` — les trois
> premiers fichiers de ce lot.
>
> ✅ **Rebasé sur `df118782`** (GF-0, palier v44). Les paliers s'enchaînent
> 43 → 44 → 45 ; les deux conflits étaient du genre « les deux, dans l'ordre ».
> `enrollment_finance_offline_schema.dart` n'a pas conflité : la `TableSchema` de
> GF-0 est ailleurs dans le fichier, ce lot ne touche que `parentsTable`.
>
> **5574 tests verts, `analyze` propre**, après rebase.

| Lot | Portée | État |
|---|---|---|
| **TP-0** | Schéma local **v45** : `parents.phone_number` perd son `NOT NULL` (via `_rebuildTableInPlace`, le patron de la v43) ; les `''` deviennent `NULL`. | ✅ |
| **TP-1** | Types `String?` de bout en bout : `ParentSnapshotDto`, `ParentLocalModel`, `LocalParent`, `ParentSummary`, `ParentPayload` (outbox), requête d'agrégat (omis quand nul). | ✅ |
| **TP-2** | **Rapprochement** — `findGuardianWithoutPhone`, miroir de `GuardianMatcher` : sans numéro, nom complet exact parmi les tuteurs **déjà rattachés à cet élève** et eux-mêmes sans numéro. | ✅ |
| **TP-3** | Wizard Tuteurs : plus d'étoile, `isPhoneAcceptable` accepte le vide, mention de ce que l'absence coûte. | ✅ |
| **TP-4/5** | Affichages : « Sans numéro » explicite dans la carte tuteur et les résultats de recherche ; le récapitulatif escamote la ligne. | ✅ |
| **TP-6** | l10n (FR + EN) et tests — 5 de migration, 9 de règle pure, 5 de DAO. | ✅ |

## Ce que l'écran dit maintenant

| Endroit | Tuteur sans numéro |
|---|---|
| Champ téléphone | Aucune étoile, mention « facultatif — sans numéro, ce tuteur ne recevra aucune notification et n'aura pas accès au portail parent, et il ne pourra pas être repris pour un frère ou une sœur » |
| Garde de l'étape | **Passe.** Seul un numéro entamé mais incomplet la bloque |
| Carte du tuteur | « Sans numéro » au lieu d'un tiret |
| Résultats de recherche | « Sans numéro » — une ligne vide se lirait comme un chargement inachevé |
| Récapitulatif | La ligne s'escamote |
| Fratrie | **Une fiche par dossier.** Le rapprochement ne traverse pas les dossiers |

## Pièges repérés

- 🔴 **`ParentSnapshotDto.fromJson` fait `j['phoneNumber'] as String`.** Le jour
  où le serveur descend un tuteur sans numéro, le pull d'inscription **lève**.
  Ce n'est pas un confort : c'est la première chose à corriger.
- 🔴 **`student_parent` est purgé AVANT la boucle d'upsert**
  (`enrollment_draft_dao.dart`). La liste des tuteurs déjà rattachés — dont le
  rapprochement par nom a besoin — doit être capturée avant la purge, comme le
  fait déjà `previousDesignation`. Sinon la règle ne voit jamais personne et
  chaque passage sur l'étape crée un doublon.
- ✅ `findParentIdByPhone` se garde déjà sur la clé vide (`if (key.isEmpty)
  return null`) : aucune fusion catastrophique à craindre côté local. Mais la
  conséquence est l'inverse — **sans règle de nom, `upsertParentByPhone`
  réinsère à chaque rejeu**.
- ⚠️ `upsertDraftGuardianParent` lève `ParentPhoneConflictException` sur
  `findParentIdByPhone(...)`. Clé vide ⇒ `null` ⇒ pas de faux conflit. À
  préserver : un « ce numéro appartient déjà à un autre tuteur » sur deux fiches
  sans numéro serait incompréhensible.
- ⚠️ SQLite ne sait pas retirer un `NOT NULL` : reconstruction rename/copy/drop,
  sur le patron des paliers v33/v34/v43.
- ⚠️ Le back est **non commité** sur une branche de correctif
  (`fix/finance-outstanding-per-charge`). Si le contrat bouge, le front suit.
- 🔴 **`ParentPayload.fromJson` de l'outbox castait aussi en `as String`.** Un
  dossier mis en file avec un tuteur sans numéro serait relu en erreur et
  basculerait en `failed` — issue TERMINALE, sur une inscription déjà validée au
  guichet. Corrigé en même temps que le cast du pull.
- ✅ Le rejeu est prouvé **à travers le DAO**, pas seulement sur la règle pure :
  c'est le seul niveau où le piège de la purge se voit. Un test unitaire vert sur
  `findGuardianWithoutPhone` ne dit rien de ce que le DAO lui passe.
- ✅ Un test vérifie que la reconstruction **repose ses index**
  (`idx_parents_phone`, `idx_parents_names`). `_rebuildTableInPlace` le faisait
  déjà ; rien ne le prouvait, et une table qui perd ses index marche encore —
  elle rame.
