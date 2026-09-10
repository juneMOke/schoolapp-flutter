import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';

export 'package:school_app_flutter/features/enrollment/presentation/contracts/enrollment_load_status.dart';

/// Un élève de la liste, **nommé quand on peut le nommer**.
class RecouvrementCallListRow extends Equatable {
  final String studentId;

  /// `null` quand le registre des inscriptions ne connaît pas cet élève.
  ///
  /// ⚠️ **Ce n'est pas une anomalie.** Le tableau de bord découvre sa
  /// population dans le **grand-livre** ; l'écran nominatif, lui, croise les
  /// **inscriptions**. Un élève qui a quitté l'école en gardant une dette est
  /// donc compté ici et absent là-bas — c'est voulu, une dette ne s'efface pas
  /// d'un départ. Le rendu écrit alors son identifiant plutôt que de le faire
  /// disparaître : un élève qui sort d'une liste de relance sans que personne
  /// ne le remarque, c'est une créance qu'on cesse d'appeler.
  final String? displayName;

  final MoneyBag expected;
  final MoneyBag paid;
  final MoneyBag remaining;

  const RecouvrementCallListRow({
    required this.studentId,
    required this.displayName,
    required this.expected,
    required this.paid,
    required this.remaining,
  });

  @override
  List<Object?> get props => [
    studentId,
    displayName,
    expected,
    paid,
    remaining,
  ];
}

class RecouvrementCallListState extends Equatable {
  final EnrollmentLoadStatus status;

  /// Les élèves visés, **triés par nom** puis par identifiant : c'est une liste
  /// qu'on appelle, l'ordre alphabétique est le seul qui serve. Les élèves sans
  /// nom ferment la marche.
  final List<RecouvrementCallListRow> rows;

  const RecouvrementCallListState({
    this.status = EnrollmentLoadStatus.initial,
    this.rows = const <RecouvrementCallListRow>[],
  });

  @override
  List<Object?> get props => [status, rows];
}

/// L'aperçu nominatif d'un groupe visé — **avant** d'éditer quoi que ce soit.
///
/// La spec l'exige dans cet ordre : on clique un groupe, on lit qui est
/// concerné, et alors seulement on décide d'en faire du papier. Émettre
/// directement au clic ferait signer une liste qu'on n'a pas lue.
///
/// **Lecture 100 % locale, et aucune écriture.** Les montants viennent du
/// registre déjà en mémoire ; seuls les noms se lisent, dans les inscriptions.
class RecouvrementCallListCubit extends Cubit<RecouvrementCallListState> {
  final SearchLocalEnrollmentsUseCase _searchEnrollments;

  RecouvrementCallListCubit({
    required SearchLocalEnrollmentsUseCase searchEnrollments,
  }) : _searchEnrollments = searchEnrollments,
       super(const RecouvrementCallListState());

  int _generation = 0;

  /// Nomme [targeted], qui vient déjà filtré par la simulation.
  ///
  /// [schoolLevelId] borne la recherche des noms au niveau visé : on ne lit pas
  /// l'école entière pour nommer trente élèves.
  Future<void> load({
    required String academicYearId,
    required String schoolLevelId,
    required List<LocalRecoveryLine> targeted,
  }) async {
    final generation = ++_generation;
    emit(const RecouvrementCallListState(status: EnrollmentLoadStatus.loading));

    final outcome = await _searchEnrollments.currentYearEnrolled(
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
    );
    if (generation != _generation || isClosed) return;

    // ⚠️ **Un échec de nommage ne fait pas échouer l'aperçu.** Les montants
    // sont déjà là ; sans les noms, la liste reste lisible par identifiants et
    // le papier, lui, sera nommé par le serveur. Tomber en erreur ici ferait
    // perdre une information exacte pour une information d'appoint.
    final names = <String, String>{};
    outcome.fold((_) {}, (items) {
      for (final item in items) {
        names[item.studentId] = '${item.lastName} ${item.firstName}'.trim();
      }
    });

    final rows =
        [
          for (final line in targeted)
            RecouvrementCallListRow(
              studentId: line.studentId,
              displayName: names[line.studentId],
              expected: line.expected,
              paid: line.paidTotal,
              remaining: line.remaining,
            ),
        ]..sort((a, b) {
          // Les sans-nom ferment la marche : les intercaler sous un identifiant
          // opaque casserait l'ordre alphabétique qu'on vient chercher.
          final an = a.displayName;
          final bn = b.displayName;
          if (an == null && bn != null) return 1;
          if (an != null && bn == null) return -1;
          final byName = (an ?? '').compareTo(bn ?? '');
          return byName != 0 ? byName : a.studentId.compareTo(b.studentId);
        });

    emit(
      RecouvrementCallListState(
        status: EnrollmentLoadStatus.success,
        rows: rows,
      ),
    );
  }
}
