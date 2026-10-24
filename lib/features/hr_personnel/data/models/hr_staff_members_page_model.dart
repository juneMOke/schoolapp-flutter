import 'package:school_app_flutter/features/hr_personnel/data/models/hr_staff_dashboard_wire.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Miroir de `StaffMemberPageDto` (`GET /hr/staff-stats/members`).
///
/// Une ligne illisible fait échouer la page : l'écarter fausserait
/// `totalElements`, et la pagination annoncerait un agent absent.
abstract final class HrStaffMembersPageModel {
  static HrStaffMembersPage fromJson(Map<String, dynamic> json) =>
      HrStaffMembersPage(
        totalElements: (json['totalElements'] as num).toInt(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 0,
        items: [
          for (final raw in (json['items'] as List<dynamic>? ?? const []))
            _rowOf(raw as Map<String, dynamic>),
        ],
      );

  static HrStaffMemberRow _rowOf(Map<String, dynamic> json) {
    final dossier = json['dossier'] as Map<String, dynamic>?;
    return HrStaffMemberRow(
      id: json['id'] as String,
      staffNumber: json['staffNumber'] as String,
      lastName: json['lastName'] as String,
      middleName: _textOrNull(json['middleName']),
      firstName: _textOrNull(json['firstName']),
      sex: StaffSex.fromWire(json['sex'] as String?),
      category: HrStaffDashboardWire.categoryOf(json['category']),
      jobTitle: _textOrNull(json['jobTitle']),
      entryDate: _textOrNull(json['entryDate']),
      seniorityYears: (json['seniorityYears'] as num?)?.toInt(),
      contractKind: StaffContractKind.fromWire(json['contractKind'] as String?),
      // Absent sans `hr.document.read` : rien à afficher, pas un zéro.
      dossier: dossier == null
          ? null
          : HrDossierCount(
              provided: (dossier['provided'] as num).toInt(),
              required: (dossier['required'] as num).toInt(),
            ),
    );
  }

  /// Un texte vide n'est pas une valeur : il se lit comme absent.
  static String? _textOrNull(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw : null;
}
