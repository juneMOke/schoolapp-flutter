import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_receipt_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_modal_parts.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payment_allocations_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ticket_print_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que « Télécharger le reçu » fait réellement quand on appuie dessus.
///
/// Deux gestes derrière un même bouton, et ils n'ont pas du tout le même poids —
/// d'où ce type, et d'où le fait que la décision soit une fonction pure
/// éprouvable plutôt qu'une clause noyée dans un arbre de widgets.
enum FacturationReceiptGesture {
  /// **Lecture.** La copie locale si elle est là — ce qui fonctionne hors
  /// ligne —, sinon un `GET` qui rend exactement cette pièce-là. Rien n'est
  /// écrit, aucun numéro n'est consommé.
  restitute,

  /// **Écriture.** Le serveur produit le reçu à partir de l'identifiant du
  /// paiement. Sur un reçu annulé, cela rescelle son instantané, consomme un
  /// numéro d'une séquence auditée sans trou et repointe `payment.receiptId`.
  emit,

  /// Rien à offrir : l'encaissement n'est pas remonté, son uuid est client.
  none,
}

/// Décide du geste, sur l'**adressabilité** de la pièce — jamais sur ses octets.
///
/// C'est tout l'objet de cette fonction, et une revue adversariale a montré ce
/// que coûtait l'autre garde. Une pièce annulée dont l'éviction a emporté les
/// octets reste parfaitement lisible : la route de téléchargement du serveur ne
/// filtre PAS l'annulation (`DocumentStoreService.getArchived` charge par
/// identifiant ; le filtre d'annulation vit sur `EditiquePortImpl
/// .findDocumentById`, qui est un autre chemin). Garder sur « a-t-on les
/// octets ? » retombait donc sur l'ÉMISSION pour une pièce que le serveur
/// rendait gratuitement — et un reçu retiré pour erreur de montant redevenait
/// le reçu officiel du versement, avec le même montant erroné.
///
/// L'identifiant d'archive, lui, survit à l'éviction : `downgradeToKnown` ne
/// remet à null que l'empreinte et le poids.
///
/// [FacturationReceiptGesture.restitute] exige `documentId` et non
/// [EditiqueCacheEntry.isAddressable] : le serveur n'expose aucune recherche
/// par numéro, et la restitution rend `NotFoundFailure` sans identifiant. Un
/// numéro seul ne désigne rien.
/// [canEmit] porte la permission `editique.write` (ADR-014). La RESTITUTION
/// d'une copie déjà émise n'écrit rien, ne consomme aucun numéro et reste donc
/// ouverte à qui a ouvert la fiche ; c'est la PRODUCTION d'une pièce neuve qui
/// est gardée — même partage que le catalogue Documents.
@visibleForTesting
FacturationReceiptGesture facturationReceiptGesture({
  required EditiqueCacheEntry? cached,
  required bool isPendingSync,
  bool canEmit = true,
}) {
  if (cached?.documentId?.isNotEmpty ?? false) {
    return FacturationReceiptGesture.restitute;
  }
  if (isPendingSync || !canEmit) return FacturationReceiptGesture.none;
  return FacturationReceiptGesture.emit;
}

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
        // Le versement attend-il encore son premier papier ? Lu une fois à
        // l'ouverture ; la ligne se retire d'elle-même dès qu'un tirage sort.
        BlocProvider<TicketPrintStatusCubit>(
          create: (_) =>
              getIt<TicketPrintStatusCubit>()..load(intent.paymentId),
        ),
      ],
      child: BlocBuilder<PaymentReceiptCubit, PaymentReceiptState>(
        builder: (_, receipt) => BlocBuilder<TicketPrintStatusCubit, TicketPrintStatusState>(
          builder: (_, ticket) => FacturationPaymentDetailDialogView(
            intent: intent,
            allocations: FacturationPaymentAllocationsSection(
              paymentId: intent.paymentId,
            ),
            receiptNumber: receipt.hasDefinitiveNumber ? receipt.number : null,
            receiptPending:
                intent.isPendingSync || receipt.hasProvisionalNumber,
            receiptForbidden: !PermissionGate.allows(context, const [
              Perm.editiqueWrite,
            ]),
            // Le retrait se dit toujours, quel que soit le geste offert : c'est
            // ce que le guichet doit pouvoir expliquer à la famille qui présente
            // le papier.
            cancelledReceipt: receipt.cached?.isCancelled ?? false
                ? receipt.cached
                : null,
            // Le geste est décidé par `facturationReceiptGesture`, qui porte la
            // règle et son pourquoi. La copie annulée est bien servie (arbitrage
            // du 2026-08-06) : un guichet doit pouvoir remettre sous les yeux
            // d'une famille le papier qu'elle présente pour lui expliquer
            // pourquoi il n'a plus cours. La rature et le motif sont à l'écran,
            // la pièce ne trompe personne.
            onDownloadReceipt: switch (facturationReceiptGesture(
              cached: receipt.cached,
              isPendingSync: intent.isPendingSync,
              canEmit: PermissionGate.allows(context, const [
                Perm.editiqueWrite,
              ]),
            )) {
              FacturationReceiptGesture.restitute =>
                () => showEditiqueRestitutionDialog(
                  context,
                  type: EditiqueDocumentType.paymentReceipt,
                  title: AppLocalizations.of(
                    context,
                  )!.editiqueViewerReceiptTitle,
                  documentId: receipt.cached?.documentId,
                  documentNumber: receipt.cached?.documentNumber,
                ),
              FacturationReceiptGesture.emit =>
                () => showEditiquePaymentReceiptDialog(
                  context,
                  paymentId: intent.paymentId,
                ),
              FacturationReceiptGesture.none => null,
            },
            // Trois conditions, et la troisième est jugée ICI parce que seule la
            // modale connaît l'annulation : un reçu retiré ne doit jamais
            // ressortir sous forme de ticket.
            ticketPrint:
                ticket.awaitsPrint && !(receipt.cached?.isCancelled ?? false)
                ? FacturationTicketPrintRow(paymentId: intent.paymentId)
                : null,
          ),
        ),
      ),
    ),
  );
}

