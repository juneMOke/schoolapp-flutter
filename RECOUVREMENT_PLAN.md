# RECOUVREMENT_PLAN.md — combien il manque, et où

> Plan front du module **Recouvrement** (ex « Contrôle des frais ») et de son
> tableau de bord. Contrat back **figé** au terme de quatre tours ; ce plan
> n'ouvre aucune question de contrat.

---

## 0. D'où vient ce plan

Quatre tours de confrontation avec le back, le 2026-09-10 :

| | Document | Ce qui s'y est joué |
|---|---|---|
| 1 | Contrat back v1 | `/ledger` + `/call-list.pdf`, 7 lots, 7 amendements à la maquette |
| 2 | Contre-lecture du front (D1→D9) | `/ledger` refusé : le registre est déjà sur l'appareil |
| 3 | Contrat back v2 | `/ledger` **retiré**, 4 lots, le serveur devient une imprimerie |
| 4 | Addendum front (D10→D12) puis back | identités résolues serveur, garde arithmétique, compression du corps |
| 5 | Clôture | R1→R4 tranchés, contrat clos, back démarre L1 |

**Bilan des erreurs, écrit une fois pour mémoire.** Le back s'est trompé quatre
fois (la source du registre, le code de refus du plafond, la faille du libellé
de classe par ligne, le chiffre de la sélection mixte). Le front trois fois (la
dichotomie rapport/pièce, la garde arithmétique, et la croyance qu'un refus
avant désérialisation épargne le téléversement). **Aucune des sept n'aurait été
trouvée par celui qui l'avait commise.**

---

## 1. La question posée

> « Où en est la dette de l'école, quelles classes décrochent, et que coûterait
> un renvoi ? »

Trois lectures d'un même fait : pour chaque élève inscrit et chaque frais, un
**dû** et un **payé cumulé**. C'est un **stock**, pas un flux — l'écran ignore
les dates et ne dit jamais « combien est entré aujourd'hui ». Cette
question-là appartient à Finances ▸ Caisse.

### Ce qui change par rapport au tableau de bord livré le 2026-09-02

| | `FEE_CONTROL_DASHBOARD_PLAN.md` (livré) | Ce plan |
|---|---|---|
| Frais | **un** à la fois | une **sélection**, jamais vide |
| Unité | des élèves | des élèves **et** des montants |
| Sortie | aucune | une **liste de relance signée**, en PDF serveur |
| Arbitrage | aucun | la **simulation de renvoi** |

Le nouvel écran **absorbe** l'ancien : il ne s'y ajoute pas. Le classement par
niveau, le dépliage en classes et la bande de synthèse sont repris tels quels.

---

## 2. Le fait déterminant

**Tout le registre est déjà sur l'appareil, et le back l'a reconnu en retirant
son endpoint.**

```
student_charges  student_id · academic_year_id · school_level_id
                 school_level_group_id · fee_tariff_id · fee_code · label
                 expected_amount_in_cents · amount_paid_in_cents
                 optimistic_paid_in_cents · currency · status · due_at
```

