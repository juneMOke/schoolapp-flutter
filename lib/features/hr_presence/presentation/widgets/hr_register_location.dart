import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';

/// Le jour et les filtres du registre tenus dans l'adresse :
/// `?jour=2026-10-21&vue=list&categorie=teacher&statut=absent`. F5 rouvre le
/// même jour, un lien du tableau de bord y mène, Précédent revient au jour
/// d'avant.
///
/// La recherche n'y va pas : chaque frappe serait une entrée d'historique.
/// Les valeurs par défaut (dernier jour ouvré, cartes, tout le personnel)
/// laissent l'adresse nue.
class HrRegisterLocation extends StatelessWidget {
  static const dayParam = 'jour';
  static const viewParam = 'vue';
  static const categoryParam = 'categorie';
  static const statusParam = 'statut';

  final StaffAttendanceState state;
  final StaffAttendanceCubit cubit;
  final Widget child;

  const HrRegisterLocation({
    super.key,
    required this.state,
    required this.cubit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final query = state.dayQuery;
    return LocationParamsSync(
      current: {
        dayParam: state.isToday ? null : state.day,
        viewParam: state.viewMode == CollectionViewMode.grid
            ? null
            : state.viewMode.name,
        categoryParam: query.category?.name,
        statusParam: query.status?.name,
      },
      onLocation: (values) {
        cubit
          ..setViewMode(
            _byName(CollectionViewMode.values, values[viewParam]) ??
                CollectionViewMode.grid,
          )
          ..setDayCategory(_byName(StaffCategory.values, values[categoryParam]))
          ..setDayStatus(_byName(PresenceStatus.values, values[statusParam]));
        unawaited(cubit.showDay(values[dayParam]));
      },
      child: child,
    );
  }

  /// Une valeur inconnue (lien tronqué, ancienne version) vaut le défaut.
  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      name == null ? null : values.where((v) => v.name == name).firstOrNull;
}
