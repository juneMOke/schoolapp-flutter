import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';

abstract class EnrollmentOfflineEvent extends Equatable {
  const EnrollmentOfflineEvent();

  @override
  List<Object?> get props => [];
}

/// Charge la liste locale (option : filtre statut).
class LoadLocalEnrollments extends EnrollmentOfflineEvent {
  final String? status;

  const LoadLocalEnrollments({this.status});

  @override
  List<Object?> get props => [status];
}

/// Recherche locale par nom.
class SearchLocalEnrollmentsByName extends EnrollmentOfflineEvent {
  final String query;

  const SearchLocalEnrollmentsByName(this.query);

  @override
  List<Object?> get props => [query];
}

/// Charge le détail local d'un dossier.
class LoadLocalEnrollmentDetail extends EnrollmentOfflineEvent {
  final String enrollmentId;

  const LoadLocalEnrollmentDetail(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

/// Confirme un dossier en local-first (retour immédiat, push en fond).
class ConfirmLocalEnrollment extends EnrollmentOfflineEvent {
  final ConfirmEnrollmentDraft draft;

  const ConfirmLocalEnrollment(this.draft);

  @override
  List<Object?> get props => [draft.hashCode];
}
