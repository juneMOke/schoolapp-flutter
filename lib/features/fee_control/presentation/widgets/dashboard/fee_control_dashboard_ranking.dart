import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_class_rows.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/fee_control_dashboard_group_row.dart';
import 'package:school_app_flutter/features/fee_control/presentation/widgets/dashboard/states/fee_control_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Le classement des groupes — le cœur de l'écran.
///
/// L'ordre vient du projecteur, **du plus en retard au plus en règle** : la
/// question posée est « quel niveau décroche », pas « où en est l'école ». Un
/// ordre alphabétique obligerait à lire quarante lignes pour trouver les trois
/// qui comptent.
///
/// Chargement, vide et erreur passent par les widgets partagés (règle #10). Un
/// échec est ici toujours local : le wrapper ne proposera donc jamais de
/// « reconnexion », seulement une reprise.
class FeeControlDashboardRanking extends StatelessWidget {
  /// Vrai quand le tableau porte sur toute l'école : les noms de niveaux sont
  /// alors préfixés de leur cycle, faute de quoi deux « 1ère année » de cycles
  /// différents deviendraient indiscernables.
  final bool showCycleInLabels;

  final FeeControlDashboardLabels labels;

  /// Année portée par le contexte académique — le dépliage en a besoin pour
  /// lire les classes du niveau.
  final String academicYearId;

  const FeeControlDashboardRanking({
    super.key,
    required this.labels,
    required this.academicYearId,
    required this.showCycleInLabels,
  });

  /// Vrai quand la ligne désigne un périmètre que l'écran nominatif accepte :
  /// un niveau, et un cycle que le référentiel sait lui rattacher.
  bool _canOpenControl(String? schoolLevelId) =>
      schoolLevelId != null && labels.groupIdOf(schoolLevelId) != null;

  /// Ouvre l'écran nominatif sur **exactement** le périmètre de la ligne tapée.
  ///
  /// Le frais vient de `lastQuery`, jamais des sélecteurs : entre le moment où
  /// l'écran a lu et celui où l'on tape, l'utilisateur a pu changer de frais
  /// sans relancer. Ce sont les chiffres affichés qui ouvrent la liste, pas les
  /// critères en cours de saisie — sinon la liste ne répondrait pas de la
  /// synthèse qui l'a ouverte.
  ///
  /// Le cycle vient du niveau, pas du filtre : le filtre peut être « tous les
  /// cycles », alors que l'écran nominatif exige un cycle et un niveau.
  void _openControl(
    BuildContext context,
    FeeControlDashboardState state, {
    required String schoolLevelId,
    String? classroomId,
  }) {
    final query = state.lastQuery;
    if (query == null) return;
    final groupId = labels.groupIdOf(schoolLevelId);
    if (groupId == null) return;

    context.push(
      AppRoutesNames.feeControl,
      extra: FeeControlIntent(
        schoolLevelGroupId: groupId,
        schoolLevelId: schoolLevelId,
        classroomId: classroomId,
        feeCode: query.feeCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<FeeControlDashboardBloc, FeeControlDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.summary != curr.summary ||
          prev.errorType != curr.errorType ||
          prev.expandedLevelId != curr.expandedLevelId ||
          prev.classesStatus != curr.classesStatus ||
          prev.classes != curr.classes,
      builder: (context, state) {
        if (state.status == EnrollmentLoadStatus.initial) {
          return const SizedBox.shrink();
        }
        if (state.status == EnrollmentLoadStatus.loading) {
          return const EteeloListSkeleton(rowCount: 5, showAvatar: false);
        }
        if (state.status == EnrollmentLoadStatus.failure) {
          return EnrollmentResultsErrorState(
            type: state.errorType ?? EnrollmentErrorType.unknown,
            message: state.errorMessage,
            onRetry: () => context.read<FeeControlDashboardBloc>().add(
              const FeeControlDashboardRefreshRequested(),
            ),
          );
        }
        if (state.summary.isEmpty) {
          return FeeControlDashboardEmptyState(
            title: l10n.feeControlDashboardEmptyTitle,
            description: l10n.feeControlDashboardEmptyDescription,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.feeControlDashboardRankingTitle,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              l10n.feeControlDashboardRankingHint,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppDimensions.spacingS),
            for (final group in state.summary.groups) ...[
              FeeControlDashboardGroupRow(
                key: ValueKey(group.schoolLevelId ?? '__sans-niveau__'),
                label: labels.labelFor(
                  group.schoolLevelId,
                  l10n,
                  withGroup: showCycleInLabels,
                ),
                breakdown: group.breakdown,
                expanded: state.expandedLevelId == group.schoolLevelId,
                // Rien à transmettre à l'écran nominatif dans deux cas : la
                // ligne n'a pas de niveau, ou le référentiel ne sait pas à quel
                // cycle il appartient — que l'écran voisin exige. Offrir le
                // passage quand même donnerait un bouton qui ne fait rien.
                onOpenControl: _canOpenControl(group.schoolLevelId)
                    ? () => _openControl(
                        context,
                        state,
                        schoolLevelId: group.schoolLevelId!,
                      )
                    : null,
                // Sans niveau, aucune classe où chercher : la ligne reste
                // inerte plutôt que d'offrir un chevron qui n'ouvre rien.
                onToggle: group.schoolLevelId == null
                    ? null
                    : () => context.read<FeeControlDashboardBloc>().add(
                        FeeControlDashboardGroupToggled(
                          academicYearId: academicYearId,
                          schoolLevelId: group.schoolLevelId,
                        ),
                      ),
              ),
              if (state.expandedLevelId == group.schoolLevelId)
                FeeControlDashboardClassRows(
                  status: state.classesStatus,
                  classes: state.classes,
                  classroomsMissing: state.classroomsMissing,
                  onOpenControl: _canOpenControl(group.schoolLevelId)
                      ? (row) => _openControl(
                          context,
                          state,
                          schoolLevelId: group.schoolLevelId!,
                          classroomId: row.classroomId,
                        )
                      : null,
                ),
            ],
          ],
        );
      },
    );
  }
}
