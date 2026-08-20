import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_charge_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_collect_preflight.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_data_loader.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_statement_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_detail_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_payments_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_detail_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_detail_header.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationDetailPage extends StatelessWidget {
  final FacturationDetailIntent intent;

  const FacturationDetailPage({super.key, required this.intent});

  String _studentFullName(AppLocalizations l10n) {
    final fullName = [
      intent.lastName,
      intent.firstName,
      intent.surname,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');

    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  /// Classe affichée dans le sur-titre « Facturation · {classe} » (spec §06).
  String _classLabel(AppLocalizations l10n) {
    final value = intent.levelName.trim().isNotEmpty
        ? intent.levelName.trim()
        : intent.levelGroupName.trim();
    return value.isEmpty ? l10n.facturationDetailUnknownValue : value;
  }

  Future<void> _openCreatePayment(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final chargesBloc = context.read<StudentChargesBloc>();
    final paymentsBloc = context.read<PaymentsBloc>();
    final financeOfflineBloc = context.read<FinanceOfflineBloc>();

    if (chargesBloc.state.status != StudentChargesStatus.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.facturationCreatePaymentChargesUnavailable),
        ),
      );
      return;
    }

    // La SEULE attente réseau de cet écran, et elle est bornée. La fiche, elle,
    // s'affiche depuis le local sans rien attendre — mais le « reste » composé
    // ci-dessous borne la saisie et décide s'il faut encaisser : servi périmé
    // parce qu'un versement du poste voisin n'est pas descendu, il fait
    // réencaisser. C'est là que `FACTURATION_OFFLINE_PLAN.md` §13 plaçait cette
    // attente, et nulle part ailleurs.
    final refreshed = await runFacturationCollectPreflight(
      context,
      studentId: intent.studentId,
      academicYearId: intent.academicYearId,
    );
    if (!context.mounted) return;

    // Relecture locale en échec : on repart de ce qui est déjà affiché plutôt
    // que de fermer le guichet. La page, elle, se remettra à jour toute seule
    // sur le signal de revalidation (relecture silencieuse du loader).
    final charges = refreshed ?? chargesBloc.state.studentCharges;

    // FRONT §6/§8 : on retient les postes dont le RESTE composé est > 0, JAMAIS
    // `status` (miroir serveur — un poste soldé localement afficherait encore
    // UNPAID et réapparaîtrait comme payable → re-encaissement sur ce guichet).
    final unpaid = charges.where((c) => c.remainingInCents > 0).toList();

    if (unpaid.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.facturationCreatePaymentNoChargesAvailable),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await showFacturationCreatePaymentDialog(
      context,
      intent: FacturationCreatePaymentIntent(
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        studentCharges: charges,
      ),
      paymentsBloc: paymentsBloc,
      studentChargesBloc: chargesBloc,
      financeOfflineBloc: financeOfflineBloc,
    );
  }

  void _openChargeDetail(BuildContext context, StudentCharge charge) {
    // Détail d'un frais ouvert en popin (spec §16), au-dessus de la page.
    showFacturationChargeDetailDialog(
      context,
      intent: FacturationChargeDetailIntent(
        chargeId: charge.id,
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        feeCode: charge.feeCode,
        expectedAmountInCents: charge.expectedAmountInCents,
        amountPaidInCents: charge.amountPaidInCents,
        currency: charge.currency,
        chargeStatus: charge.status,
      ),
    );
  }

  void _openPaymentDetail(BuildContext context, Payment payment) {
    // Détail d'un paiement ouvert en popin (spec §15), au-dessus de la page.
    showFacturationPaymentDetailDialog(
      context,
      intent: FacturationPaymentDetailIntent(
        paymentId: payment.id,
        studentId: intent.studentId,
        academicYearId: intent.academicYearId,
        firstName: intent.firstName,
        lastName: intent.lastName,
        surname: intent.surname,
        levelName: intent.levelName,
        levelGroupName: intent.levelGroupName,
        payerFirstName: payment.payerFirstName,
        payerLastName: payment.payerLastName,
        payerMiddleName: payment.payerMiddleName,
        amountInCents: payment.amountInCents,
        currency: payment.currency,
        paidAt: payment.paidAt,
        // Garde du reçu : tant que l'encaissement n'est pas remonté, son uuid
        // est inconnu du serveur et la demande de pièce répondrait 404.
        isPendingSync: payment.isPendingSync,
        cashierFullName: payment.cashierFullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final studentFullName = _studentFullName(l10n);

    return MultiBlocProvider(
      providers: [
        BlocProvider<PaymentsBloc>(create: (_) => getIt<PaymentsBloc>()),
        BlocProvider<StudentChargesBloc>(
          create: (_) => getIt<StudentChargesBloc>(),
        ),
        // Chemin d'écriture offline-first de l'encaissement (file outbox).
        // La lecture (paiements/créances) est servie en local par les repos
        // offline-first liés en DI (BLoCs online ci-dessus inchangés).
        BlocProvider<FinanceOfflineBloc>(
          create: (_) => getIt<FinanceOfflineBloc>(),
        ),
        // Signal « un cycle de rafraîchissement vient d'aboutir » : c'est lui
        // qui remplace l'attente qu'on faisait subir à chaque lecture. Le
        // loader s'en sert pour relire sans skeleton, la légende de fraîcheur
        // pour se réafficher même quand le grand-livre n'a pas bougé.
        BlocProvider<LedgerRevalidationCubit>(
          create: (_) =>
              getIt<LedgerRevalidationCubit>()..watch(intent.studentId),
        ),
        // Fraîcheur du grand-livre (ADR-002) affichée sous les totaux.
        BlocProvider<LedgerFreshnessCubit>(
          create: (_) => getIt<LedgerFreshnessCubit>(),
        ),
        // Garde d'éditique : le relevé prend le studentId dans son URL, or un
        // élève saisi hors ligne porte un uuid client que le serveur ignore.
        // Résolu une fois au montage — l'id de l'élève ne change pas ici.
        BlocProvider<EditiqueEligibilityCubit>(
          create: (_) =>
              getIt<EditiqueEligibilityCubit>()
                ..resolveForStudent(intent.studentId),
        ),
      ],
      child: AppPageBackground(
        appBar: StudentDetailAppBar(
          fullName: studentFullName,
          eyebrow: '${l10n.facturationDetailEyebrow} · ${_classLabel(l10n)}',
          firstName: intent.firstName,
          lastName: intent.lastName,
          fallbackRoute: AppRoutesNames.facturations,
          showCloseButton: true,
          trailing: const _BillingBalanceAppBarPill(),
        ),
        child: LayoutBuilder(
          builder: (context, available) {
            // Grand écran : on élargit le contenu (1180) pour juxtaposer
            // Paiements | Frais ; en dessous, largeur de lecture conservée (880).
            final wide =
                available.maxWidth >= AppBreakpoints.financeDetailTwoColMin;
            final contentMaxWidth = wide
                ? AppDimensions.detailContentMaxWidth
                : AppDimensions.facturationContentMaxWidth;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact =
                        constraints.maxWidth <
                        AppDimensions.detailCompactBreakpoint;
                    final twoCol =
                        constraints.maxWidth >=
                        AppBreakpoints.financeDetailTwoColMin;
                    final blockSpacing = compact
                        ? AppDimensions.spacingM
                        : AppDimensions.detailSectionSpacing;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<StudentChargesBloc, StudentChargesState>(
                          buildWhen: (prev, curr) =>
                              prev.status != curr.status ||
                              prev.studentCharges != curr.studentCharges,
                          builder: (context, state) {
                            final hasCharges =
                                state.status == StudentChargesStatus.success &&
                                state.studentCharges.isNotEmpty;
                            final totalDue = hasCharges
                                ? state.studentCharges.fold<double>(
                                    0.0,
                                    (sum, charge) =>
                                        sum + charge.expectedAmountInCents,
                                  )
                                : 0.0;
                            // Déjà payé & reste COMPOSÉS (miroir serveur +
                            // encaissements de ce poste non remontés), FRONT §5.
                            final alreadyPaid = hasCharges
                                ? state.studentCharges.fold<double>(
                                    0.0,
                                    (sum, charge) =>
                                        sum + charge.paidTotalInCents,
                                  )
                                : 0.0;
                            final remaining = hasCharges
                                ? state.studentCharges.fold<double>(
                                    0.0,
                                    (sum, charge) =>
                                        sum + charge.remainingInCents,
                                  )
                                : 0.0;
                            final currency = hasCharges
                                ? state.studentCharges.first.currency
                                : '';

                            // Tuiles de synthèse affichées directement sur la page
                            // (l'identité élève + classe vit déjà dans l'AppBar).
                            return FinanceDetailKpiBand(
                              hasCharges: hasCharges,
                              totalDueCents: totalDue,
                              alreadyPaidCents: alreadyPaid,
                              remainingCents: remaining,
                              currency: currency,
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        FacturationDetailStatementBar(
                          studentId: intent.studentId,
                          academicYearId: intent.academicYearId,
                        ),
                        SizedBox(height: blockSpacing),
                        // Identité inconnue — lien profond ouvert sans
                        // `extra` : on n'affiche pas un solde sans pouvoir dire
                        // à qui il appartient. Une classe manquante, elle, ne
                        // justifie rien de tel : elle ne sert qu'au sur-titre.
                        if (!intent.hasStudentIdentity)
                          FinanceContextErrorCard(
                            title: l10n.facturationDetailContextErrorTitle,
                            message: l10n.facturationDetailContextErrorMessage,
                            icon: Icons.report_problem_outlined,
                            accent: AppColors.warning,
                            accentSoft: AppColors.warning.withValues(
                              alpha: 0.14,
                            ),
                            borderColor: AppColors.warning.withValues(
                              alpha: 0.2,
                            ),
                          )
                        else
                          FacturationDetailDataLoader(
                            intent: intent,
                            child: Builder(
                              builder: (blocContext) {
                                final payments =
                                    FacturationDetailPaymentsSection(
                                      studentId: intent.studentId,
                                      academicYearId: intent.academicYearId,
                                      onCreatePaymentRequested: () =>
                                          _openCreatePayment(blocContext),
                                      onViewPaymentRequested: (payment) =>
                                          _openPaymentDetail(
                                            blocContext,
                                            payment,
                                          ),
                                    );
                                final charges = FacturationDetailChargesSection(
                                  studentId: intent.studentId,
                                  academicYearId: intent.academicYearId,
                                  onViewChargeRequested: (charge) =>
                                      _openChargeDetail(blocContext, charge),
                                );

                                // Grand écran : Paiements et Frais côte à côte.
                                if (twoCol) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: payments),
                                      SizedBox(width: blockSpacing),
                                      Expanded(child: charges),
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    payments,
                                    SizedBox(height: blockSpacing),
                                    charges,
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pastille de solde rendue dans l'AppBar (spec §06).
///
/// Vit dans le sous-arbre du [MultiBlocProvider] de la page, donc le
/// [StudentChargesBloc] est bien accessible depuis l'AppBar.
class _BillingBalanceAppBarPill extends StatelessWidget {
  const _BillingBalanceAppBarPill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<StudentChargesBloc, StudentChargesState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.studentCharges != curr.studentCharges,
      builder: (context, state) {
        final hasCharges =
            state.status == StudentChargesStatus.success &&
            state.studentCharges.isNotEmpty;
        if (!hasCharges) {
          return const SizedBox.shrink();
        }

        // Solde = somme des restes COMPOSÉS (FRONT §5) : le miroir serveur seul
        // ferait réapparaître un poste soldé localement comme dû.
        final remaining = state.studentCharges.fold<double>(
          0.0,
          (sum, charge) => sum + charge.remainingInCents,
        );
        final hasBalance = remaining > 0;
        final amount = formatMonetaryAmountWithCurrency(
          amount: remaining / 100,
          currency: state.studentCharges.first.currency,
        );

        return FacturationBalancePill(
          hasBalance: hasBalance,
          label: hasBalance
              ? l10n.facturationBalanceDuePill(amount)
              : l10n.facturationBalanceUpToDatePill,
        );
      },
    );
  }
}
