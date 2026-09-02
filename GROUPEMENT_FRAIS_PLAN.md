# Grouper les frais de l'élève par nature — « une nature, une jauge, ses tranches dessous »

> **Périmètre :** la section « Frais de l'élève » du **détail Facturation**
> (`facturation_detail_charges_section.dart`). Rien d'autre ne change de forme.
>
> ✅ **Lu dans le code**, pas deviné : `finance_ledger_read_dao.dart`,
> `fee_control_fee_options.dart`, `student_charge_money.dart`,
> `provisioning_repository_impl.dart`, `SECTIONS_FRAIS_PLAN.md`.
>
> 🔴 **Suite de deux plans**, à un cran encore au-dessus :
> `NOMMAGE_CHARGES_PLAN.md` nomme la *ligne* (« libellé (code du tarif) »),
> `SECTIONS_FRAIS_PLAN.md` nomme la *section* ; celui-ci **replie les lignes
> sous leur section** dans la fiche de l'élève.

**Décisions actées.**

| | |
|---|---|
| Maille du groupe | **`fee_code`**, jamais `fee_tariff_id` — même maille que le Contrôle des frais |
| Un groupe d'**une** tranche | Reste une **ligne nue**, sans chevron : un accordéon qui répète son en-tête est du bruit |
| Titre du groupe | **Titre de l'école si connu, nature localisée sinon** — « connu » = *persisté*, jamais « cache de session chaud » |
| Jauge | **Une par devise.** Une jauge unique sur deux devises n'existe pas, comme le total de [MoneyBag] |
| Statut | **Dérivé du reste COMPOSÉ**, sur le groupe **et** sur la tranche — jamais `charge.status` |
| Ordre | Celui du DAO, **inchangé** — il groupe et date déjà |
| Écrans voisins | Page d'encaissement et étape « Frais » du wizard **restent plates** (hors périmètre, divergence assumée) |

---

## 1. Ce que l'écran fait aujourd'hui

`FacturationDetailChargesSection` rend une liste **plate** de
`FacturationChargeLine`, une par `StudentCharge`. Chaque ligne porte déjà ce
qu'on veut voir en tête de groupe : désignation, badge, jauge `payé/attendu`,
pied « Attendu · Payé · reste ». Le clic ouvre la popin de détail du frais.

Trois acquis rendent le repli peu coûteux :

- **L'ordre est déjà bon.** Le DAO trie
  `fee_code ASC, (due_at IS NULL), due_at, (t.code IS NULL), t.code, id`
  (`finance_ledger_read_dao.dart:71`) : les tranches d'une même nature sont déjà
  **contiguës et dans l'ordre des échéances**. Le groupement est un **pli
  d'affichage**, pas un re-tri — et surtout pas un `ORDER BY` à changer.
- **L'argent est déjà multi-devise.** `MoneyBag` et
  `expectedBag / paidTotalBag / remainingBag` existent, et n'exposent
  **aucun total** — délibérément.
- **La règle de nommage existe**, en un seul endroit (`feeDesignation`).

## 2. Le libellé : ce qui a été arbitré, et pourquoi le mécanisme a changé

L'intention retenue est « **le titre de l'école si présent, la nature sinon** ».
Le mécanisme d'abord envisagé — lire le cache de session de Configuration —
**ne tient pas** :

`loadFeeCodes` n'est appelé que depuis Configuration (le BLoC et deux widgets), et
`ProvisioningRepository` est un lazy singleton. Le cache est donc **froid pour un
caissier**, qui est exactement l'utilisateur de cet écran. « Lire le cache s'il
est chaud » afficherait « Frais scolaires » ou « Minerval » selon qu'on est passé
ou non par Configuration dans la session — sur la même tablette, le même jour, sans
que rien ne l'explique.

**Le titre est donc persisté** (GF-0), et « connu » veut dire *présent en base*.
Le repli devient prévisible : une tablette qui n'a jamais vu le serveur dit
« Minerval », et **ne se contredit jamais**.

### D-9 n'est pas contredit

`CONFIGURATION_PLAN.md` D-9 tranche « catalogue en mémoire de session, rien n'est
persisté », au motif qu'un catalogue vieilli « deviendrait un fichier de
constantes qui se croit frais, et sa divergence n'apparaîtrait qu'en 422, à
l'activation ».

