import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la liste nominative du bloc E laisse voir de son titre, de son pied
/// et de ses exports.
///
/// - Le titre R10 et le pied ne parlent que d'une page qui répond à la
///   question **affichée** (même question, même onglet, même recherche) :
///   une page d'une autre question mentirait (R14).
/// - Les exports ne s'arment que sur une liste chargée (`success`), en
///   ligne, et sur un onglet non vide.
/// - Sous un 403, ils disparaissent, haut et bas (Q1) : pas de bouton
///   inactif à la raison fausse.
class RecoveryStudentsExportGate {
  /// La page qui répond à la question affichée, sinon `null`.
  final RecoveryStudentsPage? page;

  /// Le compte de l'onglet actif, lu sur [page].
  final int? tabCount;

  /// Faux sous un 403 : les boutons d'export ne se montrent pas.
  final bool visible;
  final bool armed;
  final String? reason;

  const RecoveryStudentsExportGate._({
    required this.page,
    required this.tabCount,
    required this.visible,
    required this.armed,
    required this.reason,
  });

  factory RecoveryStudentsExportGate.of({
    required RecoveryStudentsState students,
    required RecoveryStudentsQuery exportQuery,
    required String search,
    required bool online,
    required String? offlineReason,
    required AppLocalizations l10n,
  }) {
    final page = answers(students.query, exportQuery, search)
        ? students.page
        : null;
    final tabCount = page == null
        ? null
        : countOf(page.counts, exportQuery.tab);
    final failure = students.failure;
    final forbidden =
        students.status == RecoveryLoadStatus.failure &&
        failure != null &&
        EteeloErrorType.fromFailure(failure) == EteeloErrorType.forbidden;
    final loaded =
        students.status == RecoveryLoadStatus.success && page != null;
    final String? reason;
    if (!online) {
      reason = offlineReason;
    } else if (!loaded) {
      reason = l10n.recoveryStudentsExportAwaitList;
    } else {
      reason = l10n.recoveryStudentsExportEmpty;
    }
    return RecoveryStudentsExportGate._(
      page: page,
      tabCount: tabCount,
      visible: !forbidden,
      armed: !forbidden && online && loaded && (tabCount ?? 0) > 0,
      reason: reason,
    );
  }

  /// La requête de l'état répond-elle à la question affichée ? Le numéro de
  /// page n'y entre pas : une autre page de la même liste garde son titre.
  static bool answers(
    RecoveryStudentsQuery? asked,
    RecoveryStudentsQuery shown,
    String search,
  ) {
    if (asked == null) return false;
    final trimmed = search.trim();
    return asked.question == shown.question &&
        asked.tab == shown.tab &&
        asked.classroomId == shown.classroomId &&
        asked.situation == shown.situation &&
        asked.trimmedSearch == (trimmed.isEmpty ? null : trimmed);
  }

  static int countOf(RecoveryTabCounts c, RecoveryTab t) => switch (t) {
    RecoveryTab.toChase => c.toChase,
    RecoveryTab.inOrder => c.inOrder,
    RecoveryTab.all => c.all,
  };
}
