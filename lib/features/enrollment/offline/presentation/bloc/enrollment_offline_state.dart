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

class EnrollmentOfflineDetailLoaded extends EnrollmentOfflineState {
  final LocalEnrollmentDetail detail;

  const EnrollmentOfflineDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

class EnrollmentOfflineError extends EnrollmentOfflineState {
  final String message;

  const EnrollmentOfflineError(this.message);

  @override
  List<Object?> get props => [message];
}
