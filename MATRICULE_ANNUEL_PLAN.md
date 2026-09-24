# Matricule annuel — socle de synchronisation et ligne sur le ticket

> ## Statut au 2026-09-24 : **écrit avant exécution, rien n'est livré**
>
> Plan front du champ `annualMatriculationNumber`, ajouté par le back et **pas
> encore déployé**. Aucune question de contrat n'est ouverte : la note du back
> est complète, et ce plan ne fait qu'en tirer les conséquences côté front.
>
> | | état |
> |---|---|
> | §3 Schéma `enrollments.annual_matriculation_number` | à écrire |
> | §4 Palier v51 (escalier **tenant**) | à écrire |
> | §5 Les deux DTO de pull | à écrire |
> | §6 L'écriture, deux chemins | à écrire |
> | §7 La lecture du ticket | à écrire |
> | §8 La ligne sur le papier | à écrire |
> | §9 Les tests | à écrire |
> | **Re-hydratation** (§11.1) | **différée — livraison ultérieure** |
> | **Fiche élève et listes** (§11.2) | **hors lot** |

---

## 0. D'où vient ce plan

Deux sources, et elles ne disent pas la même chose.

| | Source | Ce qu'on en tire |
|---|---|---|
| 1 | Note back du 2026-09-24 (Artifact du porteur) | le contrat : forme du champ, endpoints, règles, `null` légitimes |
| 2 | Lecture du code de pull des inscriptions | **quatre faits que la note ne dit pas**, et qui décident du plan |

Les quatre faits, vérifiés dans le dépôt :

1. **Il y a DEUX flux d'inscriptions**, pas un. `enrollments` porte le delta
   maigre (`UPDATE`-only), `enrollment_snapshots` porte l'agrégat complet
   (élève + parents + inscription, `UPSERT`). La note dit « ce flux » sans
   trancher ; **c'est le curseur du delta qu'une re-hydratation doit remettre à
   zéro**, l'autre coûterait dix fois plus.
2. **Le rejeu du delta fonctionne, et ça tient à un caractère.** La garde LWW de
   `_applyDeltaItem` est `updated_at <= ?`, **inclusive** : rejouer les mêmes
   lignes avec des horodatages identiques passe. En `<` strict, toute
   re-hydratation aurait été un coup d'épée dans l'eau — sans rien signaler.
3. **Le delta est gardé par `_hasEverHydrated`**, qui lit le curseur de
   l'**hydratant**. Effacer le curseur du delta est donc sans danger : la garde
   ne mord pas.
4. **Le delta ignore les lignes non `SYNCED`** (`WHERE … AND sync_status = ?`).
   Un brouillon local ne recevra le champ qu'à sa prochaine mise à jour
   légitime. C'est voulu — on n'écrase jamais une écriture locale — mais il faut
   le savoir avant de conclure « le champ ne descend pas ».

---

## 1. Ce que le champ est, et ce qu'il n'est pas

Le matricule classique ne change jamais. Le matricule annuel reprend son préfixe
et ses six chiffres, et **remplace l'année par le code catalogue du niveau** où
l'élève est inscrit cette année-là.

| Matricule classique | Niveau | Matricule annuel |
|---|---|---|
| `CF-2026-000018` | `P4` | `CF-P4-000018` |
| `CF-2026-000018` | `P5` (année suivante) | `CF-P5-000018` |
| `CF-2026-000123` | `HG-SCI-1` | `CF-HG-SCI-1-000123` |

- **Il appartient à l'INSCRIPTION, pas à l'élève.** Deux inscriptions ⇒ deux
  matricules annuels. Toute lecture est donc scopée à une année.
- **Lecture seule**, calculé serveur, jamais accepté en push.
- **`null` légitime** : niveau hors catalogue officiel, ou matricule classique
  au format non standard (imports). Et un troisième cas, propre au ticket :
  versement sans année.
- 🔴 **Ce n'est PAS une clé.** La séquence à six chiffres repart à 1 chaque
  année civile : deux élèves d'un même niveau peuvent partager le même matricule
  annuel. **Jamais** de recherche, de déduplication ni de jointure dessus. Le
  matricule classique et les UUID restent les seuls identifiants.
- Le poste **ne peut pas le calculer** : le référentiel ne transmet pas le code
  catalogue des niveaux.

---

## 2. Périmètre, et pourquoi il s'arrête là

**Dans ce lot** : le socle de synchronisation (colonne, les deux mappings) et la
ligne sur le ticket de perception.

