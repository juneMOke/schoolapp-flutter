import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_detail_beneficiaries.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_detail_lines.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/sale_detail/boutique_sale_amount_banner.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/sale_detail/boutique_sale_detail_actions.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/sale_detail/boutique_sale_detail_parts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le corps de la fiche d'une vente : qui, quand, quoi, puis le montant et
/// les gestes — en deux colonnes dès que la largeur le permet.
class BoutiqueSaleDetailBody extends StatelessWidget {
  final SaleDetail detail;
  final bool isPrinting;
  final bool isClaiming;
  final VoidCallback onPrintTicket;
  final VoidCallback onOpenReceipt;
  final VoidCallback onClaimReceipt;

  const BoutiqueSaleDetailBody({
    super.key,
    required this.detail,
    required this.isPrinting,
    required this.isClaiming,
    required this.onPrintTicket,
    required this.onOpenReceipt,
    required this.onClaimReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sale = detail.sale.sale;
    final payerName = _payerNameOf(detail);

    final banner = BoutiqueSaleAmountBanner(detail: detail);
    final pending = sale.syncStatus == 'PENDING_SYNC'
        ? BoutiqueSaleNotice(
            icon: Icons.cloud_upload_outlined,
            color: AppColors.warningInk,
            text: l10n.boutiqueSaleDetailPendingNotice,
          )
        : null;
    final info = BoutiqueSaleCard(
      child: Column(
        children: [
          // La ligne RESTE, même anonyme : on a ouvert ce détail POUR
          // savoir, et une ligne absente laisserait croire à un oubli
          // d'affichage. Le ticket, lui, escamote son bloc — une pièce
          // remise au client et un écran de consultation n'ont pas le même
          // lecteur ni le même enjeu.
          BoutiqueSaleInfoRow(
            icon: Icons.person_outline_rounded,
            label: l10n.boutiqueSaleDetailPayer,
            value: payerName.isEmpty
                ? l10n.boutiqueHistoryPayerUnknown
                : payerName,
            muted: payerName.isEmpty,
          ),
          if ((sale.payerPhoneNumber ?? '').trim().isNotEmpty)
            BoutiqueSaleInfoRow(
              icon: Icons.phone_outlined,
              label: l10n.boutiqueSaleDetailPhone,
              value: sale.payerPhoneNumber!,
            ),
          BoutiqueSaleInfoRow(
            icon: Icons.schedule_outlined,
            label: l10n.boutiqueSaleDetailSoldAt,
            value: _dateTimeOf(sale.soldAt),
          ),
          // « Encaissé par » : sur une caisse tenue à plusieurs, c'est la
          // seule ligne qui dit QUI a pris l'argent. Le nom vient du
          // serveur ou de la session au moment de la vente — jamais de
          // l'utilisateur courant, qui n'est pas forcément le même.
          BoutiqueSaleInfoRow(
            icon: Icons.badge_outlined,
            label: l10n.boutiqueSaleDetailCollectedBy,
            value: (sale.collectedByName ?? '').trim().isEmpty
                ? l10n.boutiqueSaleDetailCollectedByUnknown
                : sale.collectedByName!,
            muted: (sale.collectedByName ?? '').trim().isEmpty,
          ),
          BoutiqueSaleInfoRow(
            icon: Icons.receipt_long_outlined,
            label: l10n.boutiqueSaleDetailReceipt,
            value:
                sale.receiptNumber ??
                ProvisionalSaleReference.of(detail.sale.id),
          ),
        ],
      ),
    );
    // Absente d'une vente sans élève : une section vide ne dirait rien que
    // la liste des articles ne dise déjà.
    final students = detail.beneficiaries.isEmpty
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoutiqueSaleSectionTitle(label: l10n.boutiqueSaleDetailStudents),
              const SizedBox(height: AppDimensions.spacingS),
              BoutiqueSaleCard(
                padding: EdgeInsets.zero,
                child: BoutiqueSaleDetailBeneficiaries(
                  beneficiaries: detail.beneficiaries,
                ),
              ),
            ],
          );
    final lines = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BoutiqueSaleSectionTitle(label: l10n.boutiqueSaleDetailLines),
        const SizedBox(height: AppDimensions.spacingS),
        BoutiqueSaleCard(
          padding: EdgeInsets.zero,
          child: BoutiqueSaleDetailLines(lines: detail.sale.lines),
        ),
      ],
    );
    final actions = BoutiqueSaleDetailActions(
      detail: detail,
      isPrinting: isPrinting,
      isClaiming: isClaiming,
      onPrintTicket: onPrintTicket,
      onOpenReceipt: onOpenReceipt,
      onClaimReceipt: onClaimReceipt,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Grand écran : la vente à gauche (qui, quand, quoi), le montant et
        // les gestes à droite. En une colonne de 1180, chaque libellé
        // finissait à 1100 dp de sa valeur et les boutons s'étiraient.
        if (constraints.maxWidth >= AppBreakpoints.financeDetailTwoColMin) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacingXL),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      info,
                      const SizedBox(height: AppDimensions.spacingM),
                      if (students != null) ...[
                        students,
                        const SizedBox(height: AppDimensions.spacingM),
                      ],
                      lines,
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingL),
                SizedBox(
                  width: AppDimensions.saleDetailSideColumnWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      banner,
                      if (pending != null) ...[
                        const SizedBox(height: AppDimensions.spacingM),
                        pending,
                      ],
                      const SizedBox(height: AppDimensions.spacingL),
                      actions,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            banner,
            const SizedBox(height: AppDimensions.spacingM),
            if (pending != null) ...[
              pending,
              const SizedBox(height: AppDimensions.spacingM),
            ],
            info,
            const SizedBox(height: AppDimensions.spacingM),
            if (students != null) ...[
              students,
              const SizedBox(height: AppDimensions.spacingM),
            ],
            lines,
            const SizedBox(height: AppDimensions.spacingL),
            actions,
            const SizedBox(height: AppDimensions.spacingXL),
          ],
        );
      },
    );
  }

  /// Le nom composé rendu par le serveur en priorité ; à défaut, les champs
  /// saisis dans l'ordre où le guichet les a remplis. Vide si la vente est
  /// anonyme — c'est l'appelant qui décide quoi en dire.
  static String _payerNameOf(SaleDetail detail) {
    final sale = detail.sale.sale;
    final composed = sale.payerName;
    if (composed != null && composed.trim().isNotEmpty) return composed;
    return [
      sale.payerLastName ?? '',
      sale.payerMiddleName ?? '',
      sale.payerFirstName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  /// `sold_at` est en UTC : il se lit à l'heure de l'école, comme le ticket
  /// et le tableau de bord — pas à celle du poste.
  static String _dateTimeOf(String soldAt) {
    final parsed = DateTime.tryParse(soldAt);
    if (parsed == null) return soldAt;
    return formatSchoolDateTime(parsed);
  }
}
