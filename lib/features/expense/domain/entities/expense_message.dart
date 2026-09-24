import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';

/// Un message du fil d'une demande (F30).
///
/// **Append-only** : créé, jamais modifié ni supprimé. Chaque geste de
/// décision en écrit un, et son [id] — un uuid fabriqué par le poste — sert
/// de clé d'idempotence au geste comme au message (Q3).
///
/// [body] est SENSIBLE : un motif de refus nomme des fournisseurs et des
/// collègues. Il ne sort donc jamais par `toString()`.
class ExpenseMessage extends Equatable {
  final String id;
  final String expenseId;
  final String body;

  /// L'acte constaté, ou `null` pour un commentaire libre.
  final ExpenseAct? act;

  /// L'identifiant sert à juger la propriété (F24), le nom à l'afficher.
  /// L'identifiant peut manquer sur un message venu d'une session héritée.
  final String? authorId;
  final String? authorName;

  /// L'horloge du geste : c'est elle qui ordonne la séquence (F31).
  final DateTime createdAt;

  final ExpenseSyncState syncState;

  const ExpenseMessage({
    required this.id,
    required this.expenseId,
    required this.body,
    this.act,
    this.authorId,
    this.authorName,
    required this.createdAt,
    this.syncState = ExpenseSyncState.pending,
  });

  /// Un commentaire libre ne constate aucun geste.
  bool get isComment => act == null;

  /// Le serveur n'a pas encore accusé ce message ; il attend dans la file.
  bool get isPending => syncState == ExpenseSyncState.pending;

  /// Le serveur l'a **refusé**, ou un geste antérieur l'a condamné : il ne
  /// partira plus.
  ///
  /// Il reste au fil — celui-ci est append-only — mais il ne doit surtout pas
  /// s'y lire comme accusé : l'horloge seule laisserait croire que le geste a
  /// eu lieu.
  bool get isRejected => syncState == ExpenseSyncState.rejected;

  /// Écrit par le compte de la session ? La comparaison se fait sur
  /// l'identifiant, jamais sur le nom (F24) — et **deux identifiants vides ne
  /// se ressemblent pas** : une session héritée sans `uid` ne s'approprierait
  /// pas tout le fil.
  bool isMine(String? accountId) =>
      accountId != null &&
      accountId.isNotEmpty &&
      authorId != null &&
      authorId == accountId;

  // `body` SENSIBLE : jamais rendu par toString() (fuite par journal).
  @override
  bool? get stringify => false;

  @override
  List<Object?> get props => [
    id,
    expenseId,
    body,
    act,
    authorId,
    authorName,
    createdAt,
    syncState,
  ];
}