Ce motif porte sur un catalogue qui **alimente une écriture**. Ce qu'on persiste
ici est un **cache d'affichage** :

- il ne sert **qu'à nommer** ; aucune écriture ne lit cette table ;
- le `code` qui part sur le fil vient toujours de la créance, **jamais du cache** ;
- une écriture de nommage reste en ligne, et rend le catalogue à jour.

Un titre périmé affiche donc un ancien nom jusqu'au prochain rafraîchissement.
Un code périmé, lui, n'existe pas — c'est ce que D-9 protégeait.

### Le piège que SF-4 a déjà rencontré

La liste par défaut **ne sert pas les sections masquées**. Une créance posée sur
une nature depuis masquée retomberait sur `localizedFeeLabel` alors que l'école
l'a nommée. Le rafraîchissement passe donc par **`includeHidden: true`** :
masquer dit « ne me la propose plus à la saisie », jamais « ne sais plus la
nommer ». On stocke `active`, on ne s'en sert **pas** pour nommer.

### La surface d'incohérence est étroite par construction

Le titre de l'école n'apparaît que sur les en-têtes **multi-tranches**. Un groupe
d'une seule créance reste nommé par le libellé **du tarif** — un instantané gelé,
conformément à SF (« renommer la section ne réécrit pas les tarifs posés »).

## 3. Ce qui ment déjà, et qu'on corrige au passage

`student_charges.status` est le **miroir serveur**, jamais recalculé après un
encaissement local : rien ne le réécrit dans les DAO. Dans la fenêtre où un
versement n'est pas remonté, la jauge dit 100 % (composée, FRONT §5) et le badge
dit « à régler ». Les compteurs de l'en-tête de section
(`facturation_detail_charges_section.dart:62-68`) comptent eux aussi sur `status`.

Un badge de **groupe** dérivé du miroir amplifierait le défaut. Le statut se
dérive donc de la **nullité**, jamais d'une somme — ce qui le rend au passage
insensible à la devise :

| condition | statut |
|---|---|
| rien payé nulle part (`paidTotalInCents == 0` partout) | **à régler** |
| tout `remainingInCents == 0` | **soldé** |
| sinon | **partiel** |

C'est FRONT §6/§8 appliqué à l'affichage : `status` ne décide jamais.

## 4. La forme

```
  Frais d'examen (OM2)              [Soldé]        ← une seule tranche : ligne nue
  ██████████  Attendu 30 000 FC · Payé 30 000 FC

▸ Minerval · 7 tranches             [Partiel]      ← une nature, plusieurs tranches
  ████░░░░░░  Attendu 350 000 FC · Payé 150 000 FC · 200 000 FC restant
──────── déplié ────────
    Minerval — 1/7 (T1)  [Soldé]    ██████  50 000 · 50 000
    Minerval — 2/7 (T2)  [Partiel]  ███░░░  50 000 · 20 000 · 30 000 restant
```

L'en-tête est la ligne actuelle **sur des totaux** ; les enfants sont la ligne
actuelle, **inchangée**, clic → popin de détail. Le clic de l'en-tête plie/déplie
et **n'ouvre rien** : il n'existe pas de « détail de nature ».

**Multi-devise** : une barre quand `soleEntry != null`, une barre fine par devise
sinon — la dégradation que la pastille de solde de l'AppBar tient déjà.

## 5. Les lots

| Lot | Ce qu'il fait | État |
|---|---|---|
| **GF-0** | `ref_fee_code_sections` (v44) + DAO + rafraîchissement **une fois par session** (lecture traversante, PAS un `PullHandler` — voir ci-dessous) + écriture au passage après un renommage | ✅ |
| **GF-1** | `groupChargesByFeeCode` — fonction pure : clé `fee_code`, ordre du DAO préservé, un `MoneyBag` par groupe, statut dérivé | ✅ |
| **GF-2** | Désignation du groupe : titre local si présent, nature localisée sinon, + « N tranches ». `FeeSectionTitlesCubit` en lecture traversante | ✅ |
| **GF-3** | `FacturationChargeGroupAccordion` — en-tête, corps, `AnimatedSize` + reduced-motion ; un groupe d'une tranche reste une ligne nue. Atomes visuels partagés extraits (`fee_progress_parts.dart`) | ✅ |
| **GF-4** | Statut sur le composé, **groupe ET tranche** (`StudentCharge.composedStatus`) | ✅ |
| **GF-5** | Résumé de section re-formulé — natures · tranches · **reste composé**, FR + EN | ✅ |
| **GF-6** | Tests : groupement pur, désignation, cubit, accordéon, section, migration, DAO, cache | ✅ |