Les créances **et** les paiements descendent par un pull de **masse** — keyset,
sans filtre élève, sur l'année active (`finance_student_charges`,
`finance_payments`). Le référentiel suit : `ref_fee_code_sections` (le titre que
l'école a rédigé), `ref_fee_tariffs` (la devise par tarif),
`ref_exchange_rates` (la série datée), `ref_classroom_members` (le roster),
`students`.

**Ce que le serveur ne peut pas voir, et que nous voyons :** les allocations des
paiements non encore remontés (`sync_status <> 'SYNCED'`). Un versement encaissé
hors ligne à 9 h déplace le taux immédiatement. C'est l'argument qui a fait
tomber `/ledger` : un registre serveur nommerait « n'a rien payé » un élève
encaissé une heure plus tôt — et le papier signé le nommerait aussi.

---

## 3. Ce que cet écran n'est pas

| | | |
|---|---|---|
| Finances ▸ Caisse | ce qui est **entré dans le tiroir** | un flux, daté, serveur |
| Facturation | encaisser, émettre un reçu, remiser | cet écran **n'écrit rien** sur l'argent |
| Inscriptions | appliquer un renvoi, dossier par dossier | la simulation **ne s'applique jamais** |
| Boutique | achats non facturés | hors dette scolaire : ni dans l'attendu, ni dans le taux |

---

## 4. Décisions tranchées

### D1 — 100 % local, un seul appel réseau : le PDF ✅

Aucune lecture ne passe par le réseau. Le seul appel est
`POST /api/v1/finance/relance-list`, et il **écrit un document**, il ne lit rien.

L'écran reste donc entier hors ligne, sous la seule permission
`finance.charge.read` — celle du secrétariat, celle qui a fait sortir ce module
de Finances le 2026-09-02.

### D2 — le module devient « Recouvrement », menu **et** route ✅

`controle-frais` → `recouvrement` sur les trois identifiants et les deux
chemins. Un chemin qui dit « contrôle-frais » sous un menu « Recouvrement »
vieillit mal, et le coût est un rename mécanique.

| Avant | Après |
|---|---|
| `MenuConstants.feeControlMenuId = 'controle-frais'` | `recouvrementMenuId = 'recouvrement'` |
| `feeControlDashboardId = 'controle-frais-dashboard'` | `recouvrementDashboardId = 'recouvrement-dashboard'` |
| `feeControlId = 'controle-frais-eleves'` | `recouvrementControlId = 'recouvrement-controle'` |

Le répertoire `lib/features/fee_control/` devient `lib/features/recouvrement/`
par un **rename pur** (`git mv`), commité seul — cf. la note de découpage des
commits : un déplacement de module ne se mélange jamais à une modification.

### D3 — l'onglet Finances ▸ Recouvrement est supprimé ✅

`FinanceRecoveryTab`, `FinanceRecoveryBloc`, `GetFinanceRecoveryUseCase`, les
entités `finance_recovery/` et l'appel à `/finance-stats/recovery` partent. La
page Finances retombe à un seul onglet et devient la page **Caisse** —
`FinanceDashboardTabs` disparaît avec elle.

**Pourquoi supprimer et non conserver.** Deux écrans de recouvrement dont l'un
compose la file d'écritures et l'autre non donneraient deux chiffres différents
sur les mêmes données. C'est exactement ce que la contre-lecture reprochait à
`/ledger`. Le profil « pilotage sans accès aux créances »
(`finance.stats.read` sans `finance.charge.read`) garde la Caisse.

⚠️ **`/finance-stats/recovery` reste servi** côté back : la suppression est un
choix de l'app, pas une rupture de contrat. Le jour où un client web en aurait
besoin, il est là.

### D4 — deux sous-menus, pas deux onglets internes ✅

La spec décrit un `FinTabs` monté par une coque `RecouvrementScreen`. L'app a
déjà **deux sous-menus** rendus par la coquille, avec leurs routes et leurs
gardes. On garde les sous-menus.

**Écart avec la maquette, assumé** : monter des onglets internes sous un
sous-menu qui en est déjà un ferait deux niveaux de bascule pour une seule
navigation, et casserait la synchronisation de la barre latérale que
`NavigationBloc` tient déjà.

### D5 — la maille reste le **niveau**, dépliable en classes ✅

Accordé par le back (sa D7). Ses propres mesures le prouvent : sur l'année en
cours, la couverture d'affectation à une classe est de **5 %, 13 %, 0 %** selon
le cycle. Un classement par classe rangerait 95 % de l'effectif dans une ligne
« Non affectés » : le classement resterait vrai et n'apprendrait rien.

`school_level_id` est porté par la créance elle-même et renseigné par le pull
**et** par le semis d'inscription — zéro jointure.

### D6 — le tableau de bord absorbe le FCD ✅

Le classement par niveau, le dépliage en classes, la bande de synthèse et le
passage vers l'écran nominatif (`FeeControlIntent`) sont **repris**, pas
réécrits. Ce qui change : ils portent une sélection de frais au lieu d'un seul.

### D7 — la simulation est en V1, et elle est le point d'entrée de la liste ✅

⚠️ **Le clic ouvre un APERÇU, il n'édite pas.** La liste qui sort d'ici se signe
et circule : la faire sortir d'un clic ferait produire un papier que personne n'a
lu, sur une population qu'on n'a pas vérifiée. L'aperçu nomme les élèves depuis
les inscriptions locales, et le bouton d'édition vit dans son pied.

L'aperçu et l'édition partagent la **même** population, calculée une seule fois :
deux appels du prédicat à deux instants pourraient déjà diverger, et l'écran ne
doit pas montrer douze noms pour en imprimer treize.

C'est du calcul pur en mémoire, sans couche data neuve. Et dans la spec, le
**clic sur une ligne de classe de la simulation est le seul point d'entrée de la
liste de relance** : livrer le contrat qu'on vient de négocier en quatre tours
sans son déclencheur n'aurait pas de sens.

### D8 — le taux suit la règle serveur ✅

`round((Σ attendu − Σ reste) × 100 / Σ attendu)`, et `100` quand
`Σ attendu == 0`. **Jamais `perçu / attendu`**, qui franchit 100 % dès qu'un
versement solde la créance d'un autre exercice.

C'est déjà la règle de `FinanceKpis.collectionRate`, avec la même
justification. Elle survit à la suppression de l'entité : elle migre ici.

### D9 — jamais de somme inter-devise ✅

Tout montant du module est un `MoneyBag`. Le sac n'expose **aucun scalaire
agrégé**, et ce n'est pas un oubli d'API : c'est ce qui rend le geste impossible
plutôt que déconseillé.

### D10 — l'équivalent dollars trie, il n'affiche jamais ✅

`cents / rateMicros` sert à ordonner une liste mixte et à comparer un plancher.
Il ne produit **jamais** un montant affiché. Si aucun taux n'est posé, le
critère « a payé moins que… » est indisponible en sélection mixte, et le dit.

### D11 — le statut d'élève est emprunté, jamais recalculé ✅

`LocalFeeChargeAggregate.status` reste la seule règle du module. C'est ce qui
interdit aux deux écrans de se contredire sur le même élève — invariant §6.1 du
plan FCD, qu'on ne rouvre pas.

### D12 — l'évolution mensuelle n'est pas reprise ✅

Le graphe mensuel de l'onglet Finances disparaît avec lui. La spec le range
elle-même hors périmètre : « trésorerie du jour, ticket moyen — questions de
flux, traitées par Encaissements ».

---

## 5. Contrat de lecture (100 % local)

### 5.1 Les natures de frais de l'année — **existe**

`GetFeeCodesForYearUseCase` → `List<String>`, triées par effectif porté. Des
**codes**, jamais des libellés : l'écran est école-wide et un même `fee_code`
porte des libellés différents d'un niveau à l'autre.

### 5.2 Les positions **multi-frais** — **à étendre**

Le DAO actuel (`getFeeChargePositionsByLevel`) est borné à **un** `fee_code` et
rend un `LocalFeeLevelAggregate` par (élève, niveau) portant une position par
devise. Il faut :

```sql
WHERE sc.fee_code IN (?, ?, …)      -- au lieu de = ?
GROUP BY sc.student_id, sc.school_level_id, sc.fee_code, sc.currency
```

et une entité qui garde le **détail par frais** — le taux par frais en a besoin,
et le statut de l'élève se calcule sur la sélection entière :

```dart
/// Position d'un élève sur UNE SÉLECTION de frais, rattachée au niveau que
/// portent ses créances.
class LocalRecoveryLine {
  final String? schoolLevelId;      // nullable, et la ligne est conservée
  final String studentId;
  /// Une entrée par (fee_code, devise). Jamais vide.
  final List<RecoveryChargePosition> positions;
}
```

⚠️ Le plafond de variables liées de SQLite (999) n'est pas un risque ici — une
école a moins de dix natures de frais — mais la borne existante
(`_idBatchSize = 500`) reste la référence si la liste venait à grossir.

### 5.3 Les classes du niveau déplié — **existe**

`GetOfflineClassroomsUseCase` + `GetComposedRostersUseCase`. La classe se
**compose** à la lecture (miroir `ref_classroom_members` ± `classroom_transfers`
non remontés) — un transfert fait hors ligne se voit immédiatement.

### 5.4 Le taux de guichet — **existe**

`ExchangeRateReader.forCurrentSchool()` → série datée, `rateMicros` entier
(`numeric(18,6)` = micro-unité), `divergenceBandBp`, `setBy`. **Une lecture ne
remonte jamais d'erreur** : sans école résolue, la série est vide et l'écran
n'offre aucun arbitrage — jamais un taux inventé.

### 5.5 Les identités — **existe**

`SearchLocalEnrollmentsUseCase` pour la note des non-facturés,
`ref_classroom_members` pour les noms du roster. **Aucune identité ne part sur le
fil** : le serveur les résout lui-même (D10 de l'addendum).

---

## 6. Le contrat d'écriture — le seul appel réseau

```
POST /api/v1/finance/relance-list        finance.charge.read  (seule)
Content-Encoding: gzip                   → 268 Ko au pire palier au lieu de 1,62 Mio
```

```json
{
  "scope": { "kind": "SCHOOL_LEVEL", "id": "…" },
  "feeCodes": ["TUITION", "BOOKS"],
  "criterion": "NO_PAYMENT",
  "thresholdInCents": 12000, "thresholdCurrency": "USD",
  "arretedAt": "2026-09-10T08:05:00Z",
  "pendingWrites": 3,
  "lines": [
    { "studentId": "…",
      "due":         [{ "currency": "USD", "amountInCents": 30000 }],
      "paid":        [{ "currency": "USD", "amountInCents": 12000 }],
      "outstanding": [{ "currency": "USD", "amountInCents": 18000 }] }
  ]
}
```

| Champ | Ce que le front garantit |
|---|---|
| `scope.kind` | `CLASSROOM` · `SCHOOL_LEVEL` · `SCHOOL_LEVEL_GROUP` · `UNASSIGNED`, exclusifs. **Le libellé est résolu serveur** — on n'envoie jamais de chaîne d'affichage. |
| `criterion` | **Descriptif** : le serveur l'imprime en sous-titre, il ne filtre rien. C'est nous qui avons filtré. |
| `arretedAt` | Notre horloge. Le document imprime **aussi** la date d'émission du serveur — les deux ne peuvent pas se confondre. |
| `pendingWrites` | **Des encaissements de la file finance non acquittés, et rien d'autre.** Ni inscriptions, ni transferts, ni présence. Le gabarit dit « n encaissement(s) », pas « n écriture(s) ». |
| `lines[]` | `studentId` + trois sacs. **Sacs non élagués** : un élève soldé part avec `outstanding: [{USD, 0}]`, jamais un sac vide — le sac vide dit « aucun montant », l'entrée à zéro dit « en dollars, il ne reste rien ». |

### Les erreurs, et ce qu'on en fait

| Code | `detailCode` | Rendu à l'écran |
|---|---|---|
| `400` | `REPORT_LINE_CAP` | nos mots, ses chiffres (`lines`, `cap`) — **le décodeur existe déjà** |
| `400` | `UNKNOWN_STUDENTS` | `{ count, sample }` — `sample` porte des identifiants, jamais des noms |
| `400` | `INCONSISTENT_LINE` | **notre bug** : journal de débogage, message générique à l'écran |
| `403` | — | `finance.charge.read` absente : jamais de « Réessayer » |
| `429` | — | **« Un document est déjà en préparation sur ce serveur »** — le permis est partagé avec le rapport de caisse et le registre d'inscriptions : le refus peut venir d'un collègue. `Retry-After: 60`. |

### Les délais, mesurés le 2026-09-10 (lot L4 du back) ✅

| Palier | Rendu avant le 1ᵉʳ octet | Montant (gzip) | Descendant (PDF) |
|---|---|---|---|
| 100 lignes | ~1,1 s | 5 Ko | 65 Ko |
| **500 lignes — un niveau** | **~3,0 s** | **26 Ko** | **228 Ko** |
| 2 000 lignes | ~5,9 s | 103 Ko | 833 Ko |
| 5 000 lignes (plafond, mixte) | ~7,1 s | 257 Ko | 2 050 Ko |

**`receiveTimeout` = 30 s · `sendTimeout` = 60 s.** Ils ne mesurent pas la même
chose, et c'est ce qui fixe l'écart :

- ⚠️ **`receiveTimeout` joue DEUX rôles.** Sur `request.close()` c'est un
  **budget total** — l'attente avant les en-têtes, donc le silence de rendu de
  1 à 7 s. Sur le flux du corps c'est un **intervalle entre chunks**, réarmé à
  chaque paquet (`handleResponseStream`, Dio 5.9). Le PDF du plafond met
  5 min 28 à descendre sur 50 kbit/s et **ne coupe pas** pour autant.
- ⚠️ **`sendTimeout` est un budget TOTAL**, lui : l'adaptateur l'applique à
  `request.addStream`, qui ne se complète qu'une fois tout le corps écrit.
  41 s au plafond sur 50 kbit/s — **30 s couperait un envoi sain**.

### 🔴 Ce que les mesures apprennent, et que quatre tours de contrat avaient manqué

**C'est la réponse qui coûte, pas la requête.** Au plafond, le PDF pèse **huit
fois** le corps compressé (2 050 Ko contre 257 Ko), et il n'y a pas de remède
symétrique : un PDF est déjà compressé. Nous avons passé quatre tours sur le
canal montant ; c'est le descendant qui contraint.

**Conséquence produit — déjà tenue par construction.** Un tirage de 5 000 lignes
n'est pas praticable depuis un guichet étroit, et aucun réglage ne le rendra tel.
L'écran n'en propose pas : le clic porte sur une ligne de **groupe**, donc un
niveau — 228 Ko et 3 s de rendu à 500 élèves, qui est l'usage réel. Le plafond de
5 000 reste une garde de dernier recours, pas un parcours.
- **Le plafond de taille de corps** — invisible du dépôt back, il vit côté ops.
  L3 enverra un corps réel de 1,62 Mio contre staging. Notre plafond local se
  posera **en dessous** du sien.
- **`Expect: 100-continue`** — rétrogradé en bonus des deux côtés. Le
  `HandlerInterceptor` épargne la désérialisation, **pas le téléversement** :
  quand il refuse, les octets sont partis. Ce qui borne réellement le coût, c'est
  la compression.

---

## 7. Invariants à ne jamais casser

1. **Une seule règle de statut** dans le module — celle de
   `LocalFeeChargeAggregate`. Les trois écrans ne peuvent pas diverger sur un
   élève.
2. **Le `paid_pending` est toujours composé.** Un encaissement hors ligne doit
   déplacer le taux immédiatement — c'est l'argument qui a tué `/ledger`.
3. **Jamais deux devises additionnées.** `MoneyBag` partout, y compris dans le
   corps de la requête.
4. **Le taux porte sur les concernés**, jamais sur les inscrits : un élève sans
   créance de ce frais n'est pas un mauvais payeur, il n'est pas facturé.
5. **Le reste est planché à zéro créance par créance**, jamais globalement.
   `Σ max(0, eᵢ − pᵢ) ≠ max(0, Σeᵢ − Σpᵢ)` — un élève qui paie 400 sur une
   scolarité de 300 et rien sur 100 de fournitures le prouve. Le back refusera
   la ligne qui viole `max(0, due − paid) ≤ outstanding ≤ due`.
6. **Les sacs partent non élagués.** L'élagage est un geste d'affichage
   (`withoutZeros`), jamais de sérialisation.
7. **Le plafond de 5 000 lignes se vérifie localement avant l'envoi.** On connaît
   le compte sans faire le voyage ; le `400` serveur est un dernier recours, pas
   le chemin normal.
8. **La sélection de frais n'est jamais vide.** Décocher le dernier est ignoré,
   sans erreur — sinon aucun indicateur n'est calculable.
9. **La simulation n'écrit rien.** Aucun bouton « Appliquer », aucune action de
   masse : un renvoi passe par les Inscriptions, dossier par dossier.
10. **Zéro log d'argent** (checklist money-grade).

---

## 8. Pièges identifiés avant d'écrire

### Sur le document

- ⚠️ **`Printing.layoutPdf`, jamais `sharePdf`** — le plugin de partage écrit le
  fichier en clair dans le cache de l'app et ne l'efface jamais ; ces pages
  portent des noms d'élèves.
- ⚠️ **Garder les octets avant de les rendre** — un portail captif qui répond
  `200` en HTML arriverait au visualiseur comme un document vide.
- ⚠️ **Le 429 n'est pas une panne, c'est une file.** Le bouton reste désarmé le
  temps annoncé plutôt que d'inviter à rejouer ce qui vient d'être refusé. Le
  repli en l'absence de `Retry-After` vit dans `AppConstants`, **pas** dans les
  jetons de motion : c'est le protocole qui la dicte, et rangée avec les
  animations elle serait réglée pour la fluidité et divergerait en silence.
- ⚠️ **`REPORT_LINE_CAP` a maintenant trois appelants.** Le décodeur de
  `finance_till_report_button.dart` doit **monter d'un cran** — son propre
  commentaire l'annonçait.
- ⚠️ **La pièce n'est pas archivée.** Elle est numérotée et scellée comme `RP` et
  `RI`, mais rien n'est stocké côté serveur : pas de cache, pas de delta, pas de
  restitution par identifiant. **Ne pas réutiliser `EditiqueDocument`** — une
  entité dédiée, sur le modèle de `TillReport`.

### Sur l'écran

- ⚠️ **`AppPageBackground` borne le contenu à 1180 px** — tout seuil responsive
  au-dessus est inatteignable, quelle que soit la taille de l'écran.
- ⚠️ **Le roster peut ne pas être descendu**, et `classroom.read` peut manquer.
  Le dépliage doit alors **le dire** — `feeControlEmptyRosterMissing` et
  `feeControlClassroomWithheld` existent déjà.
- ⚠️ **Un élève peut porter la sélection sur deux niveaux** (changement en cours
  d'année). Il apparaît dans les deux groupes et compte deux fois. C'est voulu —
  c'est ce qui maintient « le total est la somme des groupes » — mais son
  **statut sur la sélection** doit alors se calculer par (élève, niveau), pas
  par élève, sous peine d'un total qui cesse d'être la somme de ses lignes.
- ⚠️ **Le curseur de seuil doit se sentir immédiat** : recalcul mémoïsé,
  synchrone, sans jamais rejouer un chargement.

### Sur le renommage (REC-0)

- ⚠️ **Un sous-menu déclaré au registre DOIT avoir son `case`** dans le `switch`
  de la coquille, sinon il tombe dans « page en cours de développement » sans la
  moindre erreur.
- ⚠️ **`accueil_page_test.dart` code en dur** le nombre de cartes et de lignes ;
  **`shell_sub_menu_coverage_test.dart` code en dur** la table des identifiants.
- ⚠️ **Chercher tous les `goNamed` / `AppRoutesNames.feeControl*`** avant de
  renommer : une redirection vers un accueil déjà sous la pile ne fait **rien**
  (la clé de page est le chemin matché, sans query params).

### Sur les tests

- ⚠️ **Un bloc né dans `setUp` ne dénoue jamais ses Futures sous `pump()`** →
  `runAsync`. Et un test vert en isolé peut rougir dans la suite complète.
- ⚠️ **Une fixture construite en Dart n'exerce jamais `fromJson`** — le modèle de
  requête doit être testé sur du JSON réel.
- ⚠️ **`null` en `whereArgs` lève** (sqflite) : le SQL multi-frais ne doit pas
  lier de `null`.

### Sur la localisation

- ⚠️ **`flutter gen-l10n` puis `dart format lib/l10n/`**, sans quoi trois clés
  produisent 1500 lignes de churn.

---

## 9. Architecture

```
lib/features/recouvrement/                    ← git mv depuis fee_control/
├── data/
│   ├── datasources/  relance_list_remote_data_source.dart      (@RestApi)
│   ├── models/       relance_list_request_model.dart           (+ .g.dart)
│   └── repositories/ relance_list_repository_impl.dart
├── domain/
│   ├── entities/     relance_list.dart          (bytes + fileName, cf. TillReport)
│   │                 recovery_scope.dart        (kind + id)
│   │                 recovery_criterion.dart
│   ├── repositories/ relance_list_repository.dart
│   └── usecases/     emit_relance_list_usecase.dart
└── presentation/
    ├── bloc/         recouvrement_dashboard_bloc.dart      (périmètre + registre)
    │                 recouvrement_simulation_cubit.dart    (pur, synchrone)
    │                 relance_list_cubit.dart               (3 états : prêt/en cours/refusé)
    │                 recouvrement_projectors/…             (purs, testables seuls)
    ├── contracts/    (repris de fee_control)
    ├── helpers/      (repris)
    ├── pages/        recouvrement_dashboard_page.dart
    │                 recouvrement_control_page.dart        (ex fee_control_page)
    │                 recouvrement_feature_scope.dart
    └── widgets/      dashboard/  perimetre · chiffres_cles · taux_par_frais
                                  classement · simulation · lectures
                      relance/    relance_list_button · relance_list_errors

lib/features/finance/…                        ← SUPPRESSIONS (REC-8)
  presentation/widgets/finance_recovery_tab.dart
  presentation/widgets/finance_dashboard_tabs.dart
  presentation/bloc/finance/finance_recovery_*.dart
  domain/entities/finance_recovery/                (collectionRate migre)
  domain/usecases/get_finance_recovery_usecase.dart
```

**Extension de la couche `finance/offline`** (elle reste chez Finance : c'est le
grand-livre, pas le module) :

```
domain/entities/  local_recovery_line.dart
domain/usecases/  get_recovery_positions_use_case.dart
data/local/dao/   finance_ledger_read_dao.dart      ← + getRecoveryPositions()
```

---

## 10. Les lots — **tous livrés le 2026-09-10**

> `REC-0` → `REC-9` commités sur `feat/finance-encaissements-dashboard`.
> Revue adversariale passée : **5 défauts trouvés et corrigés** (§10 bis).


> `REC-0` est isolé et mécanique : il se commite **seul**, avant tout le reste.
> `REC-1` à `REC-4` livrent le tableau de bord. `REC-5`/`REC-6` livrent le
> document. `REC-8` nettoie. Chaque lot laisse `flutter analyze` propre et
> `flutter test` vert.

| Lot | Contenu | Fichiers |
|---|---|---|
| **REC-0** | **Le renommage, seul.** `git mv fee_control → recouvrement`, les trois `MenuConstants`, les deux routes, les libellés `.arb` FR + EN, `gen-l10n` + `dart format`. Les deux tests qui codent en dur les identifiants suivent. **Aucune modification de comportement.** | `menu_constants` · `app_routes_names` · `app_router` · `home_page` · `menu_factory` · `accueil_modules_factory` · `module_access_registry` · `injection` · l10n · 2 tests |
| **REC-1** | **La lecture multi-frais.** `LocalRecoveryLine` + `RecoveryChargePosition`, le SQL `IN (…)` groupé par `(élève, niveau, frais, devise)`, l'usecase. Le statut reste emprunté à `LocalFeeChargeAggregate`. | `finance/offline/**` · tests DAO sur base mémoire |
| **REC-2** | **Périmètre et chiffres clés.** Sélecteur de frais (jamais vide) + périmètre, ligne de contexte avec le taux du jour ; les quatre chiffres — attendu, perçu, n'ont rien payé, paiement partiel — en `MoneyBag`. Invariant testé : `rien + partiel + soldé == total`. | `bloc` · `widgets/dashboard/perimetre` · `chiffres_cles` |
| **REC-3** | **Taux par frais.** Un groupe par devise, jamais un classement unique. Barre = poids du frais dans l'attendu de sa devise, remplissage = part perçue. `finPct(x, 0) == 0` — jamais NaN, jamais 100 %. La règle `collectionRate` migre ici depuis `FinanceKpis`. | `projectors` · `widgets/dashboard/taux_par_frais` |
| **REC-4** | **Le classement**, porté du FCD sur une sélection : niveaux triés du plus en retard au plus en règle, dépliage en classes, passage vers l'écran nominatif. Comparaison des taux **en produits croisés d'entiers**, jamais sur un pourcentage borné pour l'affichage. | `widgets/dashboard/classement` · projecteurs repris |
| **REC-5** | **La simulation.** Critère · plancher · seuil ; quatre tuiles ; tableau trié par effectif conservé croissant. Recalcul **synchrone**, sans chargement. Aucune écriture, aucun bouton « Appliquer ». Cubit pur, testé sans widget. | `recouvrement_simulation_cubit` · `widgets/dashboard/simulation` |
| **REC-6** | **La liste de relance — data.** Modèle de requête (sacs non élagués), gzip du corps, `@RestApi`, `build_runner`, repository, usecase. Les trois `detailCode` décodés. `REPORT_LINE_CAP` **promu au socle** (3ᵉ appelant). Timeouts posés, `sendTimeout` laissé en `TODO` documenté jusqu'à L4. | `data/**` · `app_constants` · `core/error` · tests mapper + repo |
| **REC-7** | **La liste de relance — présentation.** Le clic d'une ligne de simulation ouvre l'**aperçu nominatif** (§7 de la spec) ; l'édition part de là, jamais du clic. Trois états qui survivent au tap : désarmé pendant le rendu, désarmé le temps du `Retry-After` sur 429, octets rendus puis **abandonnés** (le serveur n'archive rien). Garde locale du plafond avant l'envoi. `Printing.layoutPdf`. | `relance_list_cubit` · `widgets/relance/**` · l10n |
| **REC-8** | **Suppression de l'onglet Finances ▸ Recouvrement.** Bloc, entités, usecase, datasource, l10n orphelines, tests. `FinanceStatsDashboardPage` retombe à un onglet et devient la Caisse. | `finance/**` · tests |
| **REC-9** | **Lectures & alertes** (trois `FinInsight` calculées, jamais rédigées en dur) puis **revue adversariale** money-grade : états partagés (règle #10), a11y, `buildWhen`, `mounted` après `await`, `FeatureScope` qui ferme son bloc. | `widgets/dashboard/lectures` · revue |

---

## 11. Écarts assumés avec la spec de maquette

| La spec dit | Ce qu'on fait | Pourquoi |
|---|---|---|
| Classement par **classe** | par **niveau**, dépliable | 5 % / 13 % / 0 % de couverture d'affectation sur l'année en cours |
| `FinTabs` interne monté par une coque | **deux sous-menus** | deux niveaux de bascule pour une navigation, et la barre latérale décroche |
| `RecListeAppel` + `window.print()` | **PDF serveur** numéroté et scellé | une pièce qui se signe ne se fabrique pas sur la tablette |
| Tolérance d'arrondi de 0,5 sur le statut | comparaisons **exactes** | des centimes entiers de bout en bout |
| `FIN_POSTE[k].dev` — une devise par frais | la devise se lit **sur la créance** | la grille porte la devise par tarif : un poste peut être en USD au primaire et en CDF au secondaire |
| — | l'**évolution mensuelle** n'est pas reprise | la spec la range elle-même hors périmètre |

---

## 10 bis. Ce que la revue adversariale a trouvé

Cinq **silences** — des cas où l'écran ne dit rien tout en se trompant. Aucun ne
se voyait à l'usage nominal.

1. **Le taux arrivé après les lignes.** Les deux cubits chargent en parallèle ;
   si la série de taux arrivait après le registre, la simulation gardait un
   cours nul et le critère du plancher ne visait **personne**, sans un mot, et
   seulement en sélection mixte. Le taux est désormais reposé quand il bouge.
2. **Le groupe sans niveau était éditable comme `UNASSIGNED`.** Or cette valeur
   du contrat désigne les élèves **sans classe**, pas les créances sans
   **niveau** : le serveur aurait résolu un titre pour une population qui n'est
   pas celle de la feuille. La ligne n'est plus cliquable là — comme le
   dépliage la refusait déjà. **À rouvrir avec le back** si le besoin apparaît.
3. **Le champ du plancher gardait son texte** quand le critère l'oubliait : y
   revenir montrait un montant que le calcul ne connaissait plus.
4. **Une lecture sans personne vidait l'écran en silence**, sous un périmètre
   qu'on venait de choisir. Distinct du vide structurel, qui remplace tout.
5. **Une sélection pouvait survivre à la liste dont elle venait** — année neuve,
   grille refaite : l'écran interrogeait un frais que l'année ne facture plus.

---

## 12. Ce que ce plan attend encore

- ✅ **L4 du back — rendu le 2026-09-10.** Les deux délais sont posés (§6).
- **L3 du back** — le verdict de l'épreuve d'un corps réel contre staging
  (plafond de taille côté ops) et celui de `Expect: 100-continue` avec Dio.
  Ni l'un ni l'autre ne change le code : le premier fixerait notre plafond
  local, le second ne ferait qu'épargner un téléversement déjà borné à 257 Ko.
- **Le groupe sans niveau n'est pas éditable** (§10 bis, n° 2) : `scope.kind`
  n'a pas de valeur pour lui. À rouvrir si le besoin apparaît.
