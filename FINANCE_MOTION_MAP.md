# Finance Motion Map

Ce document couvre desormais la convention Motion transverse demarree en Finance,
et etendue aux surfaces non-finance visibles (Home shell + Enrollment).

## Standard transverse AppMotion

Source unique: `lib/core/theme/app_motion.dart`

- `AppMotion.micro` -> `130ms`
- `AppMotion.fast` -> `160ms`
- `AppMotion.medium` -> `180ms`
- `AppMotion.standard` -> `220ms`
- `AppMotion.entrance` -> `260ms`
- `AppMotion.layout` -> `280ms`
- `AppMotion.inCurve` -> `Curves.easeInCubic`
- `AppMotion.outCurve` -> `Curves.easeOutCubic`
- `AppMotion.gentleOut` -> `Curves.easeOut`

Compatibilite: `FinanceMotion` delegue vers `AppMotion` pour ne pas casser
les usages existants du module Finance.

## Scope Point 2 (non-finance prioritaire)

### Lot 1 - Home shell (visible, faible risque)

| Widget | Type d'animation | Token(s) |
|---|---|---|
| `Sidebar` | Expansion/reduction layout | `layout` + `outCurve` |
| `SidebarHeader` | Switch expanded/collapsed | `standard` + `outCurve`/`inCurve` |
| `SidebarMenuItem` | Hover/selection item | `fast` + `outCurve` |
| `SidebarMenuItem` | Expansion sous-menus | `medium` + `gentleOut` |
| `SidebarFooter` | Transition compacte/etendue | `standard` + `outCurve` |

### Lot 2 - Enrollment micro-feedback

| Widget | Type d'animation | Token(s) |
|---|---|---|
| `EnrollmentDataTable` | Hover row + action eye | `micro`, `fast` |
| `EnrollmentDataTable` | Icones tri (switch) | `standard` + `outCurve`/`inCurve` |
| `EnrollmentDetailBackButton` | Hover bouton retour | `fast` + `outCurve` |
| `SearchFormStatusDropdown` | Highlight item / check opacity | `fast` + `outCurve` |

### Lot 3 - Enrollment polish etats

| Widget | Type d'animation | Token(s) |
|---|---|---|
| `GuardianInfoStepBody` | Barre de chargement (switch) | `medium` + `outCurve`/`inCurve` |
| `GuardianFieldsGrid` | Selection chips relation | `fast` + `outCurve` |
| `WizardBreadcrumb` | Opacite steps futures | `fast` |
| `FormFieldLabel` | Affichage tooltip d'aide | `tooltipShowDuration` |

## Regles d'usage (transverses)

1. **Entree de page/detail**: `AppMotion.entrance`.
2. **Switch d'etat (loading/error/empty/success)**: `AppMotion.standard`.
3. **Micro-feedback (hover/highlight/presse)**: `AppMotion.micro` ou `AppMotion.fast`.
4. **Transition douce de groupe**: `AppMotion.medium` + `AppMotion.gentleOut`.
5. **Cohesion courbes**: preferer `switchInCurve: outCurve` et `switchOutCurve: inCurve`.
6. **Interdit**: introduire une `Duration(...)` UI hardcodee dans le scope cible.

## Checklist de validation par lot

- [ ] Aucune nouvelle `Duration(...)` hardcodee sur les fichiers du lot
- [ ] Mapping widget -> token renseigne dans ce document
- [ ] Courbes d'entree/sortie coherentes sur les switches d'etat
- [ ] Pas de regression UX visible (hover, switch, transitions shell)

## Rappel du mapping Finance existant

| Composant | Type d'animation | Token(s) |
|---|---|---|
| `FacturationPaymentDetailPage` | Entree page/sections | `entrance` + `outCurve` |
| `FacturationChargeDetailPage` | Entree page/sections | `entrance` + `outCurve` |
| `FacturationPage` | Transition contenu principal | `standard` |
| `FacturationDetailPaymentsSection` | Switch loading/empty/error/table | `standard` + `outCurve`/`inCurve` |
| `FacturationDetailChargesSection` | Switch loading/empty/error/table | `standard` + `outCurve`/`inCurve` |
| `FacturationPaymentAllocationsSection` | Switch etats allocations | `standard` + `outCurve`/`inCurve` |
| `FacturationChargeAllocationsSection` | Switch etats allocations | `standard` + `outCurve`/`inCurve` |
| `FacturationCreatePaymentAllocationEditor` | Switch/resize liste allocations | `standard` + `outCurve`/`inCurve` |
| `FacturationCreatePaymentAllocationItem` | Reveal champs/snapshots | `standard` + `medium` |
| `FacturationCreatePaymentSubmitSection` | Message d'aide + CTA | `medium` + `gentleOut` |
| `FinanceStateCard` | Feedback visuel d'etat | `medium` + `outCurve` |
| `FacturationDataTable` | Hover/sort interactions | `micro`, `fast`, `standard` |