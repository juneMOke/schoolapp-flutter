import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_day_leave_guard.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';

/// Le jour et les filtres du registre tenus dans l'adresse :
/// `?jour=2026-10-21&vue=grid&categorie=teacher&statut=absent`. F5 rouvre le
/// même jour, un lien partagé aussi, Précédent revient au jour d'avant.
///
/// La recherche n'y va pas : chaque frappe serait une entrée d'historique.
/// Les valeurs par défaut (dernier jour ouvré, liste, tout le personnel)
/// laissent l'adresse nue.
class HrRegisterLocation extends StatelessWidget {
  static const dayParam = 'jour';
  static const viewParam = 'vue';
  static const categoryParam = 'categorie';
  static const statusParam = 'statut';

  final StaffAttendanceState state;
  final StaffAttendanceCubit cubit;

  /// Un jour changé par l'adresse (Précédent, Suivant) passe par la même
  /// garde que les flèches.
  final PresenceDayLeaveGuard guard;
  final Widget child;

  const HrRegisterLocation({
    super.key,
    required this.state,
    required this.cubit,
    required this.guard,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LocationParamsSync(
      current: _current,
      onLocation: (values) {
        cubit
          ..setViewMode(
            _byName(CollectionViewMode.values, values[viewParam]) ??
                CollectionViewMode.list,
          )
          ..setDayCategory(_byName(StaffCategory.values, values[categoryParam]))
          ..setDayStatus(_byName(PresenceStatus.values, values[statusParam]));
        final day = values[dayParam];
        if (day != _current[dayParam]) unawaited(_followDay(context, day));
      },
      child: child,
    );
  }

  Map<String, String?> get _current => {
    dayParam: state.isToday ? null : state.day,
    viewParam: state.viewMode == CollectionViewMode.list
        ? null
        : state.viewMode.name,
    categoryParam: state.dayQuery.category?.name,
    statusParam: state.dayQuery.status?.name,
  };

  /// Le jour lu dans l'adresse, après la garde. « Rester » remet l'adresse
  /// sur le jour affiché : sinon elle montrerait un jour qu'on n'a pas
  /// ouvert.
  Future<void> _followDay(BuildContext context, String? day) async {
    if (await guard.leaveThen(() => cubit.showDay(day))) return;
    final router = context.mounted ? LocationQuery.ownedBy(context) : null;
    if (router != null) LocationQuery.write(router, _current);
  }

  /// Une valeur inconnue (lien tronqué, ancienne version) vaut le défaut.
  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      name == null ? null : values.where((v) => v.name == name).firstOrNull;
}
