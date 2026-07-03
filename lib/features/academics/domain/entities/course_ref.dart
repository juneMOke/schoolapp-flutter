import 'package:equatable/equatable.dart';

/// Référence d'un cours (branche) enseigné dans une classe : son identifiant et
/// son libellé d'affichage (le nom de la branche).
///
/// [id] peut être vide lorsque le backend renvoie encore l'ancien format (une
/// simple liste de libellés, sans identifiant) : dans ce cas le cours n'est pas
/// encore ouvrable (cf. [hasId]).
class CourseRef extends Equatable {
  final String id;
  final String label;

  const CourseRef({required this.id, required this.label});

  /// `true` si l'identifiant est exploitable pour ouvrir le détail du cours.
  bool get hasId => id.trim().isNotEmpty;

  @override
  List<Object?> get props => [id, label];
}
