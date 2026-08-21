import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/disciplinary_status_ui.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_status_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// Carte d'un cas disciplinaire (local) : liséré de gravité, en-tête (gravité,
/// date, titre, catégorie, statut), contenu, chip de sanction, badge de
/// commentaires, frise de statut et actions (avancer / classer sans suite).
class DisciplinaryCaseCard extends StatelessWidget {
  final OfflineDisciplinaryCase caseData;

  /// Nombre de commentaires (badge). `content` détaillé chargé au détail seul.
  final int commentCount;

  /// Avance le cas au statut suivant (Ouvert→Pris en charge→Résolu).
  final VoidCallback? onAdvance;

  /// Classe le cas sans suite (DISMISSED). Disponible si non terminal.
  final VoidCallback? onDismiss;

  /// Ouvre le fil de commentaires du cas (lecture + ajout).
  final VoidCallback? onOpenComments;

  const DisciplinaryCaseCard({
    super.key,
    required this.caseData,
    this.commentCount = 0,
    this.onAdvance,
    this.onDismiss,
    this.onOpenComments,
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
                if (caseData.sanction != null) ...[
                  const SizedBox(height: AppDimensions.spacingM),
                  _SanctionChip(sanction: caseData.sanction!),
                ],
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
            _DateLabel(date: caseData.disciplinaryCaseDate),
            if (commentCount > 0) _CommentBadge(count: commentCount),
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
    // Frise au-dessus, actions dessous : l'avancement peut porter 2 boutons
    // (avancer + classer sans suite) → empilement pour éviter tout débordement.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisciplinaryCaseStatusStepper(status: caseData.status),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          children: [
            Expanded(
              child: _AdvanceAction(
                status: caseData.status,
                onAdvance: onAdvance,
                onDismiss: onDismiss,
              ),
            ),
            if (onOpenComments != null)
              TextButton.icon(
                onPressed: onOpenComments,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: Text(l10n.disciplinaryCommentsDialogTitle),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bleuArdoise,
                ),
              ),
          ],
        ),
      ],
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

class _CommentBadge extends StatelessWidget {
  final int count;

  const _CommentBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: AppDimensions.disciplinaryChipIconSize,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Text(
          l10n.disciplinaryCommentsCountBadge(count),
          style: AppTextStyles.badge.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final DisciplinaryStatus status;

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
  final DisciplinaryStatus status;
  final VoidCallback? onAdvance;
  final VoidCallback? onDismiss;

  const _AdvanceAction({
    required this.status,
    required this.onAdvance,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = status.advanceActionLabel(l10n);
    final target = status.advanceTarget;

    if (label == null || target == null) {
      // Statut terminal : pas d'action, on rappelle l'issue du dossier.
      final terminal = status.terminalLabel(l10n);
      if (terminal == null) return const SizedBox.shrink();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.getIcon(),
            size: AppDimensions.detailMiniIconSize,
            color: status.getColor(),
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            terminal,
            style: AppTextStyles.action.copyWith(color: status.getColor()),
          ),
        ],
      );
    }

    // Avancer ou classer part par le MÊME agrégat que la création
    // (`POST /sync/disciplinary-cases`, gardé `discipline.write`) : sans cette
    // enveloppe, un profil en lecture produisait une écriture rejetée en 403
    // TERMINAL, laissant la base locale afficher un cas « classé » que le
    // serveur tient pour ouvert — et l'état est terminal côté UI, donc
    // irréparable sans wipe. Le libellé d'état terminal, lui, reste ouvert :
    // c'est de la lecture.
    return PermissionGate.access(
      kDisciplineInstructAccess,
      child: SessionWriteGate(
        child: Wrap(
          spacing: AppDimensions.spacingS,
          runSpacing: AppDimensions.spacingXS,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrimaryButton(
              label: label,
              icon: target.getIcon(),
              fullWidth: false,
              onPressed: onAdvance,
            ),
            if (status.canDismiss && onDismiss != null)
              TextButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.block_rounded, size: 16),
                label: Text(l10n.disciplinaryAdvanceDismiss),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
