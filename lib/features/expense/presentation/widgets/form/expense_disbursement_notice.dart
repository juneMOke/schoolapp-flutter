import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Dit quand l'argent est sorti, sans laisser le choisir (écart de recette
/// E1, F49) : une déclaration neuve est payée à l'instant où l'agent appuie
/// sur « Déclarer » ; une redéclaration reprend l'instant d'origine.
class ExpenseDisbursementNotice extends StatelessWidget {
  /// L'instant d'origine d'une redéclaration, ou `null` pour une neuve.
  final DateTime? redeclaredAt;

  const ExpenseDisbursementNotice({super.key, this.redeclaredAt});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final at = redeclaredAt;
    final String text;
    if (at == null) {
      text = l10n.expenseDisbursedNowNotice;
    } else {
      final dates = MaterialLocalizations.of(context);
      final wall = SchoolTime.wallClock(at);
      text = l10n.expenseDisbursedRedeclaredNotice(
        dates.formatMediumDate(wall),
        dates.formatTimeOfDay(
          TimeOfDay.fromDateTime(wall),
          alwaysUse24HourFormat: true,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.schedule, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
