import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultats_classe.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

enum ResultatsClasseStatus { initial, loading, success, empty, failure }

/// Sentinelle pour distinguer « champ non fourni » de « remis à null » dans
/// [ResultatsClasseState.copyWith] (convention projet pour les champs nullable).
const _undefined = Object();

/// État de la vue classe.
///
/// Des `%` `null` et des lignes `nonClasse` sont **normaux** dans [resultats],
/// **pas** une erreur. [ResultatsClasseStatus.empty] = classe sans élève à
/// afficher (`lignes` vide ou `effectif == 0`).
class ResultatsClasseState extends Equatable {
  final ResultatsClasseStatus status;
  final ResultatsClasse? resultats;
  final ResultatsErrorType errorType;

  const ResultatsClasseState({
    this.status = ResultatsClasseStatus.initial,
    this.resultats,
    this.errorType = ResultatsErrorType.none,
  });

  ResultatsClasseState copyWith({
    ResultatsClasseStatus? status,
    Object? resultats = _undefined,
    ResultatsErrorType? errorType,
  }) => ResultatsClasseState(
    status: status ?? this.status,
    resultats: identical(resultats, _undefined)
        ? this.resultats
        : resultats as ResultatsClasse?,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, resultats, errorType];
}
