import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/features/documents/data/repositories/offline/editique_document_pull_repository_impl.dart';

/// [PullHandler] du catalogue des pièces scellées. Enregistré sur le
/// `PullCoordinator` par le registrar Documents.
///
/// Ne lève pas : un échec (`Left`) est traduit en [PullOutcome.error], isolé du
/// reste du cycle. Tant que la route n'est pas déployée côté serveur, ce
/// handler comptera un échec par cycle — sans pénaliser aucun autre module.
class EditiqueDocumentPullHandler implements PullHandler {
  final EditiqueDocumentPullRepositoryImpl _repository;

  const EditiqueDocumentPullHandler(this._repository);

  static const String resourceName = kEditiqueDocumentsResource;

  @override
  String get resource => resourceName;

  /// GET /sync/editique-documents — gardé sur `editique.read` côté serveur.
  @override
  List<Perm> get requiredPermissions => const [Perm.editiqueRead];

  @override
  Future<PullOutcome> pull() async {
    final result = await _repository.syncDocuments();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
