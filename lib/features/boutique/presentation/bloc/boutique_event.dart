part of 'boutique_bloc.dart';

sealed class BoutiqueEvent extends Equatable {
  const BoutiqueEvent();

  @override
  List<Object?> get props => [];
}

/// Charge (ou recharge) le catalogue de l'année.
///
/// **Ne touche pas au panier** : un rechargement ne fait jamais perdre une vente
/// en composition.
class BoutiqueCatalogRequested extends BoutiqueEvent {
  final String academicYearId;

  const BoutiqueCatalogRequested(this.academicYearId);

  @override
  List<Object?> get props => [academicYearId];
}

class BoutiqueQueryChanged extends BoutiqueEvent {
  final String query;

  const BoutiqueQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// `null` = « Toutes ».
class BoutiqueFamilyFilterChanged extends BoutiqueEvent {
  final ArticleFamily? family;

  const BoutiqueFamilyFilterChanged(this.family);

  @override
  List<Object?> get props => [family];
}

/// Vide la recherche et repasse à « Toutes ».
class BoutiqueFiltersReset extends BoutiqueEvent {
  const BoutiqueFiltersReset();
}

class BoutiqueArticleAdded extends BoutiqueEvent {
  final BoutiqueArticle article;

  const BoutiqueArticleAdded(this.article);

  @override
  List<Object?> get props => [article];
}

class BoutiqueLineRemoved extends BoutiqueEvent {
  final String lineKey;

  const BoutiqueLineRemoved(this.lineKey);

  @override
  List<Object?> get props => [lineKey];
}

class BoutiqueLineQuantityChanged extends BoutiqueEvent {
  final String lineKey;
  final int quantity;

  const BoutiqueLineQuantityChanged(this.lineKey, this.quantity);

  @override
  List<Object?> get props => [lineKey, quantity];
}

class BoutiqueLineBeneficiaryAssigned extends BoutiqueEvent {
  final String lineKey;
  final CartBeneficiary beneficiary;

  const BoutiqueLineBeneficiaryAssigned(this.lineKey, this.beneficiary);

  @override
  List<Object?> get props => [lineKey, beneficiary];
}

class BoutiqueLineBeneficiaryCleared extends BoutiqueEvent {
  final String lineKey;

  const BoutiqueLineBeneficiaryCleared(this.lineKey);

  @override
  List<Object?> get props => [lineKey];
}

class BoutiqueLineLevelChanged extends BoutiqueEvent {
  final String lineKey;
  final String? schoolLevelId;

  const BoutiqueLineLevelChanged(this.lineKey, this.schoolLevelId);

  @override
  List<Object?> get props => [lineKey, schoolLevelId];
}

class BoutiqueLineSizeChanged extends BoutiqueEvent {
  final String lineKey;
  final String? size;

  const BoutiqueLineSizeChanged(this.lineKey, this.size);

  @override
  List<Object?> get props => [lineKey, size];
}

class BoutiquePayerChanged extends BoutiqueEvent {
  final CartPayer payer;

  const BoutiquePayerChanged(this.payer);

  @override
  List<Object?> get props => [payer];
}

/// « Utiliser » le payeur reconnu au répertoire.
class BoutiquePayerFromDirectoryUsed extends BoutiqueEvent {
  final BoutiquePayer payer;

  const BoutiquePayerFromDirectoryUsed(this.payer);

  @override
  List<Object?> get props => [payer];
}

/// Vide lignes **et** payeur. Sans confirmation : le panier n'est pas encore un
/// engagement.
class BoutiqueCartCleared extends BoutiqueEvent {
  const BoutiqueCartCleared();
}

/// Encaisser le panier — le geste irréversible.
class BoutiqueSaleSubmitted extends BoutiqueEvent {
  final String academicYearId;

  /// Nom du caissier, imprimé sur le ticket. `null` si l'identité n'a pas pu
  /// être résolue — un ticket sans caissier vaut mieux qu'aucune vente.
  final String? cashierName;

  const BoutiqueSaleSubmitted({required this.academicYearId, this.cashierName});

  @override
  List<Object?> get props => [academicYearId, cashierName];
}

/// « Nouvelle vente » : vide le panier, garde l'écran.
class BoutiqueNewSaleStarted extends BoutiqueEvent {
  const BoutiqueNewSaleStarted();
}
