import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/services/programme_stats.dart';

/// Une rangée du programme : le chapitre et ce que sa ligne compte autour de
/// lui (notes de séance, évaluations qui le citent).
class ProgrammeChapitre extends Equatable {
  final Chapitre chapitre;
  final int notesCount;
  final int evaluationsCount;

  const ProgrammeChapitre({
    required this.chapitre,
    this.notesCount = 0,
    this.evaluationsCount = 0,
  });

  @override
  List<Object?> get props => [chapitre, notesCount, evaluationsCount];
}

/// Le programme d'un cours : ses chapitres dans l'ordre de progression.
class Programme extends Equatable {
  final String coursId;
  final List<ProgrammeChapitre> chapitres;

  /// Évaluations du cours (toutes, rattachées ou non).
  final int evaluationsCount;

  const Programme({
    required this.coursId,
    required this.chapitres,
    this.evaluationsCount = 0,
    this.readOnly = false,
  });

  ProgrammeStats get stats =>
      ProgrammeStats.of(chapitres.map((row) => row.chapitre));

  bool get isEmpty => chapitres.isEmpty;

  /// Lu en ligne : ni création, ni ordre, ni suppression.
  final bool readOnly;

  @override
  List<Object?> get props => [coursId, chapitres, evaluationsCount, readOnly];
}
