import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_element.dart';
import 'package:school_app_flutter/features/school_calendar/domain/entities/calendar_scope_options.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_labels.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/helpers/calendar_nature_style.dart';
import 'package:school_app_flutter/features/school_calendar/presentation/widgets/calendar_date_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que l'utilisateur choisit dans le détail d'un élément.
enum ElementDetailChoice { edit, delete, verify, replace }

/// O1 — le détail d'un élément (feuille du bas sous 760, modale au-delà, par
/// `showEteeloAdaptiveSheet`). Un élément national ne se modifie jamais
/// (A3) : s'il est remplaçable, l'école peut le **remplacer** dans son
/// calendrier ; un élément de l'école ne propose que ce que le droit permet,
/// et supprimer un remplacement rétablit l'élément national.
class ElementDetailSheet extends StatelessWidget {
  final CalendarElement element;
  final CalendarScopeOptions scopes;
  final bool canEdit;

  /// L'élément national que [element] remplace, s'il est connu.
  final CalendarElement? replaced;

  const ElementDetailSheet({
    super.key,
    required this.element,
    required this.scopes,
    required this.canEdit,
    this.replaced,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = element.nature.tone;
    final author = element.createdBy?.name;
    Widget fact(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CalendarDateChip(
                  date: element.startDate,
                  tone: tone,
                  strong: true,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CalendarLabels.nature(l10n, element.nature),
                        style: AppTypography.eyebrow.copyWith(color: tone.ink),
                      ),
                      Text(element.title, style: AppTypography.titleMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            fact(
              l10n.schoolCalendarDates,
              '${CalendarLabels.dates(context, element)} · '
              '${l10n.schoolCalendarDurationDays(element.durationDays)}',
            ),
            fact(
              l10n.schoolCalendarConcerns,
              CalendarLabels.scope(l10n, element.scope, scopes),
            ),
            fact(
              l10n.schoolCalendarSource,
              element.isNational
                  ? l10n.schoolCalendarNationalFramework
                  : l10n.schoolCalendarInternal,
            ),
            if (replaced case final national?)
              fact(
                l10n.schoolCalendarReplacesLabel,
                '${national.title} · ${CalendarLabels.dates(context, national)}',
              ),
            if (author != null) fact(l10n.schoolCalendarAddedBy, author),
            if ((element.note ?? '').isNotEmpty)
              fact(l10n.schoolCalendarFormNote, element.note!),
            if (element.isNational)
              EteeloNotice.warning(
                element.replaceable
                    ? l10n.schoolCalendarNationalReplaceable
                    : l10n.schoolCalendarNationalLocked,
              ),
            if (element.toVerify)
              EteeloNotice.warning(l10n.schoolCalendarCarriedOver),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                if (canEdit && element.isNational && element.replaceable) ...[
                  SecondaryButton(
                    label: l10n.schoolCalendarClose,
                    fullWidth: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  PrimaryButton(
                    label: l10n.schoolCalendarReplaceAction,
                    icon: Icons.swap_horiz_rounded,
                    fullWidth: false,
                    onPressed: () =>
                        Navigator.of(context).pop(ElementDetailChoice.replace),
                  ),
                ] else if (canEdit && !element.isNational) ...[
                  SecondaryButton(
                    label: element.isReplacement
                        ? l10n.schoolCalendarRestoreNational
                        : l10n.schoolCalendarDelete,
                    icon: element.isReplacement
                        ? Icons.restore_rounded
                        : Icons.delete_outline,
                    fullWidth: false,
                    onPressed: () =>
                        Navigator.of(context).pop(ElementDetailChoice.delete),
                  ),
                  if (element.toVerify)
                    SecondaryButton(
                      label: l10n.schoolCalendarDateVerified,
                      icon: Icons.check_rounded,
                      fullWidth: false,
                      onPressed: () =>
                          Navigator.of(context).pop(ElementDetailChoice.verify),
                    ),
                  PrimaryButton(
                    label: l10n.schoolCalendarEdit,
                    icon: Icons.edit_outlined,
                    fullWidth: false,
                    onPressed: () =>
                        Navigator.of(context).pop(ElementDetailChoice.edit),
                  ),
                ] else
                  SecondaryButton(
                    label: l10n.schoolCalendarClose,
                    fullWidth: false,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
