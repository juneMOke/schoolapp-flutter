import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux bornes de la période précise.
///
/// Elles sont **contraintes l'une par l'autre**, comme aux inscriptions : « Du »
/// ne dépasse pas « Au », et réciproquement. S'y ajoutent les bornes du
/// serveur, qui refuserait en 400 plutôt que de rattraper : pas de jour futur,
/// pas avant l'ouverture de l'année, pas plus de
/// [DashboardWindow.maxDayCount] jours. L'utilisateur n'a pas à découvrir ces
/// règles par une erreur : le sélecteur ne le laisse pas les enfreindre.
class BoutiqueDashboardRangeFields extends StatelessWidget {
  final DashboardWindow window;

  /// L'ouverture de l'année, si l'année la dit.
  final DateTime? yearStart;

  final ValueChanged<DashboardWindow> onChanged;

  const BoutiqueDashboardRangeFields({
    super.key,
    required this.window,
    required this.onChanged,
    this.yearStart,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final from = window.from;
    final to = window.to;
    final today = SchoolTime.today(DateTime.now());
    final start = yearStart;
    final earliest = DashboardWindow.earliestFrom(to);
    final latest = DashboardWindow.latestTo(from);

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingS,
      children: [
        SizedBox(
          width: AppDimensions.boutiqueDashboardDateFieldWidth,
          child: EteeloDateInput(
            label: l10n.boutiqueDashboardRangeFieldFrom,
            value: from,
            firstDate: start != null && start.isAfter(earliest)
                ? start
                : earliest,
            lastDate: to,
            onChanged: (value) => _request(from: value, to: to),
          ),
        ),
        SizedBox(
          width: AppDimensions.boutiqueDashboardDateFieldWidth,
          child: EteeloDateInput(
            label: l10n.boutiqueDashboardRangeFieldTo,
            value: to,
            firstDate: from,
            lastDate: latest.isBefore(today) ? latest : today,
            onChanged: (value) => _request(from: from, to: value),
          ),
        ),
      ],
    );
  }

  /// Ne demande que lorsque la fenêtre est complète et dans l'ordre : une
  /// borne effacée ne déclenche rien.
  void _request({required DateTime? from, required DateTime? to}) {
    if (from == null || to == null || from.isAfter(to)) return;
    onChanged(DashboardWindow(from: from, to: to));
  }
}
