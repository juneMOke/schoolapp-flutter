import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_results_error_state.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_cycle_tree.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_breakdown_tile.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/states/recouvrement_dashboard_empty_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// « Où en est chaque niveau » : les cycles de l'école, chacun dépliable en ses
/// niveaux, chaque ligne portant la répartition tricolore de ses élèves.
///
/// **L'ordre est celui de l'école, pas celui du retard.** La section se lit
/// comme on parcourt l'établissement — cycle après cycle, niveau après niveau.
/// Le « qui décroche » reste dit ailleurs : la lecture « écart » de fin de page
/// nomme le niveau en tête et celui qui ferme la marche.
///
/// Chargement, vide et erreur passent par les widgets partagés (règle #10). Un
/// échec est ici toujours local : le wrapper ne proposera jamais de
/// « reconnexion », seulement une reprise.
class RecouvrementCyclesSection extends StatefulWidget {
  final FeeControlDashboardLabels labels;

  const RecouvrementCyclesSection({super.key, required this.labels});

  @override
  State<RecouvrementCyclesSection> createState() =>
      _RecouvrementCyclesSectionState();
}

class _RecouvrementCyclesSectionState extends State<RecouvrementCyclesSection> {
  /// Le choix explicite de l'utilisateur, cycle par cycle. Sans choix, un cycle
  /// est ouvert s'il est **seul** — sous un filtre de cycle, le replier ne
  /// laisserait qu'une ligne à ouvrir avant de lire quoi que ce soit —, replié
  /// sinon.
  ///
  /// Gardé d'une lecture à l'autre : cocher un frais ne doit pas refermer le
  /// cycle qu'on est en train de lire. Ce qui s'affiche dessous est, lui,
  /// toujours tiré de la lecture en vigueur — rien n'y survit d'une autre.
  final Map<String, bool> _expanded = <String, bool>{};

  /// Clé du groupe des niveaux que le référentiel ne rattache à aucun cycle.
  static const String _unplacedKey = '__hors-cycle__';

  String _keyOf(RecouvrementCycleNode node) => node.cycleId ?? _unplacedKey;

  bool _isExpanded(RecouvrementCycleNode node, {required bool alone}) =>
      _expanded[_keyOf(node)] ?? alone;

  void _toggle(RecouvrementCycleNode node, {required bool alone}) {
    final next = !_isExpanded(node, alone: alone);
    setState(() => _expanded[_keyOf(node)] = next);
  }

  /// Vrai quand la ligne désigne un périmètre que l'écran nominatif accepte :
  /// un niveau, et un cycle que le référentiel sait lui rattacher.
  bool _canOpenControl(String? schoolLevelId) =>
      schoolLevelId != null && widget.labels.groupIdOf(schoolLevelId) != null;

  /// Ouvre l'écran nominatif sur **exactement** le niveau de la ligne.
  ///
  /// Le frais vient de `lastQuery`, jamais des sélecteurs : ce sont les
  /// chiffres affichés qui ouvrent la liste, pas des critères qu'on aurait
  /// changés depuis. L'écran nominatif ne contrôle qu'une nature à la fois :
  /// sur une sélection qui en porte plusieurs, on ouvre sur la première — c'est
  /// un point d'entrée, pas un contrat.
  ///
  /// Le cycle vient du niveau, pas du filtre : le filtre peut valoir « tous les
  /// cycles », alors que l'écran nominatif exige un cycle et un niveau.
  void _openControl(RecouvrementDashboardState state, String schoolLevelId) {
    final query = state.lastQuery;
    if (query == null) return;
    final groupId = widget.labels.groupIdOf(schoolLevelId);
    if (groupId == null) return;
    final feeCode = query.feeCodes.firstOrNull;
    if (feeCode == null) return;

    context.push(
      AppRoutesNames.recouvrementControl,
      extra: FeeControlIntent(
        schoolLevelGroupId: groupId,
        schoolLevelId: schoolLevelId,
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
          prev.errorMessage != curr.errorMessage ||
          // L'œil transmet le frais de `lastQuery` : une ligne bâtie sur une
          // requête périmée ouvrirait l'écran voisin sur un autre frais.
          prev.lastQuery != curr.lastQuery,
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

        final nodes = RecouvrementCycleTree.build(
          state.ranking.groups,
          widget.labels,
        );
        final alone = nodes.length == 1;

        return _card(
          l10n,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < nodes.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                ..._cycle(l10n, state, nodes[i], alone: alone),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _cycle(
    AppLocalizations l10n,
    RecouvrementDashboardState state,
    RecouvrementCycleNode node, {
    required bool alone,
  }) {
    final expanded = _isExpanded(node, alone: alone);
    return [
      RecouvrementBreakdownTile(
        key: ValueKey('cycle-${_keyOf(node)}'),
        label: _cycleLabel(l10n, node),
        breakdown: node.breakdown,
        expanded: expanded,
        onToggle: () => _toggle(node, alone: alone),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.recouvrementLevelIndent,
            bottom: AppDimensions.spacingS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final level in node.levels)
                RecouvrementBreakdownTile(
                  key: ValueKey(
                    'level-${level.schoolLevelId ?? '__sans-niveau__'}',
                  ),
                  // Sous son cycle, le niveau n'a plus à en porter le nom :
                  // c'est ce que faisait le préfixe du classement à plat.
                  label: widget.labels.labelFor(
                    level.schoolLevelId,
                    l10n,
                    withGroup: false,
                  ),
                  breakdown: level.breakdown,
                  dense: true,
                  onView: _canOpenControl(level.schoolLevelId)
                      ? () => _openControl(state, level.schoolLevelId!)
                      : null,
                ),
            ],
          ),
        ),
    ];
  }

  String _cycleLabel(AppLocalizations l10n, RecouvrementCycleNode node) {
    final cycleId = node.cycleId;
    if (cycleId == null) return l10n.recouvrementCycleUnplaced;
    return widget.labels.cycleNameOf(cycleId) ?? l10n.recouvrementCycleUnplaced;
  }

  /// Les états qui précèdent la carte — squelette, erreur, vide — restent NUS :
  /// ce sont des anatomies partagées, et les envelopper leur donnerait un titre
  /// de section pour dire qu'il n'y a rien à titrer.
  Widget _card(AppLocalizations l10n, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
    child: BiToneSectionCard(
      title: l10n.recouvrementCyclesTitle,
      subtitle: l10n.recouvrementCyclesHint,
      child: child,
    ),
  );
}
