import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_family_style.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un niveau proposable au guichet pour une ligne walk-in.
class BoutiqueLevelOption {
  final String id;
  final String label;

  const BoutiqueLevelOption({required this.id, required this.label});
}

/// Une ligne du panier.
///
/// Chaque ligne porte **son** bénéficiaire, **sa** taille et **sa** quantité :
/// un même panier peut habiller trois enfants de niveaux différents sans qu'on
/// refasse la vente trois fois.
///
/// Une ligne dont le prix n'est pas résolu **se signale elle-même** — et jamais
/// par la couleur seule : elle porte aussi les mots « Prix à résoudre » et
/// « Niveau requis… », parce qu'un daltonien tient une caisse aussi bien qu'un
/// autre.
class BoutiqueCartLineTile extends StatelessWidget {
  final CartLine line;
  final List<BoutiqueLevelOption> levels;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String?> onLevelChanged;
  final VoidCallback onPickBeneficiary;
  final VoidCallback onClearBeneficiary;

  const BoutiqueCartLineTile({
    super.key,
    required this.line,
    required this.levels,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onLevelChanged,
    required this.onPickBeneficiary,
    required this.onClearBeneficiary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resolved = line.isResolved;

    return Semantics(
      // La mention arrive AVANT le libellé : un lecteur d'écran doit annoncer
      // le problème avant l'article, pas après l'avoir décrit.
      label: resolved
          ? null
          : '${l10n.boutiqueLevelRequired} ${line.article.label}',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Fond BLANC, et non gris : une carte posée se lit comme un objet
          // qu'on manipule ; un gris de fond la faisait passer pour une zone
          // désactivée. C'est le liseré de gauche qui porte l'état.
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: resolved
                ? AppColors.border
                : AppColors.boutiqueUnresolvedBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.bleuProfond.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Le liseré d'état : accent de famille quand la ligne est prête,
              // couleur d'alerte quand le prix ne se résout pas. Jamais SEUL —
              // les mots « Prix à résoudre » restent dans la ligne, parce qu'un
              // daltonien tient une caisse aussi bien qu'un autre.
              Container(
                width: 4,
                color: resolved
                    ? BoutiqueFamilyStyle.accentOf(line.article.family)
                    : AppColors.boutiqueUnresolvedText,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopRow(line: line, onRemove: onRemove),
                      const SizedBox(height: AppDimensions.spacingS),
                      Wrap(
                        spacing: AppDimensions.spacingS,
                        runSpacing: AppDimensions.spacingS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _BeneficiaryChip(
                            line: line,
                            onPick: onPickBeneficiary,
                            onClear: onClearBeneficiary,
                          ),
                          // Le sélecteur de niveau n'existe QUE sur une ligne
                          // walk-in d'un article à grille : dès qu'un
                          // bénéficiaire est posé, le niveau vient de l'élève,
                          // et l'offrir ferait croire qu'on peut en choisir un
                          // autre.
                          if (line.article.requiresLevel &&
                              line.beneficiary == null)
                            _LevelSelector(
                              line: line,
                              levels: levels,
                              onChanged: onLevelChanged,
                            ),
                          _Stepper(
                            quantity: line.quantity,
                            onChanged: onQuantityChanged,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String metaOf(CartLine line, AppLocalizations l10n) {
    final unit = line.unitPriceInCents;
    if (unit == null) return l10n.boutiquePriceUnresolved;
    return l10n.boutiqueLineMeta(
      BoutiqueMoneyFormat.compact(unit, line.article.currency),
      line.quantity,
    );
  }
}

class _TopRow extends StatelessWidget {
  final CartLine line;
  final VoidCallback onRemove;

  const _TopRow({required this.line, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final total = line.lineTotalInCents;

    final accent = BoutiqueFamilyStyle.accentOf(line.article.family);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Le médaillon de famille, comme sur la vignette du catalogue : c'est
        // ce qui permet de retrouver un article dans le panier sans le lire.
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            BoutiqueFamilyStyle.iconOf(line.article.family),
            size: 18,
            color: accent,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.article.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.bleuProfond,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                BoutiqueCartLineTile.metaOf(line, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: line.isResolved
                      ? AppColors.textMuted
                      : AppColors.boutiqueUnresolvedText,
                  fontWeight: line.isResolved
                      ? FontWeight.w400
                      : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              // Un tiret, JAMAIS « 0.00 $ » : un zéro s'additionne à l'œil et
              // fait croire que la ligne est gratuite.
              total == null
                  ? '—'
                  : BoutiqueMoneyFormat.exact(total, line.article.currency),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                // Chiffres à chasse fixe : des totaux de ligne qui dansent en
                // largeur ne s'additionnent plus à l'œil.
                fontFeatures: const [FontFeature.tabularFigures()],
                color: line.isResolved
                    ? AppColors.bleuProfond
                    : AppColors.boutiqueUnresolvedText,
              ),
            ),
            const SizedBox(height: 2),
            // La corbeille sous le prix, et non à côté : au bout d'une ligne,
            // elle jouxtait le pas « + » du compteur, et un doigt qui vise vite
            // supprimait au lieu d'ajouter.
            _RemoveButton(onRemove: onRemove),
          ],
        ),
      ],
    );
  }
}

/// Le retrait d'une ligne — **immédiat, sans confirmation** : le panier n'est
/// pas encore un engagement, et l'ajout se refait d'un geste.
class _RemoveButton extends StatelessWidget {
  final VoidCallback onRemove;

  const _RemoveButton({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final tooltip = MaterialLocalizations.of(context).deleteButtonTooltip;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 17,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _BeneficiaryChip extends StatelessWidget {
  final CartLine line;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _BeneficiaryChip({
    required this.line,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final beneficiary = line.beneficiary;

    if (beneficiary == null) {
      // Puce pointillée : elle se lit « à remplir », là où une puce pleine se
      // lirait « déjà rempli ».
      return ActionChip(
        avatar: const Icon(Icons.person_add_alt, size: 14),
        label: Text(l10n.boutiqueBeneficiaryPlaceholder),
        onPressed: onPick,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.border),
        ),
      );
    }

    return InputChip(
      avatar: CircleAvatar(
        radius: 11,
        backgroundColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
        child: Text(
          _initialsOf(beneficiary.fullName),
          style: const TextStyle(fontSize: 9, color: AppColors.bleuArdoise),
        ),
      ),
      label: Text(
        beneficiary.classroomLabel == null
            ? beneficiary.fullName
            : '${beneficiary.fullName} · ${beneficiary.classroomLabel}',
      ),
      onDeleted: onClear,
      deleteIcon: const Icon(Icons.close, size: 14),
    );
  }

  static String _initialsOf(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _LevelSelector extends StatelessWidget {
  final CartLine line;
  final List<BoutiqueLevelOption> levels;
  final ValueChanged<String?> onChanged;

  const _LevelSelector({
    required this.line,
    required this.levels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unresolved = line.declaredLevelId == null;

    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: line.declaredLevelId,
        // Liste FERMÉE : le walk-in choisit un niveau, jamais un prix
        // (invariant I-2). Il n'y a aucun champ de montant sur cette ligne.
        items: [
          for (final level in levels)
            DropdownMenuItem(value: level.id, child: Text(level.label)),
        ],
        hint: Text(
          l10n.boutiqueLevelRequired,
          style: TextStyle(
            color: unresolved
                ? AppColors.boutiqueUnresolvedText
                : AppColors.textMuted,
            fontWeight: unresolved ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onChanged: onChanged,
        isDense: true,
      ),
    );
  }
}

/// Le compteur. Le « − » est **désactivé à 1** : descendre sous un exemplaire
/// se fait par la corbeille, jamais par le pas — un compteur qui supprime
/// surprend, et l'action n'est pas réversible d'un geste.
class _Stepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _Stepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    // Terre-cuite, comme le pas de la vignette et le bouton d'encaissement :
    // c'est la couleur de ce qui va être payé, et le guichet reconnaît le même
    // compteur d'un écran à l'autre.
    decoration: BoxDecoration(
      color: AppColors.terreCuite.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.terreCuite.withValues(alpha: 0.30)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.terreCuite,
            ),
          ),
        ),
        _StepButton(icon: Icons.add, onPressed: () => onChanged(quantity + 1)),
      ],
    ),
  );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(999),
    child: SizedBox(
      width: 32,
      height: 30,
      child: Icon(
        icon,
        size: 16,
        // Le « − » à 1 est INACTIF, pas invisible : il reste à sa place, et le
        // retrait se fait par la corbeille — un compteur qui supprime surprend.
        color: onPressed == null
            ? AppColors.terreCuite.withValues(alpha: 0.30)
            : AppColors.terreCuite,
      ),
    ),
  );
}
