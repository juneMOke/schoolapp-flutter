import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/attendance_error_type.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_cubit.dart';
import 'package:school_app_flutter/features/attendances/presentation/register/bloc/class_presence_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_empty_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/states/attendance_results_error_state.dart';
import 'package:school_app_flutter/features/home/presentation/bloc/navigation_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre Classes ▸ Composition, dans la coquille : une classe sans élève se
/// compose là.
void openClassComposition(BuildContext context) =>
    context.read<NavigationBloc>().add(
      SubMenuItemSelected(
        menuId: MenuConstants.classesMenuId,
        subMenuId: MenuConstants.organisationId,
        title: AppLocalizations.of(context)!.classesOrganisationHeroTitle,
      ),
    );

/// Ce que montrent la fiche et le récapitulatif tant que le mois n'est pas
/// exploitable : chargement, échec de lecture (avec Réessayer), ou classe
/// sans élève. `null` quand le mois est prêt.
Widget? classMonthPlaceholder(BuildContext context, ClassPresenceState state) {
  final data = state.monthData;
  if (data == null) {
    if (!state.monthFailed) return const EteeloListSkeleton(rowCount: 4);
    return AttendanceResultsErrorState(
      type: AttendanceErrorType.storage,
      onRetry: () => unawaited(context.read<ClassPresenceCubit>().refresh()),
    );
  }
  if (data.students.isEmpty) {
    return AttendanceResultsEmptyState(
      onOpenComposition: () => openClassComposition(context),
    );
  }
  return null;
}
