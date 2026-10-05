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

  ChapitreObjectif copyWith({String? texte, bool? atteint}) => ChapitreObjectif(
    id: id,
    texte: texte ?? this.texte,
    atteint: atteint ?? this.atteint,
  );

  @override
  List<Object?> get props => [id, texte, atteint];
}
