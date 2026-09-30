import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';

/// Tout ce que la tablette sait du fichier du personnel, lu en une fois.
class StaffFileSnapshot extends Equatable {
  /// Les fiches, dans l'ordre de l'état civil.
  final List<StaffMember> members;

  /// Les pièces versées, par agent. Vide pour un compte sans
  /// `hr.document.read` : le flux ne lui est jamais annoncé.
  final Map<String, List<StaffDocument>> documentsByMember;

  /// Les pièces du dossier et les contrats qui les exigent.
  final List<StaffDocumentType> documentTypes;

  /// Le fichier a-t-il déjà été descendu une fois sur cette tablette ? Sans
  /// cela, un fichier vide ne dit rien : jamais téléchargé n'est pas vide.
  final bool hasEverSynced;

  const StaffFileSnapshot({
    required this.members,
    required this.documentsByMember,
    required this.documentTypes,
    required this.hasEverSynced,
  });

  static const StaffFileSnapshot empty = StaffFileSnapshot(
    members: [],
    documentsByMember: {},
    documentTypes: [],
    hasEverSynced: false,
  );

  @override
  List<Object?> get props => [
    members,
    documentsByMember,
    documentTypes,
    hasEverSynced,
  ];
}
