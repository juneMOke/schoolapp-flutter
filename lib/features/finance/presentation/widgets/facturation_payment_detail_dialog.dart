import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_receipt_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_allocations_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre le détail d'un paiement en popin (spec §15).
Future<void> showFacturationPaymentDetailDialog(
  BuildContext context, {
  required FacturationPaymentDetailIntent intent,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<PaymentsBloc>(
          create: (_) {
            final bloc = getIt<PaymentsBloc>();
            if (intent.paymentId.trim().isNotEmpty) {
              bloc.add(
                PaymentsAllocationsRequested(paymentId: intent.paymentId),
              );
            }
            return bloc;
          },
        ),
        // Numéro de pièce lu en local (table `generated_documents`) : le
        // serveur ne l'expose sur aucune lecture REST, seule la synchro l'a
        // scellé. Aucun téléchargement n'est nécessaire pour l'afficher.
        BlocProvider<PaymentReceiptCubit>(
          create: (_) => getIt<PaymentReceiptCubit>()..load(intent.paymentId),
        ),
      ],
      child: BlocBuilder<PaymentReceiptCubit, PaymentReceiptState>(
        builder: (_, receipt) => FacturationPaymentDetailDialogView(
          intent: intent,
          allocations: FacturationPaymentAllocationsSection(
            paymentId: intent.paymentId,
            currency: intent.currency,
          ),
          receiptNumber: receipt.hasDefinitiveNumber ? receipt.number : null,
          receiptPending: intent.isPendingSync || receipt.hasProvisionalNumber,
          // Deux gestes derrière un même bouton, et c'est la présence d'une
          // copie locale qui tranche — pas la connectivité.
          //
          // Copie locale : on la ressort telle quelle, ce qui fonctionne hors
          // ligne. Sinon, le reçu est produit par le serveur à partir de
          // l'identifiant du paiement, et n'est donc demandable que pour un
          // encaissement déjà remonté — sans quoi l'uuid client donnerait un
          // 404.
          onDownloadReceipt: switch (receipt.cached) {
            final EditiqueCacheEntry cached =>
              () => showEditiqueRestitutionDialog(
                context,
                type: EditiqueDocumentType.paymentReceipt,
                title: AppLocalizations.of(context)!.editiqueViewerReceiptTitle,
                documentId: cached.documentId,
                documentNumber: cached.documentNumber,
              ),
            _ =>
              intent.isPendingSync
                  ? null
                  : () => showEditiquePaymentReceiptDialog(
                      context,
                      paymentId: intent.paymentId,
                    ),
          },
        ),
      ),
    ),
  );
}

/// Contenu visuel (pur, sans BLoC) de la popin de détail d'un paiement.
class FacturationPaymentDetailDialogView extends StatelessWidget {
  final FacturationPaymentDetailIntent intent;
  final Widget allocations;

  /// Numéro **définitif** de la pièce, ou `null` s'il n'est pas connu.
  ///
  /// Ne transite jamais un `PROV-…` : un numéro provisoire n'est pas un numéro
  /// de pièce, il se signale par [receiptPending].
  final String? receiptNumber;

  /// La pièce existe mais son numéro n'est pas encore scellé par le serveur.
  final bool receiptPending;

  /// `null` désactive le téléchargement — cas d'un encaissement pas encore
  /// remonté, dont l'identifiant est inconnu du serveur.
  final VoidCallback? onDownloadReceipt;

  const FacturationPaymentDetailDialogView({
    super.key,
    required this.intent,
    required this.allocations,
    this.receiptNumber,
    this.receiptPending = false,
    this.onDownloadReceipt,
  });

  String _payerFullName(AppLocalizations l10n) {
    final fullName = [
      intent.payerLastName,
      intent.payerMiddleName ?? '',
      intent.payerFirstName,
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  /// Numéro de pièce affichable, ou un libellé neutre.
  ///
  /// Trois cas : numéro définitif scellé par la synchro → affiché tel quel ;
  /// pièce en attente de scellement → mention d'attente, car un `PROV-…` n'est
  /// pas un numéro de pièce officiel ; rien de connu → chaîne vide, comme
  /// avant (le rendu clé/valeur affiche alors un tiret).
  String _receiptNumberValue(AppLocalizations l10n) {
    final number = receiptNumber?.trim();
    if (number != null && number.isNotEmpty) return number;
    if (receiptPending) return l10n.facturationPaymentReceiptNumberPending;
    return '';
  }

  String _studentFullName(AppLocalizations l10n) {
    final fullName = [
      intent.lastName,
      intent.surname,
      intent.firstName,
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return fullName.isEmpty ? l10n.facturationDetailUnknownValue : fullName;
  }

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final amount = formatMonetaryAmountWithCurrency(
      amount: intent.amountInCents / 100,
      currency: intent.currency,
    );
    final date = MaterialLocalizations.of(
      context,
    ).formatFullDate(intent.paidAt);

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.facturationModalMaxWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FinanceModalDarkHeader(
              eyebrow: l10n.facturationPaymentDetailHeroTitle,
              title: amount,
              onClose: () => _close(context),
            ),
            const FinanceModalGoldDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PayerBlock(
                      payerLabel: l10n.facturationPaymentPayerLabel,
                      payerName: _payerFullName(l10n),
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    FinanceKeyValueRows(
                      rows: [
                        FinanceKeyValueRow(
                          icon: Icons.payments_outlined,
                          label: l10n.facturationPaymentAmountPaidLabel,
                          value: amount,
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.facturationPaymentPaidAtLabel,
                          value: date,
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: l10n.facturationPaymentMethodLabel,
                          value: l10n.facturationPaymentMethodCash,
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.person_outline_rounded,
                          label: l10n.facturationPaymentCollectedByLabel,
                          value: '',
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.school_outlined,
                          label: l10n.facturationPaymentStudentLabel,
                          value: _studentFullName(l10n),
                        ),
                        FinanceKeyValueRow(
                          icon: Icons.receipt_long_outlined,
                          label: l10n.facturationPaymentReceiptLabel,
                          value: _receiptNumberValue(l10n),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    allocations,
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            FinanceModalFooter(
              secondaryLabel: l10n.facturationPaymentDownloadReceiptLabel,
              secondaryIcon: Icons.download_outlined,
              onSecondary: onDownloadReceipt,
              secondaryHint: l10n.facturationPaymentReceiptPendingSyncHint,
              primaryLabel: l10n.facturationPaymentCloseLabel,
              primaryIcon: Icons.check_rounded,
              onPrimary: () => _close(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloc payeur : médaillon billet vert + « Payeur » + nom complet.
class _PayerBlock extends StatelessWidget {
  final String payerLabel;
  final String payerName;

  const _PayerBlock({required this.payerLabel, required this.payerName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.billingPaymentMedallionSoft,
            borderRadius: AppRadius.brMd,
          ),
          child: const Icon(
            Icons.payments_outlined,
            size: 20,
            color: AppColors.feeStatusPaid,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payerLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                payerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
