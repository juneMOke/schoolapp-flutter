import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_reach.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';

enum ReachStatus {
  /// Aucune sélection dans un mode qui en demande une : rien à compter.
  invalid,
  loading,
  ready,
  failure,
}

class AnnouncementReachState extends Equatable {
  final ReachStatus status;
  final AnnouncementAudience? audience;
  final AnnouncementReach? reach;
  final Failure? failure;

  const AnnouncementReachState({
    this.status = ReachStatus.invalid,
    this.audience,
    this.reach,
    this.failure,
  });

  /// `false` seulement quand le serveur l'a dit : une portée pas encore lue
  /// ne bloque rien.
  bool get whatsappDisabled => reach?.whatsappEnabled == false;

  /// La portée lue pour [target] exactement — `null` pendant un calcul ou pour
  /// une autre audience : un récapitulatif n'annonce jamais un chiffre périmé.
  AnnouncementReach? settledFor(AnnouncementAudience target) =>
      status == ReachStatus.ready && audience == target ? reach : null;

  @override
  List<Object?> get props => [status, audience, reach, failure];
}

/// La portée de l'audience en cours, recalculée par le serveur à chaque
/// changement — après un court silence, pour ne pas appeler à chaque coche.
class AnnouncementReachCubit extends Cubit<AnnouncementReachState> {
  static const defaultDebounce = Duration(milliseconds: 300);

  /// Le silence attendu avant d'appeler ; nul dans les tests.
  final Duration debounce;

  final AnnouncementAudienceRepository _repository;
  Timer? _timer;
  int _ticket = 0;

  AnnouncementReachCubit(this._repository, {this.debounce = defaultDebounce})
    : super(const AnnouncementReachState());

  void update(AnnouncementAudience audience) {
    _timer?.cancel();
    // Toute lecture déjà partie vaut pour une audience qui n'est plus celle-ci.
    _ticket++;
    if (audience.isEmpty) {
      emit(AnnouncementReachState(audience: audience));
      return;
    }
    emit(
      AnnouncementReachState(
        status: ReachStatus.loading,
        audience: audience,
        reach: state.reach,
      ),
    );
    _timer = Timer(debounce, () => _read(audience));
  }

  Future<void> retry() async {
    final audience = state.audience;
    if (audience == null || audience.isEmpty) return;
    emit(
      AnnouncementReachState(status: ReachStatus.loading, audience: audience),
    );
    await _read(audience);
  }

  Future<void> _read(AnnouncementAudience audience) async {
    final ticket = ++_ticket;
    final result = await _repository.reach(audience);
    // Une réponse arrivée après un changement plus récent est jetée.
    if (isClosed || ticket != _ticket) return;
    emit(
      result.fold(
        (failure) => AnnouncementReachState(
          status: ReachStatus.failure,
          audience: audience,
          failure: failure,
        ),
        (reach) => AnnouncementReachState(
          status: ReachStatus.ready,
          audience: audience,
          reach: reach,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
