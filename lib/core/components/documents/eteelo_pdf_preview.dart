import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rendu des pages d'un document, quelle qu'en soit l'origine.
///
/// Isolé dans son propre widget parce que [PdfPreview] rasterise via des canaux
/// de plateforme : **il ne peut pas s'afficher dans un test widget**. Tout ce
/// qui l'entoure — en-tête, pied, gardes, actions — reste donc testable sans
/// lui, à condition de passer par le point d'injection que la visionneuse
/// expose.
///
/// `useActions: false` : la barre d'actions native de `printing` est remplacée
/// par le pied de la visionneuse, pour que les libellés passent par
/// `AppLocalizations` (règle non-négociable #4) et que les boutons soient ceux
/// du design system.
class EteeloPdfPreview extends StatelessWidget {
  /// Les octets à rasteriser.
  final Uint8List bytes;

  /// Nom proposé si l'utilisateur enregistre depuis la visionneuse système.
  final String fileName;

  /// Repli d'affichage propre à l'appelant.
  ///
  /// L'éditique garde le sien : sa carte d'erreur porte l'anatomie du module
  /// (motif serveur, reprise interdite sur une pièce horodatée), que le message
  /// neutre ne saurait pas dire. Absent ⇒ le repli du socle.
  final WidgetBuilder? errorBuilder;

  const EteeloPdfPreview({
    super.key,
    required this.bytes,
    required this.fileName,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (_) => bytes,
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      maxPageWidth: AppDimensions.documentViewerMaxWidth,
      pdfFileName: fileName,
      scrollViewDecoration: const BoxDecoration(color: AppColors.surfaceAlt),
      // Le rendu des pages passe par le canal natif du plugin. Il échoue si le
      // binaire installé précède l'ajout de la dépendance (le classique
      // `MissingPluginException` après un simple hot restart), ou si la
      // rastérisation refuse le document. Sans ce repli, Flutter affiche son
      // `ErrorWidget` rouge, en anglais et hors charte.
      //
      // ⚠️ Le document est bien là : c'est un incident d'AFFICHAGE, pas de
      // production. Aucune reprise n'est proposée — régénérer ne changerait
      // rien — et le message dit que le pied reste utilisable, car imprimer et
      // partager, eux, n'ont pas besoin de la rastérisation.
      onError: (errorContext, _) =>
          errorBuilder?.call(errorContext) ?? const _RenderFailure(),
      loadingWidget: const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: EteeloSkeletonBox(
          height: AppDimensions.documentViewerSkeletonHeight,
        ),
      ),
    );
  }
}

/// Le repli d'affichage, charté et défilant.
///
/// `SingleChildScrollView` parce que la carte d'erreur porte une hauteur
/// plancher : dans une modale déjà plafonnée à 88 % de l'écran, en-tête et pied
/// déduits, il peut ne pas rester assez de place sur une tablette en paysage.
class _RenderFailure extends StatelessWidget {
  const _RenderFailure();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: EteeloErrorResult(
        type: EteeloErrorType.server,
        title: l10n.documentViewerRenderFailedTitle,
        message: l10n.documentViewerRenderFailedMessage,
      ),
    );
  }
}
