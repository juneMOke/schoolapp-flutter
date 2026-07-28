import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

class FirstRegistrationPageHelpers {
  const FirstRegistrationPageHelpers._();

  /// Aplatit les cycles/niveaux de l'année **courante** (contrairement au
  /// vivier de réinscription, borné à l'année N-1) en options plates
  /// utilisables par la recherche « par niveau visé ».
  static List<SearchLevelOption> buildAcademicOptions(
    List<SchoolLevelGroupBundle> bundles,
  ) {
    final seenKeys = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.group.displayOrder,
      inners: (bundle) => bundle.levels,
      innerOrder: (level) => level.displayOrder,
      mapItem: (bundle, level) => SearchLevelOption(
        schoolLevelGroupId: bundle.group.id,
        schoolLevelId: level.id,
        label: '${bundle.group.name} - ${level.name}',
      ),
    );

    return sortedOptions
        .where((option) => seenKeys.add(option.key))
        .toList(growable: false);
  }
}
