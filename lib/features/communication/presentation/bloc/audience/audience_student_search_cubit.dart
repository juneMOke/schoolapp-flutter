import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_audience_repository.dart';

class AudienceStudentSearchState extends Equatable {
  final String query;
  final bool loading;
  final List<AudienceStudent> results;
  final Failure? failure;

  const AudienceStudentSearchState({
    this.query = '',
    this.loading = false,
    this.results = const [],
    this.failure,
  });

  /// La recherche ne part qu'à partir de deux caractères.
  bool get tooShort =>
      query.trim().length < AudienceStudentSearchCubit.minLength;

  @override
  List<Object?> get props => [query, loading, results, failure];
}

/// La recherche d'élèves du mode « Élèves », en ligne : la même règle que le
/// serveur appliquera à l'envoi (inscrits actifs, suspendus exclus).
class AudienceStudentSearchCubit extends Cubit<AudienceStudentSearchState> {
  static const minLength = 2;
  static const defaultDebounce = Duration(milliseconds: 300);

  /// Le silence attendu avant d'appeler ; nul dans les tests.
  final Duration debounce;

  final AnnouncementAudienceRepository _repository;
  Timer? _timer;
  int _ticket = 0;

  AudienceStudentSearchCubit(
    this._repository, {
    this.debounce = defaultDebounce,
  }) : super(const AudienceStudentSearchState());

  void search(String query) {
    _timer?.cancel();
    _ticket++;
    final next = AudienceStudentSearchState(query: query);
    if (next.tooShort) {
      emit(next);
      return;
    }
    emit(AudienceStudentSearchState(query: query, loading: true));
    _timer = Timer(debounce, () => _read(query));
  }

  void clear() => search('');

  Future<void> _read(String query) async {
    final ticket = ++_ticket;
    final result = await _repository.searchStudents(query);
    if (isClosed || ticket != _ticket) return;
    emit(
      result.fold(
        (failure) => AudienceStudentSearchState(query: query, failure: failure),
        (results) => AudienceStudentSearchState(query: query, results: results),
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
