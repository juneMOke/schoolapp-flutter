import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';

/// Un bloc de signature imprimé au pied des rapports de caisse : sa légende
/// (« ÉTABLI PAR »), le nom, la fonction (« Caissière »).
class ReportSignatory extends Equatable {
  /// L'ordre d'impression, 1..n sans trou.
  final int rank;
  final String caption;

  /// Facultatif : sans nom, le bloc s'imprime avec un blanc à remplir à la
  /// main.
  final String? name;
  final String function;

  /// Rang 1 seulement : sur le journalier, la personne qui a clôturé les
  /// caisses du jour, si elle est seule, remplace [name].
  final bool filledByCloser;

  const ReportSignatory({
    required this.rank,
    required this.caption,
    required this.function,
    this.name,
    this.filledByCloser = false,
  });

  ReportSignatory copyWith({
    int? rank,
    String? caption,
    String? name,
    bool clearName = false,
    String? function,
    bool? filledByCloser,
  }) => ReportSignatory(
    rank: rank ?? this.rank,
    caption: caption ?? this.caption,
    name: clearName ? null : (name ?? this.name),
    function: function ?? this.function,
    filledByCloser: filledByCloser ?? this.filledByCloser,
  );

  @override
  List<Object?> get props => [rank, caption, name, function, filledByCloser];
}

/// Les signataires de l'école, tels que le serveur les sert.
class ReportSignatories extends Equatable {
  /// La liste désignée, dans l'ordre d'impression ; vide si rien n'est
  /// désigné.
  final List<ReportSignatory> signatories;

  /// L'instant du dernier enregistrement, **tel que reçu** (précision à la
  /// microseconde) : il repart tel quel comme `expectedUpdatedAt`. `null` si
  /// rien n'est désigné.
  final String? updatedAtWire;
  final DateTime? updatedAt;
  final String? updatedByName;

  /// Rien n'est désigné : les rapports impriment [defaultSignatories].
  final bool defaults;
  final List<ReportSignatory> defaultSignatories;

  const ReportSignatories({
    required this.signatories,
    required this.defaults,
    this.defaultSignatories = const [],
    this.updatedAtWire,
    this.updatedAt,
    this.updatedByName,
  });

  /// Ce que les rapports impriment aujourd'hui.
  List<ReportSignatory> get printed =>
      defaults ? defaultSignatories : signatories;

  @override
  List<Object?> get props => [
    signatories,
    updatedAtWire,
    updatedAt,
    updatedByName,
    defaults,
    defaultSignatories,
  ];
}

/// `409 SIGNATORIES_CHANGED` : la liste a changé depuis qu'elle a été
/// montrée. Porte la liste actuelle, que l'écran montre à la place ; le geste
/// n'est jamais rejoué.
class SignatoriesChangedFailure extends TreasuryRefusalFailure {
  final ReportSignatories current;

  const SignatoriesChangedFailure(this.current)
    : super(TreasuryRefusal.signatoriesChanged);

  @override
  List<Object?> get props => [...super.props, current];
}
