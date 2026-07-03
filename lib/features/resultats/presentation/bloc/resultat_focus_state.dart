import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_focus.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

enum ResultatFocusStatus { initial, loading, success, failure }

/// Sentinelle pour distinguer « champ non fourni » de « remis à null » dans
/// [ResultatFocusState.copyWith] (convention projet pour les champs nullable).
const _undefined = Object();

/// État de la vue focus.
///
/// `bulletinParDomaine == null` (élève non classé sur le groupe) et
/// `synthese.application` / `synthese.conduite == null` (hors périmètre V1) sont
/// des cas **valides** à rendre « — » dans [focus], **pas** des erreurs.
class ResultatFocusState extends Equatable {
  final ResultatFocusStatus status;
  final ResultatFocus? focus;
  final ResultatsErrorType errorType;

  const ResultatFocusState({
    this.status = ResultatFocusStatus.initial,
    this.focus,
    this.errorType = ResultatsErrorType.none,
  });

  ResultatFocusState copyWith({
    ResultatFocusStatus? status,
    Object? focus = _undefined,
    ResultatsErrorType? errorType,
  }) => ResultatFocusState(
    status: status ?? this.status,
    focus: identical(focus, _undefined) ? this.focus : focus as ResultatFocus?,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, focus, errorType];
}
