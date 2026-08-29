import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_line.dart';
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
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: resolved
              ? AppColors.surfaceAlt
              : AppColors.boutiqueUnresolvedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: resolved
                ? AppColors.border
                : AppColors.boutiqueUnresolvedBorder,
          ),
        ),
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
                // Le sélecteur de niveau n'existe QUE sur une ligne walk-in
                // d'un article à grille : dès qu'un bénéficiaire est posé, le
                // niveau vient de l'élève, et l'offrir ferait croire qu'on peut
                // en choisir un autre.
                if (line.article.requiresLevel && line.beneficiary == null)
                  _LevelSelector(
                    line: line,
                    levels: levels,
                    onChanged: onLevelChanged,
                  ),
                _Stepper(quantity: line.quantity, onChanged: onQuantityChanged),
              ],
            ),
          ],
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.article.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        Text(
          // Un tiret, JAMAIS « 0.00 $ » : un zéro s'additionne à l'œil et fait
          // croire que la ligne est gratuite.
          total == null
              ? '—'
              : BoutiqueMoneyFormat.exact(total, line.article.currency),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: line.isResolved
                ? AppColors.bleuProfond
                : AppColors.boutiqueUnresolvedText,
          ),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: EdgeInsets.zero,
          color: AppColors.textMuted,
        ),
      ],
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
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppColors.border),
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
            style: const TextStyle(fontWeight: FontWeight.w600),
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
    child: Opacity(
      opacity: onPressed == null ? 0.35 : 1,
      child: SizedBox(width: 30, height: 28, child: Icon(icon, size: 16)),
    ),
  );
}
