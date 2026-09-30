import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/capture/document_capture_gateway.dart';
import 'package:school_app_flutter/core/capture/document_capture_service.dart';
import 'package:school_app_flutter/core/capture/platform_document_capture_gateway.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_flow.dart';

/// Capture de pièces (caméra, photo ou PDF importés), partagée par tout module
/// qui garde des justificatifs sur la tablette.
///
/// Rien n'est touché à l'enregistrement : la caméra et le sélecteur de fichiers
/// ne s'ouvrent qu'au geste de l'utilisateur.
void registerDocumentCapture(GetIt getIt) {
  getIt.registerLazySingleton<DocumentCaptureGateway>(
    PlatformDocumentCaptureGateway.new,
  );
  getIt.registerFactory<DocumentCaptureService>(
    () => DocumentCaptureService(getIt<DocumentCaptureGateway>()),
  );
  getIt.registerFactory<DocumentCaptureFlow>(
    () => DocumentCaptureFlow(getIt<DocumentCaptureService>()),
  );
}
