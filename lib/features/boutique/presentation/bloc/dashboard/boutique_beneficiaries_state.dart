import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiaries_page.dart';

const Object _undefined = Object();

enum BeneficiariesStatus { initial, loading, ready, failure }

/// Un article proposé au filtre : tout le catalogue, plus un article retiré que
/// le palmarès aurait désigné.
class BeneficiaryArticleOption extends Equatable {
  final String id;
  final String label;

  const BeneficiaryArticleOption({required this.id, required this.label});

  @override
  List<Object?> get props => [id, label];
}

class BoutiqueBeneficiariesState extends Equatable {
  /// Huit lignes repliées, puis « Voir les n élèves ».
  static const int collapsedCount = 8;

  final BeneficiariesStatus status;
  final BoutiqueBeneficiariesPage? page;
  final Failure? failure;

  /// Les filtres sont **cumulatifs** et **survivent au changement de
  /// période** : on suit le même article sur 30 jours.
  final String? articleId;
  final String? classId;

  /// Le libellé de la classe choisie, retenu au geste : une autre période peut
  /// ne plus la porter dans son menu, et le filtre resterait actif sans nom.
  final String? selectedClassLabel;
  final String search;

  final List<BeneficiaryArticleOption> articleOptions;
  final bool expanded;
  final bool loadingMore;

  const BoutiqueBeneficiariesState({
    this.status = BeneficiariesStatus.initial,
    this.page,
    this.failure,
    this.articleId,
    this.classId,
    this.selectedClassLabel,
    this.search = '',
    this.articleOptions = const [],
    this.expanded = false,
    this.loadingMore = false,
  });

  bool get hasFilters =>
      articleId != null || classId != null || search.trim().isNotEmpty;

  /// Le libellé de l'article filtré — pour le titre et l'état vide.
  String? get articleLabel {
    for (final option in articleOptions) {
      if (option.id == articleId) return option.label;
    }
    return null;
  }

  /// Le libellé de la classe filtrée : celui du menu de la dernière réponse,
  /// ou, s'il n'y figure plus, celui retenu au geste.
  String? get classLabel {
    if (classId == null) return null;
    for (final c in page?.classes ?? const []) {
      if (c.id == classId) return c.label;
    }
    return selectedClassLabel;
  }

  BoutiqueBeneficiariesState copyWith({
    BeneficiariesStatus? status,
    Object? page = _undefined,
    Object? failure = _undefined,
    Object? articleId = _undefined,
    Object? classId = _undefined,
    Object? selectedClassLabel = _undefined,
    String? search,
    List<BeneficiaryArticleOption>? articleOptions,
    bool? expanded,
    bool? loadingMore,
  }) => BoutiqueBeneficiariesState(
    status: status ?? this.status,
    page: identical(page, _undefined)
        ? this.page
        : page as BoutiqueBeneficiariesPage?,
    failure: identical(failure, _undefined)
        ? this.failure
        : failure as Failure?,
    articleId: identical(articleId, _undefined)
        ? this.articleId
        : articleId as String?,
    classId: identical(classId, _undefined) ? this.classId : classId as String?,
    selectedClassLabel: identical(selectedClassLabel, _undefined)
        ? this.selectedClassLabel
        : selectedClassLabel as String?,
    search: search ?? this.search,
    articleOptions: articleOptions ?? this.articleOptions,
    expanded: expanded ?? this.expanded,
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [
    status,
    page,
    failure,
    articleId,
    classId,
    selectedClassLabel,
    search,
    articleOptions,
    expanded,
    loadingMore,
  ];
}
