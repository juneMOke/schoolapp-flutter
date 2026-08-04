import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_anomaly.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payment_anomalies_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Alerte d'administration sur un trop-perçu détecté à la synchro (ADR-012
/// RG-012-15, amendé par la requalification `REJETÉ` → `ANOMALIE`).
///
/// **Non dismissible**, et c'est tout son intérêt : il n'y a pas de croix, pas
/// de glissement, pas de fermeture par tap à côté. Le seul geste qui l'éteint
/// est « Traité », qui écrit un accusé horodaté et nommé en base. C'est
/// exactement ce que la feuille de reprise de synchro ne sait pas faire — elle
/// se ferme d'un tap et son motif s'efface d'un clic sur « Réessayer ».
///
/// Monté au-dessus de toutes les routes, au même endroit que le bandeau de
/// dégradation de session : une anomalie d'argent ne doit pas dépendre de
/// l'écran sur lequel se trouve l'utilisateur.
///
/// ⚠️ **Jamais hors session.** Le bandeau nomme un caissier et un motif
/// d'anomalie financière, et son bouton « Traité » écrit un accusé en base au
/// nom de l'utilisateur courant. Sur l'écran de connexion, il exposerait des
/// données nominatives à qui tient l'appareil, et laisserait n'importe qui
/// éteindre l'alerte — au nom d'un uid vide. Il est donc conditionné à une
/// session authentifiée, exactement comme le bandeau de dégradation.
class PaymentAnomalyBanner extends StatelessWidget {
  final Widget child;

  const PaymentAnomalyBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // `context.watch` plutôt qu'un BlocBuilder imbriqué : la garde de session
    // prime sur tout le reste, et doit être réévaluée à chaque changement de
    // statut d'authentification.
    final authenticated =
        context.watch<AuthBloc>().state.status == AuthStatus.authenticated;
    if (!authenticated) return child;

    return BlocBuilder<PaymentAnomaliesCubit, PaymentAnomaliesState>(
      buildWhen: (prev, curr) => prev.open != curr.open,
      builder: (context, state) {
        final anomaly = state.latest;
        if (anomaly == null) return child;

        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: _Bar(anomaly: anomaly, remaining: state.open.length - 1),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final PaymentAnomaly anomaly;

  /// Nombre d'autres anomalies ouvertes. Elles ne sont pas listées ici : le
  /// bandeau en montre une à la fois et réapparaît tant qu'il en reste.
  final int remaining;

  const _Bar({required this.anomaly, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.warning,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.report_problem_outlined,
              size: 18,
              color: AppColors.textOnDark,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.paymentAnomalyBannerTitle,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _detail(l10n),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textOnDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            TextButton(
              onPressed: () =>
                  context.read<PaymentAnomaliesCubit>().acknowledge(anomaly.id),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textOnDark,
              ),
              child: Text(l10n.paymentAnomalyAcknowledgeLabel),
            ),
          ],
        ),
      ),
    );
  }

  /// Ce que l'opérateur doit savoir pour arbitrer : le caissier et le motif.
  /// Chaque élément est omis s'il est inconnu — un libellé vide serait pire que
  /// son absence.
  String _detail(AppLocalizations l10n) {
    final parts = <String>[
      if (anomaly.cashierFullName case final cashier?) cashier,
      if (anomaly.reason case final reason? when reason.trim().isNotEmpty)
        reason,
      if (remaining > 0) l10n.paymentAnomalyOthersPending(remaining),
    ];
    return parts.isEmpty
        ? l10n.paymentAnomalyBannerFallback
        : parts.join(' · ');
  }
}
