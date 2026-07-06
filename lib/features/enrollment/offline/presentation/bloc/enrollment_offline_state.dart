import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';

abstract class EnrollmentOfflineState extends Equatable {
  const EnrollmentOfflineState();

  @override
  List<Object?> get props => [];
}

class EnrollmentOfflineInitial extends EnrollmentOfflineState {
  const EnrollmentOfflineInitial();
}

class EnrollmentOfflineLoading extends EnrollmentOfflineState {
  const EnrollmentOfflineLoading();
}

class EnrollmentOfflineListLoaded extends EnrollmentOfflineState {
  final List<LocalEnrollmentListItem> items;

  const EnrollmentOfflineListLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class EnrollmentOfflineDetailLoaded extends EnrollmentOfflineState {
  final LocalEnrollmentDetail detail;

  const EnrollmentOfflineDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class EnrollmentOfflineConfirming extends EnrollmentOfflineState {
  const EnrollmentOfflineConfirming();
}

/// Confirmé localement : dossier en attente de synchro (matricule « en cours »
/// pour un NEW). C'est l'état pending-sync exposé à l'UI.
class EnrollmentOfflineConfirmedPendingSync extends EnrollmentOfflineState {
  final String enrollmentId;

  const EnrollmentOfflineConfirmedPendingSync(this.enrollmentId);

  @override
  List<Object?> get props => [enrollmentId];
}

class EnrollmentOfflineError extends EnrollmentOfflineState {
  final String message;

  const EnrollmentOfflineError(this.message);

  @override
  List<Object?> get props => [message];
}
