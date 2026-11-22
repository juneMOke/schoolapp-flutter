import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_rule_block.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_chrome.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_list.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_tabs.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_toolbar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc E « Où en est chaque élève ? » (§4.3, §4.6 E) : la règle, les
/// onglets collés à la liste, la liste nominative et ses exports.
///
/// Ne charge rien : [students] est l'état du `RecoveryStudentsCubit` que la
/// page alimente, et chaque geste remonte par son rappel.
class RecoveryStudentsPanel extends StatelessWidget {
  final RecoveryDashboard dashboard;
  final RecoveryStudentsState students;
  final RecoveryRuleKind rule;
  final int? thresholdInCents;
  final RecoveryTab tab;
  final String search;
  final RecoveryStudentsQuery exportQuery;
  final bool exportsEnabled;
  final String? exportsDisabledReason;

  /// Le résumé des frais de la pastille (« Scolarité · +1 autre »).
  final String feesLabel;

  /// Posée sur la carte : la simulation y remonte (« Changer », I14).
  final GlobalKey? anchorKey;
  final ValueChanged<RecoveryRuleKind> onRuleChanged;
  final ValueChanged<int?> onThresholdChanged;
  final ValueChanged<RecoveryTab> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onFeesTapped;
  final ValueChanged<RecoveryStudentRow> onStudentTapped;

  /// « Réessayer » de la liste en échec.
  final VoidCallback onRetry;

  const RecoveryStudentsPanel({
    super.key,
    required this.dashboard,
    required this.students,
    required this.rule,
    required this.thresholdInCents,
    required this.tab,
    required this.search,
    required this.exportQuery,
    required this.exportsEnabled,
    this.exportsDisabledReason,
    required this.feesLabel,
    this.anchorKey,
    required this.onRuleChanged,
    required this.onThresholdChanged,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onPageChanged,
    required this.onFeesTapped,
    required this.onStudentTapped,
    required this.onRetry,
  });

  /// La règle à laquelle le serveur a répondu (« au moins » sans montant ou
  /// indisponible ⇒ la règle par défaut).
  RecoveryRuleKind get _answeredRule =>
      rule == RecoveryRuleKind.atLeast &&
          (thresholdInCents == null || !dashboard.atLeastAvailable)
      ? RecoveryRuleKind.somePayment
      : rule;

  int? _countOf(RecoveryTabCounts? c, RecoveryTab t) => c == null
      ? null
      : switch (t) {
          RecoveryTab.toChase => c.toChase,
          RecoveryTab.inOrder => c.inOrder,
          RecoveryTab.all => c.all,
        };

  List<RecoveryStudentsTabData> _tabs(AppLocalizations l10n) {
    final counts = students.page?.counts;
    // Le contrat ne donne pas de reste par onglet : celui d'« À relancer »
    // est le reste dû des élèves visés par la simulation (F), posée sur la
    // même règle — exactement les élèves pas en ordre (R8, R12).
    final owed = dashboard.simulation.abandonedOutstanding;
    final all = counts?.all ?? 0;
    return [
      (
        tab: RecoveryTab.toChase,
        icon: Icons.cancel_outlined,
        title: l10n.recoveryStudentsTabToChase,
        count: counts?.toChase,
        subtitle: owed.isEmpty
            ? null
            : l10n.recoveryStudentsTabToChaseSub(
                recoveryAmountLines(owed, dashboard.currencies).join(' / '),
              ),
      ),
      (
        tab: RecoveryTab.inOrder,
        icon: Icons.check_circle_outline,
        title: l10n.recoveryStudentsTabInOrder,
        count: counts?.inOrder,
        subtitle: counts == null || all == 0
            ? null
            : l10n.recoveryStudentsTabInOrderSub(
                (counts.inOrder * 100 / all).round(),
              ),
      ),
      (
        tab: RecoveryTab.all,
        icon: Icons.groups_outlined,
        title: l10n.recoveryStudentsTabAll,
        count: counts?.all,
        subtitle: l10n.recoveryStudentsTabAllSub,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final page = students.page;
    final tabCount = _countOf(page?.counts, tab);
    final exportable = exportsEnabled && (tabCount ?? 0) > 0;
    final reason = exportsEnabled
        ? l10n.recoveryStudentsExportEmpty
        : exportsDisabledReason;
    final verbs = recoveryRuleVerbs(
      l10n,
      _answeredRule,
      recoveryThresholdText(thresholdInCents, dashboard.currencies),
    );
    final tone = RecoveryStudentsTones.of(tab);
    // Les bascules se lisent sur la largeur que le bloc reçoit (§4.1).
    return LayoutBuilder(
      builder: (context, received) {
        final narrow = received.maxWidth < AppBreakpoints.dataTableCardsMax;
        final layout = RecoveryStudentsList.layoutFor(received.maxWidth);
        return EteeloStatsCard(
          key: anchorKey,
          title: l10n.recoveryStudentsTitle,
          subtitle: l10n.recoveryStudentsSubtitle,
          icon: Icons.how_to_reg_outlined,
          tone: DashboardSense.encaisse,
          toneSurface: false,
          actionsBeside: !narrow,
          actions: [
            RecoveryFeesPill(feesLabel: feesLabel, onTap: onFeesTapped),
          ],
          child: Builder(
            builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RecoveryRuleBlock(
                    dashboard: dashboard,
                    rule: rule,
                    thresholdInCents: thresholdInCents,
                    narrow: narrow,
                    onRuleChanged: onRuleChanged,
                    onThresholdChanged: onThresholdChanged,
                  ),
                  const SizedBox(height: AppSpacing.md + 6),
                  RecoveryStudentsTabs(
                    tabs: _tabs(l10n),
                    active: tab,
                    narrow: narrow,
                    onSelect: onTabChanged,
                  ),
                  Container(
                    padding: EdgeInsets.all(
                      narrow ? AppSpacing.sm + 2 : AppSpacing.md + 2,
                    ),
                    decoration: BoxDecoration(
                      color: RecoveryStudentsTones.soft(tone),
                      border: Border.all(
                        color: ColorMix.tint(
                          AppColors.border,
                          tone,
                          RecoveryStudentsTones.frameBorderPercent,
                        ),
                      ),
                      borderRadius: narrow
                          ? AppRadius.brLg
                          : const BorderRadius.only(
                              topRight: AppRadius.lg,
                              bottomLeft: AppRadius.lg,
                              bottomRight: AppRadius.lg,
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.sm + 2,
                      children: [
                        RecoveryStudentsToolbar(
                          title: page?.title,
                          count: page?.totalElements,
                          tab: tab,
                          verbs: verbs,
                          search: search,
                          onSearchChanged: onSearchChanged,
                          exportQuery: exportQuery,
                          exportsEnabled: exportable,
                          exportsDisabledReason: reason,
                        ),
                        RecoveryStudentsList(
                          students: students,
                          tab: tab,
                          search: search,
                          currencies: dashboard.currencies,
                          onPageChanged: onPageChanged,
                          onStudentTapped: onStudentTapped,
                          onRetry: onRetry,
                          layout: layout,
                        ),
                        if (page != null)
                          RecoveryStudentsFooter(
                            count: tabCount ?? 0,
                            title: page.title,
                            query: exportQuery,
                            enabled: exportable,
                            disabledReason: reason,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
