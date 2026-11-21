import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « n éléments repris de l'année précédente à vérifier… » (spec §4.6 C,
/// maquette `CalNotice`), dans la carte d'aide : « Les passer en revue »
/// ouvre la vue Liste filtrée (I10), puis devient « Tout afficher ».
class CalendarVerifyNotice extends StatelessWidget {
  final int count;
  final bool filtered;
  final VoidCallback onToggle;

  const CalendarVerifyNotice({
    super.key,
    required this.count,
    required this.filtered,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloNotice.tinted(
      message: l10n.schoolCalendarVerifyNotice(count),
      icon: Icons.warning_amber_rounded,
      ink: AppColors.calendarVerifyInk,
      background: AppColors.calendarVerifySoft,
      border: AppColors.calendarVerifyBorder,
      action: TextButton(
        onPressed: onToggle,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.bleuArdoise,
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
        child: Text(
          filtered ? l10n.schoolCalendarShowAll : l10n.schoolCalendarReview,
        ),
      ),
    );
  }
}
