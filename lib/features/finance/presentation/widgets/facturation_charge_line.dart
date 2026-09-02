import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_progress_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_status_badge.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_pending_sync_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ligne de frais de l'élève (spec §11).
///
/// En-tête (libellé + badge de statut), barre de progression et pied
/// « Attendu · Payé · {reste} restant ». La ligne reste cliquable.
///
/// Depuis GF-3, elle vit aussi **sous** un en-tête de nature, comme tranche
/// d'un accordéon : [dense] retire alors sa bordure, que le cadre du groupe
/// porte déjà.
class FacturationChargeLine extends StatelessWidget {
  final StudentCharge charge;
  final VoidCallback onViewRequested;

  /// Rendue à l'intérieur d'un groupe : pas de bordure propre, le cadre du
  /// groupe l'entoure déjà. Deux cadres emboîtés à deux pixels d'écart se
  /// lisent comme une erreur de rendu.
  final bool dense;

  const FacturationChargeLine({
    super.key,
    required this.charge,
    required this.onViewRequested,
    this.dense = false,
  });

  String _formatAmount(double cents) => formatMonetaryAmountWithCurrency(
    amount: cents / 100,
    currency: charge.currency,
  );

  double get _progress {
    // Progression sur le total COMPOSÉ (miroir + encaissements de ce poste non
    // remontés), FRONT §5 — pas sur le seul miroir serveur.
    if (charge.expectedAmountInCents <= 0) {
      return charge.paidTotalInCents > 0 ? 1 : 0;
    }
    return (charge.paidTotalInCents / charge.expectedAmountInCents).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Statut COMPOSÉ (GF-4), jamais `charge.status`. Le miroir serveur n'est
    // pas recalculé après un encaissement local : il disait encore « à régler »
    // sur un frais que le guichet venait de solder, pendant que la jauge
    // juste au-dessus affichait 100 %.
    final status = charge.composedStatus;
    final visuals = status.visuals;
    // Reste COMPOSÉ (FRONT §5) : déjà borné à 0 par l'entité.
    final remaining = charge.remainingInCents;
    final isSettled = remaining <= 0;

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onViewRequested,
        borderRadius: AppRadius.brMd,
        hoverColor: AppColors.bleuArdoise.withValues(alpha: 0.06),
        splashColor: AppColors.bleuArdoise.withValues(alpha: 0.10),
        highlightColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spacingM),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: dense ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                // La tranche, pas la famille de frais : sur un minerval en
                // sept tranches, la nature seule rendait sept lignes
                // identiques que rien ne permettait de départager.
                label: chargeDesignation(charge, l10n),
                statusLabel: status.localizedLabel(l10n),
                visuals: visuals,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              FeeProgressBar(progress: _progress, fill: visuals.color),
              const SizedBox(height: AppDimensions.spacingS),
              FeeAmountsRow(
                expectedLabel: l10n.facturationDetailChargeExpectedAmountColumn,
                paidLabel: l10n.facturationDetailChargePaidAmountColumn,
                expected: _formatAmount(charge.expectedAmountInCents),
                paid: _formatAmount(charge.paidTotalInCents),
                remainingText: isSettled
                    ? null
                    : l10n.facturationChargeLineRemainingSuffix(
                        _formatAmount(remaining),
                      ),
              ),
              // Encaissement de ce poste non encore remonté (FRONT §5).
              if (charge.amountPaidPendingInCents > 0) ...[
                const SizedBox(height: AppDimensions.spacingS),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: FinancePendingSyncBadge(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  final String statusLabel;
  final FeeStatusVisuals visuals;

  const _Header({
    required this.label,
    required this.statusLabel,
    required this.visuals,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        FeeStatusBadge(label: statusLabel, visuals: visuals),
      ],
    );
  }
}