/// Contenu visuel (pur, sans BLoC) de la popin de détail d'un paiement.
class FacturationPaymentDetailDialogView extends StatelessWidget {
  final FacturationPaymentDetailIntent intent;
  final Widget allocations;

  /// Vrai si l'émission est refusée faute de `editique.write` (ADR-014). La
  /// vue ne décide pas du droit — elle en reçoit le verdict pour pouvoir
  /// nommer la bonne cause sous un bouton éteint.
  final bool receiptForbidden;

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

  /// Ligne de rattrapage d'impression, `null` quand le versement n'attend aucun
  /// papier : déjà servi, encaissé sur une autre tablette, ou reçu annulé.
  final Widget? ticketPrint;

  /// Reçu que l'établissement a **retiré**, `null` tant qu'il tient.
  ///
  /// Barre son numéro et porte le motif. Un numéro barré seul ne dirait pas
  /// grand-chose : c'est la phrase qui explique, la rature ne fait que la
  /// rendre impossible à manquer.
  final EditiqueCacheEntry? cancelledReceipt;

  const FacturationPaymentDetailDialogView({
    super.key,
    required this.intent,
    required this.allocations,
    this.receiptNumber,
    this.receiptPending = false,
    this.receiptForbidden = false,
    this.onDownloadReceipt,
    this.cancelledReceipt,
    this.ticketPrint,
  });

  /// Ce que l'établissement a retiré, et pourquoi quand il l'a dit.
  ///
  /// Le motif vient du serveur — texte libre saisi par un agent. Affiché tel
  /// quel, sans traduction ; son absence ne se comble pas.
  String? _cancellationNotice(BuildContext context, AppLocalizations l10n) {
    final cancelledAt = cancelledReceipt?.cancelledAt;
    if (cancelledAt == null) return null;

    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.fromMillisecondsSinceEpoch(cancelledAt));
    final reason = cancelledReceipt?.cancellationReason?.trim();

