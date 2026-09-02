# Nommer les sections de frais — « une nature, un titre, par école »

> **Contrat back :** `fee_code_sections` (V115), `FeeCodeDto`,
> `FeeCodeSectionsRequest`, `GET`/`POST /api/v1/finance/fee-codes`.
>
> ✅ **Lu dans le code serveur**, pas deviné : `FeeCodeSectionService`,
> `FeeCodeController`, `V115.0.0__create_fee_code_sections.sql`.
>
> 🔴 **Suite de `NOMMAGE_CHARGES_PLAN.md`**, mais d'un cran au-dessus : NC nomme
> la *ligne* (« libellé (code du tarif) »), SF nomme la *section* qui les
> regroupe. Les deux se complètent — le titre au-dessus, la tranche en dessous.

**Décisions actées.**

| | |
|---|---|
| `code` reste la clé | Identique d'une école à l'autre, seul lui part sur le fil |
| Le titre, l'ordre et la visibilité | **appartiennent à l'école** (V115) |
| `FeeCodeOrdering.preferred` | **Devient un repli**, plus une décision — cf. SF-1 |
| Renommer | Libre et rétroactif : le titre n'est jamais recopié sur une créance |
| Masquer ≠ supprimer | Quitte le sélecteur, jamais les statistiques |
| Le libellé d'un tarif | Reste un **instantané** : renommer la section ne réécrit pas les tarifs posés |

---

## 1. Ce que le serveur fait vraiment

`GET /api/v1/finance/fee-codes` n'est plus un référentiel figé identique pour
tous. Il sert quatre champs, dont trois sont ceux de l'établissement :

- `code` — la clé. `TUITION`. Un code inconnu rend 422.
- `label` — le titre que la direction a écrit, ou la proposition française du
  serveur tant qu'elle ne l'a pas réécrite.
- `active` — la section est-elle encore proposée à la saisie ? La liste par
  défaut ne sert pas les masquées ; `?includeHidden=true` les rend.
- `sortOrder` — le rang, **déjà appliqué à l'ordre de la liste**.

`POST /api/v1/finance/fee-codes` écrit un **lot** : les sections absentes ne sont
pas touchées, et chaque champ est indépendamment facultatif. Le serveur ne stocke
que les **surcharges** — une école qui n'a rien renommé n'a aucune ligne en base.

Trois refus nommés en 422 : `UNKNOWN_FEE_CODE`, `DUPLICATE_FEE_CODE`,
`DUPLICATE_FEE_SECTION_LABEL`.

## 2. Ce que le front faisait — et qui devient faux

`fee_code_ordering.dart` compensait l'absence de rang serveur par une constante
locale de huit natures, et le disait lui-même :

> *Idéalement servi par le serveur (`displayOrder`) : le jour où il l'est, cette
> liste disparaît sans que rien d'autre ne bouge.*

Ce jour est arrivé. Mais la constante ne **disparaît pas** : elle devient un
repli. Une école qui n'a rien classé reçoit les vingt-trois natures de
l'énumération à plat, et les trois qu'un directeur saisit réellement s'y
noieraient. La constante ne s'applique donc que tant que l'école n'a rien décidé.

**Comment le savoir sans champ supplémentaire** — `FeeCodeOrdering.isConfigured` :
une école qui n'a rien paramétré reçoit les rangs `0, 1, … n-1`, dans cet ordre
et sans trou. Un rang qui ne vaut pas sa position signifie donc qu'une décision a
été prise : une section hissée en tête, ou une autre masquée qui laisse un trou.

## 3. Les lots

| Lot | Ce qu'il fait | État |
|---|---|---|
| **SF-0** | `FeeCodeOption`/`FeeCodeModel` lisent `active` et `sortOrder`, **tolérés absents** (serveur antérieur à V115 → tout visible, rang = position servie) | ✅ |
| **SF-1** | L'ordre de l'école prime ; `preferred` devient un repli piloté par `isConfigured` | ✅ |
| **SF-2** | `GET ?includeHidden` + `POST` au data source ; `saveFeeCodeSections` au repository, **avec purge du cache de session** | ✅ |
| **SF-3** | `FeeSectionsSettingsCard` — renommer, masquer, reclasser, en tête de l'onglet Frais | ✅ |
| **SF-4** | `SettingsTariffsPanel` groupe les tarifs sous le titre de leur section | ✅ |

### Trois pièges tenus, et pourquoi

1. **Le cache de session est périmé par construction après une écriture.**
   `ProvisioningRepositoryImpl` garde les codes en mémoire pour la durée de la
   session. Le laisser en place après un renommage ferait afficher l'ancien titre
   au formulaire de tarif jusqu'à la déconnexion. `saveFeeCodeSections` le purge,
   et `includeHidden: true` ne passe **jamais** par lui — c'est la liste de
   l'écran qui vient d'écrire.

2. **On n'envoie que ce qui a changé.** Envoyer les vingt-trois sections à chaque
   enregistrement ferait naître vingt-trois surcharges là où la direction n'a
   renommé qu'un titre, et retirerait au serveur la propriété qui lui permet
   d'ajouter une 24ᵉ nature sans rattraper toutes les écoles.

3. **Le panneau des tarifs charge le catalogue COMPLET.** Un tarif peut porter
   une nature depuis masquée ; sans elle, sa ligne retomberait sur son code brut
   (« BOARDING ») au lieu du titre écrit par la direction. Le sélecteur, lui, ne
   reçoit que les sections `active` — proposer une nature qu'on vient de masquer
   défairait le geste sous les yeux de l'utilisateur.

## 4. Hors périmètre

- **Le code du tarif** (« T1 », « T2 ») dans la ligne : c'est `NOMMAGE_CHARGES_PLAN.md`.
- **Les statistiques** (`/finance/recovery`, `/finance/till`) : le serveur y sert
  déjà le titre de l'école depuis V115, sans changement de contrat. Rien à faire
  côté client.
- **Les montants indicatifs** (`kIndicativeAmountsInCents`) : toujours locaux,
  toujours à reverser au serveur s'il vient à les porter.
