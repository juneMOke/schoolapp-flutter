import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiary_class.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_beneficiary.dart';

/// Une page de « qui a reçu quoi » — la réponse de
/// `GET /boutique/beneficiaries`.
class BoutiqueBeneficiariesPage extends Equatable {
  /// Calculé **après** les filtres article, classe et recherche.
  final int totalElements;
  final int page;
  final int size;

  /// Les classes de la fenêtre, calculées **avant** les filtres classe et
  /// recherche : c'est la liste du menu, qui ne doit pas se vider dès qu'on y
  /// choisit une classe. Les élèves non placés n'y figurent pas.
  final List<BeneficiaryClass> classes;

  /// Les lignes vendues sans élève désigné (niveau seul) : exclues de la
  /// liste, et l'écran le dit.
  final int walkInLineCount;

  final List<BoutiqueBeneficiary> items;

  /// Quand le serveur a répondu, si la page vient du cache hors ligne.
  final DateTime? cachedAt;

  /// Vrai quand la page est une recherche hors ligne rejouée sur une photo
  /// qui ne portait pas tous les élèves : « aucun élève » n'y prouve rien.
  final bool partial;

  const BoutiqueBeneficiariesPage({
    required this.totalElements,
    required this.page,
    required this.size,
    this.classes = const [],
    this.walkInLineCount = 0,
    this.items = const [],
    this.cachedAt,
    this.partial = false,
  });

  bool get hasMore => (page + 1) * size < totalElements;

  /// Ajoute la page suivante à celle-ci. Les classes et le compte des
  /// walk-in ne dépendent pas de la page : ceux de la dernière réponse font foi.
  BoutiqueBeneficiariesPage append(BoutiqueBeneficiariesPage next) =>
      BoutiqueBeneficiariesPage(
        totalElements: next.totalElements,
        page: next.page,
        size: next.size,
        classes: next.classes,
        walkInLineCount: next.walkInLineCount,
        items: [...items, ...next.items],
        cachedAt: next.cachedAt,
        partial: next.partial,
      );

  BoutiqueBeneficiariesPage cached(DateTime at) => BoutiqueBeneficiariesPage(
    totalElements: totalElements,
    page: page,
    size: size,
    classes: classes,
    walkInLineCount: walkInLineCount,
    items: items,
    cachedAt: at,
    partial: partial,
  );

  @override
  List<Object?> get props => [
    totalElements,
    page,
    size,
    classes,
    walkInLineCount,
    items,
    cachedAt,
    partial,
  ];
}
