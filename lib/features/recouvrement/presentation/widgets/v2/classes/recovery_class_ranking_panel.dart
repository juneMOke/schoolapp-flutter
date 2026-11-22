import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_panel_head.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_class_ranking_groups.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/classes/recovery_ranking_options.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc D — « Classes en tête et classes à relancer » (R7, D7).
///
/// Sur un frais à la fois, choisi parmi les frais retenus : les 4 premières
/// classes « En tête », les 4 dernières « À relancer en priorité » (la moitié
/// de chaque côté sous 8, `RecoveryClassRanking.split`). Deux colonnes dès
/// [AppBreakpoints.detailCompactMax] de largeur **reçue**, l'une sous l'autre
/// en deçà ; sous [AppBreakpoints.dataTableCardsMax], la barre passe sous le
/// nom. « Non affectés » se lit à part, sans classement ni verdict.
///
/// [rankingFeeCode] est la valeur d'un [RecoveryRankingOption] (le code, ou
/// `code|devise` pour un frais en deux devises) ; inconnue, le premier frais
/// classé la remplace.
class RecoveryClassRankingPanel extends StatelessWidget {
  final RecoveryDashboard dashboard;
  final String rankingFeeCode;
  final ValueChanged<String> onRankingFeeChanged;
  final ValueChanged<RecoveryClassFeeRow> onClassTapped;

  const RecoveryClassRankingPanel({
    super.key,
    required this.dashboard,
    required this.rankingFeeCode,
    required this.onRankingFeeChanged,
    required this.onClassTapped,
  });

  @override
  Widget build(BuildContext context) {
    final options = RecoveryRankingOptions.of(dashboard);
    final selected = RecoveryRankingOptions.resolve(options, rankingFeeCode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final narrow = width < AppBreakpoints.dataTableCardsMax;
        final twoColumns = width >= AppBreakpoints.detailCompactMax;
        return Container(
          padding: EdgeInsets.all(
            narrow ? AppSpacing.gridGap : AppSpacing.sectionGap,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
            boxShadow: AppElevation.shadowCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecoveryClassPanelHead(
                stacked: narrow,
                action: _feeChoice(context, options, selected),
              ),
              if (selected != null)
                RecoveryClassRankingBody(
                  ranking: selected.ranking,
                  twoColumns: twoColumns,
                  narrow: narrow,
                  onClassTapped: onClassTapped,
                )
              else
                RecoveryClassMuted(
                  AppLocalizations.of(context)!.recoveryClassesNone,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget? _feeChoice(
    BuildContext context,
    List<RecoveryRankingOption> options,
    RecoveryRankingOption? selected,
  ) {
    if (selected == null) return null;
    final l10n = AppLocalizations.of(context)!;
    if (options.length == 1) {
      return RecoveryFeeCurrencyChip(
        label: selected.feeLabel,
        currency: selected.currency,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppDimensions.recoveryClassFeeSelectMinWidth,
      ),
      child: EteeloSelectInput<String>(
        label: l10n.recoveryClassesFeeField,
        hideLabel: true,
        density: EteeloSelectDensity.compact,
        minWidth: AppDimensions.recoveryClassFeeSelectMinWidth,
        value: selected.value,
        items: [
          for (final o in options)
            EteeloSelectItem(
              value: o.value,
              label: l10n.recoveryClassesFeeOption(
                o.feeLabel,
                MoneyFormat.symbolOf(o.currency),
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null && value != selected.value) {
            onRankingFeeChanged(value);
          }
        },
      ),
    );
  }
}
