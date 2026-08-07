import 'package:school_app_flutter/core/helpers/sorted_nested_options_helper.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';

class ReRegistrationsPageHelpers {
  const ReRegistrationsPageHelpers._();

  static List<ReRegistrationAcademicOption> buildAcademicOptions(
    List<SchoolLevelGroupBundle> bundles,
  ) {
    final seenKeys = <String>{};
    final sortedOptions = SortedNestedOptionsHelper.buildFlat(
      outers: bundles,
      outerOrder: (bundle) => bundle.group.displayOrder,
      inners: (bundle) => bundle.levels,
      innerOrder: (level) => level.displayOrder,
      mapItem: (bundle, level) => ReRegistrationAcademicOption(
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
