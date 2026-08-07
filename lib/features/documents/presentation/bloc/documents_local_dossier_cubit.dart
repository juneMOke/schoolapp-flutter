import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/list_cached_documents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollment_detail_use_case.dart';

/// Ce que **cette tablette** sait du dossier de l'élève.
///
/// Deux informations, et deux seulement :
/// - l'axe de synchro du dossier, qui décide si l'attestation est adressable
///   (son `enrollmentId` est un uuid client tant que l'ACK n'est pas revenu) ;
/// - les pièces déjà scellées dont une trace locale existe, qui font passer une
///   ligne de « Émettre » à « Consulter » et alimentent « Dernière émission ».
///
/// Ce n'est **pas** un inventaire du dossier serveur : aucun endpoint ne liste
/// les pièces d'un élève. Une attestation produite depuis un autre poste est
/// invisible ici, et la ligne dira « Émettre » — ce qui ne coûte rien, la pièce
/// étant idempotente. La nuance est portée par les libellés, jamais masquée.
class DocumentsLocalDossierCubit extends Cubit<DocumentsLocalDossierState> {
  final GetLocalEnrollmentDetailUseCase _getLocalEnrollmentDetail;
  final ListCachedDocumentsUseCase _listCachedDocuments;

  DocumentsLocalDossierCubit(
    this._getLocalEnrollmentDetail,
    this._listCachedDocuments,
  ) : super(const DocumentsLocalDossierState());

  /// Charge ce que le local sait. Un `enrollmentId` vide (lien profond rechargé)
  /// n'est pas une erreur : il n'y a simplement rien à lire — et les pièces en
  /// cache, elles, sont scopées par élève, donc restent lisibles.
  Future<void> load(
    String enrollmentId, {
    String? studentId,
    String? academicYearId,
  }) async {
    if (isClosed) return;

    final cached = studentId == null
        ? const <EditiqueCacheEntry>[]
        : await _listCachedDocuments(
            studentId: studentId,
            academicYearId: academicYearId,
          );
    if (isClosed) return;

    if (enrollmentId.trim().isEmpty) {
      emit(DocumentsLocalDossierState(loaded: true, cachedPieces: cached));
      return;
    }

    final result = await _getLocalEnrollmentDetail(enrollmentId);
    if (isClosed) return;

    emit(
      result.fold(
        // Échec de lecture locale : on reste sur « rien de connu ». Les gardes
        // en aval sont fail-closed, donc l'attestation restera éteinte plutôt
        // que d'être proposée sur un axe de synchro inconnu.
        (_) => DocumentsLocalDossierState(loaded: true, cachedPieces: cached),
        (detail) => DocumentsLocalDossierState(
          loaded: true,
          enrollmentSyncState: detail.enrollment.syncState,
          knownPieces: detail.documents,
          cachedPieces: cached,
        ),
      ),
    );
  }
}

class DocumentsLocalDossierState extends Equatable {
  final bool loaded;

  /// `null` tant que la lecture n'a rien donné — l'attestation reste éteinte.
  final SyncState? enrollmentSyncState;

  /// Trace des pièces que cette tablette a **produites** (`generated_documents`)
  /// : elle porte le numéro et la date de la dernière émission, jamais d'octets.
  final List<LocalGeneratedDocument> knownPieces;

  /// Pièces dont cette tablette détient une **copie scellée** — les seules
  /// consultables hors ligne. Index distinct du précédent, et pour cause : on
  /// peut avoir produit une pièce sans en garder les octets (relevé, quitus),
  /// et en détenir une qu'on n'a pas produite (re-téléchargement).
  final List<EditiqueCacheEntry> cachedPieces;

  const DocumentsLocalDossierState({
    this.loaded = false,
    this.enrollmentSyncState,
    this.knownPieces = const <LocalGeneratedDocument>[],
    this.cachedPieces = const <EditiqueCacheEntry>[],
  });

  @override
  List<Object?> get props => [
    loaded,
    enrollmentSyncState,
    knownPieces,
    cachedPieces,
  ];
}
