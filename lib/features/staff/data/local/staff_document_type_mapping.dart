import 'package:school_app_flutter/core/staff/local/staff_document_type_local_model.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Le modèle du référentiel vit dans `core` (le référentiel l'écrit) ; son
/// entité appartient au module. La conversion se fait donc ici.
extension StaffDocumentTypeMapping on StaffDocumentTypeLocalModel {
  StaffDocumentType toEntity() => StaffDocumentType(
    code: StaffDocumentCode.fromWire(code),
    rawCode: code,
    label: label,
    alwaysRequired: alwaysRequired,
    requiredFor: {
      for (final kind in requiredFor) ?StaffContractKind.fromWire(kind),
    },
  );
}
