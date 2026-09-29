import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Une pièce du dossier, et les contrats qui l'exigent — servie par le socle
/// (`staffDocumentTypes`), jamais codée en dur sur le poste.
class StaffDocumentType extends Equatable {
  final StaffDocumentCode? code;
  final String rawCode;
  final String label;

  /// Exigée de tout agent, contrat posé ou non.
  final bool alwaysRequired;
  final Set<StaffContractKind> requiredFor;

  const StaffDocumentType({
    required this.code,
    required this.rawCode,
    required this.label,
    required this.alwaysRequired,
    required this.requiredFor,
  });

  /// Exigée d'un agent dont le contrat en vigueur est [kind] (`null` = aucun
  /// contrat posé : seules les pièces communes le sont).
  bool isRequiredFor(StaffContractKind? kind) =>
      alwaysRequired || (kind != null && requiredFor.contains(kind));

  @override
  List<Object?> get props => [rawCode, label, alwaysRequired, requiredFor];
}
