import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';

/// Réclamation du **reçu de vente scellé** (RV) auprès du serveur.
///
/// ## Réclamer, et non émettre
///
/// Le scellement a lieu au push de la vente, côté serveur, et il est
/// *best-effort* : l'ACK peut revenir **sans pièce** sur un 201 parfaitement en
/// ligne, et le handler d'outbox acquitte quand même — c'est le bon arbitrage,
/// l'argent est encaissé. Cette route est la sortie de ce cas : elle ne crée pas
/// une seconde pièce, elle redemande celle qui devait exister.
///
/// Le serveur la sert **idempotente sous verrou**
/// (`boutique_sales.receipt_document_id`) : la rejouer ne brûle aucun numéro de
/// séquence, contrairement au relevé et au quitus. C'est ce qui autorise un
/// bouton que le guichet peut presser deux fois sans rien abîmer.
///
/// ## Pourquoi un contrat à part
///
/// `BoutiqueHistoryRepository` est une **lecture locale seule** — c'est ce qui
/// permet de consulter la caisse quand le réseau manque. Ici il y a un
/// aller-retour réseau **obligatoire**, comme pour toute pièce d'éditique : une
/// pièce est produite maintenant ou pas du tout, et ne passe jamais par
/// l'outbox. Les mêler ferait perdre cette garantie de l'historique.
abstract class BoutiqueReceiptRepository {
  /// Réclame le reçu de [saleId], consigne en local ce que le serveur annonce,
  /// et rend la pièce reçue.
  ///
  /// ⚠️ La pièce peut revenir **sans son numéro** : il ne voyage que dans un
  /// `Content-Disposition` que le contrat OpenAPI ne documente sur aucune route.
  /// L'identifiant d'archive, lui, est annoncé par `X-Document-Id`. Les deux se
  /// traitent donc séparément, et l'appelant ne doit rien promettre sur le
  /// numéro avant de l'avoir lu.
  Future<Either<Failure, EditiqueDocument>> claimSaleReceipt(String saleId);
}
