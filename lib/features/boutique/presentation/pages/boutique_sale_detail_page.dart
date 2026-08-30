import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/sale_detail_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_money_format.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_print_flow.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_sale_detail_lines.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_top_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fiche d'une vente déjà encaissée, ouverte depuis l'historique.
///
/// **Elle ne modifie rien.** Une vente encaissée est figée (I-6) ; ce qu'on peut
/// encore en faire, c'est en ressortir la preuve : le ticket thermique, que la
/// tablette compose seule, et le reçu scellé, que le serveur a produit.
///
/// Les deux ne se valent pas et ne se remplacent pas — le ticket est remis au
/// comptoir, le reçu fait quittance — donc les deux boutons coexistent.
class BoutiqueSaleDetailPage extends StatelessWidget {
  final String saleId;

  /// Libellés des niveaux, pour le ticket : une ligne walk-in porte un niveau
  /// déclaré, et l'imprimer par son identifiant ne dirait rien à personne.
  final Map<String, String> levelLabels;

  const BoutiqueSaleDetailPage({
    super.key,
    required this.saleId,
    required this.levelLabels,
  });

  /// Ouvre la fiche. Rend quand elle se referme.
  static Future<void> push(
    BuildContext context, {
    required String saleId,
    required Map<String, String> levelLabels,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          BoutiqueSaleDetailPage(saleId: saleId, levelLabels: levelLabels),
    ),
  );

  @override
  Widget build(BuildContext context) => BlocProvider<SaleDetailCubit>(
    create: (_) => SaleDetailCubit(
      getDetail: getIt<GetBoutiqueSaleDetailUseCase>(),
      markPrinted: getIt<MarkSaleTicketPrintedUseCase>(),
      saleId: saleId,
    )..load(),
    child: _SaleDetailView(levelLabels: levelLabels),
  );
}

class _SaleDetailView extends StatefulWidget {
  final Map<String, String> levelLabels;

  const _SaleDetailView({required this.levelLabels});

  @override
  State<_SaleDetailView> createState() => _SaleDetailViewState();
}

class _SaleDetailViewState extends State<_SaleDetailView> {
  /// Vrai pendant l'envoi à l'imprimante — le bouton se neutralise plutôt que
  /// de laisser empiler deux envois vers la même machine.
  bool _isPrinting = false;

