import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

/// Corps de la requête de saisie d'une note (body du `PUT`), **garantissant la
/// cohérence statut/points par construction**.
///
/// Invariants reflétés côté client (verrouillés backend, sinon 400) — garantis
/// par la factory [SaisirNoteRequest.forStatut], durcie en `throw` (active même
/// en build release, là où un `assert` serait supprimé) :
/// 1. `statut == NOTEE` ⟹ [pointsObtenus] **non nul** (la borne `0..maxPoints`
///    est validée par le BLoC, qui seul connaît `maxPoints`) ;
/// 2. autres statuts (`ABSENT_JUSTIFIE` / `ABSENT_NON_JUSTIFIE` / `EN_ATTENTE`)
///    ⟹ [pointsObtenus] **forcé à null** (le backend l'ignore de toute façon) ;
/// 3. `UNKNOWN` interdit : aucune saisie possible avec un statut inconnu.
class SaisirNoteRequest extends Equatable {
  final String studentId;

  /// Non nul **si et seulement si** [statut] == [StatutNote.notee].
  final double? pointsObtenus;

  final StatutNote statut;

  const SaisirNoteRequest._({
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
  });

  /// Construit la requête pour [statut], en appliquant les invariants ci-dessus.
  factory SaisirNoteRequest.forStatut({
    required String studentId,
    required StatutNote statut,
    double? pointsObtenus,
  }) {
    if (studentId.isEmpty) {
      throw ArgumentError.value(
        studentId,
        'studentId',
        'ne doit pas être vide',
      );
    }
    switch (statut) {
      case StatutNote.notee:
        if (pointsObtenus == null) {
          throw ArgumentError.value(
            pointsObtenus,
            'pointsObtenus',
            'requis quand le statut est NOTEE',
          );
        }
        return SaisirNoteRequest._(
          studentId: studentId,
          statut: statut,
          pointsObtenus: pointsObtenus,
        );
      case StatutNote.absentJustifie:
      case StatutNote.absentNonJustifie:
      case StatutNote.enAttente:
        // Points ignorés par le backend : on ne les porte pas (règle 2).
        return SaisirNoteRequest._(studentId: studentId, statut: statut);
      case StatutNote.unknown:
        throw ArgumentError.value(
          statut,
          'statut',
          'UNKNOWN ne peut pas être saisi',
        );
    }
  }

  @override
  List<Object?> get props => [studentId, pointsObtenus, statut];
}
