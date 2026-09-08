import 'package:equatable/equatable.dart';

/// Ce qu'une classe a versé **dans la caisse d'une devise**, sur la fenêtre.
///
/// Un **classement**, jamais un total : le serveur coupe à huit lignes
/// (`CLASSROOM_RANKING_SIZE`) et il n'existe aucune ligne « autres ». Additionner
/// ces montants ne redonne donc pas le total de la caisse, et ce n'est pas une
/// erreur — c'est ce que la carte assume en s'appelant un palmarès.
///
/// **Le cycle n'y figure pas, délibérément.** Il aurait dû être doublé du texte
/// — une couleur ne porte jamais seule une information — et en toutes lettres il
/// répète ce que le nom de la classe dit déjà : « 1ère humanités · Secondaire ».
/// Réserve à connaître : ça ne tient que parce que les classes de ce parc se
/// nomment d'après leur cycle. Une école qui nommerait ses classes « A1 », « B2 »
/// rendrait le cycle informatif, et il faudrait rouvrir la question — en sachant
/// que le serveur devrait traverser deux ports pour le reconstituer.
class TillClassroomAmount extends Equatable {
  /// L'identifiant de la classe. Porté pour lui-même : la carte ne navigue
  /// nulle part aujourd'hui, mais deux classes peuvent porter le même nom d'une
  /// année à l'autre, et un palmarès qui se dédoublonnerait sur le libellé en
  /// fusionnerait deux.
  final String classroomId;

  /// Le nom affiché de la classe, tel que le serveur l'envoie.
  final String name;

  /// Encaissé par cette classe dans la devise du bloc, en centimes.
  final int amount;

  const TillClassroomAmount({
    required this.classroomId,
    required this.name,
    required this.amount,
  });

  @override
  List<Object?> get props => [classroomId, name, amount];
}
