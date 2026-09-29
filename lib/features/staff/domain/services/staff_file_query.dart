import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_member_search.dart';

/// Le filtre « contrat » de la liste : un statut, ou les agents sans contrat.
enum StaffContractFilter {
  permanent,
  vacataire,
  conventionne,

  /// « Contrat à poser » : aucun contrat en vigueur.
  none;

  bool matches(StaffContractKind? kind) => switch (this) {
    StaffContractFilter.permanent => kind == StaffContractKind.permanent,
    StaffContractFilter.vacataire => kind == StaffContractKind.vacataire,
    StaffContractFilter.conventionne => kind == StaffContractKind.conventionne,
    StaffContractFilter.none => kind == null,
  };
}

/// Les critères de la liste du personnel. Tous se combinent en ET ; tout se
/// recalcule en mémoire, sans jamais repasser par la base.
class StaffFileQuery extends Equatable {
  final String text;
  final StaffCategory? category;

  /// `null` = tous les contrats.
  final StaffContractFilter? contract;
  final bool incompleteOnly;

  const StaffFileQuery({
    this.text = '',
    this.category,
    this.contract,
    this.incompleteOnly = false,
  });

  static const StaffFileQuery none = StaffFileQuery();

  bool get isActive =>
      text.trim().isNotEmpty ||
      category != null ||
      contract != null ||
      incompleteOnly;

  StaffFileQuery withText(String value) => _copy(text: value);

  StaffFileQuery withCategory(StaffCategory? value) =>
      _copy(category: () => value);

  /// Un second tap sur le filtre actif le retire.
  StaffFileQuery toggleContract(StaffContractFilter? value) =>
      _copy(contract: () => value == contract ? null : value);

  StaffFileQuery toggleIncomplete() => _copy(incompleteOnly: !incompleteOnly);

  /// La ligne passe-t-elle tous les critères ?
  bool accepts(StaffFileRow row) {
    if (category != null && row.member.category != category) return false;
    if (contract != null && !contract!.matches(row.kind)) return false;
    if (incompleteOnly && !row.isIncomplete) return false;
    return StaffMemberSearch.matches(row.member, text);
  }

  StaffFileQuery _copy({
    String? text,
    StaffCategory? Function()? category,
    StaffContractFilter? Function()? contract,
    bool? incompleteOnly,
  }) => StaffFileQuery(
    text: text ?? this.text,
    category: category == null ? this.category : category(),
    contract: contract == null ? this.contract : contract(),
    incompleteOnly: incompleteOnly ?? this.incompleteOnly,
  );

  @override
  List<Object?> get props => [text, category, contract, incompleteOnly];
}
