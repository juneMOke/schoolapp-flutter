import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_status_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte d'un cas disciplinaire : liséré de gravité, en-tête (gravité, date,
/// titre, catégorie, statut), contenu, chip de sanction, frise de statut et
/// bouton d'avancement.
class DisciplinaryCaseCard extends StatelessWidget {
  final DisciplinaryCaseSummary caseData;

  /// Pousse le cas au statut suivant. Dormant pour l'instant (pas d'endpoint
  /// backend) ; le bouton reste présent et prêt à être câblé.
  final VoidCallback? onAdvance;

  const DisciplinaryCaseCard({
    super.key,
    required this.caseData,
    this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final severityColor = caseData.severity.getColor();

    // Liséré de gravité via une barre à gauche (un Border non uniforme ne peut
    // pas porter de borderRadius) ; coins arrondis assurés par le clip.
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: AppDimensions.disciplinaryCardAccentWidth,
            child: ColoredBox(color: severityColor),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left:
                  AppDimensions.disciplinaryCardAccentWidth +
                  AppDimensions.spacingL,
              right: AppDimensions.spacingL,
              top: AppDimensions.spacingM,
              bottom: AppDimensions.spacingM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, l10n),
                if (caseData.content.trim().isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    caseData.content,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spacingM),
                _SanctionChip(sanction: caseData.sanction),
                const SizedBox(height: AppDimensions.spacingM),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppDimensions.spacingM),
                _footer(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingXS,
          children: [
            _SeverityChip(severity: caseData.severity),
            if (caseData.createdAt != null)
              _DateLabel(date: caseData.createdAt!),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          caseData.title,
          style: AppTextStyles.sectionTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (caseData.category != DisciplinaryCategory.unknown)
          Text(
            caseData.category.getDisplayName(l10n),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppDimensions.spacingS),
        _StatusPill(status: caseData.status),
      ],
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    final stepper = DisciplinaryCaseStatusStepper(status: caseData.status);
    final action = _AdvanceAction(
      status: caseData.status,
      onAdvance: onAdvance,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            AppBreakpoints.disciplinaryCardFooterStackMax) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stepper,
              const SizedBox(height: AppDimensions.spacingM),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: stepper),
            const SizedBox(width: AppDimensions.spacingM),
            action,
          ],
        );
      },
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final DisciplinarySeverity severity;

  const _SeverityChip({required this.severity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = severity.getColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.disciplinaryChipPaddingH,
        vertical: AppDimensions.disciplinaryChipPaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppDimensions.disciplinaryTintAlpha),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AppDimensions.disciplinaryChipIconSize,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            l10n.disciplinaryCaseSeverityChip(severity.getDisplayName(l10n)),
            style: AppTextStyles.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final DateTime date;

  const _DateLabel({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: AppDimensions.disciplinaryChipIconSize,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          MaterialLocalizations.of(context).formatMediumDate(date),
          style: AppTextStyles.badge.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final DisciplinaryCaseStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = status.getColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.disciplinaryStatusPillPaddingH,
        vertical: AppDimensions.disciplinaryStatusPillPaddingV,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppDimensions.disciplinaryTintAlpha),
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: color.withValues(
            alpha: AppDimensions.disciplinaryTintBorderAlpha,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.getIcon(),
            size: AppDimensions.disciplinaryStatusPillIconSize,
            color: color,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            status.getDisplayName(l10n),
            style: AppTextStyles.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _SanctionChip extends StatelessWidget {
  final DisciplinarySanction sanction;

  const _SanctionChip({required this.sanction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.disciplinaryChipPaddingH,
        vertical: AppDimensions.disciplinarySanctionChipPaddingV,
      ),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoise.withValues(
          alpha: AppDimensions.disciplinarySanctionTintAlpha,
        ),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: AppDimensions.disciplinaryChipIconSize,
            color: AppColors.bleuArdoise,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            sanction.getDisplayName(l10n),
            style: AppTextStyles.badge.copyWith(color: AppColors.bleuArdoise),
          ),
        ],
      ),
    );
  }
}

class _AdvanceAction extends StatelessWidget {
  final DisciplinaryCaseStatus status;
  final VoidCallback? onAdvance;

  const _AdvanceAction({required this.status, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final next = status.nextStatus;
    final label = status.advanceActionLabel(l10n);

    if (next == null || label == null) {
      // Statut terminal : pas d'action, on rappelle la clôture.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: AppDimensions.detailMiniIconSize,
            color: AppColors.vertSavane,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            l10n.disciplinaryCaseClosedLabel,
            style: AppTextStyles.action.copyWith(color: AppColors.vertSavane),
          ),
        ],
      );
    }

    return PrimaryButton(
      label: label,
      icon: next.getIcon(),
      fullWidth: false,
      onPressed: onAdvance,
    );
  }
}
