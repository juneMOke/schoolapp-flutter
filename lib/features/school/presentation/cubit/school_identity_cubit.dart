import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';

part 'school_identity_state.dart';

/// Porte l'identité de l'établissement courant pour les surfaces qui la
/// nomment (bandeau de l'Accueil aujourd'hui, en-têtes de pièces demain).
///
/// Instance app-lifetime fournie par `main.dart` : [load] est rejoué à
/// l'ouverture de session et au retour réseau (le référentiel a pu être pullé
/// entre-temps), [clear] à la déconnexion — sans quoi une reconnexion sur une
/// autre école garderait le nom de la précédente.
class SchoolIdentityCubit extends Cubit<SchoolIdentityState> {
  final SchoolRepository _repository;

  SchoolIdentityCubit({required SchoolRepository repository})
    : _repository = repository,
      super(const SchoolIdentityState.unknown());

  /// Relit l'identité en local. Un échec de lecture n'est pas remonté : il se
  /// traduit par une identité inconnue, donc par le libellé générique.
  Future<void> load() async {
    final result = await _repository.loadCurrentSchool();
    if (isClosed) return;
    result.fold(
      (_) => emit(const SchoolIdentityState.unknown()),
      (school) => emit(SchoolIdentityState(school: school)),
    );
  }

  void clear() => emit(const SchoolIdentityState.unknown());
}
