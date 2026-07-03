import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

enum PeriodesScolairesStatus { initial, loading, success, empty, failure }

/// État du chargement des grandes périodes (alimente le sélecteur de période).
///
/// [PeriodesScolairesStatus.empty] = année sans période exploitable (rare : la
/// carte de recherche désactive alors le bouton « Afficher »).
class PeriodesScolairesState extends Equatable {
  final PeriodesScolairesStatus status;
  final List<PeriodeScolaire> periodes;
  final ResultatsErrorType errorType;

  const PeriodesScolairesState({
    this.status = PeriodesScolairesStatus.initial,
    this.periodes = const [],
    this.errorType = ResultatsErrorType.none,
  });

  PeriodesScolairesState copyWith({
    PeriodesScolairesStatus? status,
    List<PeriodeScolaire>? periodes,
    ResultatsErrorType? errorType,
  }) => PeriodesScolairesState(
    status: status ?? this.status,
    periodes: periodes ?? this.periodes,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, periodes, errorType];
}
