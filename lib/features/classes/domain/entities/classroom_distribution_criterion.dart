enum ClassroomDistributionCriterion {
  gender,
  percentage;

  String toApiValue() => switch (this) {
    ClassroomDistributionCriterion.gender => 'GENDER',
    ClassroomDistributionCriterion.percentage => 'PERCENTAGE',
  };
}
