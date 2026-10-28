import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_day_banner_parts.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/touch_target.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_status_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le mois d'un [PayrollBanner] — livre et tableau de bord : ‹ le surtitre
/// de l'écran, le mois (qui ouvre le sélecteur) et son statut › puis
/// « Mois en cours » quand on s'en est éloigné. Le mois se lit une seule
/// fois : plus de frise.
class PayrollBannerMonth extends StatelessWidget {
  /// Le surtitre, en capitales or : « LIVRE DE PAIE », « TABLEAU DE BORD ».
  final String eyebrow;

  /// `YYYY-MM`.
  final String month;
  final PayrollPhase? phase;

  /// `null` : la flèche est grisée (premier mois, mois en cours).
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  /// `null` sur le mois en cours : le bouton de retour n'apparaît pas.
  final VoidCallback? onCurrent;
  final VoidCallback onPick;

  const PayrollBannerMonth({
    super.key,
    required this.eyebrow,
    required this.month,
    required this.phase,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrent,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phase = this.phase;
    final onCurrent = this.onCurrent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresenceBannerButton(
          icon: Icons.chevron_left,
          tooltip: l10n.presenceMarkPreviousMonth,
          onPressed: onPrevious,
        ),
        const SizedBox(width: AppSpacing.sm),
        // Flexible : sur téléphone le mois passe à la ligne plutôt que de
        // pousser la flèche suivante hors du bandeau.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.orDoux,
                  letterSpacing: 1.2,
                ),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _MonthButton(
                    label: PayrollLabels.month(context, month),
                    onPick: onPick,
                  ),
                  if (phase != null) PayrollStatusPill(phase: phase),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        PresenceBannerButton(
          icon: Icons.chevron_right,
          tooltip: l10n.presenceMarkNextMonth,
          onPressed: onNext,
        ),
        if (onCurrent != null) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onCurrent,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.payrollAgentOnBanner,
            ),
            child: Text(l10n.presenceMarkCurrentMonth),
          ),
        ],
      ],
    );
  }
}

/// Le mois du bandeau, qui ouvre le sélecteur : une icône le dit, la zone
/// d'appui fait 48 dp, et le lecteur d'écran annonce un bouton.
class _MonthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPick;

  const _MonthButton({required this.label, required this.onPick});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: Tooltip(
      message: AppLocalizations.of(context)!.presenceMarkPickMonth,
      child: InkWell(
        onTap: onPick,
        borderRadius: AppRadius.brSm,
        child: TouchTarget(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.payrollAgentOnBanner,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.calendar_month_outlined,
                size: AppSpacing.xl,
                color: AppColors.payrollAgentOnBannerMuted,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
