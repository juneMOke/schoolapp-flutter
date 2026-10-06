import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_file_preview.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_content.dart';

/// Montre une pièce du dossier : un PDF dans la visionneuse partagée, une
/// photo en plein écran, zoomable ([showEteeloFilePreview]).
///
/// Ni partage ni impression : une pièce d'identité ou un diplôme ne quitte
/// pas la tablette par ce geste — le spouleur offre « Enregistrer en PDF ».
Future<void> showStaffDocumentViewer(
  BuildContext context, {
  required String title,
  required StaffDocumentContent content,
}) => showEteeloFilePreview(
  context,
  title: title,
  bytes: content.bytes,
  mimeType: content.mimeType,
  fileName: content.fileName,
);
