import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

enum EleveSearchStatus { initial, loading, success, empty, failure }

/// État de la recherche « Par élève ».
///
/// [EleveSearchStatus.empty] = aucun élève trouvé (« Aucun élève trouvé »). La
/// sélection d'un résultat déclenche un `ResultatFocusRequested` côté UI/scope
/// (les BLoCs restent indépendants). [resultats] est ordonné par le backend
/// (nom puis prénom) : conserver l'ordre.
class EleveSearchState extends Equatable {
  final EleveSearchStatus status;
  final List<ClassroomMember> resultats;
  final ResultatsErrorType errorType;

  const EleveSearchState({
    this.status = EleveSearchStatus.initial,
    this.resultats = const [],
    this.errorType = ResultatsErrorType.none,
  });

  EleveSearchState copyWith({
    EleveSearchStatus? status,
    List<ClassroomMember>? resultats,
    ResultatsErrorType? errorType,
  }) => EleveSearchState(
    status: status ?? this.status,
    resultats: resultats ?? this.resultats,
    errorType: errorType ?? this.errorType,
  );

  @override
  List<Object?> get props => [status, resultats, errorType];
}
