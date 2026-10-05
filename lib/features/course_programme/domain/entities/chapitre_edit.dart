import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';

/// Ce que la modale d'un chapitre rend : la fiche, les ressources jointes et
/// celles retirées. Les fichiers partent à l'enregistrement du chapitre, pas
/// à l'ajout dans la modale.
class ChapitreEdit extends Equatable {
  final Chapitre chapitre;
  final List<RessourceDraft> addedRessources;
  final List<String> removedRessourceIds;
  final bool isNew;

  const ChapitreEdit({
    required this.chapitre,
    required this.isNew,
    this.addedRessources = const [],
    this.removedRessourceIds = const [],
  });

  @override
  List<Object?> get props => [
    chapitre,
    addedRessources,
    removedRessourceIds,
    isNew,
  ];
}

/// Une sous-période où rattacher un chapitre : celles de l'année et du cycle
/// de la classe du cours. Une sous-période close reste proposée — on
/// planifie, on ne note pas.
class SousPeriodeOption extends Equatable {
  final String id;
  final int ordre;

  const SousPeriodeOption({required this.id, required this.ordre});

  @override
  List<Object?> get props => [id, ordre];
}

/// L'issue d'un enregistrement : la fiche est gardée ; [ressourcesKept] dit
/// si toutes les ressources jointes l'ont été aussi.
class ChapitreEditOutcome extends Equatable {
  final Chapitre chapitre;
  final bool ressourcesKept;

  const ChapitreEditOutcome({
    required this.chapitre,
    required this.ressourcesKept,
  });

  @override
  List<Object?> get props => [chapitre, ressourcesKept];
}
