import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_pdf_preview.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre l'aperçu d'un document déjà produit : **on voit, puis on décide**.
///
/// C'est le geste que le module `documents` possédait seul et que toutes les
/// sorties papier partagent désormais — registre, rapport de caisse, liste de
/// relance, feuille d'appel, ticket. Le document arrive **composé** : cette
/// visionneuse ne produit rien, ne demande rien au serveur, et ne connaît
/// aucun domaine.
///
/// [onPrint] est le cœur de la généralisation. Par défaut le document part au
/// spouleur système ; les tickets, eux, passent leur propre flux — thermique
/// d'abord, PDF en filet — sans quoi les faire entrer dans l'aperçu casserait
/// la doctrine AM-11 (« le parent repart avec un papier »).
///
/// ⚠️ **Cette visionneuse ne passe PAS par `EteeloDialogBody`**, et ce n'est pas
/// un oubli : son corps n'est pas un document qui coule, c'est un aperçu qui
/// gère son propre défilement et exige une hauteur **bornée**. La disposition
/// défilante du socle lui offrirait une hauteur infinie — soit une exception de
/// layout, soit un défilement dans un défilement. Le clavier est abaissé à
/// l'ouverture : une pièce à lire n'a rien à saisir.
///
/// [previewBuilder] est la couture de test, et elle est exposée **ici aussi**
/// parce que c'est ce point d'entrée que les écrans empruntent : sans elle,
/// aucun test ne pourrait exercer le parcours réel — ouvrir, agir, refermer.
/// ⚠️ Le vrai aperçu interdit `pumpAndSettle` : son gabarit de chargement est
/// un shimmer qui ne s'arrête jamais.
Future<void> showEteeloDocumentViewer(
  BuildContext context, {
  required String title,
  required PrintableDocument document,
  Future<void> Function()? onPrint,
  bool canShare = true,
  bool closeAfterPrint = false,
  Widget Function(BuildContext context, PrintableDocument document)?
  previewBuilder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => EteeloDocumentViewerView(
      title: title,
      document: document,
      onPrint: onPrint,
      canShare: canShare,
      closeAfterPrint: closeAfterPrint,
      previewBuilder: previewBuilder,
    ),
  );
}

/// Contenu de la visionneuse : en-tête, aperçu, pied d'actions.
class EteeloDocumentViewerView extends StatelessWidget {
  /// Ce que le lecteur a sous les yeux (« Registre des inscrits »).
  final String title;

  final PrintableDocument document;

  /// Le geste d'impression. `null` ⇒ remise au spouleur système.
  final Future<void> Function()? onPrint;

  /// ⚠️ `Printing.sharePdf` écrit la pièce **en clair** dans le cache de
  /// l'application ; seule la fin de session l'efface (`SharedDocumentCache`).
  /// Le drapeau existe pour qu'un appelant puisse refuser ce dépôt.
  final bool canShare;

  /// Referme la visionneuse une fois l'impression rendue.
  ///
  /// Vrai pour un **ticket** : le papier est sorti, garder l'aperçu n'a plus
  /// d'objet — et surtout, un message d'échec rendu sous une modale est
  /// inatteignable. Faux pour un rapport, qu'on peut vouloir imprimer **puis**
  /// partager sans le rouvrir.
  final bool closeAfterPrint;

  /// Point d'injection de l'aperçu.
  ///
  /// [EteeloPdfPreview] rasterise par canal de plateforme et ne se monte pas en
  /// test widget : sans cette couture, aucun test ne pourrait exercer l'en-tête,
  /// le pied, ni l'échec d'une action.
  final Widget Function(BuildContext context, PrintableDocument document)?
  previewBuilder;

  const EteeloDocumentViewerView({
    super.key,
    required this.title,
    required this.document,
    this.onPrint,
    this.canShare = true,
    this.closeAfterPrint = false,
    this.previewBuilder,
  });

  void _close(BuildContext context) => Navigator.of(context).maybePop();

