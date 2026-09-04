import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_dashboard_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux seuls réglages du tableau de bord : quel frais, quel périmètre.
///
/// Deux, et pas davantage. L'écran répond à une question courte — « qui est en
/// ordre » — et chaque critère supplémentaire la transformerait en formulaire
/// de recherche, ce que la page voisine fait déjà mieux.
class FeeControlDashboardFilters extends StatelessWidget {
  /// Sentinelle de « tous les cycles » : `EteeloSelectInput` distingue mal
  /// `null` (rien de choisi) d'un choix explicite de tout voir — même raison
  /// que `FeeControlClassroomField.allClassroomsValue`.
  static const String allCyclesValue = '__all__';

  final List<String> feeCodes;
  final String? selectedFeeCode;
  final List<FeeControlCycleOption> cycles;
  final String? selectedCycleId;
  final bool enabled;
  final ValueChanged<String?> onFeeCodeChanged;
  final ValueChanged<String?> onCycleChanged;

  const FeeControlDashboardFilters({
    super.key,
    required this.feeCodes,
    required this.selectedFeeCode,
    required this.cycles,
    required this.selectedCycleId,
    required this.onFeeCodeChanged,
    required this.onCycleChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final fee = EteeloSelectInput<String>(
      label: l10n.feeControlFeeLabel,
      value: feeCodes.contains(selectedFeeCode) ? selectedFeeCode : null,
      enabled: enabled && feeCodes.isNotEmpty,
      onChanged: onFeeCodeChanged,
      items: [
        for (final code in feeCodes)
          EteeloSelectItem<String>(
            value: code,
            // Nommé par sa NATURE : l'écran couvre toute l'école, où deux
            // niveaux portent le même code sous des libellés différents.
            label: code.localizedFeeLabel(l10n),
          ),
      ],
    );

    final cycle = EteeloSelectInput<String>(
      label: l10n.feeControlSearchCycleLabel,
      value: selectedCycleId ?? allCyclesValue,
      enabled: enabled,
      onChanged: onCycleChanged,
      items: [
        EteeloSelectItem<String>(
          value: allCyclesValue,
          label: l10n.feeControlDashboardCycleAll,
        ),
        for (final option in cycles)
          EteeloSelectItem<String>(value: option.id, label: option.name),
      ],
    );

    return BiToneSectionCard(
      title: l10n.feeControlSearchTitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= AppBreakpoints.feeControlTableWideMin;
          if (!wide) {
            return Column(
              children: [
                fee,
                const SizedBox(height: AppDimensions.spacingM),
                cycle,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: fee),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(child: cycle),
            ],
          );
        },
      ),
    );
  }
}
