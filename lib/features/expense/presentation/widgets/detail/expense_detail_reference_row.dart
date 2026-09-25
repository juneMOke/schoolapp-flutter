import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Une ligne du tableau de références de la fiche : libellé à gauche, valeur à
/// droite, filet sous chacune sauf la dernière.
class ExpenseDetailReferenceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const ExpenseDetailReferenceRow({
    super.key,
    required this.label,
    required this.value,
    required this.last,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: AppDimensions.expenseNotePaddingV,
    ),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppDimensions.expenseDetailLabelWidth,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS + AppDimensions.spacingXS),
        Expanded(child: Text(value, style: AppTextStyles.body)),
      ],
    ),
  );
}
