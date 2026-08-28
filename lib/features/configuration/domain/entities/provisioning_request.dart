import 'package:equatable/equatable.dart';

/// Ce que le promoteur déclare de son établissement : son année, l'offre qu'il
/// ouvre, et sa grille tarifaire.
///
/// **Aucun identifiant de base n'y figure — que des codes de catalogue.** Le
/// client coche des cases dans le catalogue qu'on lui a servi ; rien de ce qu'il
/// envoie ne peut désigner l'école d'un autre, et le serveur lit la sienne dans
/// le jeton.
///
/// C'est aussi l'objet que le brouillon local persiste entre deux ouvertures de
/// l'assistant : les étapes 2 à 4 le construisent, et le serveur ne le voit
/// qu'en simulation jusqu'à l'activation.
class ProvisioningRequest extends Equatable {
  final AcademicYearInput? academicYear;

  /// Nombre de classes ouvert sur chaque niveau retenu qui n'en fixe pas un
  /// lui-même. Le réglage par niveau le surcharge.
  final int? defaultClassroomsPerLevel;

  final List<CycleInput> cycles;

  final List<FeeInput> fees;

  const ProvisioningRequest({
    this.academicYear,
    this.defaultClassroomsPerLevel,
    this.cycles = const <CycleInput>[],
    this.fees = const <FeeInput>[],
  });

  /// Brouillon vide — l'état d'un assistant qu'on vient d'ouvrir.
  static const ProvisioningRequest empty = ProvisioningRequest();

  ProvisioningRequest copyWith({
    AcademicYearInput? academicYear,
    int? defaultClassroomsPerLevel,
    List<CycleInput>? cycles,
    List<FeeInput>? fees,
  }) {
    return ProvisioningRequest(
      academicYear: academicYear ?? this.academicYear,
      defaultClassroomsPerLevel:
          defaultClassroomsPerLevel ?? this.defaultClassroomsPerLevel,
      cycles: cycles ?? this.cycles,
      fees: fees ?? this.fees,
    );
  }

  /// La simulation valide l'année **en premier** : tant que l'étape 2 n'est pas
  /// remplie, l'appel rend 400. Inutile de le déclencher pour l'apprendre.
  bool get isSimulatable => academicYear != null && cycles.isNotEmpty;

  @override
  List<Object?> get props => [
    academicYear,
    defaultClassroomsPerLevel,
    cycles,
    fees,
  ];
}

class AcademicYearInput extends Equatable {
  final String name;

  /// Instants UTC. Le suffixe `Z` n'est pas décoratif sur cette route : sans
  /// lui le corps est illisible et l'appel rend 400.
  final DateTime startDate;
  final DateTime endDate;

  final bool current;

  const AcademicYearInput({
    required this.name,
    required this.startDate,
    required this.endDate,
    this.current = true,
  });

  bool get hasValidRange => endDate.isAfter(startDate);

  AcademicYearInput copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? current,
  }) {
    return AcademicYearInput(
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      current: current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [name, startDate, endDate, current];
}

class CycleInput extends Equatable {
  final String catalogCode;
  final List<LevelInput> levels;

  const CycleInput({required this.catalogCode, required this.levels});

  @override
  List<Object?> get props => [catalogCode, levels];
}

/// Un niveau retenu.
///
/// [classrooms] surcharge le réglage global ; [sections] le **remplace** quand
/// le niveau porte plusieurs filières — on n'ouvre alors pas « trois classes »
/// mais « une scientifique et deux pédagogiques », ce qu'un simple compte ne
/// saurait dire.
///
/// Les deux ensemble sur un même niveau rendent 422 : c'est un bug client, que
/// l'interface doit rendre inatteignable.
class LevelInput extends Equatable {
  final String catalogCode;
  final int? classrooms;
  final List<SectionInput> sections;

  const LevelInput({
    required this.catalogCode,
    this.classrooms,
    this.sections = const <SectionInput>[],
  });

  @override
  List<Object?> get props => [catalogCode, classrooms, sections];
}

class SectionInput extends Equatable {
  final String officialCode;

  /// Une section ouverte compte au moins une classe : à zéro, on retire la
  /// section de la liste plutôt que de l'envoyer vide.
  final int classrooms;

  const SectionInput({required this.officialCode, required this.classrooms});

  @override
  List<Object?> get props => [officialCode, classrooms];
}

/// Un frais et l'assiette de niveaux sur laquelle il porte.
///
/// L'assiette n'est jamais une liste de classes : deux classes d'un même niveau
/// paient la même chose, c'est le modèle. En échange, un frais dû par tous
/// s'exprime en une ligne au lieu de quinze.
class FeeInput extends Equatable {
  final String feeCode;
  final String label;

  /// Montant en centimes. La saisie se fait en unité, en français (virgule
  /// décimale) — la conversion vit dans une seule fonction.
  final int amountInCents;

  /// Code ISO à trois lettres. Les totaux se cumulent **par devise**, jamais
  /// entre elles.
  final String currency;

  /// Échéance, fin de journée en UTC.
  final DateTime? dueAt;

  final FeeScopeInput appliesTo;

  const FeeInput({
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.appliesTo,
  });

  FeeInput copyWith({
    String? feeCode,
    String? label,
    int? amountInCents,
    String? currency,
    DateTime? dueAt,
    FeeScopeInput? appliesTo,
  }) {
    return FeeInput(
      feeCode: feeCode ?? this.feeCode,
      label: label ?? this.label,
      amountInCents: amountInCents ?? this.amountInCents,
      currency: currency ?? this.currency,
      dueAt: dueAt ?? this.dueAt,
      appliesTo: appliesTo ?? this.appliesTo,
    );
  }

  @override
  List<Object?> get props => [
    feeCode,
    label,
    amountInCents,
    currency,
    dueAt,
    appliesTo,
  ];
}

/// Portée d'un frais.
enum FeeScope {
  /// Tous les niveaux qui reçoivent au moins une classe — le frais dû par tous.
  allOpenedLevels('ALL_OPENED_LEVELS'),

  /// Les seuls niveaux désignés — cantine, internat.
  levels('LEVELS');

  const FeeScope(this.wire);

  final String wire;

  static FeeScope fromWire(String? wire) {
    for (final scope in values) {
      if (scope.wire == wire) return scope;
    }
    return allOpenedLevels;
  }
}

class FeeScopeInput extends Equatable {
  final FeeScope scope;

  /// Codes de niveaux, seulement pour [FeeScope.levels]. Au moins un, sinon 422.
  final List<String> levelCatalogCodes;

  const FeeScopeInput({
    required this.scope,
    this.levelCatalogCodes = const <String>[],
  });

  const FeeScopeInput.allOpenedLevels()
    : scope = FeeScope.allOpenedLevels,
      levelCatalogCodes = const <String>[];

  bool get isValid =>
      scope == FeeScope.allOpenedLevels || levelCatalogCodes.isNotEmpty;

  @override
  List<Object?> get props => [scope, levelCatalogCodes];
}
