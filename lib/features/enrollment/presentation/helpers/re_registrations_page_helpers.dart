import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';

class ReRegistrationsPageHelpers {
  const ReRegistrationsPageHelpers._();

  static List<ReRegistrationAcademicOption> buildAcademicOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final seenKeys = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.schoolLevelGroup.displayOrder,
      inners: (bundle) => bundle.schoolLevels,
      innerOrder: (levelBundle) => levelBundle.schoolLevel.displayOrder,
      mapItem: (bundle, levelBundle) => ReRegistrationAcademicOption(
        schoolLevelGroupId: bundle.schoolLevelGroup.id,
        schoolLevelId: levelBundle.schoolLevel.id,
        label: '${bundle.schoolLevelGroup.name} - ${levelBundle.schoolLevel.name}',
      ),
    );

    return sortedOptions
        .where((option) => seenKeys.add(option.key))
        .toList(growable: false);
  }
}
