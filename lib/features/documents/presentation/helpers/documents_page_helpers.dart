import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/documents_search_form.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

class DocumentsPageHelpers {
  const DocumentsPageHelpers._();

  /// Aplatit les cycles/niveaux du contexte académique en options « cycle -
  /// niveau », ordonnées par `displayOrder` et dédoublonnées par clé composite.
  static List<DocumentsLevelOption> buildAcademicOptions(
    List<SchoolLevelGroupBundle> bundles,
  ) {
    final seen = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.group.displayOrder,
      inners: (bundle) => bundle.levels,
      innerOrder: (level) => level.displayOrder,
      mapItem: (bundle, level) => DocumentsLevelOption(
        schoolLevelGroupId: bundle.group.id,
        schoolLevelId: level.id,
        label: '${bundle.group.name} - ${level.name}',
      ),
    );

    return sortedOptions
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }
}
