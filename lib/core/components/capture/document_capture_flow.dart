import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_failure.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/capture/document_capture_service.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_sheet.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Signature de l'ouverture de la feuille de choix, injectable en test.
typedef DocumentCaptureSheetOpener =
    Future<DocumentCaptureMode?> Function(
      BuildContext context, {
      required String title,
      bool cameraUnavailable,
      DocumentCapturePolicy policy,
    });

/// Le parcours complet d'obtention d'une pièce, vu de l'écran : choisir un
/// geste, obtenir la pièce, et dire pourquoi elle est refusée le cas échéant.
///
/// Rend la pièce vérifiée, ou `null` si l'utilisateur renonce ou si la pièce
/// est refusée — le refus a déjà été annoncé, l'appelant n'a rien à ajouter.
///
/// **Jamais d'impasse** : une caméra refusée ou absente rouvre la feuille sans
/// l'action Numériser, avec un message, plutôt que de laisser l'utilisateur
/// devant une erreur.
class DocumentCaptureFlow {
  final DocumentCaptureService _service;
  final DocumentCaptureSheetOpener _openSheet;

  DocumentCaptureFlow(
    this._service, {
    DocumentCaptureSheetOpener openSheet = showDocumentCaptureSheet,
  }) : _openSheet = openSheet;

  /// [policy] : les bornes de la pièce attendue (celles du dossier du
  /// personnel par défaut).
  Future<CapturedDocument?> run(
    BuildContext context, {
    required String title,
    DocumentCapturePolicy policy = DocumentCapturePolicy.staffDocument,
  }) async {
    var cameraUnavailable = false;
    while (true) {
      final mode = await _openSheet(
        context,
        title: title,
        cameraUnavailable: cameraUnavailable,
        policy: policy,
      );
      if (mode == null || !context.mounted) return null;

      final result = await _service.capture(mode, policy: policy);
      if (!context.mounted) return null;

      DocumentCaptureFailure? failure;
      CapturedDocument? document;
      result.fold((f) => failure = f, (d) => document = d);
      if (document != null) return document;
      if (failure is CameraUnavailableFailure) {
        cameraUnavailable = true;
        continue;
      }
      final message = _messageOf(
        AppLocalizations.of(context)!,
        failure!,
        policy,
      );
      if (message != null) AppSnackBar.showError(context, message);
      return null;
    }
  }

  /// Texte d'un refus, ou `null` quand il n'y a rien à dire (renoncement).
  static String? _messageOf(
    AppLocalizations l10n,
    DocumentCaptureFailure failure,
    DocumentCapturePolicy policy,
  ) {
    return switch (failure) {
      DocumentCaptureCancelled() => null,
      CameraUnavailableFailure() => l10n.documentCaptureCameraUnavailable,
      DocumentTooLargeFailure() => l10n.documentCaptureTooLarge(
        policy.maxMegabytes,
      ),
      UnsupportedDocumentFailure() => l10n.documentCaptureUnsupported,
      DocumentReadFailure() => l10n.documentCaptureReadError,
    };
  }
}
