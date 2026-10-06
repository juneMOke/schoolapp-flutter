import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';

/// Un bloc du contenu rédigé d'un chapitre. Une `liste` porte ses éléments
/// dans [items] ; les autres types portent leur texte dans [texte].
class ChapitreBloc extends Equatable {
  final String id;
  final ChapitreBlocType type;
  final String texte;
  final List<String> items;

  const ChapitreBloc({
    required this.id,
    required this.type,
    this.texte = '',
    this.items = const [],
  });

  /// Un bloc vide n'est jamais enregistré.
  bool get isEmpty => type == ChapitreBlocType.liste
      ? items.every((item) => item.trim().isEmpty)
      : texte.trim().isEmpty;

  /// La forme du fil et de la ligne locale.
  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.wireValue,
    'texte': texte,
    'items': items,
  };

  ChapitreBloc copyWith({String? texte, List<String>? items}) => ChapitreBloc(
    id: id,
    type: type,
    texte: texte ?? this.texte,
    items: items ?? this.items,
  );

  @override
  List<Object?> get props => [id, type, texte, items];
}
