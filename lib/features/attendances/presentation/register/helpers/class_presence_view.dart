import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La ligne d'un élève telle que la montrent les widgets communs du registre.
///
/// L'envoi se suit à l'échelle de l'appel (une classe, un jour) : un refus se
/// lit et se reprend dans le bandeau de l'appel validé, pas carte par carte.
extension ClassPresenceLineView on ClassPresenceLine {
  PresenceRowView presenceView(AppLocalizations l10n, String classroomName) {
    final justification = mark.justification;
    return PresenceRowView(
      personId: student.id,
      firstName: student.firstName,
      lastName: student.lastName,
      title: student.familyName,
      subtitle: l10n.classPresenceSubtitle(
        student.firstName,
        student.number,
        classroomName,
      ),
      status: status,
      arrival: mark.arrival,
      lateMinutes: mark.lateMinutes,
      justificationLabel: justification?.reason.getDisplayName(l10n),
      sync: sync,
    );
  }
}
