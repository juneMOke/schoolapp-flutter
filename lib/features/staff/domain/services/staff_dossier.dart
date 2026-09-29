import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Où en est le dossier administratif d'un agent : les pièces que son contrat
/// exige, et celles déjà versées.
class StaffDossier extends Equatable {
  /// Les pièces exigées, dans l'ordre servi par le socle.
  final List<StaffDocumentType> required;

  /// Les codes (valeurs du fil) des pièces exigées déjà versées.
  final Set<String> filled;

  const StaffDossier({required this.required, required this.filled});

  /// Calcule le dossier d'un agent dont le contrat en vigueur est [kind]
  /// (`null` : contrat à poser — seules les pièces communes sont exigées).
  ///
  /// Une pièce versée puis devenue inutile (changement de contrat) reste au
  /// dossier, simplement non comptée.
  factory StaffDossier.of({
    required StaffContractKind? kind,
    required List<StaffDocumentType> types,
    required List<StaffDocument> documents,
  }) {
    final required = [
      for (final type in types)
        if (type.isRequiredFor(kind)) type,
    ];
    // Une pièce refusée n'est pas au dossier : le serveur ne l'a pas.
    final present = {
      for (final document in documents)
        if (document.syncState != StaffSyncState.failed) document.rawCode,
    };
    return StaffDossier(
      required: required,
      filled: {
        for (final type in required)
          if (present.contains(type.rawCode)) type.rawCode,
      },
    );
  }

  int get total => required.length;
  int get done => filled.length;

  /// Rien d'exigé (référentiel pas encore descendu) ne se lit pas « complet » :
  /// on ne sait pas.
  bool get isKnown => required.isNotEmpty;
  bool get isComplete => isKnown && done == total;
  bool get isEmpty => done == 0;

  @override
  List<Object?> get props => [required, filled];
}
