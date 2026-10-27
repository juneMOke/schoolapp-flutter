import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_sheet.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/school_day_calendar.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix d'un mois d'un registre, sans les flèches : la grille des douze
/// mois de l'année scolaire, à partir de [firstMonth] (le mois de la
/// rentrée). Les mois après [lastMonth] (le mois en cours) se voient, grisés,
/// et ne se choisissent pas. Feuille sur téléphone, modale sur grand écran.
///
/// Les mois sont neutres : une pastille ne dit pas si le mois est en
/// vacances, son écran le dira une fois ouvert.
///
/// Rend le mois choisi en `YYYY-MM`, ou `null` si rien n'a été choisi.
Future<String?> pickPresenceMonth(
  BuildContext context, {
  required String month,
  required String? firstMonth,
  required String lastMonth,
}) => showEteeloAdaptiveSheet<String>(
  context: context,
  builder: (sheetContext) => PresenceMonthGrid(
    months: presencePickerMonths(firstMonth: firstMonth, lastMonth: lastMonth),
    selected: month,
    lastMonth: lastMonth,
    onSelected: (picked) => Navigator.of(sheetContext).pop(picked),
  ),
);

/// Les douze mois proposés : de la rentrée, ou, rentrée inconnue, des onze
/// mois qui précèdent le mois en cours, comme le registre les lirait.
List<String> presencePickerMonths({
  required String? firstMonth,
  required String lastMonth,
}) {
  final first = firstMonth ?? SchoolDayCalendar.addMonths(lastMonth, -11);
  return [
    for (var i = 0; i < DateTime.monthsPerYear; i++)
      SchoolDayCalendar.addMonths(first, i),
  ];
}

/// La grille du sélecteur, sur trois colonnes.
class PresenceMonthGrid extends StatelessWidget {
  final List<String> months;
  final String selected;

  /// Le dernier mois choisissable, `YYYY-MM`.
  final String lastMonth;
  final ValueChanged<String> onSelected;

  const PresenceMonthGrid({
    super.key,
    required this.months,
    required this.selected,
    required this.lastMonth,
    required this.onSelected,
  });

  static const _columns = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = [
      for (var i = 0; i < months.length; i += _columns)
        months.sublist(i, (i + _columns).clamp(0, months.length)),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.presenceMarkPickMonth,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: AppDimensions.presenceMarkTapTarget,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows) ...[
            Row(
              children: [
                for (final (i, month) in row.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MonthCell(
                      month: month,
                      selected: month == selected,
                      enabled: month.compareTo(lastMonth) <= 0,
                      onTap: () => onSelected(month),
                    ),
                  ),
                ],
                // Une dernière rangée incomplète garde la largeur des autres.
                for (var i = row.length; i < _columns; i++) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Spacer(),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Un mois de la grille : « oct. » sur « 2026 ». Le mois affiché est cerné à
/// la marque, comme dans la frise de la Paie.
class _MonthCell extends StatelessWidget {
  final String month;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _MonthCell({
    required this.month,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = enabled ? AppColors.textPrimary : AppColors.textMutedAa;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: PresenceLabels.month(MaterialLocalizations.of(context), month),
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Material(
        color: enabled ? AppColors.surfaceRaised : AppColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd,
          side: BorderSide(
            color: selected ? DashboardSense.marque : AppColors.border,
            width: selected
                ? AppDimensions.chartHighlightBorderWidth
                : AppDimensions.tileBorderWidth,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.brMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.presenceMonthShort('${int.parse(month.substring(5))}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: ink,
                      fontWeight: selected ? FontWeight.w700 : null,
                    ),
                  ),
                  Text(
                    month.substring(0, 4),
                    maxLines: 1,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMutedAa,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
