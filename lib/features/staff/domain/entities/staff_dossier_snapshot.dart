import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Le dossier d'un agent tel que la tablette le connaît : les pièces du
/// référentiel et celles versées pour lui, la plus récente d'abord.
class StaffDossierSnapshot extends Equatable {
  final List<StaffDocumentType> types;
  final List<StaffDocument> documents;

  const StaffDossierSnapshot({required this.types, required this.documents});

  static const empty = StaffDossierSnapshot(types: [], documents: []);

  /// La pièce courante d'un code : la plus récente qui n'a pas été refusée —
  /// un refus ne masque pas la bonne pièce versée avant lui. À défaut, la
  /// dernière refusée, pour montrer pourquoi.
  StaffDocument? currentOf(String rawCode) {
    StaffDocument? rejected;
    for (final document in documents) {
      if (document.rawCode != rawCode) continue;
      if (document.syncState != StaffSyncState.failed) return document;
      rejected ??= document;
    }
    return rejected;
  }

  @override
  List<Object?> get props => [types, documents];
}
