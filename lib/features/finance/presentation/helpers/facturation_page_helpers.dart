import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form.dart';

class FacturationPageHelpers {
  const FacturationPageHelpers._();

  static List<FacturationLevelOption> buildAcademicOptions(
    List<SchoolLevelGroupBundle> bundles,
  ) {
    final seen = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.group.displayOrder,
      inners: (bundle) => bundle.levels,
      innerOrder: (level) => level.displayOrder,
      mapItem: (bundle, level) => FacturationLevelOption(
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
