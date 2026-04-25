# Finance Motion Map

Ce document fixe la convention d'animations du module Finance.

## Tokens de reference

Source unique: `lib/features/finance/presentation/widgets/common/finance_motion.dart`

- `FinanceMotion.micro` -> `130ms`
- `FinanceMotion.fast` -> `160ms`
- `FinanceMotion.medium` -> `180ms`
- `FinanceMotion.standard` -> `220ms`
- `FinanceMotion.entrance` -> `260ms`
- `FinanceMotion.inCurve` -> `Curves.easeInCubic`
- `FinanceMotion.outCurve` -> `Curves.easeOutCubic`
- `FinanceMotion.gentleOut` -> `Curves.easeOut`

## Mapping composant -> motion

| Composant | Type d'animation | Token(s) |
|---|---|---|
| `FacturationPaymentDetailPage` | Entrée page/sections | `entrance` + `outCurve` |
| `FacturationChargeDetailPage` | Entrée page/sections | `entrance` + `outCurve` |
| `FacturationPage` | Transition contenu principal | `standard` |
| `FacturationDetailPaymentsSection` | Switch loading/empty/error/table | `standard` + `outCurve`/`inCurve` |
| `FacturationDetailChargesSection` | Switch loading/empty/error/table | `standard` + `outCurve`/`inCurve` |
| `FacturationPaymentAllocationsSection` | Switch états allocations | `standard` + `outCurve`/`inCurve` |
| `FacturationChargeAllocationsSection` | Switch états allocations | `standard` + `outCurve`/`inCurve` |
| `FacturationCreatePaymentAllocationEditor` | Switch/resize liste allocations | `standard` + `outCurve`/`inCurve` |
| `FacturationCreatePaymentAllocationItem` | Reveal champs/snapshots | `standard` + `medium` |
| `FacturationCreatePaymentSubmitSection` | Message d'aide + CTA | `medium` + `gentleOut` |
| `FinanceStateCard` | Feedback visuel d'etat | `medium` + `outCurve` |
| `FacturationDataTable` | Hover/sort interactions | `micro`, `fast`, `standard` |

## Regles d'usage

1. **Entrée de page/detail**: toujours `FinanceMotion.entrance`.
2. **Switch d'etat (loading/error/empty/success)**: toujours `FinanceMotion.standard`.
3. **Micro-feedback (hover, highlight, presse visuelle)**: `micro` ou `fast`.
4. **CTA et transitions douces**: `medium` + `gentleOut`.
5. **Interdit**: introduire une `Duration(...)` hardcodee dans `lib/features/finance/presentation/`.

## Checklist review PR (Finance UI)

- [ ] Aucune nouvelle duree hardcodee
- [ ] Nouvelles animations referencees via `FinanceMotion`
- [ ] Courbes coherentes (`outCurve` pour entree, `inCurve` pour sortie)
- [ ] Pas de rupture UX entre pages Finance