  Future<void> _print(BuildContext context) async {
    final print = onPrint;
    // Capturé AVANT l'await : l'impression peut durer — une trentaine de
    // secondes sur une thermique — et le contexte du dialogue a pu disparaître
    // entre-temps.
    final navigator = Navigator.of(context);

    await _runPlatformAction(
      context,
      print ??
          () => Printing.layoutPdf(
            onLayout: (_) => document.bytes,
            name: document.fileName,
          ),
    );

    // ⚠️ **La visionneuse s'efface, et c'est ce qui rend le message utilisable.**
    // Un SnackBar posé pendant qu'une modale est ouverte reste visible mais
    // INATTEIGNABLE : la barrière du dialogue avale les appuis, si bien que
    // l'action « Paramètres » d'une permission refusée ne se déclenche jamais.
    // Constaté par le test du flux ticket, pas supposé.
    if (closeAfterPrint) navigator.maybePop();
  }

  Future<void> _share(BuildContext context) {
    return _runPlatformAction(
      context,
      () =>
          Printing.sharePdf(bytes: document.bytes, filename: document.fileName),
    );
  }

  /// Exécute une action de plateforme en rendant son échec visible.
  ///
  /// Imprimer et partager passent par un canal natif qui peut ne pas répondre —
  /// binaire installé antérieur à la dépendance, ou plateforme sans service
  /// d'impression. Sans cette prise en charge, l'appui ne produit **rien du
  /// tout** : ni action, ni message, et l'exception part en erreur asynchrone
  /// non capturée.
  Future<void> _runPlatformAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    // Prélevé AVANT le premier `await` : l'action peut survivre à la modale —
    // un envoi thermique reste en vol une trentaine de secondes — et le
    // `ScaffoldMessenger` de l'application, lui, ne se démonte pas.
    final message = AppLocalizations.of(context)!.documentViewerActionFailed;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
    } catch (_) {
      // Le document est intact et toujours à l'écran : seul le geste a échoué.
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final preview = previewBuilder;

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.documentViewerMaxWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DocumentViewerHeader(
              title: title,
              subtitle: document.reference,
              onClose: () => _close(context),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: preview == null
                  ? EteeloPdfPreview(
                      bytes: document.bytes,
                      fileName: document.fileName,
                    )
                  : preview(context, document),
            ),
            const Divider(height: 1, color: AppColors.border),
            DocumentViewerFooter(
              canShare: canShare,
              onPrint: () => _print(context),
              onShare: () => _share(context),
              onClose: () => _close(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce qu'on regarde, et sous quelle référence.
class DocumentViewerHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  const DocumentViewerHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final reference = subtitle;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (reference != null && reference.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    reference,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

/// Imprimer · Partager · Fermer.
class DocumentViewerFooter extends StatelessWidget {
  final bool canShare;

  /// `null` **désarme** le bouton : c'est ce dont l'éditique a besoin tant que
  /// le serveur n'a pas rendu la pièce — imprimer ce qui n'est pas arrivé n'a
  /// pas de sens, et un bouton qui ne fait rien est pire qu'un bouton éteint.
  final VoidCallback? onPrint;
  final VoidCallback? onShare;
  final VoidCallback onClose;

  const DocumentViewerFooter({
    super.key,
    this.canShare = true,
    required this.onPrint,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppDimensions.spacingS,
        runSpacing: AppDimensions.spacingS,
        children: [
          // `fullWidth: false` obligatoire hors colonne : le thème rend les
          // boutons pleine largeur, ce qui casse une disposition en ligne.
          EteeloButton.secondary(
            label: l10n.documentViewerPrintLabel,
            icon: Icons.print_outlined,
            onPressed: onPrint,
            fullWidth: false,
          ),
          if (canShare)
            EteeloButton.secondary(
              label: l10n.documentViewerShareLabel,
              icon: Icons.share_outlined,
              onPressed: onShare,
              fullWidth: false,
            ),
          EteeloButton.primary(
            label: l10n.documentViewerCloseLabel,
            icon: Icons.check_rounded,
            onPressed: onClose,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
