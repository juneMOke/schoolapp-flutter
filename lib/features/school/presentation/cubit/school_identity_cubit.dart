import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/school/domain/entities/school.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/domain/repositories/school_repository.dart';

part 'school_identity_state.dart';

/// Porte l'identité de l'établissement courant pour les surfaces qui la
/// nomment ou la signent (bandeau de l'Accueil et tête de la barre latérale
/// aujourd'hui, en-têtes de pièces demain).
///
/// Instance app-lifetime fournie par `main.dart` : [load] est rejoué à
/// l'ouverture de session, au retour réseau et à chaque cycle de pull qui a
/// ramené des données (le référentiel — donc le sceau — a pu descendre
/// entre-temps), [clear] à la déconnexion — sans quoi une reconnexion sur une
/// autre école garderait le nom et le logo de la précédente.
class SchoolIdentityCubit extends Cubit<SchoolIdentityState> {
  final SchoolRepository _repository;

  SchoolIdentityCubit({required SchoolRepository repository})
    : _repository = repository,
      super(const SchoolIdentityState.unknown());

  /// Relit l'identité et le sceau en local. Un échec de lecture n'est pas
  /// remonté : il se traduit par une identité inconnue, donc par le nom et le
  /// symbole de marque.
  ///
  /// Les deux lectures se rejoignent en **un seul `emit`** : émettre le nom
  /// puis le logo ferait clignoter les surfaces de marque à chaque cycle de
  /// pull, pour un état intermédiaire qui n'a jamais existé.
  ///
  /// Rejouée souvent (chaque pull fructueux), elle ne coûte pourtant un rendu
  /// que si quelque chose a bougé : `SchoolLogo` s'égalise sur son empreinte,
  /// donc relire les mêmes octets ne ré-émet rien.
  Future<void> load() async {
    final identity = await _repository.loadCurrentSchool();
    final logo = await _repository.loadCurrentSchoolLogo();
    if (isClosed) return;

    emit(
      SchoolIdentityState(
        school: identity.fold((_) => null, (school) => school),
        logo: logo.fold((_) => null, (logo) => logo),
      ),
    );
  }

  void clear() => emit(const SchoolIdentityState.unknown());
}
