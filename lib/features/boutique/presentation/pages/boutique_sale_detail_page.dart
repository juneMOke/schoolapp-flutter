import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/provisional_sale_reference.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_detail.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/claim_sale_receipt_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/sale_detail_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/ticket/sale_ticket_print_flow.dart';
import 'package:school_app_flutter/core/components/app_bars/module_top_bar.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/sale_detail/boutique_sale_detail_body.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La fiche d'une vente déjà encaissée, ouverte depuis « Ventes de la
/// période » du tableau de bord. Elle a son adresse,
/// `/home/boutique-tableau-de-bord/vente/{saleId}` : F5 la rouvre par son seul
/// identifiant (cf. `BoutiqueSaleRoutes`).
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

  @override
  Widget build(BuildContext context) => BlocProvider<SaleDetailCubit>(
    create: (_) => SaleDetailCubit(
      getDetail: getIt<GetBoutiqueSaleDetailUseCase>(),
      markPrinted: getIt<MarkSaleTicketPrintedUseCase>(),
      claimReceipt: getIt<ClaimSaleReceiptUseCase>(),
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

  /// Vrai pendant la réclamation du reçu, pour la même raison : deux demandes
  /// pour la même pièce ne serviraient à rien.
  bool _isClaiming = false;

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

  /// Ouvre le reçu scellé par **restitution** : rien n'est émis, aucun numéro
  /// n'est consommé.
  ///
  /// ⚠️ **Et jamais depuis une copie locale**, contrairement à ce que cette
  /// ligne annonçait : le `RV` est absent de `cacheableDocTypes` **et** du
  /// `CHECK` SQL du cache, donc la lecture locale rend toujours `null` et la
  /// mise en cache est neutralisée. Chaque ouverture est un `GET` réseau.
  /// Écart assumé : ouvrir le cache au RV coûterait une reconstruction de table
  /// (SQLite ne sait pas ajouter un `CHECK` par `ALTER`) et y déposerait le
  /// payeur, son téléphone, les prénoms des enfants et les prix.
  Future<void> _openReceipt(SaleDetail detail) => showEditiqueRestitutionDialog(
    context,
    type: EditiqueDocumentType.saleReceipt,
    title: AppLocalizations.of(context)!.boutiqueSaleDetailReceiptTitle,
    documentId: detail.sale.sale.receiptDocumentId,
    documentNumber: detail.sale.sale.receiptNumber,
  );

  /// Réclame au serveur la pièce que son scellement *best-effort* n'a pas
  /// rendue, puis la **montre**.
  ///
  /// Les octets arrivent avec la réponse : on les affiche directement plutôt que
  /// de repasser par la restitution, qui re-téléchargerait la pièce qui vient
  /// d'arriver — le `RV` n'étant pas mis en cache, ce serait un second appel
  /// réseau pour le même PDF.
  ///
  /// La relecture de la fiche est faite par le cubit : c'est elle qui fait
  /// disparaître la référence `PROV-` de la ligne « Reçu », du titre, et de tout
  /// ticket réimprimé ensuite.
  Future<void> _claimReceipt() async {
    final cubit = context.read<SaleDetailCubit>();
    // Tout ce qui vient du contexte est prélevé AVANT l'attente : la demande
    // dure, et le messager doit survivre à ce qui se ferme entre-temps.
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final title = l10n.boutiqueSaleDetailReceiptTitle;
    final failedNotice = l10n.boutiqueSaleDetailClaimReceiptFailed;

    setState(() => _isClaiming = true);
    final outcome = await cubit.claimReceipt();
    if (!mounted) return;
    setState(() => _isClaiming = false);

    await outcome.fold<Future<void>>(
      // La vente est encaissée et le ticket fait foi : l'échec ne coûte que du
      // papier, et la réclamation se refait sans risque — la route est
      // idempotente sous verrou.
      (_) async =>
          messenger?.showSnackBar(SnackBar(content: Text(failedNotice))),
      (document) async {
        if (!context.mounted) return;
        await showEteeloDocumentViewer(
          context,
          title: title,
          document: PrintableDocument(
            bytes: document.bytes,
            fileName: document.fileName,
            reference: document.documentNumber,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<SaleDetailCubit, SaleDetailState>(
      builder: (context, state) {
        final detail = state.detail;

        final title = detail == null
            ? l10n.boutiqueSaleDetailTitle
            : _referenceOf(detail, l10n);
        final content = switch (state.status) {
          SaleDetailStatus.initial || SaleDetailStatus.loading => const Padding(
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
            surface: BoutiqueErrorSurface.localSales,
            onRetry: () => context.read<SaleDetailCubit>().load(),
          ),
          SaleDetailStatus.ready => BoutiqueSaleDetailBody(
            detail: detail!,
            isPrinting: _isPrinting,
            isClaiming: _isClaiming,
            onPrintTicket: () => _printTicket(detail),
            onOpenReceipt: () => _openReceipt(detail),
            onClaimReceipt: _claimReceipt,
          ),
        };

        return AppPageBackground(
          // Référence de vente, montants : se copient à la souris.
          selectableText: true,
          appBar: ModuleTopBar(
            eyebrow: l10n.boutiqueSaleDetailEyebrow,
            title: title,
            onBack: () => Navigator.of(context).maybePop(),
            backTooltip: l10n.boutiqueSaleDetailBack,
          ),
          child: content,
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
