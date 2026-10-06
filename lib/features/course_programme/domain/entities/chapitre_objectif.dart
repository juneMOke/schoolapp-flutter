import 'package:equatable/equatable.dart';

/// Un objectif pédagogique d'un chapitre, coché une fois atteint.
class ChapitreObjectif extends Equatable {
  final String id;
  final String texte;
  final bool atteint;

  const ChapitreObjectif({
    required this.id,
    required this.texte,
    this.atteint = false,
  });

  /// La forme du fil et de la ligne locale.
  Map<String, Object?> toJson() => {
    'id': id,
    'texte': texte,
    'atteint': atteint,
  };

  ChapitreObjectif copyWith({String? texte, bool? atteint}) => ChapitreObjectif(
    id: id,
    texte: texte ?? this.texte,
    atteint: atteint ?? this.atteint,
  );

  @override
  List<Object?> get props => [id, texte, atteint];
}
