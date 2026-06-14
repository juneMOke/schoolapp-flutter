import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Déclencheur de sélection de date du filtre d'appel, aligné sur le
/// design-system : [EteeloButton] secondaire (pilule bordée) portant l'icône
/// calendrier + la date courante. Le libellé « Date » reste accessible via le
/// tooltip.
class AttendanceDateButton extends StatelessWidget {
  final DateTime date;
  final Future<void> Function() onPickDate;
  final double width;

  const AttendanceDateButton({
    super.key,
    required this.date,
    required this.onPickDate,
    this.width = AppDimensions.classesOrganisationCompactFieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);

    return SizedBox(
      width: width,
      child: EteeloButton.secondary(
        label: dateLabel,
        icon: Icons.calendar_today_outlined,
        onPressed: onPickDate,
        size: EteeloButtonSize.regular,
        fullWidth: true,
        tooltip: l10n.attendanceDateTooltip,
      ),
    );
  }
}