    return (reason == null || reason.isEmpty)
        ? l10n.facturationReceiptCancelledNotice(date)
        : l10n.facturationReceiptCancelledWithReasonNotice(date, reason);
  }

  String _payerFullName(AppLocalizations l10n) {
    final fullName = [
      intent.payerLastName ?? '',
      intent.payerMiddleName ?? '',
      intent.payerFirstName ?? '',
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return fullName.isEmpty ? l10n.facturationPaymentPayerUnnamed : fullName;
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
    // Deux devises se lisent côte à côte, jamais additionnées.
    final amount = intent.amounts.entries.map(MoneyFormat.format).join(' · ');
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
        // Coquille commune (B-9) : l'en-tête et le pied restent ancrés tant que
        // la hauteur offerte le permet, et rejoignent le défilement en dessous.
        // Cette modale n'a aucun champ, donc le clavier ne monte pas DEVANT
        // elle — mais elle peut s'ouvrir alors qu'il est déjà levé sur l'écran
        // du dessous, et c'est le seul scénario qui la faisait déborder.
        child: EteeloDialogBody(
          // En-tête sombre (~86) + liseré + filet + pied deux actions, qui
          // s'empile en colonne sous 420 dp de large.
          minPinnedHeight: 300,
          header: EteeloDialogDarkHeader(
            eyebrow: l10n.facturationPaymentDetailHeroTitle,
            title: amount,
            onClose: () => _close(context),
          ),
          headerDividers: const [EteeloDialogGoldDivider()],
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingM),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PayerBlock(
                payerLabel: l10n.facturationPaymentPayerLabel,
                payerName: _payerFullName(l10n),
                // Repli explicite plutôt qu'une ligne absente : on a ouvert
                // cette modale POUR savoir. Le tiret dit « on ne sait pas »,
                // exactement comme les autres valeurs manquantes de l'écran.
                payerPhone: intent.payerPhoneNumber?.trim().isNotEmpty ?? false
                    ? intent.payerPhoneNumber!.trim()
                    : l10n.facturationDetailUnknownValue,
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
                    // Le nom stampé par le poste qui encaisse, ou à défaut
                    // celui que le serveur attribue (v29 — le contrat de
                    // synchro le transporte désormais, ce qui laissait
                    // jusqu'ici cette ligne vide pour tout versement venu
                    // d'un autre guichet). Tiret si personne ne l'a nommé,
                    // comme les autres champs inconnus de cette modale.
                    value: intent.cashierFullName ?? '',
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
                    isStruckThrough: cancelledReceipt != null,
                  ),
                ],
              ),
              if (_cancellationNotice(context, l10n) case final notice?)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.spacingS),
                  // Jamais la seule rature ni la seule couleur : l'icône
                  // et la phrase disent ce que le trait ne peut pas dire.
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      Expanded(
                        child: Text(
                          notice,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppDimensions.spacingM),
              allocations,
              // Rattrapage d'un ticket jamais sorti. Sous la répartition
              // parce qu'il porte sur le versement entier, et pas au pied
              // — un bouton qui n'apparaît que parfois ne dit pas
              // pourquoi il est là.
              ?ticketPrint,
            ],
          ),
          footer: [
            const Divider(height: 1, color: AppColors.border),
            FinanceModalFooter(
              secondaryLabel: l10n.facturationPaymentDownloadReceiptLabel,
              secondaryIcon: Icons.download_outlined,
              onSecondary: onDownloadReceipt,
              // Le motif doit correspondre au refus, et un bouton éteint sans
              // explication n'en est pas un meilleur qu'un motif faux : les
              // deux causes ont chacune leur phrase, dans l'ordre où elles se
              // lèvent (une pièce en attente le reste, droits ou pas).
              secondaryHint: receiptPending
                  ? l10n.facturationPaymentReceiptPendingSyncHint
                  : receiptForbidden && onDownloadReceipt == null
                  ? l10n.facturationPaymentReceiptForbiddenHint
                  : null,
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

/// Bloc payeur : médaillon billet vert + « Payeur » + nom complet + numéro.
class _PayerBlock extends StatelessWidget {
  final String payerLabel;
  final String payerName;

  /// Déjà replié par l'appelant — la valeur « inconnue » se dit, elle ne se
  /// tait pas : sur un écran de détail, une ligne absente se lit comme un
  /// défaut d'affichage.
  final String payerPhone;

  const _PayerBlock({
    required this.payerLabel,
    required this.payerName,
    required this.payerPhone,
  });

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
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Flexible(
                    child: Text(
                      payerPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
