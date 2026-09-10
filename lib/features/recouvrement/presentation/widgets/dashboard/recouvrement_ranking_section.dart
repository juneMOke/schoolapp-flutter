import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_class_rows.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_group_row.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/states/recouvrement_dashboard_empty_state.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
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
class RecouvrementRankingSection extends StatelessWidget {
  /// Vrai quand le tableau porte sur toute l'école : les noms de niveaux sont
  /// alors préfixés de leur cycle, faute de quoi deux « 1ère année » de cycles
  /// différents deviendraient indiscernables.
  final bool showCycleInLabels;

  final FeeControlDashboardLabels labels;

  /// Année portée par le contexte académique — le dépliage en a besoin pour
  /// lire les classes du niveau.
  final String academicYearId;

  const RecouvrementRankingSection({
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
    RecouvrementDashboardState state, {
    required String schoolLevelId,
    String? classroomId,
  }) {
    final query = state.lastQuery;
    if (query == null) return;
    final groupId = labels.groupIdOf(schoolLevelId);
    if (groupId == null) return;

    // L'écran nominatif ne contrôle qu'UNE nature à la fois. Sur une sélection
    // qui en porte plusieurs, on ouvre sur la première : c'est un point
    // d'entrée, pas un contrat — l'écran voisin offre son propre sélecteur, et
    // ne rien passer aurait obligé à re-choisir un frais qu'on vient de cocher.
    final feeCode = query.feeCodes.firstOrNull;
    if (feeCode == null) return;

    context.push(
      AppRoutesNames.recouvrementControl,
      extra: FeeControlIntent(
        schoolLevelGroupId: groupId,
        schoolLevelId: schoolLevelId,
        classroomId: classroomId,
        feeCode: feeCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.ranking != curr.ranking ||
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
            onRetry: () => context.read<RecouvrementDashboardBloc>().add(
              const RecouvrementRefreshRequested(),
            ),
          );
        }
        if (state.ranking.isEmpty) {
          return RecouvrementDashboardEmptyState(
            title: l10n.feeControlDashboardEmptyTitle,
            description: l10n.feeControlDashboardEmptyDescription,
          );
        }

        return _card(
          l10n,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in state.ranking.groups) ...[
                RecouvrementGroupRowTile(
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
                      : () => context.read<RecouvrementDashboardBloc>().add(
                          RecouvrementGroupToggled(
                            academicYearId: academicYearId,
                            schoolLevelId: group.schoolLevelId,
                          ),
                        ),
                ),
                if (state.expandedLevelId == group.schoolLevelId)
                  RecouvrementClassRows(
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
          ),
        );
      },
    );
  }

  /// Toutes les sections de l'écran vivent dans la même carte — c'est ce qui
  /// fait lire la page comme une page, et non comme une pile de blocs qui
  /// n'auraient pas le même rang. Le classement était le dernier à ne pas
  /// l'avoir : il vient, seul, du tableau de bord du Contrôle des frais, où il
  /// était la seule section et n'avait donc rien à côtoyer.
  ///
  /// Les états qui la précèdent — squelette, erreur, vide — restent NUS : ce
  /// sont des anatomies partagées, et les envelopper leur donnerait un titre de
  /// section pour dire qu'il n'y a rien à titrer.
  Widget _card(AppLocalizations l10n, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
    child: BiToneSectionCard(
      title: l10n.feeControlDashboardRankingTitle,
      subtitle: l10n.feeControlDashboardRankingHint,
      child: child,
    ),
  );
}
