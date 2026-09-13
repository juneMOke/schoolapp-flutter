import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_type.dart';
import 'package:school_app_flutter/features/expense/presentation/helpers/expense_type_visuals.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un type : médaillon à sa teinte douce + nom court. Le nom est répété en
/// toutes lettres — la couleur seule ne distingue pas neuf catégories.
class ExpenseTypeTag extends StatelessWidget {
  /// `null` : type que le socle ne nomme pas (encore) sur ce poste.
  final ExpenseType? type;
  final bool small;

  const ExpenseTypeTag({super.key, required this.type, this.small = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = small
        ? AppDimensions.expenseTypeTagSizeSmall
        : AppDimensions.expenseTypeTagSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpenseTypeMedallion(type: type, size: size),
        const SizedBox(width: AppDimensions.spacingS),
        Flexible(
          child: Text(
            type?.shortLabel ?? l10n.expenseTypeUnknown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Le médaillon seul — couleurs et icône lues du type, jamais écrites ici.
class ExpenseTypeMedallion extends StatelessWidget {
  final ExpenseType? type;
  final double size;

  const ExpenseTypeMedallion({
    super.key,
    required this.type,
    this.size = AppDimensions.expenseTypeTagSize,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = ExpenseTypeColors.of(type);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: visuals.soft,
        borderRadius: BorderRadius.circular(AppDimensions.expenseTypeTagRadius),
      ),
      child: Icon(
        type == null
            ? ExpenseTypeVisuals.fallbackIcon
            : ExpenseTypeVisuals.icon(type!.icon),
        size: size <= AppDimensions.expenseTypeTagSizeSmall
            ? AppDimensions.expenseTypeTagIconSizeSmall
            : AppDimensions.expenseTypeTagIconSize,
        color: visuals.color,
      ),
    );
  }
}

/// Couleur et teinte douce d'un type, avec les jetons du thème en repli.
class ExpenseTypeColors {
  final Color color;
  final Color soft;

  const ExpenseTypeColors({required this.color, required this.soft});

  factory ExpenseTypeColors.of(ExpenseType? type) => ExpenseTypeColors(
    color: type == null
        ? AppColors.textMuted
        : ExpenseTypeVisuals.color(type.colorHex) ?? AppColors.textMuted,
    soft: type == null
        ? AppColors.surfaceAlt
        : ExpenseTypeVisuals.color(type.softColorHex) ?? AppColors.surfaceAlt,
  );
}