  /// Réimprime le ticket, et ne note la trace **que si le papier est sorti**.
  ///
  /// Marquer un envoi annulé ferait afficher « déjà imprimé » sur un ticket que
  /// personne n'a en main.
  Future<void> _printTicket(SaleDetail detail) async {
    final cubit = context.read<SaleDetailCubit>();
    setState(() => _isPrinting = true);
    try {
      final printed = await printSaleTicket(
        context,
        sale: detail.sale,
        levelLabels: widget.levelLabels,
        messenger: ScaffoldMessenger.maybeOf(context),
      );
      if (printed) await cubit.ticketPrinted();
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// Ouvre le reçu scellé : la copie locale d'abord, le re-téléchargement
  /// ensuite (ADR-012 D-1). Rien n'est émis, aucun numéro n'est consommé.
  Future<void> _openReceipt(SaleDetail detail) => showEditiqueRestitutionDialog(
    context,
    type: EditiqueDocumentType.saleReceipt,
    title: AppLocalizations.of(context)!.boutiqueSaleDetailReceiptTitle,
    documentId: detail.sale.sale.receiptDocumentId,
    documentNumber: detail.sale.sale.receiptNumber,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SaleDetailCubit, SaleDetailState>(
      builder: (context, state) {
        final detail = state.detail;

        return AppPageBackground(
          appBar: BoutiqueTopBar(
            eyebrow: l10n.boutiqueSaleDetailEyebrow,
            title: detail == null
                ? l10n.boutiqueSaleDetailTitle
                : _referenceOf(detail, l10n),
            onBack: () => Navigator.of(context).maybePop(),
            backTooltip: l10n.boutiqueSaleDetailBack,
          ),
          child: switch (state.status) {
            SaleDetailStatus.initial ||
            SaleDetailStatus.loading => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            ),
            // Une vente ouverte depuis la liste existe. Si elle a disparu,
            // l'écran le DIT : une fiche vide ferait croire à une vente sans
            // article.
            // ⚠️ La disparition d'une vente n'est PAS une panne de lecture :
            // « historique illisible » ferait réessayer indéfiniment une
            // lecture qui répond correctement qu'il n'y a rien.
            SaleDetailStatus.failure when state.failure is NotFoundFailure =>
              EteeloEmptyResult(
                label: l10n.boutiqueSaleDetailNotFoundTitle,
                description: l10n.boutiqueSaleDetailNotFound,
                medallionIcon: Icons.search_off_rounded,
              ),
            SaleDetailStatus.failure => BoutiqueResultsErrorState(
              failure: state.failure!,
              surface: BoutiqueErrorSurface.history,
              onRetry: () => context.read<SaleDetailCubit>().load(),
            ),
            SaleDetailStatus.ready => _Body(
              detail: detail!,
              isPrinting: _isPrinting,
              onPrintTicket: () => _printTicket(detail),
              onOpenReceipt: () => _openReceipt(detail),
            ),
          },
        );
      },
    );
  }

  /// Le numéro scellé s'il existe, sinon la référence provisoire — jamais un
  /// blanc : c'est ce que le parent lit sur son papier, et donc ce par quoi il
  /// désigne sa vente au comptoir.
  static String _referenceOf(SaleDetail detail, AppLocalizations l10n) =>
      detail.sale.sale.receiptNumber ??
      ProvisionalSaleReference.of(detail.sale.id);
}

class _Body extends StatelessWidget {
  final SaleDetail detail;
  final bool isPrinting;
  final VoidCallback onPrintTicket;
  final VoidCallback onOpenReceipt;