⚠️ **Le lot est INERTE à la livraison, par construction.** Le back n'est pas
déployé : le champ arrivera nul, les colonnes se rempliront au fil des
inscriptions modifiées, et le ticket taira la ligne. « Ça ne fait rien » sera le
comportement **attendu**, pas un défaut — à dire à qui testera, faute de quoi le
lot sera déclaré cassé.

**Hors lot, et décidé par le porteur le 2026-09-24** : la re-hydratation part
dans une livraison publiée **après** le déploiement back (§11.1), et l'affichage
fiche élève / listes attend (§11.2).

---

## 3. Le schéma

`enrollment_finance_offline_schema.dart`, table `enrollments` :
`annual_matriculation_number TEXT` après `enrollment_code`.

⚠️ L'ordre des colonnes diffèrera entre une base **neuve** (position déclarée) et
une base **migrée** (`ALTER` ajoute en queue). Sans conséquence — tous les accès
sont nommés — mais ça surprend en lisant un `PRAGMA table_info`.

---

## 4. Le palier v51

`lib/core/database/tenant/tenant_migrations.dart`, **escalier tenant** :
`enrollments` est une table d'école, et l'escalier hérité est clos à la v48.

```dart
if (upTo(51)) await _addAnnualMatriculationNumber(db);
```

Même forme que `_addTillPhone` (v50) : garde `PRAGMA table_info` avant le
`ALTER`. SQLite refuse un `ADD COLUMN` sur une colonne existante, et une base
héritée adoptée repasse par cet escalier.

`AppConstants.offlineDbSchemaVersion` → **51**.

⚠️ **Numéro ATTRIBUÉ, pas réservé.** Si un autre lot fusionne avant, c'est celui
qui fusionne en **second** qui renumérote — règle posée à la v47. Et on ne
réattribue jamais un numéro déjà sorti : le trou brûlé de la v24 dit pourquoi.

**Aucune reprise de données dans ce palier.** La colonne naît vide et se remplit
par le pull. La re-hydratation est un geste séparé (§11.1).

---

## 5. Les deux DTO

`EnrollmentDeltaDto` et `EnrollmentSnapshotDto` :
`final String? annualMatriculationNumber;`, plus la lecture dans `fromJson`.

Le contrat le porte sur l'inscription dans les deux flux :
`items[].annualMatriculationNumber` pour le delta,
`items[].enrollment.annualMatriculationNumber` pour le snapshot.

---

## 6. L'écriture — deux chemins qui ne se ressemblent pas

### 6.1 Le delta (`_applyDeltaItem`)

Un `UPDATE` à arguments **positionnels**. Ajouter `annual_matriculation_number = ?`
à la clause `SET` **et l'argument au rang exact** dans la liste.

🔴 **Le point le plus facile à rater du lot.** Une liste positionnelle décalée
écrit la bonne valeur dans la mauvaise colonne, et **rien ne lève**. Compter les
`?` avant de commiter.

**Affectation franche : ni `COALESCE`, ni garde `!= null`.**

Le matricule classique, quatre lignes plus bas, porte une garde `!= null` — il ne
devient jamais nul légitimement, et la nullifier serait une perte. L'annuel, si :
un niveau corrigé hors catalogue le fait légitimement disparaître, et le garder
imprimerait sur le papier un matricule que le serveur a retiré.

⚠️ **Deux règles voisines dans la même méthode : le commentaire doit dire
pourquoi**, faute de quoi la prochaine lecture « harmonisera » et réintroduira le
défaut.

### 6.2 Le snapshot

Une carte **nommée** (`enrollmentColumns`) : une ligne à ajouter, rien de
positionnel, rien à compter.

---

## 7. La lecture du ticket

`ProvisionalTicketDao`, méthode neuve :

```sql
SELECT annual_matriculation_number
FROM enrollments
WHERE student_id = ? AND academic_year_id = ?
ORDER BY (status = 'CANCELLED') ASC, updated_at DESC, id ASC
LIMIT 1
```

- **Tri total.** `(student_id, academic_year_id)` peut rendre plusieurs lignes —
  une annulée et la vivante. Le ticket étant **librement réimprimable**, deux
  tirages du même versement ne doivent pas porter deux matricules différents :
  `updated_at DESC` départage, `id ASC` rend le tri strict.
- `(status = 'CANCELLED') ASC` place la non annulée devant (0 avant 1).
- **Sortie anticipée quand l'année est nulle** — et donc **aucun `null` en
  `whereArgs`** : le validateur du pilote lèverait, piège déjà documenté.

---

## 8. Le papier

