import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sales_page.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';

const Object _undefined = Object();

enum SalesStatus { initial, loading, ready, failure }

class BoutiqueSalesState extends Equatable {
  final SalesStatus status;

  /// La dernière page lue. Elle reste affichée pendant qu'une autre charge :
  /// la barre de pagination dit l'attente, la table ne clignote pas.
  final BoutiqueSalesPage? page;
  final Failure? failure;

  /// Le mode de la bascule. Seul **son** critère part au serveur.
  final SalesFilterMode mode;
  final ArticleFamily? family;
  final String? classId;

  /// Le libellé de la classe choisie, retenu au geste : une autre période peut
  /// ne plus la porter dans son menu.
  final String? selectedClassLabel;

  /// La question qui a produit [page] — celle que le PDF reprend.
  final SalesQuery? query;

  const BoutiqueSalesState({
    this.status = SalesStatus.initial,
    this.page,
    this.failure,
    this.mode = SalesFilterMode.family,
    this.family,
    this.classId,
    this.selectedClassLabel,
    this.query,
  });

  /// Le critère du mode actif est-il posé ?
  bool get hasFilter => switch (mode) {
    SalesFilterMode.family => family != null,
    SalesFilterMode.classroom => classId != null,
  };

  String? get classLabel {
    if (classId == null) return null;
    for (final c in page?.classes ?? const []) {
      if (c.id == classId) return c.label;
    }
    return selectedClassLabel;
  }

  BoutiqueSalesState copyWith({
    SalesStatus? status,
    Object? page = _undefined,
    Object? failure = _undefined,
    SalesFilterMode? mode,
    Object? family = _undefined,
    Object? classId = _undefined,
    Object? selectedClassLabel = _undefined,
    Object? query = _undefined,
  }) => BoutiqueSalesState(
    status: status ?? this.status,
    page: identical(page, _undefined) ? this.page : page as BoutiqueSalesPage?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    mode: mode ?? this.mode,
    family: identical(family, _undefined)
        ? this.family
        : family as ArticleFamily?,
    classId: identical(classId, _undefined) ? this.classId : classId as String?,
    selectedClassLabel: identical(selectedClassLabel, _undefined)
        ? this.selectedClassLabel
        : selectedClassLabel as String?,
    query: identical(query, _undefined) ? this.query : query as SalesQuery?,
  );

  @override
  List<Object?> get props => [
    status,
    page,
    failure,
    mode,
    family,
    classId,
    selectedClassLabel,
    query,
  ];
}
