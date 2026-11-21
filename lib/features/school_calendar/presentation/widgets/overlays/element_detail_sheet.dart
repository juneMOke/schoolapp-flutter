import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/calendar_overlay_frame.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_actions.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/overlays/element_detail_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'utilisateur choisit dans le détail d'un élément.
enum ElementDetailChoice { edit, delete, verify, replace }

/// O1 — le détail d'un élément (feuille du bas sous 760, modale au-delà, par
/// `showEteeloAdaptiveSheet`), d'après la maquette CalItemModal : en-tête
/// sombre (nature, intitulé), carte de dates, faits en tuiles. Un élément
/// national ne se modifie jamais (A3) : s'il est remplaçable, l'école peut le
/// **remplacer** dans son calendrier ; un élément de l'école ne propose que
/// ce que le droit permet, et supprimer un remplacement rétablit l'élément
/// national.
class ElementDetailSheet extends StatelessWidget {
  final CalendarElement element;
  final CalendarScopeOptions scopes;
  final bool canEdit;

  /// Le jour de l'école : « En cours », « Dans 5 jours ».
  final DateTime today;

  /// L'élément national que [element] remplace, s'il est connu.
  final CalendarElement? replaced;

  const ElementDetailSheet({
    super.key,
    required this.element,
    required this.scopes,
    required this.canEdit,
    required this.today,
    this.replaced,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheet =
        MediaQuery.sizeOf(context).width <
        AppBreakpoints.adaptiveSheetDialogMin;
    final author = element.createdBy?.name;
    final note = element.note ?? '';
    Text text(String value) => Text(value);
    final tiles = [
      ElementFactTile(
        label: l10n.schoolCalendarDates,
        value: text(
          '${CalendarLabels.dates(context, element)} · '
          '${l10n.schoolCalendarDurationDays(element.durationDays)}',
        ),
      ),
      ElementFactTile(
        label: l10n.schoolCalendarConcerns,
        value: text(CalendarLabels.scope(l10n, element.scope, scopes)),
      ),
      ElementFactTile(
        label: l10n.schoolCalendarSource,
        value: ElementSourceValue(national: element.isNational),
      ),
      if (replaced case final national?)
        ElementFactTile(
          label: l10n.schoolCalendarReplacesLabel,
          value: text(
            '${national.title} · ${CalendarLabels.dates(context, national)}',
          ),
        ),
      if (author != null)
        ElementFactTile(label: l10n.schoolCalendarAddedBy, value: text(author)),
    ];
    final pad = sheet ? AppSpacing.lg : AppSpacing.xl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CalendarOverlayHeader(
          eyebrow: CalendarLabels.nature(l10n, element.nature),
          title: element.title,
          sheet: sheet,
          onClose: () => Navigator.of(context).pop(),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElementDateCard(element: element, today: today),
                const SizedBox(height: AppSpacing.md),
                ElementFactGrid(tiles: tiles),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    note,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (element.toVerify) ...[
                  const SizedBox(height: AppSpacing.md),
                  EteeloNotice.warning(l10n.schoolCalendarCarriedOver),
                ],
                if (element.isNational) ...[
                  const SizedBox(height: AppSpacing.md),
                  ElementNationalMention(
                    element.replaceable
                        ? l10n.schoolCalendarNationalReplaceable
                        : l10n.schoolCalendarNationalLocked,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElementDetailActions(element: element, canEdit: canEdit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
