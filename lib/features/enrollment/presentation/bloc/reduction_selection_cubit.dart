import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/reduction_grant_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/grantable_reduction.dart';

enum ReductionSelectionStatus { initial, loading, ready, failure }

class ReductionSelectionState extends Equatable {
  final ReductionSelectionStatus status;
  final List<GrantableReduction> options;
  final Set<String> selected;

  const ReductionSelectionState({
    this.status = ReductionSelectionStatus.initial,
    this.options = const [],
    this.selected = const {},
  });

  /// Ce que la section affiche : le barème, **suivi des octrois orphelins**.
  ///
  /// Un code octroyé dont le type a quitté le barème — ou dont le barème n'est
  /// pas communiqué faute de `finance.grid.read` — n'a pas d'option en face.
  /// Ne montrer que le barème le rendrait alors **invisible** : la réduction
  /// existerait en base, partirait dans l'agrégat, et l'écran de consultation
  /// n'en dirait rien. Un dossier qui cache ce qu'il porte est pire qu'un
  /// libellé laid.
  ///
  /// Faute de libellé, l'orphelin s'affiche sous son code. Le guichet peut au
  /// moins le nommer à quelqu'un.
  List<GrantableReduction> get entries {
    final known = {for (final option in options) option.code};
    final orphans = selected.where((code) => !known.contains(code)).toList()
      ..sort();
    return [
      ...options,
      for (final code in orphans) GrantableReduction(code: code, label: code),
    ];
  }

  /// Rien à montrer : ni barème, ni octroi hérité. La section s'escamote — un
  /// cadre vide ferait chercher au guichet ce qui manque.
  bool get isEmpty => entries.isEmpty;

  ReductionSelectionState copyWith({
    ReductionSelectionStatus? status,
    List<GrantableReduction>? options,
    Set<String>? selected,
  }) => ReductionSelectionState(
    status: status ?? this.status,
    options: options ?? this.options,
    selected: selected ?? this.selected,
  );

  @override
  List<Object?> get props => [status, options, selected];
}

/// Les réductions cochées au guichet (ADR-021 V1).
///
/// **Aucun montant n'en dépend, et c'est le contrat de la V1** : ce cubit ne
/// touche pas aux créances, ne les recalcule pas, ne les rafraîchit pas. Il
/// enregistre une déclaration, rien de plus.
///
/// **Chaque clic persiste.** L'étape Frais n'a pas de bouton « Enregistrer »
/// (PARCOURS 21 : lecture seule, « Continuer » pour seule action), donc une
/// case cochée qui attendrait une validation d'étape serait perdue sans que
/// rien ne l'annonce. L'état optimiste bascule d'abord et se rétablit si
/// l'écriture échoue : sur une base locale l'échec est rare, mais une case qui
/// resterait cochée sur un octroi non enregistré mentirait au guichet.
class ReductionSelectionCubit extends Cubit<ReductionSelectionState> {
  final ReductionGrantRepository repository;

  ReductionSelectionCubit(this.repository)
    : super(const ReductionSelectionState());

  Future<void> load(String enrollmentId) async {
    emit(state.copyWith(status: ReductionSelectionStatus.loading));

    final options = await repository.grantable();
    final granted = await repository.grantedFor(enrollmentId);

    emit(
      ReductionSelectionState(
        status: options.isLeft() || granted.isLeft()
            ? ReductionSelectionStatus.failure
            : ReductionSelectionStatus.ready,
        options: options.getOrElse(() => const []),
        // Un octroi dont le type a disparu du barème ne se propose plus, mais
        // il ne se perd pas non plus en silence : il reste sélectionné, et
        // c'est l'envoi qui le portera. Le retirer d'office reviendrait à
        // révoquer une réduction parce qu'une liste a changé.
        selected: granted.getOrElse(() => const []).toSet(),
      ),
    );
  }

  /// Bascule un code et **persiste immédiatement**.
  Future<void> toggle(String enrollmentId, String code) async {
    final previous = state.selected;
    final next = {...previous};
    if (!next.remove(code)) next.add(code);

    emit(state.copyWith(selected: next));

    final result = await repository.replaceGrants(
      enrollmentId,
      next.toList(growable: false)..sort(),
    );
    result.fold((_) {
      if (isClosed) return;
      emit(state.copyWith(selected: previous));
    }, (_) {});
  }
}
