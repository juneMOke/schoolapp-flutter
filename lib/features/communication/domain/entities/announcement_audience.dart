import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';

/// Le mode de ciblage, tel que le serveur le discrimine.
enum AudienceMode {
  school('SCHOOL'),
  levels('LEVELS'),
  classrooms('CLASSROOMS'),
  students('STUDENTS'),
  overdue('OVERDUE');

  const AudienceMode(this.wire);

  final String wire;

  static AudienceMode? fromWire(String? raw) {
    for (final value in values) {
      if (value.wire == raw) return value;
    }
    return null;
  }
}

/// À qui s'adresse un communiqué. L'audience est **résolue à l'envoi** par le
/// serveur : elle désigne des élèves, et chaque tuteur joignable de chacun
/// reçoit son message.
sealed class AnnouncementAudience extends Equatable {
  const AnnouncementAudience();

  AudienceMode get mode;

  /// Vrai quand le mode demande une sélection et qu'elle est vide.
  bool get isEmpty;
}

/// Tous les élèves actifs de l'année.
final class SchoolAudience extends AnnouncementAudience {
  const SchoolAudience();

  @override
  AudienceMode get mode => AudienceMode.school;

  @override
  bool get isEmpty => false;

  @override
  List<Object?> get props => const [];
}

/// Les élèves inscrits dans l'un des niveaux, avec ou sans classe.
final class LevelsAudience extends AnnouncementAudience {
  final List<String> levelIds;

  const LevelsAudience(this.levelIds);

  @override
  AudienceMode get mode => AudienceMode.levels;

  @override
  bool get isEmpty => levelIds.isEmpty;

  @override
  List<Object?> get props => [levelIds];
}

/// Les membres des classes choisies.
final class ClassroomsAudience extends AnnouncementAudience {
  final List<String> classroomIds;

  const ClassroomsAudience(this.classroomIds);

  @override
  AudienceMode get mode => AudienceMode.classrooms;

  @override
  bool get isEmpty => classroomIds.isEmpty;

  @override
  List<Object?> get props => [classroomIds];
}

/// Des élèves choisis un à un, retenus s'ils sont encore actifs à l'envoi.
///
/// Seuls les identifiants partent sur le fil. [known] porte les noms que
/// l'éditeur a choisis, ou que le serveur rend avec l'audience : de quoi
/// afficher une pastille par élève sans relire la base.
final class StudentsAudience extends AnnouncementAudience {
  final List<AudienceStudent> known;
  final List<String> studentIds;

  StudentsAudience(this.known)
    : studentIds = [for (final student in known) student.id];

  /// Les seuls identifiants, quand aucun nom n'est connu.
  const StudentsAudience.ids(this.studentIds) : known = const [];

  /// Le nom de l'élève [id], `null` s'il n'est pas connu.
  AudienceStudent? studentOf(String id) {
    for (final student in known) {
      if (student.id == id) return student;
    }
    return null;
  }

  @override
  AudienceMode get mode => AudienceMode.students;

  @override
  bool get isEmpty => studentIds.isEmpty;

  @override
  List<Object?> get props => [studentIds];
}

/// Les élèves en retard de paiement : au moins une créance échue depuis plus
/// de [overdueDays] jours, avec un reste dû.
///
/// [feeCode] = la **nature** (`TUITION`…), [tariffCode] = la tranche (`T1`),
/// qui n'est unique qu'avec sa nature. Les deux à `null` = tous les frais ;
/// une tranche sans nature est refusée par le serveur.
final class OverdueAudience extends AnnouncementAudience {
  final String? feeCode;
  final String? tariffCode;
  final int overdueDays;

  const OverdueAudience({this.feeCode, this.tariffCode, this.overdueDays = 0})
    : assert(tariffCode == null || feeCode != null);

  @override
  AudienceMode get mode => AudienceMode.overdue;

  @override
  bool get isEmpty => false;

  @override
  List<Object?> get props => [feeCode, tariffCode, overdueDays];
}
