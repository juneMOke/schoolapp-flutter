import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';

enum CashReportsStatus { loading, ready, failure }

class CashReportsState extends Equatable {
  final CashReportsStatus status;

  /// Journaliers par défaut (A5).
  final CashReportKind kind;
  final CashReportPage? page;

  /// Les rapports sur période générés pendant la session, le plus récent en
  /// tête : le serveur ne les garde pas (D31).
  final List<CashReport> periodReports;

  /// La plage de « Période » : 14 derniers jours par défaut.
  final DateTime customFrom;
  final DateTime customTo;
  final bool generating;

  /// La page demandée en dernier : « Réessayer » la redemande, même si son
  /// chargement a échoué.
  final int requestedPage;
  final Failure? failure;

  const CashReportsState({
    required this.customFrom,
    required this.customTo,
    this.status = CashReportsStatus.loading,
    this.kind = CashReportKind.daily,
    this.page,
    this.periodReports = const [],
    this.generating = false,
    this.requestedPage = 0,
    this.failure,
  });

  /// La plus longue « Période » que le serveur compose, bornes comprises
  /// (sinon 400 `INVALID_RANGE`).
  static const int maxPeriodDays = 366;

  bool get rangeReversed => customTo.isBefore(customFrom);

  /// Bornes comprises, en jours civils (un changement d'heure ne compte pas).
  bool get rangeTooLong =>
      DateTime.utc(customTo.year, customTo.month, customTo.day)
              .difference(
                DateTime.utc(customFrom.year, customFrom.month, customFrom.day),
              )
              .inDays +
          1 >
      maxPeriodDays;

  bool get rangeInvalid => rangeReversed || rangeTooLong;

  CashReportsState copyWith({
    CashReportsStatus? status,
    CashReportKind? kind,
    CashReportPage? page,
    bool clearPage = false,
    List<CashReport>? periodReports,
    DateTime? customFrom,
    DateTime? customTo,
    bool? generating,
    int? requestedPage,
    Failure? failure,
  }) => CashReportsState(
    status: status ?? this.status,
    kind: kind ?? this.kind,
    page: clearPage ? null : (page ?? this.page),
    periodReports: periodReports ?? this.periodReports,
    customFrom: customFrom ?? this.customFrom,
    customTo: customTo ?? this.customTo,
    generating: generating ?? this.generating,
    requestedPage: requestedPage ?? this.requestedPage,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    kind,
    page,
    // Sans elle, la page lue dans l'adresse se perdait pendant le premier
    // chargement (deux états « égaux ») : Réessayer relisait la page 1.
    requestedPage,
    periodReports,
    customFrom,
    customTo,
    generating,
    failure,
  ];
}

/// Trésorerie ▸ Tableau de bord, les rapports de caisse (A5) : quatre types
/// listés par le serveur, huit par page, et « Période » générée à la demande.
class CashReportsCubit extends Cubit<CashReportsState> {
  final TreasuryReportsRepository _repository;
  var _generation = 0;

  CashReportsCubit(this._repository, {required DateTime today})
    : super(
        CashReportsState(
          customFrom: DateTime(today.year, today.month, today.day - 13),
          customTo: DateTime(today.year, today.month, today.day),
        ),
      );

  /// Changer de type ramène à la première page.
  Future<void> kindChanged(CashReportKind kind) async {
    emit(state.copyWith(kind: kind, clearPage: true, requestedPage: 0));
    if (kind == CashReportKind.period) {
      ++_generation;
      emit(state.copyWith(status: CashReportsStatus.ready));
      return;
    }
    await load(0);
  }

  /// Le type et la page lus dans l'adresse (F5, Précédent, lien) : une seule
  /// lecture, directement sur la page demandée.
  Future<void> applyLocation(CashReportKind kind, int page) async {
    // Type et page changent ensemble : l'adresse ne voit jamais le type sans
    // sa page (elle s'écrirait sans, et ramènerait la première).
    emit(state.copyWith(kind: kind, clearPage: true, requestedPage: page));
    if (kind == CashReportKind.period) {
      ++_generation;
      emit(state.copyWith(status: CashReportsStatus.ready));
      return;
    }
    await load(page);
  }

  Future<void> load([int page = 0]) async {
    if (state.kind == CashReportKind.period) return;
    emit(
      state.copyWith(status: CashReportsStatus.loading, requestedPage: page),
    );
    final generation = ++_generation;
    final result = await _repository.list(state.kind, page);
    if (isClosed || generation != _generation) return;
    emit(
      result.fold(
        (failure) =>
            state.copyWith(status: CashReportsStatus.failure, failure: failure),
        (data) => state.copyWith(status: CashReportsStatus.ready, page: data),
      ),
    );
  }

  void rangeChanged(DateTime from, DateTime to) =>
      emit(state.copyWith(customFrom: from, customTo: to));

  /// Rend l'échec, `null` si le rapport s'est ajouté en tête de liste.
  Future<Failure?> generatePeriod() async {
    if (state.rangeInvalid || state.generating) return null;
    emit(state.copyWith(generating: true));
    final result = await _repository.period(state.customFrom, state.customTo);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(state.copyWith(generating: false));
        return failure;
      },
      (report) {
        emit(
          state.copyWith(
            generating: false,
            periodReports: [
              report,
              // Le même id rejoué ne double pas la ligne : la plage est la
              // même, le rapport aussi.
              for (final r in state.periodReports)
                if (r.id != report.id) r,
            ],
          ),
        );
        return null;
      },
    );
  }
}
