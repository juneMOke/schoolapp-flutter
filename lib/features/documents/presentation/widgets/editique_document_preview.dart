import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/states/editique_results_error_state.dart';

/// Rendu des pages d'une pièce reçue.
///
/// Isolé dans son propre widget parce que [PdfPreview] rasterise via des canaux
/// de plateforme : il ne peut pas s'afficher dans un test widget. Tout ce qui
/// l'entoure — états, actions, gardes — reste donc testable sans lui.
///
/// `useActions: false` : la barre d'actions native de `printing` est remplacée
/// par le pied de la modale, pour que les libellés passent par
/// `AppLocalizations` (règle non-négociable #4) et que les boutons soient ceux
/// du design system.
class EditiqueDocumentPreview extends StatelessWidget {
  final EditiqueDocument document;

  const EditiqueDocumentPreview({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (_) => document.bytes,
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      maxPageWidth: AppDimensions.editiqueViewerMaxWidth,
      pdfFileName: document.fileName,
      scrollViewDecoration: const BoxDecoration(color: AppColors.surfaceAlt),
      // Le rendu des pages passe par le canal natif du plugin. Il échoue si le
      // binaire installé précède l'ajout de la dépendance (le classique
      // `MissingPluginException` après un simple hot restart), ou si la
      // rastérisation refuse le document. Sans ce repli, Flutter affiche son
      // `ErrorWidget` rouge, en anglais et hors charte.
      //
      // La pièce est bien arrivée : c'est un incident d'affichage, pas
      // d'émission. Aucune reprise n'est donc proposée — la redemander ne
      // changerait rien, et sur une pièce horodatée en brûlerait le numéro.
      onError: (_, _) => const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: EditiqueResultsErrorState(
          type: EditiqueErrorType.server,
          canRetry: false,
        ),
      ),
      loadingWidget: const Padding(
        padding: EdgeInsets.all(AppDimensions.spacingM),
        child: EteeloSkeletonBox(
          height: AppDimensions.editiqueViewerSkeletonHeight,
        ),
      ),
    );
  }
}
