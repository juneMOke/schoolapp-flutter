import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';

enum SchoolIdentityFormStatus { initial, loading, ready, saving, failure }

/// État du formulaire de l'étape 1.
///
/// Nommé « Form » pour ne pas se confondre avec le `SchoolIdentityCubit` de la
/// feature `school`, qui lit l'identité EN LOCAL (`ref_school`) pour afficher
/// un nom d'établissement. Celui-ci lit et écrit sur le réseau. Deux sources,
/// deux porteurs — et deux noms, sans quoi l'import se choisirait au hasard.
class SchoolIdentityFormState extends Equatable {
  final SchoolIdentityFormStatus status;

  /// L'identité en cours d'édition. `null` tant que la lecture n'a pas répondu.
  final SchoolIdentity? identity;

  /// L'identité telle que le serveur la porte, pour savoir ce qui a changé.
  final SchoolIdentity? saved;

  final Failure? failure;

  /// Un enregistrement vient d'aboutir.
  final bool justSaved;

  const SchoolIdentityFormState({
    this.status = SchoolIdentityFormStatus.initial,
    this.identity,
    this.saved,
    this.failure,
    this.justSaved = false,
  });

  bool get isDirty => identity != null && identity != saved;

  bool get isComplete => identity?.isComplete ?? false;

  /// Champs requis encore vides — ce que la barre de pied nomme.
  List<SchoolIdentityField> get missingFields =>
      identity?.missingFields ?? const <SchoolIdentityField>[];

  SchoolIdentityFormState copyWith({
    SchoolIdentityFormStatus? status,
    SchoolIdentity? identity,
    SchoolIdentity? saved,
    Object? failure = _unchanged,
    bool? justSaved,
  }) {
    return SchoolIdentityFormState(
      status: status ?? this.status,
      identity: identity ?? this.identity,
      saved: saved ?? this.saved,
      failure: identical(failure, _unchanged)
          ? this.failure
          : failure as Failure?,
      justSaved: justSaved ?? this.justSaved,
    );
  }

  static const Object _unchanged = Object();

  @override
  List<Object?> get props => [status, identity, saved, failure, justSaved];
}

/// L'étape 1, séparée du parcours parce qu'elle est **la seule à écrire
/// vraiment**.
///
/// L'école existe déjà : cette étape la corrige, elle ne la crée pas. Le
/// formulaire est donc pré-rempli par lecture, jamais vide — et l'enregistrement
/// est un PUT complet des huit champs, y compris ceux que l'écran montre en
/// lecture seule, dont l'omission rendrait 400.
class SchoolIdentityFormCubit extends Cubit<SchoolIdentityFormState> {
  final ProvisioningRepository _repository;

  SchoolIdentityFormCubit({required ProvisioningRepository repository})
    : _repository = repository,
      super(const SchoolIdentityFormState());

  Future<void> load() async {
    emit(
      state.copyWith(status: SchoolIdentityFormStatus.loading, failure: null),
    );

    final result = await _repository.loadSchoolIdentity();
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SchoolIdentityFormStatus.failure,
          failure: failure,
        ),
      ),
      (identity) => emit(
        state.copyWith(
          status: SchoolIdentityFormStatus.ready,
          identity: identity,
          saved: identity,
          failure: null,
          justSaved: false,
        ),
      ),
    );
  }

  /// Modification d'un champ.
  void edit(SchoolIdentity identity) {
    emit(
      state.copyWith(
        identity: identity,
        justSaved: false,
        failure: null,
        status: state.status == SchoolIdentityFormStatus.failure
            ? SchoolIdentityFormStatus.ready
            : null,
      ),
    );
  }

  /// Changement de district : la commune se vide.
  ///
  /// La cascade descend, elle ne conserve pas une commune qui n'appartient plus
  /// au district choisi. La laisser en place produirait une adresse plausible
  /// et fausse, qui figurerait ensuite sur les attestations et les reçus.
  void selectDistrict(String district) {
    final current = state.identity;
    if (current == null || current.district == district) return;
    emit(
      state.copyWith(
        identity: SchoolIdentity(
          id: current.id,
          name: current.name,
          country: current.country,
          city: current.city,
          district: district,
          municipality: '',
          address: current.address,
          phone: current.phone,
          email: current.email,
        ),
        justSaved: false,
        failure: null,
      ),
    );
  }

  Future<void> save() async {
    final identity = state.identity;
    if (identity == null || !identity.isComplete) return;

    emit(
      state.copyWith(status: SchoolIdentityFormStatus.saving, failure: null),
    );

    final result = await _repository.saveSchoolIdentity(identity);
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SchoolIdentityFormStatus.failure,
          failure: failure,
        ),
      ),
      (persisted) => emit(
        state.copyWith(
          status: SchoolIdentityFormStatus.ready,
          // On repart de ce que le SERVEUR a relu, pas de ce qu'on lui a
          // envoyé : lui seul sait ce qu'il a réellement retenu, et l'écart
          // éventuel doit se voir tout de suite plutôt qu'à la relecture
          // suivante.
          identity: persisted,
          saved: persisted,
          failure: null,
          justSaved: true,
        ),
      ),
    );
  }
}