### Trois pièges à tenir

1. **L'état déplié vit AU-DESSUS du `BlocConsumer`**, clé `fee_code`. Cette
   section est relue en **silence** à chaque signal de `LedgerRevalidationCubit`
   et après chaque encaissement. Un état porté dans le `builder` replierait tout
   sous les doigts de l'opérateur, sans qu'il ait rien fait.

2. **Ne jamais sommer deux devises pour produire une jauge.** `MoneyBag` n'a pas
   de total, et ce n'est pas un manque d'API : c'est ce qui rend le geste
   inexprimable plutôt que déconseillé.

3. **Le nombre de tranches est celui de l'ÉLÈVE, pas celui de la grille.** Le
   Contrôle des frais compte des `LocalFeeTariff` (la grille du niveau) ; ici on
   compte des créances. Un élève inscrit en cours d'année, ou porteur d'une
   réduction, n'en porte pas sept. Annoncer le compte de la grille dans sa fiche
   décrirait un autre élève que celui qu'on regarde.

### Ce que la mise en œuvre a appris

- 🔴 **Ce flux ne peut PAS être un `PullHandler`, et l'invariant F-I1a l'a
  démontré.** Première tentative : enregistrer `fee_code_sections` sur le
  `PullCoordinator`. `sync_plan_keys_test.dart` a rougi — *tout handler
  enregistré est couvert par une clé de plan*. Et il avait raison :
  `/finance/fee-codes` n'appartient pas à l'énumération `SyncStream` du serveur,
  donc il n'a **pas** de clé de plan. Sous un plan valide, `PullCoordinator`
  saute tout handler hors plan (`outOfPlan`, `skip = true`) : le catalogue ne
  serait **jamais descendu**, en silence, avec une pastille verte. Lui inventer
  une clé aurait été pire — c'est exactement le défaut que `sync_plan_keys.dart`
  existe à prévenir (« une clé jamais présente au plan »). Et le passer
  `isBaseline` aurait fait d'un cache d'affichage une exception à tous les
  filtres, là où le seul flux socle existe parce que la navigation est briquée
  sans lui.

  **Ce qui remplace :** une lecture **traversante**, une fois par session. Le
  cubit émet le local d'abord — la fiche s'affiche sans rien attendre, hors ligne
  comprise — puis demande le catalogue, et ne ré-émet que s'il a rapporté quelque
  chose. La garde de session vit dans le repository (lazy singleton) et n'est
  armée que par un **succès** : une tablette démarrée hors couverture peut
  retenter à l'écran suivant.

  La leçon générale : **une route REST n'est pas un flux de synchro.** Le
  coordinateur n'est pas un ordonnanceur générique, c'est l'exécutant d'un
  contrat que le serveur énumère.
- **Le résumé de section comptait lui aussi sur le miroir.** Il annonçait « 2 à
  régler » au-dessus de deux lignes que le guichet venait de solder. Corrigé avec
  GF-4 : natures · tranches · **reste composé**.

## 6. Hors périmètre

- **La page d'encaissement** (`facturation_create_payment_charges_section.dart`)
  et **l'étape « Frais » du wizard** : elles montreront la même donnée sous une
  autre forme. Assumé — la saisie coche des tranches, elle ne consulte pas des
  natures.
- **Descendre les sections dans le bundle référentiel** : GF-0 se branche sur la
  route existante, sans aucun changement back. Le jour où le serveur en fait un
  vrai flux de synchro — une entrée dans `SyncStream`, donc une clé de plan —
  ce cache devient un `PullHandler` ordinaire et la lecture traversante tombe.
  C'est la seule voie propre pour le rendre continu ; tant que la route reste du
  REST simple, elle ne peut pas passer par le coordinateur.
- **La popin de détail d'un frais** : inchangée, elle porte une tranche.
