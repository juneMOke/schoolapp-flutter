import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/storage/encrypted_blob/encrypted_blob_store.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_rows.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_blobs.dart';
import 'package:school_app_flutter/features/course_programme/data/local/programme_outbox.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/handlers/chapitre_child_outbox_handler.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_sync_api.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_transfer_api.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// Handler de l'agrégat `CHAPITRE_RESSOURCE` : joindre ou retirer une
/// ressource (cf. [ChapitreChildOutboxHandler]).
///
/// Le fichier d'un document part avec sa description, en une seule requête,
/// relu dans le magasin chiffré au moment de l'envoi ; disparu du poste (clé
/// perdue), l'ajout ne peut plus partir et le dit.
class ChapitreRessourceOutboxHandler
    extends ChapitreChildOutboxHandler<ChapitreRessourcePayload> {
  final ProgrammeSyncApi _api;
  final ProgrammeTransferApi _transfer;
  final ProgrammeBlobs _blobs;

  ChapitreRessourceOutboxHandler({
    required ProgrammeSyncApi api,
    required ProgrammeTransferApi transfer,
    required ProgrammeBlobs blobs,
    required super.dao,
    required super.evictCours,
    required super.currentUser,
    required super.extras,
    super.now,
  }) : _api = api,
       _transfer = transfer,
       _blobs = blobs;

  /// Le refus rangé quand le fichier n'est plus sur le poste.
  static const String bytesLostCode = 'LOCAL_BYTES_LOST';

  @override
  String get aggregateType => ProgrammeOutbox.ressourceType;

  @override
  String get table => ProgrammeTables.ressource;

  @override
  ChapitreRessourcePayload? parse(Object? json) =>
      ChapitreRessourcePayload.tryParse(json);

  @override
  ChildGesture gestureOf(ChapitreRessourcePayload payload) => ChildGesture(
    op: payload.op,
    id: payload.ressource.id,
    chapitreId: payload.chapitreId,
  );

  @override
  Future<OutboxDispatchResult?> sendSave(
    ChapitreRessourcePayload payload,
  ) async {
    final id = payload.ressource.id;
    if (RessourceType.fromWire(payload.ressource.type) !=
        RessourceType.document) {
      await _transfer.putRessource(extras, payload);
      return null;
    }
    switch (await _blobs.read(id)) {
      case BlobUnavailable():
        return const OutboxDispatchResult.retry('Magasin indisponible');
      case BlobGone():
        await dao.markChildRejected(table, id, bytesLostCode, now());
        return const OutboxDispatchResult.failed(
          'Fichier de la ressource perdu sur le poste',
        );
      case BlobFound(:final blob):
        await _transfer.putRessource(extras, payload, bytes: blob.bytes);
        return null;
    }
  }

  @override
  Future<void> sendDelete(ChapitreRessourcePayload payload) =>
      _api.deleteRessource(extras, payload.chapitreId, payload.ressource.id);
}
