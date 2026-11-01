import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

sealed class CoteSaisieState extends Equatable {
  const CoteSaisieState();

  @override
  List<Object?> get props => const [];
}

final class CoteSaisieIdle extends CoteSaisieState {
  const CoteSaisieIdle();
}

final class CoteSaisieLoading extends CoteSaisieState {
  const CoteSaisieLoading();
}

enum CoteEmptyReason { noStudents, noCourses }

final class CoteSaisieEmpty extends CoteSaisieState {
  final CoteEmptyReason reason;

  const CoteSaisieEmpty(this.reason);

  @override
  List<Object?> get props => [reason];
}

final class CoteSaisieFailure extends CoteSaisieState {
  final ResultatsErrorType type;
  final String? incidentCode;

  const CoteSaisieFailure(this.type, {this.incidentCode});

  @override
  List<Object?> get props => [type, incidentCode];
}

/// L'écran prêt : une classe, ses cellules, et tout ce qui s'en déduit.
final class CoteSaisieReady extends CoteSaisieState {
  final CoteClasse classe;
  final List<CoteCours> cours;
  final List<CoteEleve> eleves;
  final CoteCellTable cells;
  final CoteScope scope;

  /// Toute l'année, et le sous-ensemble de la portée.
  final List<CoteColumn> year;
  final List<CoteColumn> columns;
  final String currentId;
  final Map<String, CoteEleveCalc> calcs;
  final CoteRanking ranking;
  final CoteProgress progress;

  /// Le serveur n'a pas répondu : la dernière copie de l'appareil.
  final bool fromCache;

  /// Cellules remplacées par une écriture plus récente.
  final Set<CoteCellKey> changedKeys;

  /// Croît à chaque remplacement signalé, avec son nombre : un même nombre deux
  /// fois de suite doit redonner un message.
  final int changedNotice;
  final int changedCount;

  /// Une écriture sur l'appareil a échoué.
  final bool storageFailed;

  const CoteSaisieReady({
    required this.classe,
    required this.cours,
    required this.eleves,
    required this.cells,
    required this.scope,
    required this.year,
    required this.columns,
    required this.currentId,
    required this.calcs,
    required this.ranking,
    required this.progress,
    required this.fromCache,
    this.changedKeys = const {},
    this.changedNotice = 0,
    this.changedCount = 0,
    this.storageFailed = false,
  });

  CoteEleveCalc get current => calcs[currentId]!;

  CoteEleve get currentEleve =>
      eleves.firstWhere((e) => e.studentId == currentId);

  int get currentIndex => eleves.indexWhere((e) => e.studentId == currentId);

  bool get hasPrevious => currentIndex > 0;
  bool get hasNext => currentIndex < eleves.length - 1;

  CoteSaisieReady copyWith({
    CoteCellTable? cells,
    CoteScope? scope,
    List<CoteColumn>? columns,
    String? currentId,
    Map<String, CoteEleveCalc>? calcs,
    CoteRanking? ranking,
    CoteProgress? progress,
    Set<CoteCellKey>? changedKeys,
    int? changedNotice,
    int? changedCount,
    bool? storageFailed,
  }) => CoteSaisieReady(
    classe: classe,
    cours: cours,
    eleves: eleves,
    cells: cells ?? this.cells,
    scope: scope ?? this.scope,
    year: year,
    columns: columns ?? this.columns,
    currentId: currentId ?? this.currentId,
    calcs: calcs ?? this.calcs,
    ranking: ranking ?? this.ranking,
    progress: progress ?? this.progress,
    fromCache: fromCache,
    changedKeys: changedKeys ?? this.changedKeys,
    changedNotice: changedNotice ?? this.changedNotice,
    changedCount: changedCount ?? this.changedCount,
    storageFailed: storageFailed ?? this.storageFailed,
  );

  @override
  List<Object?> get props => [
    classe,
    cells.all.length,
    cells,
    scope,
    columns,
    currentId,
    calcs,
    ranking,
    progress,
    fromCache,
    changedKeys,
    changedNotice,
    changedCount,
    storageFailed,
  ];
}
