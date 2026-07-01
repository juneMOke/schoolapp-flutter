import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';

part 'note_eleve_model.g.dart';

/// Modèle de la réponse `NoteEleveDto` (GET `.../notes/eleves`) : une ligne de
/// la grille de saisie.
///
/// [statut] est conservé en `String?` : converti en domaine via `fromApiValue`
/// (repli `unknown` si valeur inconnue), tandis que le `null` du wire est mappé
/// vers un [StatutNote] nul (« aucune saisie encore »). [pointsObtenus] est un
/// `num` nullable côté wire, coercé en `double?`.
@JsonSerializable()
class NoteEleveModel extends Equatable {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;
  final double? pointsObtenus;
  final String? statut;

  const NoteEleveModel({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.pointsObtenus,
    this.statut,
  });

  factory NoteEleveModel.fromJson(Map<String, dynamic> json) =>
      _$NoteEleveModelFromJson(json);

  Map<String, dynamic> toJson() => _$NoteEleveModelToJson(this);

  NoteEleve toEntity() => NoteEleve(
    studentId: studentId,
    firstName: firstName,
    lastName: lastName,
    middleName: middleName,
    pointsObtenus: pointsObtenus,
    // `null` (aucune saisie) préservé ; sinon repli `unknown` si inconnu.
    statut: statut == null ? null : StatutNoteX.fromApiValue(statut),
  );

  @override
  List<Object?> get props => [
    studentId,
    firstName,
    lastName,
    middleName,
    pointsObtenus,
    statut,
  ];
}
