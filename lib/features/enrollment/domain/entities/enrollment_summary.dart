import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

class EnrollmentSummary extends Equatable {
  final String enrollmentId;
  final String enrollmentCode;
  final String status;
  final StudentSummary student;

  /// Type d'inscription (valeur API : `NEW_ENROLLMENT` / `RE_ENROLLMENT` /
  /// `PRE_ENROLLMENT`). Axe **orthogonal** au [status] : un dossier de
  /// réinscription porte légitimement `status = PRE_REGISTERED` tout en étant
  /// de type `RE_ENROLLMENT`. Null pour un résumé issu du serveur (le DTO
  /// online ne l'expose pas encore) → l'UI retombe sur l'affichage par statut.
  /// Voir [isReEnrollment].
  final String? enrollmentType;

  /// État de synchro du dossier LOCAL projeté dans la liste (null pour un
  /// résumé issu du serveur, qui n'a pas d'axe synchro). Sert à distinguer un
  /// **brouillon local** (`DRAFT`, repris depuis le listing) des dossiers
  /// autoritaires. Voir [isLocalDraft].
  final SyncState? syncState;

  const EnrollmentSummary({
    required this.enrollmentId,
    required this.enrollmentCode,
    required this.status,
    required this.student,
    this.enrollmentType,
    this.syncState,
  });

  /// Vrai pour un brouillon local du wizard offline (non finalisé, non
  /// synchronisé) : la ligne est repérée « Brouillon » et son tap reprend le
  /// wizard au lieu d'ouvrir la consultation.
  bool get isLocalDraft => syncState == SyncState.draft;

  /// Vrai pour un dossier de **réinscription** (type `RE_ENROLLMENT`) : la ligne
  /// affiche une pastille de type « Réinscription » à la place du statut, pour
  /// ne pas le confondre avec une pré-inscription (même `status` PRE_REGISTERED,
  /// type différent).
  bool get isReEnrollment => enrollmentType == 'RE_ENROLLMENT';

  /// Vrai pour un **candidat de réinscription** du vivier N-1 pas encore
  /// transformé en dossier (`enrollmentId` vide — même convention que le routage
  /// du tap dans le scaffold : id vide → seed d'un nouveau brouillon RE). La
  /// ligne affiche « À réinscrire » plutôt que le statut brut `PENDING`.
  bool get isReenrollmentCandidate => enrollmentId.isEmpty;

  @override
  List<Object?> get props => [
    enrollmentId,
    enrollmentCode,
    status,
    student,
    enrollmentType,
    syncState,
  ];
}
