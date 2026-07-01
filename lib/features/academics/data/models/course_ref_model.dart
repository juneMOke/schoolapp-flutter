import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_ref.dart';

/// Modèle d'une référence de cours. Parsing **tolérant** pour absorber la
/// transition du contrat `mes-cours` :
/// - ancien format : `"Mathématiques"` (chaîne nue) → [id] vide, [label]
///   renseigné (cours non ouvrable) ;
/// - nouveau format : `{ "id": "...", "branche": "Mathématiques" }` — la clé
///   wire est `branche`, exposée côté domaine sous [label] (libellé d'affichage
///   = nom de la branche).
///
/// Modèle écrit à la main (pas de `@JsonSerializable`) car le champ accepte
/// deux formes JSON ; cohérent avec la convention « zéro `@JsonKey` » du module.
class CourseRefModel extends Equatable {
  final String id;
  final String label;

  const CourseRefModel({required this.id, required this.label});

  /// Tolère une chaîne nue (ancien contrat) ou un objet `{id, branche}`.
  factory CourseRefModel.fromJson(dynamic json) {
    if (json is String) {
      return CourseRefModel(id: '', label: json);
    }
    final map = json as Map<String, dynamic>;
    // `id` n'est exploité que s'il est une chaîne : un id mal typé (number,
    // objet…) est traité comme absent → cours non ouvrable, plutôt que de
    // construire un coursId corrompu qui échouerait tardivement côté backend.
    final id = map['id'];
    return CourseRefModel(
      id: id is String ? id : '',
      label: (map['branche'] ?? '').toString(),
    );
  }

  // Round-trip cohérent avec [fromJson] : la clé wire est `branche`.
  Map<String, dynamic> toJson() => {'id': id, 'branche': label};

  CourseRef toEntity() => CourseRef(id: id, label: label);

  @override
  List<Object?> get props => [id, label];
}
