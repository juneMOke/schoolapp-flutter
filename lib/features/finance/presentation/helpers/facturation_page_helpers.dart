import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form.dart';

class FacturationPageHelpers {
  const FacturationPageHelpers._();

  static List<FacturationLevelOption> buildAcademicOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final seen = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.schoolLevelGroup.displayOrder,
      inners: (bundle) => bundle.schoolLevels,
      innerOrder: (levelBundle) => levelBundle.schoolLevel.displayOrder,
      mapItem: (bundle, levelBundle) => FacturationLevelOption(
        schoolLevelGroupId: bundle.schoolLevelGroup.id,
        schoolLevelId: levelBundle.schoolLevel.id,
        label:
            '${bundle.schoolLevelGroup.name} - ${levelBundle.schoolLevel.name}',
      ),
    );

    return sortedOptions
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }
}
