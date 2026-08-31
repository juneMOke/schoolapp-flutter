import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';

part 'provisioning_request_model.g.dart';

/// Corps de `POST /provisioning/apply`, en simulation comme en activation.
///
/// Les instants partent par [ProvisioningInstant.toUtcInstant] : sur cette
/// route le suffixe `Z` est **obligatoire** — sans lui le corps est illisible et
/// l'appel rend 400.
@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class ProvisioningRequestModel {
  final AcademicYearInputModel academicYear;
  final int? defaultClassroomsPerLevel;
  final List<CycleInputModel> cycles;
  final List<FeeInputModel> fees;

  const ProvisioningRequestModel({
    required this.academicYear,
    required this.defaultClassroomsPerLevel,
    required this.cycles,
    required this.fees,
  });

  /// Construit le corps depuis le brouillon.
  ///
  /// Deux règles y sont tenues, toutes deux imposées par le serveur :
  /// - un cycle **décoché s'omet entièrement** — un cycle retenu sans aucun
  ///   niveau rend 400 ;
  /// - `classrooms` et `sections` ne coexistent **jamais** sur un même niveau —
  ///   les deux ensemble rendent 422.
  factory ProvisioningRequestModel.fromEntity(ProvisioningRequest request) {
    final academicYear = request.academicYear;
    if (academicYear == null) {
      throw StateError(
        'Année académique manquante : la simulation la valide en premier et '
        'rendrait 400.',
      );
    }

    return ProvisioningRequestModel(
      academicYear: AcademicYearInputModel.fromEntity(academicYear),
      defaultClassroomsPerLevel: request.defaultClassroomsPerLevel,
      cycles: request.cycles
          .where((cycle) => cycle.levels.isNotEmpty)
          .map(CycleInputModel.fromEntity)
          .toList(),
      fees: request.fees.map(FeeInputModel.fromEntity).toList(),
    );
  }

  Map<String, dynamic> toJson() => _$ProvisioningRequestModelToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class AcademicYearInputModel {
  final String name;
  final String startDate;
  final String endDate;
  final bool current;

  const AcademicYearInputModel({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  factory AcademicYearInputModel.fromEntity(AcademicYearInput input) =>
      AcademicYearInputModel(
        name: input.name,
        startDate: ProvisioningInstant.toUtcInstant(input.startDate),
        endDate: ProvisioningInstant.toUtcInstant(input.endDate),
        current: input.current,
      );

  Map<String, dynamic> toJson() => _$AcademicYearInputModelToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class CycleInputModel {
  final String catalogCode;
  final List<LevelInputModel> levels;

  const CycleInputModel({required this.catalogCode, required this.levels});

  factory CycleInputModel.fromEntity(CycleInput input) => CycleInputModel(
    catalogCode: input.catalogCode,
    levels: input.levels.map(LevelInputModel.fromEntity).toList(),
  );

  Map<String, dynamic> toJson() => _$CycleInputModelToJson(this);
}

@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class LevelInputModel {
  final String catalogCode;
  final int? classrooms;
  final List<SectionInputModel>? sections;

  const LevelInputModel({
    required this.catalogCode,
    required this.classrooms,
    required this.sections,
  });

  factory LevelInputModel.fromEntity(LevelInput input) {
    // Un niveau à sections n'envoie QUE ses sections : `classrooms` en plus
    // rend 422 (« compteur et sections en conflit »). L'interface doit rendre
    // ce cas inatteignable, et cette conversion est le dernier filet.
    if (input.sections.isNotEmpty) {
      return LevelInputModel(
        catalogCode: input.catalogCode,
        classrooms: null,
        sections: input.sections.map(SectionInputModel.fromEntity).toList(),
      );
    }
    return LevelInputModel(
      catalogCode: input.catalogCode,
      classrooms: input.classrooms,
      sections: null,
    );
  }

  Map<String, dynamic> toJson() => _$LevelInputModelToJson(this);
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class SectionInputModel {
  final String officialCode;
  final int classrooms;

  const SectionInputModel({
    required this.officialCode,
    required this.classrooms,
  });

  factory SectionInputModel.fromEntity(SectionInput input) => SectionInputModel(
    officialCode: input.officialCode,
    classrooms: input.classrooms,
  );

  Map<String, dynamic> toJson() => _$SectionInputModelToJson(this);
}

@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class FeeInputModel {
  final String feeCode;
  final String label;
  final int amountInCents;
  final String currency;
  final String? dueAt;
  final FeeScopeInputModel appliesTo;

  const FeeInputModel({
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.appliesTo,
  });

  factory FeeInputModel.fromEntity(FeeInput input) {
    final dueAt = input.dueAt;
    return FeeInputModel(
      feeCode: input.feeCode,
      label: input.label,
      amountInCents: input.amountInCents,
      currency: input.currency,
      dueAt: dueAt == null ? null : ProvisioningInstant.toUtcInstant(dueAt),
      appliesTo: FeeScopeInputModel.fromEntity(input.appliesTo),
    );
  }

  Map<String, dynamic> toJson() => _$FeeInputModelToJson(this);
}

@JsonSerializable(
  createFactory: false,
  includeIfNull: false,
  explicitToJson: true,
)
class FeeScopeInputModel {
  final String scope;
  final List<String>? levelCatalogCodes;

  const FeeScopeInputModel({
    required this.scope,
    required this.levelCatalogCodes,
  });

  factory FeeScopeInputModel.fromEntity(FeeScopeInput input) {
    // « Tous les niveaux ouverts » n'emporte aucune liste : le serveur résout
    // l'assiette lui-même à partir de la structure, ce qui la garde juste même
    // si le promoteur ajoute un niveau après avoir saisi le frais.
    if (input.scope == FeeScope.allOpenedLevels) {
      return FeeScopeInputModel(
        scope: input.scope.wire,
        levelCatalogCodes: null,
      );
    }
    return FeeScopeInputModel(
      scope: input.scope.wire,
      levelCatalogCodes: input.levelCatalogCodes,
    );
  }

  Map<String, dynamic> toJson() => _$FeeScopeInputModelToJson(this);
}