- Modèle : `annualMatriculationNumber` + entrée dans `props`.
- Repository : câblage depuis le DAO.
- Gabarit : un `_addOptional` **juste sous le matricule**. Il n'imprime rien
  quand la valeur est nulle — exactement la règle voulue, sans garde à écrire.
- Deux clés `.arb` : « Mat. annuel : » / « Annual no.: ».

```
TICKET DE PERCEPTION
------------------------------------------------
MBALA-KASA NDOMBASI AMINA
Matricule : CF-2026-000018
Mat. annuel : CF-P4-000018
Classe : 5e primaire A
```

⚠️ **Largeur, cas limite à porter par un test.**
`Mat. annuel : CF-HG-SCI-1-000123` fait **32 caractères**, soit *exactement* la
largeur d'un papier 58 mm. Un code de niveau d'un caractère de plus déborde et se
replie. C'est ce cas-là que le test doit exercer, pas un cas moyen.

---

## 9. Les tests

| Niveau | Cas |
|---|---|
| Migration v51 (3) | la colonne arrive et la ligne existante survit · rejouable · base déjà en v51 intacte |
| Delta (3) | le champ atterrit sur une ligne `SYNCED` · **un `null` venu du serveur EFFACE la valeur** (c'est l'affectation franche de §6.1 qu'on vérifie) · une ligne non `SYNCED` reste intacte |
| Snapshot (2) | une tablette neuve hydrate le champ · l'écriture locale reste préservée |
| DAO ticket (4) | prend l'inscription de l'année · préfère la non annulée · deux lectures rendent le même · année nulle ⇒ `null` |
| Gabarit (3) | ligne sous le matricule · nulle ⇒ ni ligne ni libellé · largeur à 48 **et** 32 |

⚠️ **Contre-épreuve obligatoire sur la migration** : retirer le `upTo(51)` doit
faire rougir. Un test de migration qui ne réagit pas au retrait de sa migration
ne prouve rien — payé en vrai sur la v50.

---

## 10. Vérification

`flutter analyze` à **zéro**, puis la suite **COMPLÈTE**, pas le périmètre
`documents` habituel : un palier de migration qui casse se voit dans `core/` et
dans Inscription, **jamais** dans les tests du ticket.

---

## 11. Ce qui reste après ce lot

### 11.1 La re-hydratation — livraison ultérieure

Le flux delta ne renvoie une inscription que lorsqu'elle est modifiée. Les
inscriptions déjà synchronisées n'apporteront donc **jamais** le champ d'elles-
mêmes : il faut, **une fois**, repartir de zéro sur le curseur `enrollments`.

🔴 **Elle ne part PAS avec ce lot, et c'est la décision qui compte.** Le back
n'est pas déployé : déclencher la re-hydratation à la mise à jour de
l'application paierait un re-pull complet des inscriptions **pour ne récolter que
des `null`** — et un marqueur consommé laisserait le champ vide pour toujours.

Le porteur a tranché (2026-09-24) : la re-hydratation part dans une **livraison
publiée après le déploiement back**. Le problème de coordination devient alors un
problème d'ordre de livraison, que le porteur contrôle.

Le mécanisme sera alors trivial : `SyncMetaDao.deleteCursor('enrollments')`, une
fois, sous marqueur. Deux précédents dans le dépôt —
`academics_cours_pull_repository_impl.dart` et `pre_enrollments_school_guard.dart`.
Et le §0.2 garantit que le rejeu écrira bien.

### 11.2 Fiche élève et listes

À côté du matricule classique, pour l'année consultée. Rien quand le champ est
nul — **jamais un libellé vide**, qui se lirait comme une mention effacée.

### 11.3 La règle à ne jamais enfreindre

🔴 **Aucune recherche, aucune déduplication, aucune jointure sur ce champ.**
Voir §1. Le jour où quelqu'un l'utilisera comme clé, deux élèves d'un même niveau
se confondront, et rien ne le signalera.

---

## 12. Les pièges, rassemblés

| # | Piège | Où |
|---|---|---|
| 1 | Arguments positionnels du delta décalés — rien ne lève | §6.1 |
| 2 | « Harmoniser » l'affectation franche avec la garde du matricule classique | §6.1 |
| 3 | `null` en `whereArgs` quand l'année est absente | §7 |
| 4 | Tri non total ⇒ deux tirages, deux matricules | §7 |
| 5 | `Mat. annuel : CF-HG-SCI-1-000123` = 32 caractères pile | §8 |
| 6 | Déclarer le lot cassé alors qu'il est inerte à dessein | §2 |
| 7 | Re-hydrater avant le déploiement back | §11.1 |
| 8 | Se servir du champ comme d'une clé | §11.3 |
