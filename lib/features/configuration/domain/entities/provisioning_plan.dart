import 'package:equatable/equatable.dart';

/// Ce que l'activation **va** faire, ou vient de faire.
///
/// Un seul type pour les deux, à dessein : ce qu'une simulation annonce et ce
/// qu'une exécution rapporte doivent être la même chose, sans quoi l'écran de
/// confirmation promettrait ce que l'exécution ne tient pas. Seuls les
/// identifiants sont vides en simulation.
///
/// **C'est la source unique de tous les chiffres affichés à partir de l'étape 3**
/// (§7.7 du plan). Un total recalculé localement qui diverge du plan est un
/// engagement chiffré faux juste avant une écriture irréversible.
class ProvisioningPlan extends Equatable {
  /// `true` en simulation. `false` sur la réponse d'activation.
  final bool dryRun;

  /// `null` en simulation, renseigné après activation.
  final String? academicYearId;

  final String? academicYearName;

  final ProvisioningCounts counts;

  final List<PlannedCycle> cycles;

  /// **Un tarif par niveau de l'assiette.** Un minerval saisi une fois sur vingt
  /// niveaux apparaît vingt fois ici : la liste de l'écran compte les frais
  /// saisis, celle-ci compte les tarifs qui seront écrits.
  final List<PlannedFee> fees;

  final List<ProvisioningWarning> warnings;

  const ProvisioningPlan({
    required this.dryRun,
    required this.academicYearId,
    required this.academicYearName,
    required this.counts,
    required this.cycles,
    required this.fees,
    required this.warnings,
  });

  @override
  List<Object?> get props => [
    dryRun,
    academicYearId,
    academicYearName,
    counts,
    cycles,
    fees,
    warnings,
  ];
}

/// Ce que l'activation créera, en volume.
///
/// Rendus par le serveur et **jamais calculés localement** : c'est ce qui
/// garantit que le chiffre annoncé au pied de l'étape 3 est celui que
/// l'activation écrira.
class ProvisioningCounts extends Equatable {
  final int cycles;
  final int levels;
  final int classrooms;

  /// Volume pédagogique dérivé des barèmes MINEDUC — ce que la révision 1 de la
  /// spécification ne pouvait pas connaître, faute de catalogue servi.
  final int courses;

  /// Nombre de **tarifs**, pas de lignes de l'écran (cf. [ProvisioningPlan.fees]).
  final int fees;

  const ProvisioningCounts({
    required this.cycles,
    required this.levels,
    required this.classrooms,
    required this.courses,
    required this.fees,
  });

  static const ProvisioningCounts zero = ProvisioningCounts(
    cycles: 0,
    levels: 0,
    classrooms: 0,
    courses: 0,
    fees: 0,
  );

  @override
  List<Object?> get props => [cycles, levels, classrooms, courses, fees];
}

class PlannedCycle extends Equatable {
  final String catalogCode;
  final String name;
  final String? periodType;

  /// `null` en simulation.
  final String? id;

  final List<PlannedLevel> levels;

  const PlannedCycle({
    required this.catalogCode,
    required this.name,
    required this.periodType,
    required this.id,
    required this.levels,
  });

  int get classroomCount =>
      levels.fold(0, (total, level) => total + level.classrooms.length);

  @override
  List<Object?> get props => [catalogCode, name, periodType, id, levels];
}

class PlannedLevel extends Equatable {
  final String catalogCode;
  final String name;
  final String? id;
  final List<PlannedClassroom> classrooms;

  const PlannedLevel({
    required this.catalogCode,
    required this.name,
    required this.id,
    required this.classrooms,
  });

  @override
  List<Object?> get props => [catalogCode, name, id, classrooms];
}

/// Une classe telle qu'elle sera créée.
class PlannedClassroom extends Equatable {
  /// **Le nom fait foi, et il vient d'ici.**
  ///
  /// C'est celui qui existera sur les listes, les bulletins et les reçus. Le
  /// fabriquer côté client — en concaténant le niveau, une abréviation et une
  /// lettre — serait un mensonge à usage unique : la règle de nommage
  /// (abréviation de filière, lettre comptée par filière) vit sur le serveur,
  /// et c'est lui qui l'applique.
  final String name;

  final String? id;
  final String? officialCode;
  final String? filiere;

  /// Barème de la classe. Sans lui, la classe naîtrait sans aucun cours.
  final String? grilleId;

  final int courseCount;

  const PlannedClassroom({
    required this.name,
    required this.id,
    required this.officialCode,
    required this.filiere,
    required this.grilleId,
    required this.courseCount,
  });

  @override
  List<Object?> get props => [
    name,
    id,
    officialCode,
    filiere,
    grilleId,
    courseCount,
  ];
}

/// Un tarif tel qu'il sera écrit — un niveau à la fois.
class PlannedFee extends Equatable {
  final String feeCode;
  final String? label;
  final int amountInCents;
  final String currency;
  final DateTime? dueAt;
  final String? levelCatalogCode;
  final String? id;

  const PlannedFee({
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.levelCatalogCode,
    required this.id,
  });

  @override
  List<Object?> get props => [
    feeCode,
    label,
    amountInCents,
    currency,
    dueAt,
    levelCatalogCode,
    id,
  ];
}

/// Un avertissement n'empêche rien : il dit ce que l'activation fera quand
/// même, et qui pourrait surprendre.
///
/// **Le message est servi rédigé en français** — l'afficher tel quel, ne pas le
/// traduire et surtout ne pas le tester : il changera.
class ProvisioningWarning extends Equatable {
  final String code;

  /// Le cycle ou le niveau concerné, quand l'avertissement en désigne un.
  final String? catalogCode;

  final String message;

  const ProvisioningWarning({
    required this.code,
    required this.catalogCode,
    required this.message,
  });

  @override
  List<Object?> get props => [code, catalogCode, message];
}
