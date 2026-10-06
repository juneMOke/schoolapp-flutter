import 'package:equatable/equatable.dart';

/// Le cadre d'une évaluation : ce que l'élève révise et les conditions de
/// l'épreuve. Saisi à la création, repris dans l'onglet Sujet et imprimé en
/// tête de la copie.
///
/// [dureeMinutes] nul = « Non définie ». [programme] ne garde que des lignes
/// non vides : une ligne blanche est retirée avant tout enregistrement.
class EvaluationCadre extends Equatable {
  final int? dureeMinutes;
  final List<String> programme;
  final String? consignes;

  const EvaluationCadre({
    this.dureeMinutes,
    this.programme = const [],
    this.consignes,
  });

  static const EvaluationCadre empty = EvaluationCadre();

  /// Copie normalisée : lignes de programme rognées et vides retirées,
  /// consignes blanches ramenées à `null`, durée non positive à « non définie ».
  EvaluationCadre normalized() {
    final text = consignes?.trim();
    final duree = dureeMinutes;
    return EvaluationCadre(
      dureeMinutes: duree != null && duree > 0 ? duree : null,
      programme: [
        for (final line in programme)
          if (line.trim().isNotEmpty) line.trim(),
      ],
      consignes: text == null || text.isEmpty ? null : text,
    );
  }

  @override
  List<Object?> get props => [dureeMinutes, programme, consignes];
}
