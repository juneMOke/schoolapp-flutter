import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';

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
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }
}