  const _Body({
    required this.detail,
    required this.isPrinting,
    required this.onPrintTicket,
    required this.onOpenReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sale = detail.sale.sale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AmountBanner(detail: detail),
        const SizedBox(height: AppDimensions.spacingM),
        if (sale.syncStatus == 'PENDING_SYNC') ...[
          _Notice(
            icon: Icons.cloud_upload_outlined,
            color: AppColors.warning,
            text: l10n.boutiqueSaleDetailPendingNotice,
          ),
          const SizedBox(height: AppDimensions.spacingM),
        ],
        _Card(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.person_outline_rounded,
                label: l10n.boutiqueSaleDetailPayer,
                value: _payerNameOf(detail),
              ),
              if ((sale.payerPhoneNumber ?? '').trim().isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: l10n.boutiqueSaleDetailPhone,
                  value: sale.payerPhoneNumber!,
                ),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: l10n.boutiqueSaleDetailSoldAt,
                value: _dateTimeOf(sale.soldAt),
              ),
              // « Encaissé par » : sur une caisse tenue à plusieurs, c'est la
              // seule ligne qui dit QUI a pris l'argent. Le nom vient du
              // serveur ou de la session au moment de la vente — jamais de
              // l'utilisateur courant, qui n'est pas forcément le même.
              _InfoRow(
                icon: Icons.badge_outlined,
                label: l10n.boutiqueSaleDetailCollectedBy,
                value: (sale.collectedByName ?? '').trim().isEmpty
                    ? l10n.boutiqueSaleDetailCollectedByUnknown
                    : sale.collectedByName!,
                muted: (sale.collectedByName ?? '').trim().isEmpty,
              ),
              _InfoRow(
                icon: Icons.receipt_long_outlined,
                label: l10n.boutiqueSaleDetailReceipt,
                value:
                    sale.receiptNumber ??
                    ProvisionalSaleReference.of(detail.sale.id),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        _SectionTitle(label: l10n.boutiqueSaleDetailLines),
        const SizedBox(height: AppDimensions.spacingS),
        _Card(
          padding: EdgeInsets.zero,
          child: BoutiqueSaleDetailLines(
            lines: detail.sale.lines,
            currency: sale.currency,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _Actions(
          detail: detail,
          isPrinting: isPrinting,
          onPrintTicket: onPrintTicket,
          onOpenReceipt: onOpenReceipt,
        ),
        const SizedBox(height: AppDimensions.spacingXL),
      ],
    );
  }

  /// Le nom composé rendu par le serveur en priorité ; à défaut, les champs
  /// saisis dans l'ordre où le guichet les a remplis.
  static String _payerNameOf(SaleDetail detail) {
    final sale = detail.sale.sale;
    final composed = sale.payerName;
    if (composed != null && composed.trim().isNotEmpty) return composed;
    return [
      sale.payerLastName,
      sale.payerMiddleName ?? '',
      sale.payerFirstName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ');
  }

  /// `sold_at` est en UTC : l'afficher tel quel décalerait la vente au guichet.
  static String _dateTimeOf(String soldAt) {
    final parsed = DateTime.tryParse(soldAt);
    if (parsed == null) return soldAt;
    return formatLocalDateTime(parsed);
  }
}

/// `JJ/MM/AAAA à HH:MM`, en heure locale. Partagé avec la mention d'impression.
String formatLocalDateTime(DateTime instant) {
  final local = instant.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Le montant, en Bleu Profond texturé — le même bandeau que le total du panier
/// et que la confirmation : c'est le même chiffre, d'un écran à l'autre.
class _AmountBanner extends StatelessWidget {
  final SaleDetail detail;

  const _AmountBanner({required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sale = detail.sale.sale;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingL),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.boutiqueTotalLabel.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.orDoux,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        BoutiqueMoneyFormat.exact(
                          sale.totalInCents,
                          sale.currency,
                        ),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDark,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.boutiqueHistoryArticleCount(
                          detail.sale.articleCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.storefront_outlined,
                  size: 40,
                  color: AppColors.textOnDark.withValues(alpha: 0.18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final SaleDetail detail;
  final bool isPrinting;
  final VoidCallback onPrintTicket;
  final VoidCallback onOpenReceipt;

  const _Actions({
    required this.detail,
    required this.isPrinting,
    required this.onPrintTicket,
    required this.onOpenReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isPrinting ? null : onPrintTicket,
          icon: isPrinting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined, size: 20),
          // Le libellé dit LEQUEL des deux gestes on fait : sortir un ticket
          // qui n'existe pas encore, ou en refaire un.
          label: Text(
            detail.ticketWasPrinted
                ? l10n.boutiqueSaleDetailReprintTicket
                : l10n.boutiqueSaleDetailPrintTicket,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.terreCuite,
            // ⚠️ Sans `minimumSize`, un bouton inline hérite du thème
            // plein-largeur et lève en contrainte infinie.
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          detail.ticketPrintedAt == null
              ? l10n.boutiqueSaleDetailTicketNeverPrinted
              : l10n.boutiqueSaleDetailTicketPrintedAt(
                  formatLocalDateTime(detail.ticketPrintedAt!),
                ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Le reçu scellé n'existe que si le serveur l'a produit. Offrir le
        // bouton avant ferait ouvrir une pièce introuvable : la phrase dit ce
        // qu'on attend, et quand.
        if (detail.hasSealedReceipt)
          OutlinedButton.icon(
            onPressed: onOpenReceipt,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: Text(l10n.boutiqueSaleDetailOpenReceipt),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          )
        else
          _Notice(
            icon: Icons.schedule_outlined,
            color: AppColors.textMuted,
            text: l10n.boutiqueSaleDetailReceiptPending,
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimensions.spacingM),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.24)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingM,
      vertical: AppDimensions.spacingS,
    ),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textMuted,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
                color: muted ? AppColors.textMuted : AppColors.bleuProfond,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
