import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_holding.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/state_card.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/payments_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

class FacturationDetailPaymentsSection extends StatelessWidget {
  final String studentId;
  final String academicYearId;
  final VoidCallback onCreatePaymentRequested;
  final ValueChanged<Payment> onViewPaymentRequested;

  const FacturationDetailPaymentsSection({
    super.key,
    required this.studentId,
    required this.academicYearId,
    required this.onCreatePaymentRequested,
    required this.onViewPaymentRequested,
  });

  void _retry(BuildContext context) {
    context.read<PaymentsBloc>().add(
      PaymentsRequested(studentId: studentId, academicYearId: academicYearId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FinanceSectionCard(
      backgroundColor: AppColors.surfaceRaised,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Séparation charge / caisse (ADR-014) : le secrétariat lit ce qu'un
          // élève DOIT sans avoir le droit de voir les encaissements. La
          // section ne doit alors pas affirmer « aucun versement » — elle n'en
          // sait rien. Elle se tait (ADR-015 §6-C).
          //
          // ⚠️ **Tri-état, et abonné.** `PermissionGate.allows` répond `false`
          // sur un ensemble INCONNU — l'état de tout le parc jusqu'au premier
          // refresh suivant la migration v24. Un caissier qui détient
          // `finance.payment.read` se voyait donc refuser l'historique sur
          // l'écran même où il décide s'il faut encaisser : le pire endroit
          // pour se taire, puisque le silence y fait réencaisser. On ne se tait
          // que sur `missing`, c'est-à-dire quand on SAIT que le droit manque.
          //
          // Abonné, parce que lu une seule fois le verdict resterait figé : les
          // permissions arrivent en cours de session, et rien d'autre ne
          // reconstruit cette section.
          PermissionHoldingBuilder(
            requires: const [Perm.financePaymentRead],
            builder: (context, holding) =>
                BlocConsumer<PaymentsBloc, PaymentsState>(
                  listenWhen: (prev, curr) =>
                      prev.status != curr.status ||
                      prev.errorType != curr.errorType,
                  listener: (context, state) {
                    if (state.status != PaymentsStatus.failure) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorType.localizedMessage(l10n)),
                      ),
                    );
                  },
                  buildWhen: (prev, curr) =>
                      prev.status != curr.status ||
                      prev.payments != curr.payments ||
                      prev.errorType != curr.errorType,
                  builder: (context, state) {
                    final canReadPayments =
                        holding != PermissionHolding.missing;
                    // Total PAR DEVISE : un passage au guichet peut solder une
                    // créance en dollars et une en francs, et deux versements
                    // de devises différentes ne s'additionnent pas.
                    final totalPaid = MoneyBag.sumBy(
                      state.payments,
                      (payment) =>
                          Money.parse(payment.amountInCents, payment.currency),
                    );
                    final String subtitle;
                    if (!canReadPayments) {
                      subtitle = l10n.facturationDetailPaymentsWithheldSubtitle;
                    } else if (state.status == PaymentsStatus.success) {
                      subtitle = l10n
                          .facturationDetailPaymentsRecordedWithTotal(
                            state.payments.length,
                            // Les devises se lisent côte à côte, séparées : ce
                            // sous-titre est une ligne de texte, pas un total.
                            totalPaid.entries
                                .map(MoneyFormat.format)
                                .join(' · '),
                          );
                    } else {
                      subtitle = l10n.facturationDetailPaymentsSectionSubtitle;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: l10n.facturationDetailPaymentsSectionTitle,
                          subtitle: subtitle,
                          actionLabel:
                              l10n.facturationDetailCollectPaymentAction,
                          onActionPressed: onCreatePaymentRequested,
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: AppDimensions.spacingM),
                        AnimatedSwitcher(
                          duration: FinanceMotion.standard,
                          switchInCurve: FinanceMotion.outCurve,
                          switchOutCurve: FinanceMotion.inCurve,
                          child: () {
                            // En premier : la lecture n'a pas eu lieu, il n'y
                            // a rien à relancer. Un vide honnête, pas un vide
                            // affirmatif.
                            if (!canReadPayments) {
                              return StateCard(
                                key: const ValueKey('payments-withheld'),
                                message: l10n.facturationDetailPaymentsWithheld,
                                icon: Icons.lock_outline,
                                accent: AppColors.textSecondary,
                                accentSoft: AppColors.surfaceAlt,
                              );
                            }

                            if (state.status == PaymentsStatus.loading) {
                              return const Center(
                                key: ValueKey('payments-loading'),
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state.status == PaymentsStatus.failure) {
                              return StateCard(
                                key: const ValueKey('payments-error'),
                                message: state.errorType.localizedMessage(l10n),
                                icon: Icons.error_outline,
                                accent: AppColors.warning,
                                accentSoft: AppColors.financeDetailWarningSoft,
                                actionLabel:
                                    l10n.facturationDetailPaymentsRetry,
                                onAction: () => _retry(context),
                              );
                            }

                            if (state.payments.isEmpty) {
                              return StateCard(
                                key: const ValueKey('payments-empty'),
                                message: l10n.facturationDetailPaymentsEmpty,
                                icon: Icons.inbox_outlined,
                                accent: AppColors.textSecondary,
                                accentSoft: AppColors.surfaceAlt,
                              );
                            }

                            final sorted = [...state.payments]
                              ..sort((a, b) => b.paidAt.compareTo(a.paidAt));

                            return Column(
                              key: const ValueKey('payments-list'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < sorted.length; i++) ...[
                                  FacturationPaymentLine(
                                    payment: sorted[i],
                                    onTap: () =>
                                        onViewPaymentRequested(sorted[i]),
                                  ),
                                  if (i < sorted.length - 1)
                                    const SizedBox(
                                      height: AppDimensions.spacingS,
                                    ),
                                ],
                              ],
                            );
                          }(),
                        ),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Le bouton « Encaisser un paiement » reste aligné avec le titre tant
        // qu'il y a la place (desktop, 2 colonnes, tablette) ; il ne passe sous
        // le titre que sur petit téléphone.
        final compact = constraints.maxWidth < AppBreakpoints.dataTablePhoneMax;
        // Deux gardes superposées, deux causes distinctes : la permission
        // MASQUE (ADR-014, « pas vous »), le mode de session GÈLE (ADR-010,
        // « pas maintenant »). La conjonction est celle du chemin de POUSSÉE :
        // `POST /sync/payments` exige aussi `editique.write`, parce qu'il scelle
        // le reçu en encaissant. Offrir le bouton sans ce droit produirait une
        // écriture d'outbox rejetée en 403 TERMINAL — l'argent saisi serait
        // perdu, pas rejoué.
        final button = PermissionGate.access(
          kPaymentCollectAccess,
          child: SessionWriteGate(
            child: EteeloButton.primary(
              label: actionLabel,
              icon: Icons.add,
              onPressed: onActionPressed,
              fullWidth: false,
            ),
          ),
        );

        final titleBlock = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: AppDimensions.spacingXL,
              height: AppDimensions.spacingXL,
              child: Icon(
                Icons.payments_outlined,
                size: AppDimensions.detailHeaderIconSize,
                color: AppColors.bleuArdoise,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.bleuProfond,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: AppDimensions.spacingM),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppDimensions.spacingM),
            button,
          ],
        );
      },
    );
  }
}
